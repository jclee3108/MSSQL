
IF OBJECT_ID('costel_SSLDelvPlanQuery')IS NOT NULL
    DROP PROC costel_SSLDelvPlanQuery
GO

-- v2013.10.04 

-- 연간판매계획입력_costel(납품계획불러오기) by이재천
CREATE PROC costel_SSLDelvPlanQuery                
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
    
    SELECT @BizUnit     = BizUnit, 
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
           LEFT(SalesExpectDate,6) AS PlanYM, 
           A.SalesEmpSeq AS EmpSeq, 
           MAX(C.EmpName) AS EmpName, 
           A.CustSeq, 
           MAX(D.CustName) AS CustName, 
           MAX(F.MinorName) AS CustTypeName, 
           MAX(E.UMCustClass) AS CustType, 
           MAX(D.CustNo) AS CustNo, 
           MAX(G.ItemClassSSeq) AS ItemSClass, 
           MAX(G.ItemClassMSeq) AS ItemMClass, 
           MAX(G.ItemClassLSeq) AS ItemLClass, 
           MAX(G.ItemClasSName) AS ItemSClassName, 
           MAX(G.ItemClasMName) AS ItemMClassName, 
           MAX(G.ItemClasLName) AS ItemLClassName, 
           B.ItemSeq, 
           MAX(H.ItemName) AS ItemName, 
           MAX(H.ItemNo) AS ItemNo, 
           MAX(H.Spec) AS Spec, 
           A.SMExpKind, 
           MAX(I.MinorName) AS SMExpKindName, 
           A.CurrSeq, 
           MAX(J.CurrName) AS CurrName, 
           SUM(B.DelvQty) AS PlanQty, 
           SUM(B.DelvCurAmt) AS PlanAmt
      INTO #TEMP
      FROM costel_TSLDelvContract AS A WITH (NOLOCK) 
      LEFT OUTER JOIN costel_TSLDelvContractItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN _TDAEmp                    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.SalesEmpSeq ) 
      LEFT OUTER JOIN _TDACust                   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACustClass              AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = D.CustSeq AND UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAUMinor                 AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.UMCustClass ) 
      LEFT OUTER JOIN _TDAItem                   AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS G        ON ( G.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDASMinor                 AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.SMExpKind ) 
      LEFT OUTER JOIN _TDACurr                   AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.CurrSeq = A.CurrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND LEFT(B.SalesExpectDate,4) = @PlanYear 
       AND (@EmpSeq = 0 OR A.SalesEmpSeq = @EmpSeq) 
       AND A.SalesDeptSeq = @DeptSeq 
     GROUP BY LEFT(SalesExpectDate,6), A.SalesEmpSeq, A.CustSeq, B.ItemSeq, A.SMExpKind, A.CurrSeq
    
    IF EXISTS (SELECT 1 
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
exec costel_SSLDelvPlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <PlanYear>2013</PlanYear>
    <DeptSeq>1294</DeptSeq>
    <EmpSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018370,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1403