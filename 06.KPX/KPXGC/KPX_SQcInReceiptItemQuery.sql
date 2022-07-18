
IF OBJECT_ID('KPX_SQcInReceiptItemQuery') IS NOT NULL 
    DROP PROC KPX_SQcInReceiptItemQuery
GO 

-- v2014.12.05 

-- 수입검사대상품목등록 - 조회 by이재천 
CREATE PROCEDURE KPX_SQcInReceiptItemQuery   
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle     INT,  
            @AssetSeq      INT,     
            @ItemName      NVARCHAR(100),  
            @ItemNo        NVARCHAR(100),  
            @Spec          NVARCHAR(100),  
            @DateFr    NCHAR(8),  
            @DateTo    NCHAR(8),  
            @TestItemType  INT, 
            @ItemCheck     INT, 
            @ItemLClass    INT,  
            @ItemMClass    INT,  
            @ItemSClass    INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
    
    SELECT  @AssetSeq      = ISNULL(AssetSeq    , 0),  
            @ItemName      = ISNULL(ItemName    , ''),  
            @ItemNo        = ISNULL(ItemNo      , ''),  
            @Spec          = ISNULL(Spec        , ''),  
            @TestItemType  = ISNULL(TestItemType, 0), 
            @ItemCheck     = ISNULL(ItemCheck,    0), 
            @DateFr     = ISNULL(DateFr  ,''),  
            @DateTo     = ISNULL(DateTo  ,''),  
            @ItemLClass    = ISNULL(ItemLClass  , 0),  
            @ItemMClass    = ISNULL(ItemMClass  , 0),  
            @ItemSClass    = ISNULL(ItemSClass  , 0)  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  
            AssetSeq      INT,  
            ItemName      NVARCHAR(100),  
            ItemNo        NVARCHAR(100),  
            Spec          NVARCHAR(100),  
            TestItemType  INT, 
            ItemCheck     INT, 
            DateFr        NCHAR(8),  
            DateTo        NCHAR(8),  
            ItemLClass    INT,   
            ItemMClass    INT,  
            ItemSClass    INT
         )  
    
    
    IF @DateTo = '' SET @DateTo = '99991231'              
    
    SELECT DISTINCT  
           A.ItemName    ,  
           A.ItemNo      ,  
           A.Spec        ,  
           A.ItemSeq     ,  
           B.AssetName   ,  
           C.IsInQC      ,  
           C.IsAutoDelvIn   , 
           RIGHT(B.SMAssetGrp, 1) AS AssetSeq ,  
           ISNULL(G.MinorName, '')      AS UMItemClassName,  
           ISNULL(H.MinorName, '')      AS ItemMClassName,  
           ISNULL(I.MinorName, '')      AS ItemLClassName  
      FROM _TDAItem                     AS A 
      LEFT OUTER JOIN _TDAItemAsset     AS B ON ( A.CompanySeq = B.CompanySeq AND A.AssetSeq = B.AssetSeq ) 
      LEFT OUTER JOIN KPX_TQcInReceiptItem  AS C ON ( A.CompanySeq = C.CompanySeq ANd A.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemClass     AS D ON ( A.CompanySeq = D.CompanySeq ANd A.ItemSeq = D.ItemSeq AND D.UMajorItemClass IN (2001,2004) ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( D.CompanySeq = E.CompanySeq AND D.UMItemClass = E.MinorSeq  AND E.Serl IN (1001, 2001) ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS F ON ( E.CompanySeq = F.CompanySeq AND E.ValueSeq = F.MinorSeq AND F.Serl = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( D.CompanySeq = G.CompanySeq AND D.UMItemClass = G.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( E.CompanySeq = H.CompanySeq AND E.ValueSeq = H.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS I ON ( F.CompanySeq = I.CompanySeq AND F.ValueSeq = I.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (@AssetSeq = 0 OR B.AssetSeq = @AssetSeq)  
       AND (@ItemName = '' OR A.ItemName LIKE @ItemName + '%')      
       AND (@ItemNo   = '' OR A.ItemNo   LIKE @ItemNo + '%')      
       AND (@Spec     = '' OR A.Spec     LIKE @Spec + '%')      
       AND (@ItemSClass = 0 OR D.UMItemClass = @ItemSClass)  
       AND (@ItemMClass = 0 OR E.ValueSeq = @ItemMClass)  
       AND (@ItemLClass = 0 OR F.ValueSeq = @ItemLClass)  
       AND (CONVERT(NCHAR(8), A.RegDateTime, 112) BETWEEN @DateFr AND @DateTo) 
       AND (@TestItemType = 0 OR ((@TestItemType = 1010422001 AND C.IsInQC = '1') OR (@TestItemType = 1010422002 AND C.IsAutoDelvIn = '1'))) 
       AND (@ItemCheck = '0' OR (@ItemCheck = '1' AND ISNULL(C.IsInQC,'0') = '0' AND ISNULL(C.IsAutoDelvIn,'0') = '0'))
    
    RETURN    
GO 
exec KPX_SQcInReceiptItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AssetSeq />
    <ItemLClass />
    <ItemMClass />
    <ItemSClass />
    <DateFr>20141201</DateFr>
    <DateTo>20141205</DateTo>
    <ItemName />
    <ItemNo />
    <Spec />
    <TestItemType>0</TestItemType>
    <ItemCheck>0</ItemCheck>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026513,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022194
