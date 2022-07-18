
IF OBJECT_ID('costel_SPUMatListLabelPrint')IS NOT NULL
    DROP PROC costel_SPUMatListLabelPrint
GO

-- v2013.10.10 

-- 부품식별표출력_costel(출력) by이재천
CREATE PROC costel_SPUMatListLabelPrint 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL) 
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelvIn' 
    IF @@ERROR <> 0 RETURN 
    
    SELECT B.ItemSeq, 
           A.DelvInSeq, 
           D.ItemName, 
           B.DelvInDate, 
           D.ItemNo, 
           D.Spec, 
           C.Qty 
      FROM #TPUDelvIn AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TPUDelvIn     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
      LEFT OUTER JOIN _TPUDelvInItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DelvInSeq = A.DelvInSeq ) 
      LEFT OUTER JOIN _TDAItem       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq )

    RETURN

