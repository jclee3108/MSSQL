  
IF OBJECT_ID('jongie_SSLItemSalesResultQuery') IS NOT NULL   
    DROP PROC jongie_SSLItemSalesResultQuery  
GO  
  
-- v2013.09.16 
  
-- 품목별판매결과_jongie(조회) by이재천   
CREATE PROC jongie_SSLItemSalesResultQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemClassMSeq  INT, 
            @ItemClassSSeq  INT, 
            @InvoiceDateTo  NVARCHAR(6), 
            @ItemClassLSeq  INT, 
            @EmpSeq         INT, 
            @DeptSeq        INT, 
            @ItemName       NVARCHAR(200), 
            @InvoiceDateFr  NVARCHAR(6), 
            @ItemNo         NVARCHAR(100) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      

	SELECT  @ItemClassMSeq  = ISNULL(ItemClassMSeq,0), 
            @ItemClassSSeq  = ISNULL(ItemClassSSeq,0), 
            @InvoiceDateTo  = ISNULL(InvoiceDateTo,''), 
            @ItemClassLSeq  = ISNULL(ItemClassLSeq,0), 
            @EmpSeq         = ISNULL(EmpSeq,0), 
            @DeptSeq        = ISNULL(DeptSeq,0), 
            @ItemName       = ISNULL(ItemName,''), 
            @InvoiceDateFr  = ISNULL(InvoiceDateFr,''),
            @ItemNo         = ISNULL(ItemNo,'') 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
	  WITH 
        (
            ItemClassMSeq   INT, 
            ItemClassSSeq   INT, 
            InvoiceDateTo   NVARCHAR(6), 
            ItemClassLSeq   INT, 
            EmpSeq          INT, 
            DeptSeq         INT, 
            ItemName        NVARCHAR(200), 
            InvoiceDateFr   NVARCHAR(6), 
            ItemNo          NVARCHAR(100)  
        )  
    --select @InvoiceDateFr, @InvoiceDateTo
    
    --select CONVERT(NVARCHAR(4),SUBSTRING(@InvoiceDateFr,1,4) - 1) + CONVERT(NVARCHAR(2),SUBSTRING(@InvoiceDateFr,5,2)) ,
    --       CONVERT(NVARCHAR(4),SUBSTRING(@InvoiceDateTo,1,4) - 1) , CONVERT(NVARCHAR(2),SUBSTRING(@InvoiceDateTo,5,2))
    
    -- 전년도 데이터 담기
    CREATE TABLE #TEMP
    (   InvoiceDate     NVARCHAR(6),
        ItemClassSSeq   NVARCHAR(100), 
        ItemClassMSeq   NVARCHAR(100), 
        ItemClassLSeq   NVARCHAR(100), 
        ItemSeq         INT, 
        BeforeQty       DECIMAL(19,5), 
        BeforeAmt       DECIMAL(19,5), 
        BeforeTotAmt    DECIMAL(19,5), 
        PresentQty      DECIMAL(19,5), 
        PresentAmt      DECIMAL(19,5), 
        PresentTotAmt   DECIMAL(19,5), 
        ChangeQty       DECIMAL(19,5), 
        ChangeAmt       DECIMAL(19,5), 
        ChangeTotAmt    DECIMAL(19,5) 
    )
    
    INSERT INTO #TEMP(InvoiceDate, ItemClassSSeq, ItemClassMSeq, ItemClassLSeq, ItemSeq, BeforeQty, BeforeAmt, BeforeTotAmt, PresentQty, PresentAmt, PresentTotAmt)
    SELECT LEFT(A.InvoiceDate,6),                                                                                           
           D.ItemClassSSeq,                                                                                                 
           D.ItemClassMSeq,
           D.ItemClassLSeq,
           B.ItemSeq,  
           B.Qty, 
           B.CurAmt, 
           B.CurAmt + B.CurVAT, 
           NULL,
           NULL,
           NULL
      FROM _TSLInvoice AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq ) 
      LEFT OUTER JOIN _TDAItem        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS D ON ( D.ItemSeq = B.ItemSeq ) 
     WHERE LEFT(A.InvoiceDate,6) BETWEEN CONVERT(NVARCHAR(4),SUBSTRING(@InvoiceDateFr,1,4) - 1) + CONVERT(NVARCHAR(2),SUBSTRING(@InvoiceDateFr,5,2))
                                            AND CONVERT(NVARCHAR(4),SUBSTRING(@InvoiceDateTo,1,4) - 1) + CONVERT(NVARCHAR(2),SUBSTRING(@InvoiceDateTo,5,2))
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (D.ItemClassLSeq = @ItemClassLSeq) 
       AND (@ItemClassMSeq = 0 OR D.ItemClassMSeq = @ItemClassMSeq) 
       AND (@ItemClassSSeq = 0 OR D.ItemClassSSeq = @ItemClassSSeq)
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%') 
    
    UNION ALL
    
    SELECT LEFT(A.InvoiceDate,6), 
           D.ItemClassSSeq, 
           D.ItemClassMSeq,
           D.ItemClassLSeq,
           B.ItemSeq,  
           NULL,
           NULL,
           NULL,
           B.Qty, 
           B.CurAmt, 
           B.CurAmt + B.CurVAT
      FROM _TSLInvoice AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq ) 
      LEFT OUTER JOIN _TDAItem        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS D ON ( D.ItemSeq = B.ItemSeq ) 
     WHERE SUBSTRING(A.InvoiceDate,1,6) BETWEEN @InvoiceDateFr AND @InvoiceDateTo
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (D.ItemClassLSeq = @ItemClassLSeq) 
       AND (@ItemClassMSeq = 0 OR D.ItemClassMSeq = @ItemClassMSeq) 
       AND (@ItemClassSSeq = 0 OR D.ItemClassSSeq = @ItemClassSSeq)
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%') 
    
    --select * from #TEMP
----------------------------------------------------------------------------------

    DECLARE @EnvValue INT
    SELECT @EnvValue = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 1 AND EnvSerl = 1 
    
    SELECT A.ItemClassSSeq, 
           A.ItemClassMSeq, 
           A.ItemClassLSeq, 
           B.ItemClasSName, 
           B.ItemClasMName, 
           B.ItemClasLName,
           C.ItemName, 
           C.ItemNo, 
           CONVERT(INT,CASE WHEN ISNULL(D.ConvDen,0) = 0 THEN 0 ELSE (ISNULL(D.ConvNum,0) / ISNULL(D.ConvDen,0)) END) AS BoxUnit, 
           SUM(A.BeforeQty) AS BeforeQty, 
           SUM(A.BeforeAmt) AS BeforeAmt, 
           SUM(A.BeforeTotAmt) AS BeforeTotAmt, 
           SUM(A.PresentQty) AS PresentQty, 
           SUM(A.PresentAmt) AS PresentAmt, 
           SUM(A.PresentTotAmt) AS PresentTotAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeQty),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentQty),0) / ISNULL(SUM(A.BeforeQty),0)) - 1) * 100 END AS ChangeQty, 
           CASE WHEN ISNULL(SUM(A.BeforeAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentAmt),0) / ISNULL(SUM(A.BeforeAmt),0)) - 1) * 100 END AS ChangeAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeTotAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentTotAmt),0) / ISNULL(SUM(A.BeforeTotAmt),0)) -1) * 100 END AS ChangeTotAmt,
           1 AS Kind
      FROM #TEMP AS A 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemUnit AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = @EnvValue AND D.ItemSeq = A.ItemSeq ) 
     GROUP BY A.ItemClassSSeq, A.ItemClassMSeq, A.ItemClassLSeq, A.ItemSeq,B.ItemClasSName, B.ItemClasMName, B.ItemClasLName, C.ItemName, C.ItemNo, 
              CASE WHEN ISNULL(D.ConvDen,0) = 0 THEN 0 ELSE (ISNULL(D.ConvNum,0) / ISNULL(D.ConvDen,0)) END
                                                                          
    UNION ALL 

    SELECT MAX(A.ItemClassSSeq), 
           '', 
           '', 
           '소  계',  
           '', 
           '',
           '',
           '', 
           NULL,
           SUM(A.BeforeQty) AS BeforeQty, 
           SUM(A.BeforeAmt) AS BeforeAmt, 
           SUM(A.BeforeTotAmt) AS BeforeTotAmt, 
           SUM(A.PresentQty) AS PresentQty, 
           SUM(A.PresentAmt) AS PresentAmt, 
           SUM(A.PresentTotAmt) AS PresentTotAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeQty),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentQty),0) / ISNULL(SUM(A.BeforeQty),0)) - 1) * 100 END AS ChangeQty, 
           CASE WHEN ISNULL(SUM(A.BeforeAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentAmt),0) / ISNULL(SUM(A.BeforeAmt),0)) - 1) * 100 END AS ChangeAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeTotAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentTotAmt),0) / ISNULL(SUM(A.BeforeTotAmt),0)) -1) * 100 END AS ChangeTotAmt,
           2 AS Kind
      FROM #TEMP AS A 
     GROUP BY A.ItemClassSSeq
    
    UNION ALL 
    
    SELECT '999999', 
           '', 
           '', 
           '',  
           '', 
           '총 합 계',
           '', 
           '',
           NULL,
           SUM(A.BeforeQty) AS BeforeQty, 
           SUM(A.BeforeAmt) AS BeforeAmt, 
           SUM(A.BeforeTotAmt) AS BeforeTotAmt, 
           SUM(A.PresentQty) AS PresentQty, 
           SUM(A.PresentAmt) AS PresentAmt, 
           SUM(A.PresentTotAmt) AS PresentTotAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeQty),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentQty),0) / ISNULL(SUM(A.BeforeQty),0)) - 1) * 100 END AS ChangeQty, 
           CASE WHEN ISNULL(SUM(A.BeforeAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentAmt),0) / ISNULL(SUM(A.BeforeAmt),0)) - 1) * 100 END AS ChangeAmt, 
           CASE WHEN ISNULL(SUM(A.BeforeTotAmt),0) = 0 THEN 0 ELSE ((ISNULL(SUM(A.PresentTotAmt),0) / ISNULL(SUM(A.BeforeTotAmt),0)) -1) * 100 END AS ChangeTotAmt,
           3 AS Kind
      FROM #TEMP AS A 
     HAVING (SUM(A.BeforeQty) <> 0 AND SUM(A.PresentQty) <> 0) 
         OR (SUM(A.BeforeAmt) <> 0 AND SUM(A.PresentAmt) <> 0)
         OR (SUM(A.BeforeTotAmt) <> 0 AND SUM(A.PresentTotAmt) <> 0)
    
    ORDER BY A.ItemClassSSeq, Kind
    
    RETURN  
GO
exec jongie_SSLItemSalesResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <InvoiceDateFr>201601</InvoiceDateFr>
    <InvoiceDateTo>201702</InvoiceDateTo>
    <EmpSeq />
    <DeptSeq />
    <ItemClassLSeq>2003030</ItemClassLSeq>
    <ItemClassMSeq />
    <ItemClassSSeq />
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017765,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015196