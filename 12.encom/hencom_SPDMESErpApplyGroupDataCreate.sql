IF OBJECT_ID('hencom_SPDMESErpApplyGroupDataCreate') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyGroupDataCreate
GO 

-- v2017.02.20 
-- 확정되지 않은 내역만 재집계 로직 추가 by이재천 
/************************************************************                                                
설  명 - 데이터-출하연동ERP반영_hencom : 합계마감데이터생성                                                
작성일 - 20160321                                               
작성자 - 박수영        
수정: 시간대별투입자재변경으로 자재부분 수정by박수영2015.03.21                                          
************************************************************/                                                
CREATE PROC hencom_SPDMESErpApplyGroupDataCreate                                           
    @xmlDocument    NVARCHAR(MAX),                                                  
    @xmlFlags       INT     = 0,                                                  
    @ServiceSeq     INT     = 0,                                                  
    @WorkingTag     NVARCHAR(10)= '',                                                  
    @CompanySeq     INT     = 1,                                                  
    @LanguageSeq    INT     = 1,                                                  
    @UserSeq        INT     = 0,                                                  
    @PgmSeq         INT     = 0                                                                                                  
AS                                                   
                                                      
    DECLARE @docHandle      INT,                                                
            @DateFr         NCHAR(8) ,                                                
            @DeptSeq        INT  ,                                                
            @MessageType    INT,                                                  
            @Status         INT,                                                  
            @Results        NVARCHAR(250)                                                 
                                                      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                                             
                                                     
                                             
    CREATE TABLE #hencom_TIFProdWorkReportClose (WorkingTag NCHAR(1) NULL)                                                  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClose'                                                     
    IF @@ERROR <> 0 RETURN                                                  
    
    ---- 필수입력 Message 받아오기                                                  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,                                                  
                          @Status      OUTPUT,                                                  
                          @Results     OUTPUT,                                                  
                          1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')                                                  
                          @LanguageSeq       ,                                                   
                          0,''                                                    
                                                   
                                                     
    SELECT SumMesKey  ,CfmCode                                      
      INTO #TMPSumData                                        
      FROM hencom_TIFProdWorkReportCloseSum AS M                                        
     WHERE M.CompanySeq = @CompanySeq                                        
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND DeptSeq = M.DeptSeq AND DateFr = M.WorkDate)                                              
       AND ISNULL(M.CfmCode,'0') = (CASE WHEN @WorkingTag = 'Cancel' THEN ISNULL(M.CfmCode,'0') ELSE '0' END)
    
                                   
    IF  EXISTS (SELECT 1 FROM #TMPSumData WHERE CfmCode = '1')                                
    BEGIN                                
        UPDATE #hencom_TIFProdWorkReportClose                                                 
           SET Result        = '확정처리된 데이터가 존재해서 처리할 수 없습니다.',                                                   
               MessageType   = @MessageType,  
               Status        = @Status                                                 
                               
        SELECT * FROM #hencom_TIFProdWorkReportClose                                                  
        RETURN                                                
    END                                
                                         
        /* ERP반영된 데이터는 체크 ,기존생성되고 ERP반영안된 데이터 삭제 */                                        
         IF EXISTS (SELECT 1                                         
                       FROM hencom_TIFProdWorkReportCloseSum AS M                                        
                       WHERE M.CompanySeq = @CompanySeq                                         
                       AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = M.SumMesKey)                                                      
                       AND (ISNULL(M.ProdIsErpApply,'') <> '' OR ISNULL(M.InvIsErpApply,'') <> '')                                        
        )                                        
         BEGIN                                        
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '이미 ERP반영된 데이터가 있습니다.',                                                  
                    MessageType   = @MessageType,                                                   
                    Status        = @Status                                        
                                                         
               SELECT * FROM #hencom_TIFProdWorkReportClose                                         
                                                     
             RETURN                                        
                                                 
         END                                   
       /*도급비정산 처리된 건이 있는경우 취소 및 재생성할 수 없도록함.      20160810 도급비상관없이 진행될 수 있도록 수정함 */   
    /*                        
             UPDATE #hencom_TIFProdWorkReportClose                        
                SET Result = '도급비정산처리된 데이터가 존재합니다.',                            
                    MessageType   = @MessageType,                            
                    Status        = @Status                            
             FROM #TMPSumData AS M                        
             WHERE EXISTS                         
             (SELECT 1 FROM hencom_TIFProdWorkReportClose                        
                     WHERE CompanySeq = @CompanySeq                         
                     AND MesKey IN ( SELECT MesKey                        
                                     FROM hencom_TPUSubContrCalc WHERE CompanySeq = @CompanySeq )                        
                     AND SumMesKey = M.SumMesKey )                        
         IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                      
         BEGIN                      
             SELECT * FROM #hencom_TIFProdWorkReportClose                      
             RETURN                      
         END                    */  
     
  
         /*규격대체등록된 건 있는 경우 취소 및 재생성할 수 없도록함. */                
         UPDATE #hencom_TIFProdWorkReportClose                        
                SET Result = '규격대체등록된 건이 존재합니다. 규격대체 삭제 후 처리가능합니다.',                            
         MessageType   = @MessageType,                            
                    Status        = @Status                            
                FROM #TMPSumData AS M                           
             WHERE EXISTS (SELECT 1 FROM hencom_TSLCloseSumReplaceMapping                        
                                     WHERE CompanySeq = @CompanySeq                       
                                       AND SumMesKey = M.SumMesKey )                         
         IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                      
         BEGIN                      
             SELECT * FROM #hencom_TIFProdWorkReportClose                      
             RETURN                      
         END                      
                             
                              
                                                 
         --마감데이터 자재 삭제                                        
         DELETE hencom_TIFProdMatInputCloseSum                                         
         FROM hencom_TIFProdMatInputCloseSum AS A                                        
         WHERE A.CompanySeq = @CompanySeq                                          
           AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey  = A.SumMesKey)                                        
           IF @@ERROR <> 0 RETURN                                       --마감데이터 송장 삭제                                                    
         DELETE hencom_TIFProdWorkReportCloseSum                                         
         FROM hencom_TIFProdWorkReportCloseSum AS M                                        
           WHERE M.CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = M.SumMesKey)                                         
         IF @@ERROR <> 0 RETURN                                         
         --송장데이터 마감테이블키 업데이트                                        
         UPDATE hencom_TIFProdWorkReportClose                                        
           SET SumMesKey = NULL  ,IsErpApply = NULL                                      
         FROM hencom_TIFProdWorkReportClose AS A                           
           WHERE CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = A.SumMesKey)                                        
         IF @@ERROR <> 0 RETURN                                         
         --송장자재데이터 마감테이블키 업데이트                                        
         UPDATE hencom_TIFProdMatInputClose                                         
         SET SumMesKey = NULL, SumMesSerl = NULL   ,IsErpApply = NULL                                      
         FROM hencom_TIFProdMatInputClose AS A                                        
           WHERE CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = A.SumMesKey)                                        
         IF @@ERROR <> 0 RETURN                                         
                                                 
         IF @WorkingTag = 'Cancel' --집계취소버튼                            
         BEGIN                            
             SELECT * FROM #hencom_TIFProdWorkReportClose                            
             RETURN                            
         END                            

         /*처리할 데이터 범위 Meskey 담는다.*/                                                
         SELECT M.MesKey,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq,M.DeptSeq , M.UMOutType ,M.ExpShipSeq ,M.WorkDate,M.OutQty,M.SubContrCarSeq , M.BPNo,C.IsCrtProd ,C.IsCrtInvo,M.ProdQty                                        
         INTO #TMPRowData                                                
         FROM hencom_TIFProdWorkReportClose AS M                                                
           LEFT OUTER  JOIN V_mstm_UMOutType AS C ON C.CompanySeq   = @CompanySeq AND C.MinorSeq = M.UMOutType                                           
         WHERE M.companyseq = @CompanySeq                                                 
             AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND DeptSeq = M.DeptSeq AND DateFr = M.WorkDate) 
             AND ISNULL(M.SumMesKey,0) = 0
    
    
    -- 체크, 집계 기준 데이터 중 이미 확정 된 데이터가 존재합니다.
    UPDATE #hencom_TIFProdWorkReportClose
       SET Result = '집계 기준 데이터 중 이미 확정 된 데이터가 존재합니다.' + 
                    ' ( 출하예정번호 : ' + F.ExpShipNo + 
                    ', 출하구분 : ' + D.MinorName + 
                    ', 현장 : ' + E.PJTName + 
                    ', 거래처 : ' + C.CustName + 
                    ', 규격 : ' + B.ItemName + ' )', 
           MessageType = 1234, 
           Status = 1234 
           
      FROM hencom_TIFProdWorkReportCloseSum AS A 
      LEFT OUTER JOIN _TDAItem              AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMOutType ) 
      LEFT OUTER JOIN _TPJTProject          AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN hencom_TSLExpShipment AS F ON ( F.CompanySeq = @CompanySeq AND F.ExpShipSeq = A.ExpShipSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (
                   SELECT 1 
                     FROM #TMPRowData 
                    WHERE GoodItemSeq = A.GoodItemSeq
                      AND CustSeq = A.CustSeq 
                      AND PJTSeq = A.PJTSeq 
                      AND DeptSeq = A.DeptSeq 
                      AND UMOutType = A.UMOutType 
                      AND ExpShipSeq  = A.ExpShipSeq
                      AND BPNo = A.BPNo
                  )
    -- 체크, END 
    
--select * from hencom_TIFProdWorkReportClose where deptseq = 42 and workdate = '20151209'
--GROUP  BY M.CompanySeq,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq  ,M.DeptSeq ,M.UMOutType ,M.ExpShipSeq ,M.BPNo                       

                                                     
           --select * from #TMPRowData return                                  
     --select *                                         
     --from hencom_TIFProdWorkReportCloseSum as a                                         
         --left outer join  hencom_TIFProdMatInputCloseSum as b on b.companyseq = a.companyseq and b.summeskey = a.summeskey                                        
     --where a.workdate = '20151110' and a.deptseq = 49                                        
                                   
     --select *                                         
     --from hencom_TIFProdWorkReportClose as a                                        
   --left outer join  hencom_TIFProdMatInputClose as b on b.companyseq = a.companyseq and b.meskey = a.meskey                                         
     --where a.workdate = '20151110' and a.deptseq = 49                                        
     --return                                        
                                                
         IF NOT EXISTS (SELECT 1 FROM #TMPRowData)                                                
           BEGIN                                                 
             UPDATE #hencom_TIFProdWorkReportClose                                                
             SET Result        = '처리할 데이터가 없습니다.',         
                 MessageType   = @MessageType,                                                  
                     Status         = @Status                                                 
                                
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                                
         END                                        
    

                                                         
           UPDATE #hencom_TIFProdWorkReportClose                                                
               SET Result        = @Results+ CASE WHEN ISNULL(R.GoodItemSeq,0) = 0 THEN '(규격)' WHEN ISNULL(R.CustSeq,0) = 0 THEN '(거래처)'                                         
                                               WHEN ISNULL(R.PJTSeq,0) = 0 THEN '(현장)' WHEN ISNULL(R.DeptSeq,0) = 0  THEN '(사업소)'                                         
                                               WHEN ISNULL(R.UMOutType,0) = 0 THEN '(출고구분)'  WHEN ISNULL(R.ExpShipSeq,0) = 0 THEN '(출하예정)'                                         
     --                WHEN ISNULL(R.ProdQty,0) = 0 THEN '(수량)'                                         
                                             WHEN ISNULL(R.SubContrCarSeq,0) = 0 THEN '(차량)'                                         
                                             WHEN R.IsCrtProd = '1' AND ISNULL(R.ProdQty,0) <> 0 AND (ISNULL(R.BPNo,'') = '' OR R.BPNo = '0') THEN '(호기BP번호)' END ,                                                  
                 MessageType   = @MessageType,                                                  
                 Status        = @Status                                                
           FROM #hencom_TIFProdWorkReportClose AS M                                                 
         JOIN #TMPRowData AS R ON 1=1                                                
         WHERE ISNULL(M.Status,0) = 0                                                
         AND( ISNULL(R.GoodItemSeq,0) = 0  --규격                                                
         OR ISNULL(R.CustSeq,0) = 0  --거래처                                                
         OR ISNULL(R.PJTSeq,0) = 0  --현장                                                
         OR ISNULL(R.DeptSeq,0) = 0  --부서                                                
         OR ISNULL(R.UMOutType,0) = 0 --출고구분                                                 
           OR ISNULL(R.ExpShipSeq,0) = 0   --출하예정번호                                          
         OR ISNULL(R.WorkDate,'') = '' --출하일자                                                       
     --    OR ((R.IsCrtProd = '1' OR R.IsCrtInvo = '1') AND ISNULL(R.ProdQty,0) = 0) --생산수량                                
         OR ISNULL(R.SubContrCarSeq,0) = 0 --차량정보 ERP내부코드                                                
          OR (R.IsCrtProd = '1' AND ISNULL(R.ProdQty,0) <> 0 AND (ISNULL(R.BPNo,'') = '' OR R.BPNo = '0')) --생산할 경우 호기정보없는 경우체크(생산수량 0인 경우 생산하지 않음)                                               
             )                                                  
                                                       
                                                         
                                
         /*필수값 체크처리*/                                                
     IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                                                
     BEGIN                                                 
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                                
     END              
                 
    --생산없이 출고시킬 데이터는 품목자산분류가 서비스인 것만 정상진행되도록 체크(생산여부에 체크되어있지만 생산수량이 0인 경우에 서비스로 진행해야 함.생산하지 않음)        
       IF EXISTS (SELECT 1         
                   FROM #TMPRowData AS A        
                   JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
                     JOIN _TDAItemAsset AS B ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
                   WHERE ((A.IsCrtProd <> '1' AND A.IsCrtInvo = '1') OR (A.IsCrtProd = '1' AND ISNULL(A.ProdQty,0) = 0 )) AND B.AssetSeq <> 3 --품목자산분류: 서비스        
                   )        
       BEGIN        
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '생산없이 출고시킬 데이터(생산수량 0 포함) 중에 품목자산분류가 [서비스] 아닌 규격이 존재합니다.',                                                  
               MessageType   = @MessageType,                                                  
               Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                                                
       END             
               
    --생산하고, 수량이 0이 아닌데 품목자산분류가 서비스인 것 체크.        
       IF EXISTS (SELECT 1         
                   FROM #TMPRowData AS A        
                   JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
                   JOIN _TDAItemAsset AS B ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
                   WHERE A.IsCrtProd = '1' AND ISNULL(A.ProdQty,0) <> 0  AND B.AssetSeq = 3 --품목자산분류: 서비스        
                   )        
       BEGIN        
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '생산하고 수량이 0이 아닌데 품목자산분류가 [서비스]인 규격이 존재합니다.',                                                  
               MessageType   = @MessageType,                                                  
               Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                  
           RETURN                                                
       END         
          
  --출고시킬건데 창고별품목등록에 등록되지 않은 건 체크        
      IF EXISTS (SELECT 1        
              FROM #TMPRowData   AS M                     
              LEFT OUTER JOIN (SELECT Y.ItemSeq, Z.MngDeptSeq,ISNULL(Y.WHSeq,0) AS WHSeq /*창고별품목등록 화면의 품목정보와 창고*/                                   
                                     FROM _TDAWH AS Z                                        
                JOIN _TDAWHItem AS Y  WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq                                      
                                                            AND Y.WHSeq = Z.WHSeq                                
                          WHERE Z.CompanySeq = @CompanySeq                                     
                                   GROUP BY Z.MngDeptSeq ,Y.ItemSeq,Y.WHSeq) AS SW ON SW.MngDeptSeq = M.DeptSeq AND SW.ItemSeq = M.GoodItemSeq           
              WHERE M.IsCrtInvo = '1' AND ISNULL(SW.WHSeq,0) = 0        
      )        
      BEGIN        
          UPDATE #hencom_TIFProdWorkReportClose                                                
                 SET Result        = '출고시킬 데이터중에 창고별품목등록되지 않은 규격이 존재합니다.',                                                  
                   MessageType   = @MessageType,                                                  
                   Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                                                
      END        
                                           
         /*합계마감데이터 생성*/                                                 
           SELECT IDENTITY(INT,1,1) AS DataSeq ,'A' AS WorkingTag ,0 AS Status                                                
                         , CONVERT(NVARCHAR(30),'') AS   SumMesKey                                                
                     , M.CompanySeq                                                
                     , M.GoodItemSeq ,M.CustSeq ,M.PJTSeq                                                 
                     ,M.DeptSeq , M.UMOutType ,M.ExpShipSeq ,MAX(M.WorkDate) AS WorkDate                                                 
                     ,SUM(ISNULL(M.ProdQty,0)) AS ProdQty, SUM(ISNULL(M.OutQty,0)) AS OutQty        
                     ,ISNULL(M.BPNo,'') AS BPNo                                          
                    ,CONVERT(DECIMAL(19,5),NULL) AS ItemPrice --공시단가: 정가: 규격단가                                       
                     ,CONVERT(DECIMAL(19,5),NULL) AS CustPrice --판매기준가                                  
                     ,CONVERT(DECIMAL(19,5),NULL) AS Price --적용단가                                  
                     ,CONVERT(DECIMAL(19,5),NULL) AS VATRate        
                     ,NULL AS IsInclusedVAT                                   
                     ,CONVERT(DECIMAL(19,5),NULL) AS CurAmt        
                     ,CONVERT(DECIMAL(19,5),NULL) AS CurVAT                                   
                     ,CONVERT(DECIMAL(19,5),NULL) AS TempAmt                                  
     --                ,MAX(dbo.hencom_FunGetProdDept( @CompanySeq ,M.DeptSeq )) AS ProdDeptSeq                         
     --                ,dbo.hencom_FunGetProdDept( @CompanySeq ,M.DeptSeq ) AS ProdDeptSeq                     
                     ,dbo.hencom_FunGetProdDept( @CompanySeq ,M.GoodItemSeq ) AS ProdDeptSeq        
                     ,0 AS PurDeptSeq  --매입사업소                                   
                     ,0 AS PurGoodItemSeq --매입사업소의 규격                                  
                     ,dbo.hencom_FnGetFactUnit( @CompanySeq ,M.GoodItemSeq ) AS FactUnit              
                     ,dbo.hencom_FnGetWorkCenter( @CompanySeq ,M.GoodItemSeq) AS WorkCenterSeq              
         INTO #TMPResultData                                                
         FROM hencom_TIFProdWorkReportClose AS M                                                
         LEFT OUTER JOIN hencom_TSLExpShipment AS E ON E.CompanySeq = @CompanySeq AND E.ExpShipSeq = M.ExpShipSeq                                            
         JOIN #TMPRowData AS T ON T.Meskey = M.MesKey                                                
           WHERE M.companyseq = @CompanySeq                 
               GROUP  BY M.CompanySeq,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq  ,M.DeptSeq ,M.UMOutType ,M.ExpShipSeq ,M.BPNo                       
                                                     
     /*생산부서가 여러개 등록된 경우 -1로 체크함.: 부서등록 화면 참고(사업자등록명, 비용구분)*/            
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                      
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType               
                             WHERE ISNULL(A.ProdDeptSeq,0) = -1 AND C.IsCrtProd = '1' )                                             
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                  SET Result        = '해당 부서의 생산부서가 중복등록되어 있습니다.(부서등록,생산사업장별생산품목등록)',                                                  
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                                               
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                       
                             
     --생산데이터 일 경우 생산부서(비용구분 : 제조)가 없는 경우체크                                            
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                                            
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                             
                          WHERE ISNULL(A.ProdDeptSeq,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0)                                            
         BEGIN                                            
               UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '생산부서가(부서등록,생산사업장별생산품목등록 참고) 등록되지 않았습니다.',                                                  
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                     
               SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
             RETURN                                              
         END                      
          /*생산사업장 여러개 등록된 경우 -1로 체크함.: */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.FactUnit,0) = -1 AND C.IsCrtProd = '1' )                                             
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '생산사업장이 중복 등록되어 있습니다.(생산사업장별생산품목등록화면 참고)',                                                  
                 MessageType   = @MessageType,                                                    
                    Status        = @Status                                            
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                
         /*생산사업장 없는경우 : */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                               LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                           
          WHERE ISNULL(A.FactUnit,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0 )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                      
                SET Result        = '생산사업장이 등록되지 않았습니다.(생산사업장별생산품목등록화면 참고)',                                                   
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                  
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                
           /*워크센터 중복인 경우 체크  : */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
         LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.WorkCenterSeq,0) = -1 AND C.IsCrtProd = '1' )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result  = '워크센터가 중복 등록되었습니다.(워크센터등록화면 참고)',                                                  
                    MessageType   = @MessageType,                                          
                    Status        = @Status                                             
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
             RETURN                                              
         END                
             /*워크센터 없는경우 : */                     
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.FactUnit,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0 )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '워크센터가 등록되지 않았습니다.(워크센터등록화면 참고)',                                                  
                      MessageType   = @MessageType,                                                   
                    Status        = @Status                                            
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
          RETURN                                              
         END                
                       
                       
           /*매입사업소 업데이트*/                                  
         UPDATE #TMPResultData                                  
           SET PurDeptSeq  = ISNULL((SELECT MngValSeq FROM _TDACustUserDefine WHERE CompanySeq = @CompanySeq AND CustSeq = E.PurCustSeq AND MngSerl = 1000001),0),                                  
             PurGoodItemSeq = ISNULL((SELECT ItemSeq FROM _TDAItem WHERE CompanySeq = @CompanySeq                                   
                                             AND ItemName = I.ItemName --전출사업소의 규격명칭과 동일한 규격을 전입사업소에서 찾는다.            
                                             AND AssetSeq = I.AssetSeq --품목자산분류 동일한 것. by 박수영 2016.01.26                                 
                                             AND DeptSeq = (SELECT MngValSeq FROM _TDACustUserDefine WHERE CompanySeq = @CompanySeq AND CustSeq = E.PurCustSeq AND MngSerl = 1000001)                                    
                                                            ),0)                                  
           FROM #TMPResultData AS M                                   
           LEFT OUTER JOIN hencom_TSLExpShipment AS E ON E.CompanySeq = @CompanySeq AND E.ExpShipSeq = M.ExpShipSeq                    
         LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = M.GoodItemSeq                                    
         WHERE M.UMOutType = 8020097 ---전출                                  
  
  
     --   select * from #TMPResultData return                                   
         IF EXISTS (SELECT 1 FROM #TMPResultData WHERE UMOutType = 8020097 AND PurDeptSeq = 0 )                                   
         BEGIN                                   
             UPDATE #hencom_TIFProdWorkReportClose                                                
             SET Result        = '전출인 경우 매입사업소가 없습니다.',  
                 MessageType   = @MessageType,                                                  
                 Status        = @Status                             
                                                                         
            SELECT * FROM #hencom_TIFProdWorkReportClose           
            RETURN                                                
         END                                  
    
     ---- 단가생성 ----                                  
         /*0나누기 에러 경고 처리*/                                    
     DECLARE @EnvValue1      NVARCHAR(50),                                     
             @EnvValue2      NVARCHAR(50)                                          
                 
     SET ANSI_WARNINGS OFF                                            
     SET ARITHIGNORE ON                                            
     SET ARITHABORT OFF                                        
                                         
      EXEC dbo._SCOMEnv @CompanySeq, 8040, @UserSeq, @@PROCID, @EnvValue1 OUTPUT                                       
      EXEC dbo._SCOMEnv @CompanySeq, 8041, @UserSeq, @@PROCID, @EnvValue2 OUTPUT                                    
                                            
     --     select * from #TMPResultData                                  
     --     return                                  
                                       
       --단가컬럼 CustPrice, Price 값을 동일하게 생성하고 Price를 사용자가 화면에서 수정가능.                     
       --금액은 출하수량(OutQty)로 계산.                               
         UPDATE #TMPResultData                                            
            SET ItemPrice      = ISNULL(P.Price,0) , --규격별단가                                  
                CustPrice      = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --적용단가  : 규격별단가등록화면의 단가에 현장추가정보등록의 단가율 적용한 단가                                            
                  Price          = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --단가 ISNULL(B.Price,0) * ISNULL(B.PriceRate,0) *0.01 , --실적용단가  : 현장추가정보등록의  절사기준적용                                         
                VATRate        = B.VATRate , --부가세율                                    
                IsInclusedVAT  = B.IsInclusedVAT ,   --부가세포함여부        
                CurVAT          = CASE WHEN  B.IsInclusedVAT = '1' THEN (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) /( 10+ B.VATRate * 0.1 )                                     
                                   ELSE (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) * B.VATRate * 0.01 END   ,        
                  TempAmt        = ROUND(P.Price * B.PriceRate * 0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)                                    
                                                      
         FROM #TMPResultData AS A                                            
         LEFT OUTER JOIN hencom_VPJTAddInfoDate AS B ON B.CompanySeq = @CompanySeq    /*현장추가정보등록*/                                                
         AND B.DeptSeq = A.DeptSeq                                                
                                             AND B.PJTSeq = A.PJTSeq                                          
           AND A.WorkDate BETWEEN B.StartDate AND B.EndDate                                          
         LEFT OUTER JOIN  hencom_VSLItemPrice AS P ON P.CompanySeq = @CompanySeq /*규격별단가등록*/                                                
                                             AND P.DeptSeq = A.DeptSeq                                             
                                                  AND P.ItemSeq = A.GoodItemSeq                                              
                                                  AND P.UMPriceType = B.UMPriceType                                          
                                                    AND A.WorkDate BETWEEN P.StartDate AND P.EndDate                                            
             LEFT OUTER JOIN hencom_ViewRoundStd AS RS ON RS.CompanySeq = @CompanySeq                                         
                                                 AND RS.UMTruncateType = B.UMTruncateType                                   
         WHERE A.UMOutType <> 8020097 ---전출 아닌것     
                                      
       --전출인 것은 따로 단가생성                                  
       UPDATE #TMPResultData                                            
            SET ItemPrice      = ISNULL(P.Price,0) , --규격별단가                                  
                CustPrice      = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --적용단가  : 규격별단가등록화면의 단가에 현장추가정보등록의 단가율 적용한 단가                                            
                Price          = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --단가 ISNULL(B.Price,0) * ISNULL(B.PriceRate,0) *0.01 , --실적용단가  : 현장추가정보등록의  절사기준적용                                         
                VATRate        = B.VATRate , --부가세율                                    
                IsInclusedVAT  = B.IsInclusedVAT ,   --부가세포함여부                                      
                  CurVAT         = CASE WHEN B.IsInclusedVAT = '1' THEN (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) /( 10+ B.VATRate * 0.1 )                                     
                                   ELSE (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) * B.VATRate * 0.01 END   ,                                  
                TempAmt      = ROUND(P.Price * B.PriceRate * 0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)                                    
                                                      
          FROM #TMPResultData AS A                                            
         LEFT OUTER JOIN hencom_VPJTAddInfoDate AS B ON B.CompanySeq = @CompanySeq    /*현장추가정보등록*/                                           
                                             AND B.DeptSeq = A.PurDeptSeq   
                                             AND B.PJTSeq = A.PJTSeq                                          
                                             AND A.WorkDate BETWEEN B.StartDate AND B.EndDate                                          
         LEFT OUTER JOIN  hencom_VSLItemPrice AS P ON P.CompanySeq = @CompanySeq /*규격별단가등록*/                                                
                                                  AND P.DeptSeq = A.PurDeptSeq                                              
                                                  AND P.ItemSeq = A.PurGoodItemSeq                                              
                                                  AND P.UMPriceType = B.UMPriceType                                          
                                                  AND A.WorkDate BETWEEN P.StartDate AND P.EndDate                                           
    LEFT OUTER JOIN hencom_ViewRoundStd AS RS ON RS.CompanySeq = @CompanySeq                                          
                                                   AND RS.UMTruncateType = B.UMTruncateType                                   
         WHERE A.UMOutType = 8020097 ---전출 인것                           
                                           
                                              
     --     select * from #TMPResultData                                   
     --     return                                  
     --                                       
                                      
         IF @EnvValue1 = 1003001 --반올림                                    
         BEGIN                                    
             UPDATE #TMPResultData                                    
             SET CurVAT = ISNULL(ROUND(CurVAT,0),0), --소수점첫자리에서 반올림                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - ROUND(CurVAT,0)                                    
                                    ELSE  TempAmt END , 0 )  --금액                                    
                                                 
         END                                     
           IF @EnvValue1  = 1003002 --절사                                    
         BEGIN                                    
             UPDATE #TMPResultData                                    
             SET CurVAT = ISNULL(ROUND(CurVAT,0,1),0), --소수점첫자리에서 절사                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - ROUND(CurVAT,0,1)                                    
                                 ELSE  TempAmt END,0)  --금액                                    
                                                 
           END                                      
                                             
         IF @EnvValue1 = 1003003 --올림                                    
         BEGIN                                    
             UPDATE #TMPResultData                                     
               SET CurVAT = ISNULL(CEILING(CurVAT),0), --소수점이하 올림                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - CEILING(CurVAT)                                    
                                 ELSE  TempAmt END,0)  --금액                                    
                                                 
         END                     
                                  
           /*금액 체크처리: 금액0인 건 체크: 출고데이터생성하는 경우 필수.*/                                                
     --    IF EXISTS (SELECT 1 FROM #TMPResultData AS A                                            
     --                        LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                              
     --                        WHERE ISNULL(A.Price,0) = 0 AND C.IsCrtInvo = '1' )                                                  
     --    BEGIN                                                
         --         UPDATE #hencom_TIFProdWorkReportClose                                                
     --        SET Result        = '출고를 생성하는 데이터중에 금액이 0인 규격( '+I.ItemName+' )이 있습니다.'+'(현장:'+ P.PJTName+', 현장번호:'+P.PJTNo+')',                                                  
     --            MessageType   = @MessageType,                                                  
       --            Status        = @Status                                                
       --        FROM #TMPResultData AS A                                             
     --        LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                             
       --        LEFT OUTER JOIN _TDAItem  AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq =A.GoodItemSeq                                            
       --        LEFT OUTER  JOIN _TPJTProject AS P ON P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq                                            
     --        WHERE ((ISNULL(A.Price,0) = 0 OR A.CurAmt = 0 ) AND C.IsCrtInvo = '1' )                                           
     --                                                            
     --        SELECT * FROM #hencom_TIFProdWorkReportClose                      
     --        RETURN                                              
     --    END                                                 
                                                       
         /*키생성*/                                                
         DECLARE @MaxSeq INT,                                                  
                 @Count  INT                                                   
          SELECT @Count = Count(1) FROM #TMPResultData WHERE WorkingTag = 'A' AND Status = 0                                                  
         IF @Count >0                                                    
         BEGIN                                                  
                 EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TIFProdWorkReportCloseSum','SumMesKey',@Count --rowcount                                                     
               UPDATE #TMPResultData                                                               
                  SET SumMesKey  = @MaxSeq + DataSeq                                                     
           WHERE WorkingTag = 'A'                                                               
                  AND Status = 0                                                   
         END                                  
         IF @@ERROR <> 0 RETURN                                        
     --키값 생성안될 경우 체크                                        
         IF EXISTS (SELECT 1 FROM  #TMPResultData  WHERE WorkingTag = 'A'                                                               
                                                         AND Status = 0                                           
                                                         AND ISNULL(SumMesKey ,0) = 0                                                          
                   )                                        
         BEGIN                                         
               UPDATE #hencom_TIFProdWorkReportClose                                 
                SET Result        = 'Key(SumMesKey)값이 생성되지 않았습니다.',                                                  
                    MessageType   = @MessageType,                                                   
                    Status        = @Status                                        
                 
              SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                         
         END      
 --0단가적용 처리 by박수영 2016.02.25    
      UPDATE #TMPResultData    
      SET Price       = 0,                    
          CurAmt      = 0,                    
          CurVAT      = 0,                    
          ItemPrice   = 0,                    
          CustPrice   = 0    
      FROM #TMPResultData AS M    
      JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = M.UMOutType    
      WHERE C.SetPrice = 1011590002 --단가적용방법: 0단가      
      AND M.Status = 0    
          IF EXISTS (SELECT 1 FROM #TMPResultData WHERE WorkingTag = 'A' AND Status = 0)                                                  
           BEGIN                                                   
                                                     
             INSERT INTO hencom_TIFProdWorkReportCloseSum(CompanySeq,SumMesKey,GoodItemSeq,CustSeq,PJTSeq                                                
                                                         ,DeptSeq,UMOutType,ExpShipSeq,WorkDate ,BPNo                              
,ProdQty,OutQty,CurAmt,CurVAT,Price                                                 
           ,LastUserSeq,LastDateTime,ProdDeptSeq,ItemPrice,CustPrice,VATRate,IsInclusedVAT              
                                                         ,FactUnit,WorkCenterSeq,PurDeptSeq )         
               SELECT CompanySeq, SumMesKey , GoodItemSeq ,CustSeq ,PJTSeq                                                 
                     ,DeptSeq , UMOutType ,ExpShipSeq ,WorkDate  ,BPNo                                               
                     ,ProdQty AS ProdQty, OutQty,  ISNULL(CurAmt,0) , ISNULL(CurVAT,0) , ISNULL(Price,0)                                                
                     ,@UserSeq AS LastUserSeq , GETDATE() AS LastDateTime ,ProdDeptSeq,ISNULL(ItemPrice,0),ISNULL(CustPrice,0),ISNULL(VATRate,0),IsInclusedVAT               
                     ,FactUnit,WorkCenterSeq,PurDeptSeq--매입사업소추가 2016.01.11by박수영                                           
             FROM  #TMPResultData                                                 
             IF @@ERROR <> 0 RETURN                               
         
         /*원천데이터에 마감데이터 키값을 업데이트*/                                         
                                                        
           UPDATE hencom_TIFProdWorkReportClose                                                
         SET SumMesKey = B.SumMesKey ,                                      
             IsErpApply = '1'                                      
         FROM hencom_TIFProdWorkReportClose AS A                                 
         JOIN #TMPResultData AS B ON B.CompanySeq = A.CompanySeq                                                 
                                 AND B.GoodItemSeq = A.GoodItemSeq                                                  
                                 AND B.CustSeq = A.CustSeq                                                 
                                 AND B.PJTSeq = B.PJTSeq                                                 
                                 AND B.DeptSeq = A.DeptSeq                                                 
                                 AND B.UMOutType = A.UMOutType                                                 
                                 AND B.ExpShipSeq = A.ExpShipSeq          
                                 AND B.BPNo = A.BPNo                                                
         WHERE A.CompanySeq = @CompanySeq                                                 
         AND EXISTS (SELECT 1 FROM #TMPRowData WHERE MesKey = A.MesKey)                                                                      
                                                
         IF @@ERROR <> 0 RETURN                                                
                           
         /*투입자재 대상*/                                                  
         SELECT A.CompanySeq ,A.MesKey,A.MesSerl ,A.MatItemName, M.SumMesKey ,A.Qty ,A.MatItemSeq                                              
         INTO #TMPMaiItem                                            
           FROM hencom_TIFProdMatInputClose AS A                                                 
         JOIN #TMPRowData AS B ON B.MesKey = A.MesKey                                                
        JOIN hencom_TIFProdWorkReportClose AS M ON M.MesKey = A.MesKey AND M.CompanySeq = A.CompanySeq                                              
         WHERE A.CompanySeq = @CompanySeq                                   
     --    AND ISNULL(A.Qty,0) <> 0 --자재수량이 0인것은 제외                                  
         AND ISNULL(A.SumMesKey,'') = ''                                        
       --    AND  NOT EXISTS (SELECT 1 FROM  _TDAUMinor AS UM                            
     --                            LEFT OUTER JOIN _TDAUMinorValue AS UMV ON UMV.companyseq = UM.CompanySeq                             
       --                                                                     AND UMV.MajorSeq = UM.MajorSeq                             
       --                                                                 AND UMV.MinorSeq = UM.minorSeq                             
       --                                                                AND UMV.Serl = 1000001                                
     --               WHERE UM.CompanySeq = @CompanySeq                           
       --                                            AND UM.MajorSeq = 1011629                            
     --                                            AND UM.MinorName = A.MatItemName                          
     --                                            AND ISNULL(UMV.ValueText,'') = '1' --자재투입제외 체크된 건 제외                           
     --                                     )                            
                                                       
       IF EXISTS (SELECT 1 FROM #TMPMaiItem WHERE ISNULL(MatItemName,'') = '')                                              
       BEGIN                                              
    UPDATE #hencom_TIFProdWorkReportClose                                                 
               SET Result        = '투입자재명이 없는 데이터가 있습니다.',                                                  
                   MessageType   = @MessageType,                                                  
                   Status        = @Status                                                  
                                                   
               SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                               
         END               
    --생산반영하는 출고구분인데 자재가 없는 경우 체크('W1','W2','W3' 제외하고 수량이 0,자재데이터가 없는경우)  :예외- 동여주, 송악_아스콘     
        IF EXISTS ( SELECT 1         
                   FROM #TMPRowData AS M        
                   WHERE M.IsCrtProd = '1' AND ISNULL(M.ProdQty,0) <> 0  AND DeptSeq NOT IN  (31,53)    
 --               AND ISNULL((SELECT SUM(ISNULL(Qty,0)) FROM #TMPMaiItem WHERE MesKey = M.MesKey AND MatItemName NOT IN('W1','W2','W3')),0) = 0    
                 AND ISNULL((SELECT SUM(ISNULL(Qty,0)) FROM #TMPMaiItem WHERE MesKey = M.MesKey   
                 AND MatItemName NOT IN( SELECT B.MinorName  
                                         FROM _TDAUMinorValue AS A  
                                         LEFT OUTER JOIN _TDAUMinor AS B ON B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq  
                                         WHERE A.CompanySeq = @CompanySeq AND A.MajorSeq = 1011629  
                                         AND  A.Serl = 1000001     
                                         AND ISNULL(A.ValueText,'') = '1' )  
                 ),0) = 0 )
       BEGIN                                               
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '생산할 데이터중에 투입할 자재가 없습니다.',                                                  
               MessageType   = @MessageType,                                                  
               Status        = @Status        
                       
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                           
       END                        
    

        -- ERP, MES 데이터 일치확인, Srt
        DECLARE @ErpQty DECIMAL(19,5), 
                @MesQty DECIMAL(19,5) 


        SELECT @ErpQty = SUM(ISNULL(Qty,0)) 
          FROM hencom_TIFProdMatInputClose AS A WITH(NOLOCK)  
         WHERE A.CompanySeq = @CompanySeq 
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE DateFr = A.WorkDate AND DeptSeq = A.DeptSeq) 
    
        SELECT @MesQty = 
               SUM(
                   ISNULL(b_g1, 0) + ISNULL(b_g2, 0) + ISNULL(b_g3, 0) + ISNULL(b_g4, 0) + 
                   ISNULL(b_s1, 0) + ISNULL(b_s2, 0) + ISNULL(b_s3, 0) + ISNULL(b_s4, 0) + 
                   ISNULL(b_ad1, 0) + ISNULL(b_ad2, 0) + ISNULL(b_ad3, 0) + ISNULL(b_ad4, 0) + ISNULL(b_ad5, 0) + ISNULL(b_ad6, 0) +
                   ISNULL(b_w1, 0) + ISNULL(b_w2, 0) + ISNULL(b_w3, 0) + 
                   ISNULL(b_c1, 0) + ISNULL(b_c2, 0) + ISNULL(b_c3, 0) + ISNULL(b_c4, 0) + ISNULL(b_c5, 0) + ISNULL(b_c6, 0)
                  )
          FROM hencom_TIFBCPProdClose AS A with(nolock)
         WHERE A.CompanySeq = @CompanySeq 
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE DateFr = A.b_date AND DeptSeq = A.DeptSeq) 
        
        IF ISNULL(@ErpQty,0) <> ISNULL(@MesQty,0)
        BEGIN
            UPDATE #hencom_TIFProdWorkReportClose                                                
            SET Result        = 'ERP와 MES 수량이 일치하지 않습니다.',                                                  
                MessageType   = 1234,                                                  
                Status        = 1234        
                       
            SELECT * FROM #hencom_TIFProdWorkReportClose                                                
            RETURN   
        END 
        -- ERP, MES 데이터 일치확인, End
            --@DeptSeq        INT  ,                                                
            --@MessageType    INT,                                                  
            --@Status         INT,                                                  
            --@Results        NVARCHAR(250)        
 
 
--select sum(IsNull(b_g1, 0) + IsNull(b_g2, 0) + IsNull(b_g3, 0) + IsNull(b_g4, 0) + 
--       IsNull(b_s1, 0) + IsNull(b_s2, 0) + IsNull(b_s3, 0) + IsNull(b_s4, 0) + 
--       IsNull(b_ad1, 0) + IsNull(b_ad2, 0) + IsNull(b_ad3, 0) + IsNull(b_ad4, 0) + IsNull(b_ad5, 0) + IsNull(b_ad6, 0) +
--       IsNull(b_w1, 0) + IsNull(b_w2, 0) + IsNull(b_w3, 0) + 
--       IsNull(b_c1, 0) + IsNull(b_c2, 0) + IsNull(b_c3, 0) + IsNull(b_c4, 0) + IsNull(b_c5, 0) + IsNull(b_c6, 0))
--from    hencom_TIFBCPProdClose with(nolock)
--where   deptseq = 49 and b_date = '20170628'
 
                                                                   
     --    IF EXISTS (SELECT 1 FROM #TMPMaiItem WHERE ISNULL(Qty,0) = 0)                                              
     --    BEGIN                                              
     --          UPDATE #hencom_TIFProdWorkReportClose                                                
     --        SET Result        = '투입자재 수량이 없는 데이터가 있습니다.',         
       --            MessageType   = @MessageType,                              --            Status        = @Status                                                    
     --                                              
         --        SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
     --        RETURN                                               
     --    END                                              
                                  
                                                     
        SELECT A.SumMesKey, A.MatItemName ,ISNULL(A.MatItemSeq,0) AS MatItemSeq , A.CompanySeq , SUM(B.Qty) AS Qty , ROW_NUMBER() OVER(PARTITION BY A.SumMesKey ORDER BY A.MatItemName ) AS DataSeq                                                  
        INTO #TMPMatItemResult                                                
         FROM #TMPMaiItem AS A                                                
        JOIN hencom_TIFProdMatInputClose AS B ON B.CompanySeq = A.CompanySeq   
                                            AND B.MesKey = A.MesKey   
                                            AND B.MesSerl = A.MesSerl                                                
        GROUP BY A.SumMesKey, A.MatItemName , A.CompanySeq  ,ISNULL(A.MatItemSeq,0)                                          
                                          
         INSERT  INTO hencom_TIFProdMatInputCloseSum (CompanySeq,SumMesKey,SumMesSerl,MatItemName,Qty,LastUserSeq,LastDateTime ,MatItemSeq)                                                              
         SELECT CompanySeq,SumMesKey, DataSeq, MatItemName , Qty ,@UserSeq,GETDATE() ,MatItemSeq                                                  
         FROM #TMPMatItemResult                                                 
         IF @@ERROR <> 0 RETURN                                         
           
         /*투입자재테이블에  업데이트*/                                                
         UPDATE hencom_TIFProdMatInputClose                                                
         SET SumMesKey = B.SumMesKey ,                                                
             SumMesSerl = C.SumMesSerl  ,                                      
             IsErpApply = '1'                                              
         FROM hencom_TIFProdMatInputClose AS A                                                  
         JOIN #TMPMaiItem AS B ON B.MesKey = A.MesKey AND B.MesSerl = A.MesSerl                                                
         JOIN hencom_TIFProdMatInputCloseSum AS C ON C.CompanySeq = A.CompanySeq   
                                                   AND C.SumMesKey = B.SumMesKey   
                                                   AND C.MatItemName = B.MatItemName    
                                                   AND ISNULL(C.MatItemSeq,0) = ISNULL(B.MatItemSeq,0)                                               
         WHERE A.CompanySeq = @CompanySeq                                                
         IF @@ERROR <> 0 RETURN                                         
      END                                                   
                  
       SELECT * FROM #hencom_TIFProdWorkReportClose       
                             
       --결과확인      
     /*  
 --        select * from hencom_TIFProdWorkReportClosesum where summeskey in (                 
 --        select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151229' and deptseq = 39  )           
          select * from hencom_TIFProdMatInputClose where summeskey in (                 
         select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151231' and deptseq = 40  )   
          select * from hencom_TIFProdMatInputCloseSum where summeskey in (                 
         select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151231' and deptseq = 40  )   
     */  
       RETURN
