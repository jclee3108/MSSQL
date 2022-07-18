  
IF OBJECT_ID('KPX_SPUTransImpOrderSave') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderSave  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시-저장 by 이재천   
CREATE PROC KPX_SPUTransImpOrderSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPUTransImpOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUTransImpOrder'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrder')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrder'    , -- 테이블명        
                  '#KPX_TPUTransImpOrder'    , -- 임시 테이블명        
                  'TransImpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPUTransImpOrder WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.BizUnit = A.BizUnit, 
               B.OrderDate = A.OrderDate, 
               B.SMImpKind = A.SMImpKind, 
               B.TransDate = A.TransDate, 
               B.DeptSeq = A.DeptSeq, 
               B.EmpSeq = A.EmpSeq, 
               B.CustSeq = A.CustSeq, 
               B.CurrSeq = A.CurrSeq, 
               B.ExRate = A.ExRate, 
               B.UMCountry = A.UMCountry, 
               B.UMPrice = A.UMPrice, 
               B.UMTrans = A.UMTrans, 
               B.UMCont = A.UMCont, 
               B.ContQty = A.ContQty, 
               B.UMPort = A.UMPort, 
               B.UMPayGet = A.UMPayGet, 
               B.UMPayment1 = A.UMPayment1, 
               B.UMPriceTerms = A.UMPriceTerms, 
               B.CarNo = A.CarNo, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
        
          FROM #KPX_TPUTransImpOrder AS A   
          JOIN KPX_TPUTransImpOrder AS B ON ( B.CompanySeq = @CompanySeq AND A.TransImpSeq = B.TransImpSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPUTransImpOrder WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPUTransImpOrder  
        (   
            CompanySeq,TransImpSeq,BizUnit,OrderDate,TransImpNo,
            SMImpKind,TransDate,DeptSeq,EmpSeq,CustSeq, CurrSeq,
            ExRate,UMCountry,UMPrice,UMTrans,UMCont,
            ContQty,UMPort,UMPayGet,UMPayment1,UMPriceTerms,
            CarNo,Remark,LastUserSeq,LastDateTime 
        )   
        SELECT @CompanySeq, A.TransImpSeq, A.BizUnit, A.OrderDate, A.TransImpNo,
               A.SMImpKind, A.TransDate, A.DeptSeq, A.EmpSeq, A.CustSeq, A.CurrSeq,
               A.ExRate, A.UMCountry, A.UMPrice, A.UMTrans, A.UMCont,
               A.ContQty, A.UMPort, A.UMPayGet, A.UMPayment1, A.UMPriceTerms,
               A.CarNo, A.Remark, @UserSeq,GETDATE()
          FROM #KPX_TPUTransImpOrder AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPUTransImpOrder   
    
    RETURN 
GO 
begin tran 

exec KPX_SPUTransImpOrderSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ContQty>10.00000</ContQty>
    <BizUnit>2</BizUnit>
    <CarNo />
    <CurrSeq>2</CurrSeq>
    <CustSeq>10623</CustSeq>
    <DeptSeq>44</DeptSeq>
    <EmpSeq>147</EmpSeq>
    <ExRate>2.000000</ExRate>
    <OrderDate>20141128</OrderDate>
    <Remark />
    <SMImpKind>8008006</SMImpKind>
    <TransDate>20141128</TransDate>
    <TransImpNo>201411280001</TransImpNo>
    <TransImpSeq>1</TransImpSeq>
    <UMCont>1010302002</UMCont>
    <UMCountry>20182002</UMCountry>
    <UMPayGet>8050002</UMPayGet>
    <UMPayment1>8202005</UMPayment1>
    <UMPort>8207033</UMPort>
    <UMPrice>1010285002</UMPrice>
    <UMPriceTerms>8201013</UMPriceTerms>
    <UMTrans>1010286002</UMTrans>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021338

select * from KPX_TPUTransImpOrder 
select * from KPX_TPUTransImpOrderLog
rollback 