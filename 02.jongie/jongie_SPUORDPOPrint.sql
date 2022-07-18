
IF OBJECT_ID('jongie_SPUORDPOPrint') IS NOT NULL
    DROP PROC jongie_SPUORDPOPrint
GO

-- v2013.09.11 

-- 구매발주서_jongie by이재천
CREATE PROC jongie_SPUORDPOPrint                
    @xmlDocument        NVARCHAR(MAX), 
    @xmlFlags           INT = 0, 
    @ServiceSeq         INT = 0, 
    @WorkingTag         NVARCHAR(10)= '', 
    @CompanySeq         INT = 1, 
    @LanguageSeq        INT = 1, 
    @UserSeq            INT = 0, 
    @PgmSeq             INT = 0 
AS 
    
    CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPO'     
	IF @@ERROR <> 0 RETURN  
    
    SELECT D.CustName, 
           E.EmpName, 
           B.PODate, 
           F.WHName, 
           B.Payment, 
           G.ItemName, 
           G.ItemNo, 
           G.Spec, 
           H.UnitName, 
           C.Qty, 
           C.DelvDate, 
           C.Price, 
           (ISNULL(C.CurAmt,0) + ISNULL(C.CurVAT,0)) / C.Qty AS PriceVAT, 
           C.CurAmt, 
           C.CurAmt + C.CurVAT AS TotCurAmt, 
           C.Remark1
      
      FROM #TPUORDPO AS A
      JOIN _TPUORDPO                AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq ) 
      LEFT OUTER JOIN _TPUORDPOItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.POSeq ) 
      LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDAWH        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.WHSeq = C.WHSeq ) 
      LEFT OUTER JOIN _TDAItem      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = C.UnitSeq ) 
      
    RETURN
GO
exec jongie_SPUORDPOPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <POSeq>38518792</POSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017737,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1131