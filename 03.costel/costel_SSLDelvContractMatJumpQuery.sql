  
IF OBJECT_ID('costel_SSLDelvContractMatJumpQuery') IS NOT NULL   
    DROP PROC costel_SSLDelvContractMatJumpQuery  
GO  
  
-- v2013.09.06  
  
-- 납품계약등록_costel(자재기타출고요청점프) by이재천 
CREATE PROC costel_SSLDelvContractMatJumpQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0         
AS        
    
	CREATE TABLE #costel_TSLDelvContractItem (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItem'     
	IF @@ERROR <> 0 RETURN      
      
    -- 최종조회   
    SELECT B.BizUnit, 
           D.BizUnitName, 
           B.PJTNo, 
           B.CustSeq, 
           E.CustName 

      FROM #costel_TSLDelvContractItem AS A WITH(NOLOCK) 
      JOIN costel_TSLDelvContract      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN _TDABizUnit      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = B.BizUnit ) 
      LEFT OUTER JOIN _TDACust         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      
    RETURN  
GO
exec costel_SSLDelvContractMatJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ContractSerl>1</ContractSerl>
    <ContractSeq>17</ContractSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ContractSerl>2</ContractSerl>
    <ContractSeq>17</ContractSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985