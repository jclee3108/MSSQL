
IF OBJECT_ID('costel_SSLLastyearQuery')IS NOT NULL
    DROP PROC costel_SSLLastyearQuery
GO

-- v2013.10.04 

-- 연간판매계획입력_costel(전년실적불러오기) by이재천
CREATE PROC costel_SSLLastyearQuery                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle      INT, 
            @BizUnit        INT, 
            @PlanYear       NVARCHAR(4), 
            @EmpSeq         INT, 
            @DeptSeq        INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @BizUnit    = BizUnit, 
           @PlanYear   = PlanYear, 
           @EmpSeq     = EmpSeq, 
           @DeptSeq    = DeptSeq 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
      WITH (
            BizUnit     INT, 
            PlanYear    NVARCHAR(4), 
            EmpSeq      INT, 
            DeptSeq     INT 
           )
    
    SELECT 0 AS Status, 
           CONVERT(NVARCHAR(200),'') AS SubResult, 
           CONVERT(NVARCHAR(4),LEFT(C.SalesDate,4) + 1) + CONVERT(NVARCHAR(2),SUBSTRING(C.SalesDate,5,2)) AS PlanYM, 
           C.EmpSeq AS EmpSeq, 
           MAX(E.EmpName) AS EmpName, 
           C.CustSeq, 
           MAX(F.CustName) AS CustName, 
           MAX(H.MinorName) AS CustTypeName, 
           MAX(G.UMCustClass) AS CustType, 
           MAX(F.CustNo) AS CustNo, 
           MAX(J.ItemClassSSeq) AS ItemSClass, 
           MAX(J.ItemClassMSeq) AS ItemMClass, 
           MAX(J.ItemClassLSeq) AS ItemLClass, 
           MAX(J.ItemClasSName) AS ItemSClassName, 
           MAX(J.ItemClasMName) AS ItemMClassName, 
           MAX(J.ItemClasLName) AS ItemLClassName, 
           D.ItemSeq, 
           MAX(I.ItemName) AS ItemName, 
           MAX(I.ItemNo) AS ItemNo, 
           MAX(I.Spec) AS Spec, 
           C.SMExpKind, 
           MAX(K.MinorName) AS SMExpKindName, 
           C.CurrSeq, 
           MAX(L.CurrName) AS CurrName, 
           SUM(D.Qty) AS PlanQty, 
           SUM(D.CurAmt) AS PlanAmt
      INTO #TEMP 
      FROM _TSLBill                         AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TSLSalesBillRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
      LEFT OUTER JOIN _TSLSales             AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.SalesSeq ) 
      LEFT OUTER JOIN _TSLSalesItem         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.SalesSeq = B.SalesSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = C.EmpSeq ) 
      LEFT OUTER JOIN _TDACust              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDACustClass         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = F.CustSeq AND G.UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAUMinor            AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.UMCustClass ) 
      LEFT OUTER JOIN _TDAItem              AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS J   ON ( J.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDASMinor            AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = C.SMExpKind ) 
      LEFT OUTER JOIN _TDACurr              AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.CurrSeq = C.CurrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq 
       AND C.BizUnit = @BizUnit 
       AND LEFT(C.SalesDate,4) = @PlanYear - 1
       AND (@EmpSeq = 0 OR C.EmpSeq = @EmpSeq) 
       AND C.DeptSeq = @DeptSeq 
     GROUP BY CONVERT(NVARCHAR(4),LEFT(C.SalesDate,4) + 1) + CONVERT(NVARCHAR(2),SUBSTRING(C.SalesDate,5,2)), C.EmpSeq, C.CustSeq, D.ItemSeq, C.SMExpKind, C.CurrSeq
    
    IF EXISTS (
               SELECT 1 
                 FROM _TSLPlanYearSales 
                WHERE CompanySeq = @CompanySeq
                  AND BizUnit = @BizUnit
                  AND DeptSeq = @DeptSeq
                  AND SUBSTRING(PlanYM, 1, 4) = @PlanYear
                  AND (@EmpSeq = 0 OR EmpSeq = @EmpSeq)  
              )
    BEGIN
        UPDATE A
           SET Status = 22, 
               SubResult = N'기존데이터가 존재합니다. 삭제후 진행 해주시기 바랍니다.' 
          FROM #TEMP AS A
    
        SELECT Status, SubResult FROM #TEMP
    END
    
    ELSE
    BEGIN
        SELECT * FROM #TEMP
    END
    
    RETURN
GO
exec costel_SSLLastyearQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>3</BizUnit>
    <PlanYear>2012</PlanYear>
    <DeptSeq>2</DeptSeq>
    <EmpSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018370,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1403


--select * from _TSLSales where companyseq = 1 