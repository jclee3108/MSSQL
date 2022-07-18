  
IF OBJECT_ID('costel_SSLDelvContractRevDelete') IS NOT NULL   
    DROP PROC costel_SSLDelvContractRevDelete  
GO  
  
-- v2013.09.09  
  
-- 납품계약등록_costel(차수삭제) by이재천   
CREATE PROC costel_SSLDelvContractRevDelete  
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
    SELECT * FROM 
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
    
    UPDATE A
       SET ContractRev = A.ContractRev - 1
      FROM #costel_TSLDelvContract AS A

    DELETE B
      FROM #costel_TSLDelvContract AS A
      JOIN costel_TSLDelvContract AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
     WHERE A.Status = 0 

    INSERT INTO costel_TSLDelvContract 
    (
        CompanySeq, ContractSeq, ContractRev, PJTName, PJTNo,
        BizUnit, CustSeq, BKCustSeq, ContractDate, RegDate,
        SalesEmpSeq, SalesDeptSeq, ContractDateFr, ContractDateTo, SMExpKind,
        BizEmpSeq, BizDeptSeq, MHOpenDate, CurrSeq, ExRate,
        Remark, IsCfm, CfmDate, IsStop, StopDate,
        LastUserSeq, LastDateTime
    )
    SELECT B.CompanySeq, B.ContractSeq, B.ContractRev, B.PJTName, B.PJTNo,
           B.BizUnit, B.CustSeq, B.BKCustSeq, B.ContractDate, B.RegDate,
           B.SalesEmpSeq, B.SalesDeptSeq, B.ContractDateFr, B.ContractDateTo, B.SMExpKind,
           B.BizEmpSeq, B.BizDeptSeq, B.MHOpenDate, B.CurrSeq, B.ExRate,
           B.Remark, B.IsCfm, B.CfmDate, B.IsStop, B.StopDate,
           B.LastUserSeq, B.LastDateTime
      FROM #costel_TSLDelvContract   AS A
      JOIN costel_TSLDelvContractRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 

    DELETE B
      FROM #costel_TSLDelvContract AS A 
      JOIN costel_TSLDelvContractRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
    
    SELECT * FROM #costel_TSLDelvContract 
      
    RETURN  
GO
BEGIN TRAN
exec costel_SSLDelvContractRevDelete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractRev>1</ContractRev>
    <ContractSeq>44</ContractSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985
ROLLBACK TRAN

--select * from costel_TSLDelvContract where companyseq = 1 and contractseq = 44
--select * from costel_TSLDelvContractrev where companyseq = 1 and contractseq = 44
--select * from costel_TSLDelvContractitem where companyseq = 1 and contractseq = 44
--select * from costel_TSLDelvContractitemrev where companyseq = 1 and contractseq = 44

