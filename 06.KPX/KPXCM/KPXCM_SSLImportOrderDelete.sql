IF OBJECT_ID('KPXCM_SSLImportOrderDelete') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderDelete
GO 

-- v2015.09.24 

-- MES연동 실시간하기 위한 사이트용 by이재천 
/*********************************************************************************************************************        
  
    Ver. 121004  
  
    화면명 : 수입ORDER_삭제        
    SP Name: _SSLImportOrderDelete        
    작성일 : 2009.06 : CREATEd by 김준모            
    수정일 :         
********************************************************************************************************************/        
CREATE PROCEDURE KPXCM_SSLImportOrderDelete    
    @xmlDocument    NVARCHAR(MAX),          
    @xmlFlags       INT = 0,          
    @ServiceSeq     INT = 0,          
    @WorkingTag     NVARCHAR(10)= '',          
    @CompanySeq     INT = 1,          
    @LanguageSeq    INT = 1,          
    @UserSeq        INT = 0,          
    @PgmSeq         INT = 0          
AS               
    DECLARE @docHandle  INT        
        
        
    -- 서비스 마스타 등록 생성          
    CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPO'          
    IF @@ERROR <> 0 RETURN        
    
  
  
    --     로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)        
    EXEC _SCOMLog  @CompanySeq   ,        
                   @UserSeq      ,        
                   '_TPUORDPO', -- 원테이블명        
                   '#TPUORDPO', -- 템프테이블명        
                   'POSeq' , -- 키가 여러개일 경우는 , 로 연결한다.         
                   'CompanySeq,POSeq,PONo,SMImpType,PODate,DeptSeq,EmpSeq,CustSeq,CurrSeq,ExRate,Payment,Remark,IsCustAccept,POAmd,IsDirectDelv,UnitAssySeq,    
                    IsConfirm,ConfirmDate,ConfirmEmpSeq,B2BTranCnt,IsPJT,POMngNo,SMProgStatus,ERP,LastUserSeq,LastDateTime'         
        
    
    EXEC _SCOMDeleteLog  @CompanySeq   ,        
                         @UserSeq      ,        
                         '_TPUORDPOItem', -- 원테이블명        
                         '#TPUORDPO', -- 템프테이블명        
                         'POSeq' , -- 키가 여러개일 경우는 , 로 연결한다.         
                         'CompanySeq,POSeq,POSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,MakerSeq,DelvDate,DomAmt,Remark1,Remark2,SMPriceType,SMPayType,POAmd,WhSeq,DelvTime,    
                          POReqSeq,POReqSerl,StdUnitSeq,StdUnitQty,SourceType,SourceSeq,SourceSerl,UnitAssySeq,IsConfirm,ConfirmDate,ConfirmEmpSeq,ChgDelvDate,PJTSeq,    
                          WBSSeq,CurVAT,DomPrice,DomVAT,IsVAT,LastUserSeq,LastDateTime'        
  
    EXEC _SCOMDeleteLog  @CompanySeq   ,        
                         @UserSeq      ,        
                         '_TSLImpOrder', -- 원테이블명        
                         '#TPUORDPO', -- 템프테이블명        
                         'POSeq' , -- 키가 여러개일 경우는 , 로 연결한다.         
                         'CompanySeq,POSeq,BizUnit,POAmd,PORefNo,BKCustSeq,UMPriceTerms,UMPayment1,UMPayment2,Payment3,UMShipVia,Packing,LoadingPort,ETD,DischargingPort,ETA,Destination,CountryOfOrigin,Validity,Remark,LastUserSeq,LastDateTime,Memo,IsPJT,FundAccSeq,PrePaymentDate,PaymentBankSeq,PaymentAmt,FileSeq'  
    
    
    -- I/F Table 반영 
    DECLARE @POSeq      INT, 
            @BizUnit    INT  
    
    SELECT @POSeq = (SELECT MAX(POSeq) FROM #TPUORDPO) 
    
    
    SELECT @BizUnit = (SELECT TOP 1 BizUnit
                         FROM (SELECT BizUnit
                                 FROM _TSLImpOrder 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq
                               
                               UNION 
                               
                               SELECT BizUnit 
                                 FROM _TSLImpOrderLog 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq 
                              ) AS A
                      )

    IF @BizUnit = 26 AND (SELECT MAX(WorkingTag) FROM #TPUORDPO) = 'D' 
    BEGIN 
        
        SELECT @CompanySeq AS CompanySeq, 
               @BizUnit AS BizUnit, 
               A.POSeq, 
               A.POSerl, 
               B.PONo,
               B.PODate, 
               C.CustName, 
               D.ItemNo, 
               D.Spec, 
               E.UnitName, 
               ISNULL(CONVERT(FLOAT,G.MngValText ),0) AS LotUnitQty, 
               CONVERT(INT,A.StdUnitQty) AS LotQty, 
               Z.WorkingTag, 
               '0'               AS ProcYn,
               'N'               AS ConfirmFlag,   
               GetDate()         AS CreateTime,  
               ''                AS UpdateTime, 
               ''                AS ConfirmTime,
               ''                AS ErrorMessage,
               CASE WHEN B.SmImpType = 8008001   THEN '0' ELSE '1' END AS ImpType 
          INTO #IF_PUDelv_MES     
          FROM #TPUORDPO AS Z 
          LEFT OUTER JOIN _TPUORDPO         AS B WITH(NOLOCK) ON ( B.POSeq = Z.POSeq ) 
          LEFT OUTER JOIN _TPUORDPOItem     AS A WITH(NOLOCK) ON ( A.POSeq = Z.POSeq ) 
          LEFT OUTER JOIN _TDACust          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq ) 
          LEFT OUTER JOIN _TDAItem          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = D.UnitSeq ) 
          LEFT OUTER JOIN _TDAItemUserDefine AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq And G.ItemSeq = D.ItemSeq And G.MngSerl = '1000012' ) 
          OUTER APPLY (SELECT Z.BizUnit
                         FROM _TSLImpOrder AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      
                       UNION 
                       
                       SELECT Z.BizUnit
                         FROM _TSLImpOrderLog AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      ) AS H 
         WHERE H.BizUnit = 26 
    
        INSERT INTO IF_PUDelv_MES
        (
            CompanySeq,BizUnit,POSeq,PONo,POSerl,PODate,CustName, 
            ItemNo,Spec,UnitName,LotUnitQty,LotQty,WorkingTag,ProcYn, 
            ConfirmFlag,CreateTime,UpdateTime,ConfirmTime,ErrorMessage,ImpType
        )  
        SELECT CompanySeq, BizUnit, POSeq, PONo, POSerl, PODate, CustName, 
               ItemNo, Spec, UnitName, LotUnitQty, LotQty, WorkingTag, ProcYn, 
               ConfirmFlag, CreateTime, UpdateTime, ConfirmTime, ErrorMessage, ImpType 
          FROM #IF_PUDelv_MES  
    END -- MES 반영 end 
    
    
    -- DELETE                                                                                                        
    IF EXISTS (SELECT 1 FROM #TPUORDPO WHERE WorkingTag = 'D' AND Status = 0 )          
    BEGIN          
        -- 출하의뢰마스터        
        DELETE _TPUORDPO          
          FROM _TPUORDPO AS A        
                JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
        
        -- 출하의뢰품목        
        DELETE _TPUORDPOItem         
          FROM _TPUORDPOItem AS A        
                JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
                 
        IF @@ERROR <> 0 RETURN        
              
        -- 수출invoice 마스터      
        DELETE _TSLImpOrder          
          FROM _TSLImpOrder AS A        
              JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
    END          
    
    

    
    
    SELECT * FROM #TPUORDPO         
          
RETURN     
go
begin tran 
exec KPXCM_SSLImportOrderDelete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <POSeq>38519256</POSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031398,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025120

select * From IF_PUDelv_MES


rollback