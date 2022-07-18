
IF OBJECT_ID('DTI_SSLContractSalesPlanJumpCheck') IS NOT NULL 
    DROP PROC DTI_SSLContractSalesPlanJumpCheck
GO

-- v2014.01.07 

-- 매출계획대상조회_DTI(점프체크) by이재천
CREATE PROC dbo.DTI_SSLContractSalesPlanJumpCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #DTI_TSLContractMngItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngItem'
    
    IF EXISTS (SELECT 1 
                 FROM #DTI_TSLContractMngItem AS A
                 JOIN _TSLOrderItem           AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND CONVERT(INT,Dummy6) = A.ContractSeq AND CONVERT(INT,Dummy7) = A.ContractSerl ) 
              )
    BEGIN 
        UPDATE A 
           SET Result = N'매출로 진행 된 데이터입니다.',
               MessageType = 1234, 
               Status = 1234
          FROM #DTI_TSLContractMngItem AS A 
    END 
    
    SELECT * FROM #DTI_TSLContractMngItem 
    
    RETURN    
GO
exec DTI_SSLContractSalesPlanJumpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ContractSeq>1000080</ContractSeq>
    <ContractSerl>2</ContractSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015931,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013783