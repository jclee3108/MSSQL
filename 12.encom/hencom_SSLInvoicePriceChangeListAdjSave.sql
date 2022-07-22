IF OBJECT_ID('hencom_SSLInvoicePriceChangeListAdjSave') IS NOT NULL 
    DROP PROC hencom_SSLInvoicePriceChangeListAdjSave
GO 
  
/************************************************************  
 설  명 - 데이터-단가확정수정(가계정정리를위한)_hencom : 차이조정생성  
 작성일 - 20160907  
 작성자 - 영림원  
************************************************************/  
CREATE PROC dbo.hencom_SSLInvoicePriceChangeListAdjSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #hencom_TAcAdjTempAccount2 (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TAcAdjTempAccount2'       
 IF @@ERROR <> 0 RETURN    
                        
 DECLARE @Count INT,  
         @Seq   INT,  
         @AdjYM NCHAR(6),   
         @DeptSeq INT,  
         @MWorkingTag NVARCHAR(10)  
           
     SELECT @AdjYM = YM,  
         @DeptSeq = DeptSeq,  
         @MWorkingTag = WorkingTag  
    FROM #hencom_TAcAdjTempAccount2    
           
     SELECT @MWorkingTag = ISNULL(@MWorkingTag,'')  
   
 ------------------------------------------------------  
 -- TEMP테이블생성(처리)  
 ------------------------------------------------------  
     CREATE TABLE #TempResult2(DeptSeq INT, CustSeq INT, PJTSeq INT, WorkDate NCHAR(8), SumMesKey NVARCHAR(30), SumMesKeyNo INT,    
                               GoodItemSeq INT, CurAmt DECIMAL(19,5), ReplaceRegSeq INT, ReplaceRegSerl INT,     
                               RepCustSeq INT, RepPJTSeq INT, RepItemSeq INT, RepCurAmt DECIMAL(19,5),
                               ATARegSeq INT, AdjAmt DECIMAL(19,5), SlipSeq INT, IsAllReplace NCHAR(1))            
                                 
     CREATE TABLE #hencom_TAcAdjTempAccountSub(WorkingTag NVARCHAR(10), Status INT, DataSeq INT IDENTITY, ATARegSeq INT, AdjYM NCHAR(6),  
                                            DeptSeq INT, AdjAmt DECIMAL(19,5), SlipSeq INT, Remark NVARCHAR(200), ReplaceRegSeq INT,   ReplaceRegSerl INT , 
                                            IsCustChg NCHAR(1))  

     CREATE TABLE #hencom_TAcAdjTempAccount(WorkingTag NVARCHAR(10), Status INT, DataSeq INT IDENTITY, ATARegSeq INT, AdjYM NCHAR(6),  
                                            DeptSeq INT, AdjAmt DECIMAL(19,5), SlipSeq INT, Remark NVARCHAR(200), ReplaceRegSeq INT,   ReplaceRegSerl INT , 
                                            IsCustChg NCHAR(1))  
   
 ------------------------------------------------------  
 -- 생성데이터 TEMP  
 ------------------------------------------------------  
 IF @MWorkingTag <> 'D'  
 BEGIN  
   
   INSERT INTO #TempResult2(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,     
          ReplaceRegSeq, ReplaceRegSerl, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, AdjAmt)    
   SELECT CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END AS DeptSeq,      
    A.CustSeq,      
    A.PJTSeq,      
    A.WorkDate,      
    A.SumMesKey,      
    ROW_NUMBER() OVER (PARTITION BY A.SumMesKey ORDER BY a.SumMesKey) AS SumMesKeyNo,      
    A.GoodItemSeq,      
    A.CurAmt,      
    M.ReplaceRegSeq,      
    M.ReplaceRegSerl,      
    RI.CustSeq as RepCustSeq,      
    RI.PJTSeq as RepPJTSeq,      
    RI.ItemSeq as RepItemSeq,      
    M.CurAmt as RepCurAmt,      
    ISNULL(A.CurAmt,0) - ISNULL(M.CurAmt,0)  AS AdjAmt 
     FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)       
     LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq      
                    AND M.SumMesKey = A.SumMesKey      
     LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS RI WITH(NOLOCK) ON RI.CompanySeq = A.CompanySeq      
                    AND RI.ReplaceRegSeq = M.ReplaceRegSeq      
                    AND RI.ReplaceRegSerl = M.ReplaceRegSerl        
     JOIN hemcom_TSLBillReplaceRelation               AS B  WITH(NOLOCK) ON M.CompanySeq = B.CompanySeq               
                     AND M.ReplaceRegSeq = B.ReplaceRegSeq               
                     AND M.ReplaceRegSerl = B.ReplaceRegSerl            
                     AND M.IsReplace = '1'      
     JOIN _TSLBill AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq  
            AND C.BillSeq = B.BillSeq   
    WHERE A.CompanySeq = @CompanySeq      
   AND A.WorkDate LIKE @AdjYM + '%'      
     AND CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END = @DeptSeq      
   AND ISNULL(a.SalesSeq,0) <> 0      
   AND ISNULL(ri.IsPreSales,'0') <> '1'    
      AND ISNULL(C.SlipSeq,0) <> 0  
      AND M.ReplaceRegSeq NOT IN (SELECT B.ReplaceRegSeq   
                                    FROM hencom_TAcAdjTempAccount AS B WITH(NOLOCK)  
                                    JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                     AND C.SlipSeq = B.SlipSeq  
                                   WHERE B.CompanySeq = @CompanySeq  
                                     AND ISNULL(C.SlipSeq,0) <> 0)     

    -- 생성부터 INSERT  
  INSERT INTO #hencom_TAcAdjTempAccountSub(WorkingTag, Status, ATARegSeq, AdjYM, DeptSeq, AdjAmt, SlipSeq, ReplaceRegSeq)  
  SELECT 'A', 0, 0, @AdjYM, @DeptSeq, ISNULL(CurAmt,0) - SUM(ISNULL(RepCurAmt,0)), 0, ReplaceRegSeq
    FROM #TempResult2  
   WHERE ISNULL(CustSeq,0) <> ISNULL(RepCustSeq,0) OR ISNULL(AdjAmt,0) <> 0  
   GROUP BY ReplaceRegSeq, SumMesKey, CurAmt  
   ORDER BY ReplaceRegSeq, SumMesKey   

   INSERT INTO #hencom_TAcAdjTempAccount(WorkingTag, Status, ATARegSeq, AdjYM, DeptSeq, AdjAmt, SlipSeq, ReplaceRegSeq)  
   SELECT MAX(WorkingTag), MAX(Status), MAX(ATARegSeq), MAX(AdjYM), MAX(DeptSeq), SUM(AdjAmt), MAX(SlipSeq), ReplaceRegSeq
     FROM #hencom_TAcAdjTempAccountSub 
    GROUP BY ReplaceRegSeq 
   

  UPDATE #hencom_TAcAdjTempAccount  
     SET IsCustChg = '1'  
    FROM #hencom_TAcAdjTempAccount AS A  
    JOIN (SELECT DISTINCT ReplaceRegSeq, CustSeq, RepCustSeq  
            FROM #TempResult2  
           WHERE CustSeq <> RepCustSeq) AS B ON B.ReplaceRegSeq = A.ReplaceRegSeq  
    
  ---- 생성부터 INSERT  
  --INSERT INTO #hencom_TAcAdjTempAccount(WorkingTag, Status, ATARegSeq, AdjYM, DeptSeq, AdjAmt, SlipSeq, ReplaceRegSeq)  
  --SELECT 'A', 0, 0, @AdjYM, @DeptSeq, ISNULL(SUM(A.CurAmt),0) - ISNULL(SUM(M.CurAmt),0), 0, M.ReplaceRegSeq  
  --  FROM hencom_TIFProdWorkReportCloseSum            AS A  WITH(NOLOCK)   
  --  LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq    
  --                 AND M.SumMesKey = A.SumMesKey    
  --  LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem     AS RI WITH(NOLOCK) ON RI.CompanySeq = A.CompanySeq    
  --                  AND RI.ReplaceRegSeq = M.ReplaceRegSeq    
  --                  AND RI.ReplaceRegSerl = M.ReplaceRegSerl      
  --  JOIN hemcom_TSLBillReplaceRelation               AS B  WITH(NOLOCK) ON M.CompanySeq = B.CompanySeq               
  --                  AND M.ReplaceRegSeq = B.ReplaceRegSeq               
  --                  AND M.ReplaceRegSerl = B.ReplaceRegSerl            
  --                  AND M.IsReplace = '1'       
  --  JOIN _TSLBill AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq  
  --        AND C.BillSeq = B.BillSeq  
  --WHERE A.CompanySeq = M.CompanySeq  
  --  AND A.WorkDate LIKE @AdjYM + '%'  
  --  AND CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END = @DeptSeq  
  --  AND ISNULL(A.SalesSeq,0) <> 0   
  --  AND ISNULL(ri.IsPreSales,'0') <> '1'  
  --  AND ISNULL(C.SlipSeq,0) <> 0  
  --  AND (ISNULL(A.CustSeq,0) <> ISNULL(RI.CustSeq,0) OR ISNULL(A.CurAmt,0) <> ISNULL(M.CurAmt,0))  
  --  AND M.ReplaceRegSeq NOT IN (SELECT B.ReplaceRegSeq   
  --                                FROM hencom_TAcAdjTempAccount AS B WITH(NOLOCK)  
  --                                JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
  --                                 AND C.SlipSeq = B.SlipSeq  
  --                               WHERE B.CompanySeq = @CompanySeq  
  --                                 AND ISNULL(C.SlipSeq,0) <> 0)  
  --GROUP BY M.ReplaceRegSeq   
    
  -- 생성시 이미 존재할 경우(전표처리X) 삭제하고 다시 생성할 수 있도록 'D' 데이터를 자동으로 넣어줌  
  INSERT INTO #hencom_TAcAdjTempAccount(WorkingTag, Status, ATARegSeq, AdjYM, DeptSeq, AdjAmt, SlipSeq, ReplaceRegSeq)  
  SELECT 'D', 0, B.ATARegSeq, B.AdjYM, B.DeptSeq, B.AdjAmt, B.SlipSeq, B.ReplaceRegSeq  
    FROM hencom_TAcAdjTempAccount AS B WITH(NOLOCK)  
    LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                AND C.SlipSeq = B.SlipSeq  
   WHERE B.CompanySeq = @CompanySeq  
     AND B.ReplaceRegSeq IN (SELECT ReplaceRegSeq FROM #hencom_TAcAdjTempAccount WHERE WorkingTag = 'A')  
     AND ISNULL(C.SlipSeq,0) = 0  
 END  
   
   ------------------------------------------------------  
 -- 시트삭제데이터 TEMP  
 ------------------------------------------------------  
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TAcAdjTempAccount2 WHERE WorkingTag = 'D')  
 BEGIN  
  INSERT INTO #hencom_TAcAdjTempAccount(WorkingTag, Status, ATARegSeq, AdjYM, DeptSeq, AdjAmt, SlipSeq, ReplaceRegSeq)  
  SELECT DISTINCT A.WorkingTag, 0, B.ATARegSeq, B.AdjYM, B.DeptSeq, B.AdjAmt, B.SlipSeq, A.ReplaceRegSeq  
    FROM #hencom_TAcAdjTempAccount2 AS A  
    JOIN hencom_TAcAdjTempAccount AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
               AND B.ReplaceRegSeq = A.ReplaceRegSeq  
    LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                AND C.SlipSeq = B.SlipSeq  
   WHERE A.WorkingTag = 'D'   
     AND ISNULL(C.SlipSeq,0) = 0  
 END      
   
 ------------------------------------------------------            
    -- INSERT 번호부여  
 ------------------------------------------------------           
    SELECT @Count = COUNT(1) FROM #hencom_TAcAdjTempAccount WHERE WorkingTag = 'A' AND Status = 0              
    IF @Count > 0              
    BEGIN                                         
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TAcAdjTempAccount', 'ATARegSeq', @Count      
          
        UPDATE #hencom_TAcAdjTempAccount              
           SET ATARegSeq = @Seq + DataSeq              
         WHERE WorkingTag = 'A'        
           AND Status = 0     
    END             
  
 ------------------------------------------------------            
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 ------------------------------------------------------  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          'hencom_TAcAdjTempAccount', -- 원테이블명  
          '#hencom_TAcAdjTempAccount', -- 템프테이블명  
          'ATARegSeq      ' , -- 키가 여러개일 경우는 , 로 연결한다.   
          'CompanySeq     ,ATARegSeq      ,AdjYM          ,DeptSeq        ,AdjAmt         ,  
           SlipSeq        ,Remark         ,LastUserSeq    ,LastDateTime   ,ReplaceRegSeq  ,  
           IsCustChg      '  
  
 ------------------------------------------------------            
    -- DELETE  
 ------------------------------------------------------   
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TAcAdjTempAccount WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE hencom_TAcAdjTempAccount  
     FROM #hencom_TAcAdjTempAccount A   
       JOIN hencom_TAcAdjTempAccount B ON ( A.ATARegSeq      = B.ATARegSeq )                            
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
 ------------------------------------------------------            
    -- INSERT  
 ------------------------------------------------------   
 IF EXISTS (SELECT 1 FROM #hencom_TAcAdjTempAccount WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO hencom_TAcAdjTempAccount ( CompanySeq     ,ATARegSeq      ,AdjYM          ,DeptSeq        ,AdjAmt         ,  
                                          SlipSeq        ,Remark         ,LastUserSeq    ,LastDateTime   ,ReplaceRegSeq  ,  
                                          IsCustChg      )   
   SELECT @CompanySeq    ,ATARegSeq      ,AdjYM          ,DeptSeq        ,AdjAmt         ,  
          SlipSeq        ,Remark         ,@UserSeq       ,GETDATE()      ,ReplaceRegSeq  ,  
          IsCustChg        
     FROM #hencom_TAcAdjTempAccount AS A     
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
      --and replaceRegSeq = 4526
   IF @@ERROR <> 0 RETURN  
 END     
   
 SELECT * FROM #hencom_TAcAdjTempAccount2 AS A   
   
RETURN         

--go 
--begin tran 
--exec hencom_SSLInvoicePriceChangeListAdjSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <Status>0</Status>
--    <YM>201609</YM>
--    <DeptSeq>50</DeptSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1038371,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031321
--rollback 
