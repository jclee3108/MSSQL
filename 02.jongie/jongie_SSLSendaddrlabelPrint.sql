
IF OBJECT_ID('jongie_SSLSendaddrlabelPrint')IS NOT NULL 
    DROP PROC jongie_SSLSendaddrlabelPrint
GO

-- v2013.10.01 

-- 세금계산서조회(라벨출력)_jongie by이재천
CREATE PROC jongie_SSLSendaddrlabelPrint                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    CREATE TABLE #TDACust (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDACust'     
    IF @@ERROR <> 0 RETURN  
    
    SELECT B.CustName, B.Owner, C.KorAddr1 +' '+ C.KorAddr2 AS Address, C.ZipCode, A.CustSeq, B.CustNo
      FROM #TDACust AS A 
      JOIN _TDACust AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACustAdd AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq ) 
    
    RETURN
GO
exec jongie_SSLSendaddrlabelPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CustSeq>42201</CustSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018287,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1279