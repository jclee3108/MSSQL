  
IF OBJECT_ID('costel_SSLDelvContractSave') IS NOT NULL   
    DROP PROC costel_SSLDelvContractSave  
GO  
  
-- v2013.09.04  
  
-- 납품계약등록_costel(저장) by 이재천   
CREATE PROC costel_SSLDelvContractSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #costel_TSLDelvContract (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#costel_TSLDelvContract'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('costel_TSLDelvContract')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'costel_TSLDelvContract'    , -- 테이블명        
                  '#costel_TSLDelvContract'    , -- 임시 테이블명        
                  'ContractSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContract WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #costel_TSLDelvContract AS A   
          JOIN costel_TSLDelvContract AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContract WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET ContractRev     = A.ContractRev   ,
               PJTName         = A.PJTName       ,
               PJTNo           = A.PJTNo         ,
               BizUnit         = A.BizUnit       ,
               CustSeq         = A.CustSeq       ,
               BKCustSeq       = A.BKCustSeq     ,
               ContractDate    = A.ContractDate  ,
               RegDate         = A.RegDate       ,
               SalesEmpSeq     = A.SalesEmpSeq   ,
               SalesDeptSeq    = A.SalesDeptSeq  ,
               ContractDateFr  = A.ContractDateFr,
               ContractDateTo  = A.ContractDateTo,
               SMExpKind       = A.SMExpKind     ,
               BizEmpSeq       = A.BizEmpSeq     ,
               BizDeptSeq      = A.BizDeptSeq    ,
               MHOpenDate      = A.MHOpenDate    ,
               CurrSeq         = A.CurrSeq       ,
               ExRate          = A.ExRate        ,
               Remark          = A.Remark        ,
               LastUserSeq     = @UserSeq        ,
               LastDateTime    = GETDATE()    
          
          FROM #costel_TSLDelvContract AS A   
          JOIN costel_TSLDelvContract AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContract WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO costel_TSLDelvContract  
        (   
            CompanySeq, ContractSeq, ContractRev, PJTName, PJTNo, 
            BizUnit, CustSeq, BKCustSeq, ContractDate, RegDate, 
            SalesEmpSeq, SalesDeptSeq, ContractDateFr, ContractDateTo, SMExpKind, 
            BizEmpSeq, BizDeptSeq, MHOpenDate, CurrSeq, ExRate, 
            Remark, IsCfm, CfmDate, IsStop, StopDate, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.ContractSeq, A.ContractRev, A.PJTName, A.PJTNo, 
                A.BizUnit, A.CustSeq, A.BKCustSeq, A.ContractDate, A.RegDate, 
                A.SalesEmpSeq, A.SalesDeptSeq, A.ContractDateFr, A.ContractDateTo, A.SMExpKind, 
                A.BizEmpSeq, A.BizDeptSeq, A.MHOpenDate, A.CurrSeq, A.ExRate, 
                A.Remark, 0, '', 0, '', @UserSeq, 
                GETDATE()
          FROM #costel_TSLDelvContract AS A   
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  

    END     
    
    SELECT * FROM #costel_TSLDelvContract   
      
    RETURN  
GO
BEGIN TRAN 
exec costel_SSLDelvContractSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BizDeptName />
    <BizDeptSeq>0</BizDeptSeq>
    <BizEmpName />
    <BizEmpSeq>0</BizEmpSeq>
    <BizUnit>2</BizUnit>
    <BizUnitName>평택사업장</BizUnitName>
    <IsCfm>0</IsCfm>
    <ContractDate>20130906</ContractDate>
    <ContractDateFr />
    <ContractDateTo />
    <CurrName>KRW</CurrName>
    <ExRate>1.00000</ExRate>
    <CurrSeq>1</CurrSeq>
    <CustName>(사)경기경영자총협회</CustName>
    <CustSeq>33761</CustSeq>
    <Remark />
    <MHOpenDate />
    <PJTAmt>0.00000</PJTAmt>
    <PJTName>test111</PJTName>
    <PJTNo>test22</PJTNo>
    <ContractRev>0</ContractRev>
    <CfmDate />
    <RegDate>20130906</RegDate>
    <SalesDeptSeq>147</SalesDeptSeq>
    <SalesEmpName>이재천</SalesEmpName>
    <SalesEmpSeq>2028</SalesEmpSeq>
    <SMExpKind>8009001</SMExpKind>
    <SMExpKindName>내수</SMExpKindName>
    <SMStatus>0</SMStatus>
    <SMStatusName />
    <VATRate>10.00000</VATRate>
    <ContractSeq>16</ContractSeq>
    <SalesDeptName>사업개발팀</SalesDeptName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985
ROLLBACK TRAN 