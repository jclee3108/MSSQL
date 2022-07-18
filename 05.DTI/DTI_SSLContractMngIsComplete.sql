
IF OBJECT_ID('DTI_SSLContractMngIsComplete') IS NOT NULL 
    DROP PROC DTI_SSLContractMngIsComplete
GO 

-- v2014.01.22 

-- 계약관리현황_DTI(완료여부) by이재천
CREATE PROC DTI_SSLContractMngIsComplete
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TSLContractMng (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMng'
    
    UPDATE B
       SET IsComplete = A. IsComplete
      FROM #DTI_TSLContractMng AS A 
      JOIN DTI_TSLContractMng  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
    
    SELECT * FROM #DTI_TSLContractMng 
    
    RETURN 
GO
exec DTI_SSLContractMngIsComplete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsComplete>1</IsComplete>
    <ContractSeq>1000124</ContractSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015902,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013761