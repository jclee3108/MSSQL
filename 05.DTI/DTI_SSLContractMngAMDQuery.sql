
IF OBJECT_ID('DTI_SSLContractMngAMDQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractMngAMDQuery
GO

-- v2013.12.26 

-- 계약관리등록(AMD조회)_DTI by이재천
CREATE PROC DTI_SSLContractMngAMDQuery              
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle   INT,
            @ContractSeq INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ContractSeq = ISNULL(ContractSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ContractSeq INT)

    SELECT A.ContractSeq , A.ContractRev        
      FROM DTI_TSLContractMngRev AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ContractSeq = @ContractSeq 
    
    RETURN
GO
exec DTI_SSLContractMngAMDQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractSeq>1000052</ContractSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020185,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013760