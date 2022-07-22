IF OBJECT_ID('hencom_SSLUserInvoiceReplaceListQuery') IS NOT NULL 
    DROP PROC hencom_SSLUserInvoiceReplaceListQuery
GO 

-- v2017.04.25
  
-- 사용자선택매출자료조회_hencom-조회 by 이재천   
CREATE PROC hencom_SSLUserInvoiceReplaceListQuery  
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
    DECLARE @docHandle          INT,  
            -- 조회조건   
            @FrDate             NCHAR(8), 
            @ToDate             NCHAR(8), 
            @ItemName           NVARCHAR(200), 
            @IsGoods            NCHAR(1), 
            @QueryType          INT, 
            @DeptSeq            INT, 
            @CustSeq            INT, 
            @PJTSeq             INT, 
            @UMChannel          INT, 
            @EmpSeq             INT, 
            @IsDeptName         NCHAR(1), 
            @IsResultDate       NCHAR(1), 
            @IsCustName         NCHAR(1), 
            @IsPJTName          NCHAR(1), 
            @IsItemName         NCHAR(1), 
            @IsPrice            NCHAR(1), 
            @IsUMChannelName    NCHAR(1), 
            @IsEmpName          NCHAR(1) 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FrDate          = ISNULL( FrDate       , '' ),  
           @ToDate          = ISNULL( ToDate       , '' ),  
           @ItemName        = ISNULL( ItemName     , '' ),  
           @IsGoods         = ISNULL( IsGoods      , '0' ),  
           @QueryType       = ISNULL( QueryType    , 0 ),  
           @DeptSeq         = ISNULL( DeptSeq      , 0 ),  
           @CustSeq         = ISNULL( CustSeq      , 0 ),  
           @PJTSeq          = ISNULL( PJTSeq       , 0 ),  
           @UMChannel       = ISNULL( UMChannel    , 0 ),  
           @EmpSeq          = ISNULL( EmpSeq       , 0 ), 
           @IsDeptName      = ISNULL( IsDeptName   , '0' ),  
           @IsResultDate    = ISNULL( IsResultDate , '0' ),  
           @IsCustName      = ISNULL( IsCustName   , '0' ),  
           @IsPJTName       = ISNULL( IsPJTName    , '0' ),  
           @IsItemName      = ISNULL( IsItemName   , '0' ),  
           @IsPrice         = ISNULL( IsPrice      , '0' ), 
           @IsUMChannelName = ISNULL( IsUMChannelName, '0' ), 
           @IsEmpName       = ISNULL( IsEmpName, '0' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              FrDate            NCHAR(8), 
              ToDate            NCHAR(8), 
              ItemName          NVARCHAR(200), 
              IsGoods           NCHAR(1), 
              QueryType         INT, 
              DeptSeq           INT, 
              CustSeq           INT, 
              PJTSeq            INT, 
              UMChannel         INT, 
              EmpSeq            INT, 
              IsDeptName        NCHAR(1), 
              IsResultDate      NCHAR(1), 
              IsCustName        NCHAR(1), 
              IsPJTName         NCHAR(1), 
              IsItemName        NCHAR(1), 
              IsPrice           NCHAR(1), 
              IsUMChannelName   NCHAR(1), 
              IsEmpName         NCHAR(1) 
           )    
    
    CREATE TABLE #Result 
    (
        DeptName        NVARCHAR(200), 
        DeptSeq         INT, 
        ResultDate      NCHAR(8), 
        CustName        NVARCHAR(200), 
        CustSeq         INT, 
        UMChannelName   NVARCHAR(200), 
        UMChannel       INT,
        EmpSeq          INT, 
        EmpName         NVARCHAR(200), 
        PJTName         NVARCHAR(200), 
        PJTSeq          INT, 
        ItemName        NVARCHAR(200), 
        Price           DECIMAL(19,5), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5), 
        VAT             DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5)
    )
    
    IF @QueryType = 1 -- 출하기준 
    BEGIN 
        
        INSERT INTO #Result 
        (
            DeptName        , DeptSeq    , ResultDate , CustName   , CustSeq    , 
            UMChannelName   , UMChannel  , EmpSeq     , EmpName    , PJTName    , 
            PJTSeq          , ItemName   , Price      , Qty        , Amt        , 
            VAT             , SumAmt     
        )
        SELECT A.DeptName, A.DeptSeq, A.WorkDate, A.CustName, A.CustSeq, 
               A.UMCustClassName, A.UMCustClass, E.ChargeEmpSeq, F.EmpName, A.PJTName, 
               A.PJTSeq, A.GoodItemName, A.Price, A.Qty, A.CurAmt, 
               A.CurVAT, A.CurAmt + A.CurVAT 
          FROM hencom_VInvoiceReplaceItem   AS A 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset     AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq ) 
          LEFT OUTER JOIN _TPJTProject      AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq ) 
          LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = E.ChargeEmpSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WorkDate BETWEEN @FrDate AND @ToDate 
           AND ( @ItemName = '' OR A.GoodItemName LIKE '%' + @ItemName + '%' )
           AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
           AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND ( @PJTSeq = 0 OR A.PJTSeq = @PJTSeq ) 
           AND ( @UMChannel = 0 OR A.UMCustClass = @UMChannel )
           AND ( D.SMAssetGrp <> CASE WHEN @IsGoods = '1' THEN 6008001 ELSE 1 END ) 
           AND ( @EmpSeq = 0 OR E.ChargeEmpSeq = @EmpSeq )
    END 
    ELSE IF @QueryType = 2 -- 세금계산서 기준 
    BEGIN
            
        INSERT INTO #Result 
        (
            DeptName        , DeptSeq    , ResultDate , CustName   , CustSeq    , 
            UMChannelName   , UMChannel  , EmpSeq     , EmpName    , PJTName    , 
            PJTSeq          , ItemName   , Price      , Qty        , Amt        , 
            VAT             , SumAmt     
        )
        SELECT E.DeptName   , A.DeptSeq    , B.WorkDate , F.CustName   , A.CustSeq    , 
               B.UMCustClassName, B.UMCustClass, G.ChargeEmpSeq, H.EmpName, G.PJTName    , 
               B.PJTSeq     , C.ItemName , B.Price      , B.Qty, B.CurAmt     , 
               B.CurVAT     , B.CurAmt + B.CurVAT  
          FROM _TSLBill                                 AS A 
                     JOIN hencom_VInvoiceReplaceItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
          LEFT OUTER JOIN _TDAItem                      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset                 AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq ) 
          LEFT OUTER JOIN _TDADept                      AS E ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDACust                      AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TPJTProject                  AS G ON ( G.CompanySeq = @CompanySeq AND G.PJTSeq = B.PJTSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = G.ChargeEmpSeq ) 
         WHERE A.CompanySeq = @CompanySeq
           AND A.BillDate BETWEEN @FrDate AND @ToDate
           AND ( @ItemName = '' OR C.ItemName LIKE '%' + @ItemName + '%' )
           AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
           AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND ( @PJTSeq = 0 OR B.PJTSeq = @PJTSeq ) 
           AND ( @UMChannel = 0 OR B.UMCustClass = @UMChannel )
           AND ( D.SMAssetGrp <> CASE WHEN @IsGoods = '1' THEN 6008001 ELSE 1 END ) 
           AND ( @EmpSeq = 0 OR G.ChargeEmpSeq = @EmpSeq )
    END 
    
    -- 조회기준에 따른 동적쿼리
					    
    DECLARE @SQL    NVARCHAR(MAX), 
            @SQL2   NVARCHAR(MAX)
    SET @SQL = ''                         
    SET @SQL = @SQL + ' SELECT 2 AS Sort
                              ,SUM(ISNULL(Qty,0)) AS Qty    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(Amt,0)) AS Amt    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(VAT,0)) AS VAT    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(SumAmt,0)) AS SumAmt '  + CHAR(13)  
    IF @IsDeptName      = '1' SET @SQL = @SQL + ' ,DeptSeq ,DeptName ' + CHAR(13)   
    IF @IsResultDate    = '1' SET @SQL = @SQL + ' ,ResultDate ' + CHAR(13)  
    IF @IsCustName      = '1' SET @SQL = @SQL + ' ,CustName ,CustSeq ' + CHAR(13)        
    IF @IsUMChannelName = '1' SET @SQL = @SQL + ' ,UMChannelName ,UMChannel ' + CHAR(13)        
    IF @IsPJTName       = '1' SET @SQL = @SQL + ' ,PJTName ,PJTSeq ' + CHAR(13)  
    IF @IsEmpName       = '1' SET @SQL = @SQL + ' ,EmpName ,EmpSeq ' + CHAR(13)  
    IF @IsItemName      = '1' SET @SQL = @SQL + ' ,ItemName ' + CHAR(13)  
    IF @IsPrice         = '1' SET @SQL = @SQL + ' ,Price' + CHAR(13)  
    SET @SQL = @SQL + ' FROM #Result ' + CHAR(13)     
    IF @IsDeptName = '1' OR @IsResultDate = '1' OR @IsCustName = '1' OR @IsPJTName = '1' OR @IsItemName = '1' OR @IsPrice = '1' OR @IsUMChannelName = '1' OR @IsEmpName = '1' 
    BEGIN 
        SET @SQL = @SQL + ' GROUP BY ' 
        IF @IsDeptName      = '1' SET @SQL = @SQL + ' ,DeptSeq ,DeptName ' + CHAR(13)   
        IF @IsResultDate    = '1' SET @SQL = @SQL + ' ,ResultDate ' + CHAR(13)  
        IF @IsCustName      = '1' SET @SQL = @SQL + ' ,CustName ,CustSeq ' + CHAR(13)        
        IF @IsUMChannelName = '1' SET @SQL = @SQL + ' ,UMChannelName ,UMChannel ' + CHAR(13)        
        IF @IsPJTName       = '1' SET @SQL = @SQL + ' ,PJTName ,PJTSeq ' + CHAR(13)  
        IF @IsEmpName       = '1' SET @SQL = @SQL + ' ,EmpName ,EmpSeq ' + CHAR(13)  
        IF @IsItemName      = '1' SET @SQL = @SQL + ' ,ItemName ' + CHAR(13)  
        IF @IsPrice         = '1' SET @SQL = @SQL + ' ,Price' + CHAR(13)  
        SELECT @SQL = STUFF(@SQL,CHARINDEX('GROUP BY',@SQL)+10,1,'')
        
        -- Total행 
        SET @SQL2 = ''                         
        SET @SQL2 = ' UNION ALL' 
        SET @SQL2 = @SQL2 + ' SELECT 1 AS Sort
                                  ,SUM(ISNULL(Qty,0)) AS Qty    '  + CHAR(13)  
        SET @SQL2 = @SQL2 + '       ,SUM(ISNULL(Amt,0)) AS Amt    '  + CHAR(13)  
        SET @SQL2 = @SQL2 + '       ,SUM(ISNULL(VAT,0)) AS VAT    '  + CHAR(13)  
        SET @SQL2 = @SQL2 + '       ,SUM(ISNULL(SumAmt,0)) AS SumAmt '  + CHAR(13)  
        IF @IsDeptName      = '1' SET @SQL2 = @SQL2 + ' , 0 AS DeptSeq , '''' AS DeptName ' + CHAR(13)   
        IF @IsResultDate    = '1' SET @SQL2 = @SQL2 + ' ,'''' AS ResultDate ' + CHAR(13)  
        IF @IsCustName      = '1' SET @SQL2 = @SQL2 + ' ,'''' AS CustName ,0 AS CustSeq ' + CHAR(13)        
        IF @IsUMChannelName = '1' SET @SQL2 = @SQL2 + ' ,'''' AS UMChannelName , 0 AS UMChannel ' + CHAR(13)        
        IF @IsPJTName       = '1' SET @SQL2 = @SQL2 + ' ,'''' AS PJTName , 0 AS PJTSeq ' + CHAR(13)  
        IF @IsEmpName       = '1' SET @SQL2 = @SQL2 + ' ,'''' AS EmpName , 0 AS EmpSeq ' + CHAR(13)  
        IF @IsItemName      = '1' SET @SQL2 = @SQL2 + ' ,'''' AS ItemName ' + CHAR(13)  
        IF @IsPrice         = '1' SET @SQL2 = @SQL2 + ' ,ROUND(SUM(ISNULL(Amt,0)) / SUM(ISNULL(Qty,0)),0) AS Price' + CHAR(13)  
    
        SET @SQL2 = @SQL2 + ' FROM #Result ' + CHAR(13)     
        SET @SQL2 = @SQL2 + ' ORDER BY Sort ' + CHAR(13)     
        IF @IsDeptName      = '1' SET @SQL = @SQL + ' ,DeptName ' + CHAR(13)   
        IF @IsResultDate    = '1' SET @SQL = @SQL + ' ,ResultDate ' + CHAR(13)  
        IF @IsCustName      = '1' SET @SQL = @SQL + ' ,CustName ' + CHAR(13)        
        IF @IsUMChannelName = '1' SET @SQL = @SQL + ' ,UMChannelName ' + CHAR(13)        
        IF @IsPJTName       = '1' SET @SQL = @SQL + ' ,PJTName ' + CHAR(13)  
        IF @IsEmpName       = '1' SET @SQL = @SQL + ' ,EmpName ' + CHAR(13)  
        IF @IsItemName      = '1' SET @SQL = @SQL + ' ,ItemName ' + CHAR(13)  
        IF @IsPrice         = '1' SET @SQL = @SQL + ' ,Price' + CHAR(13)  
        
        SELECT @SQL = @SQL + @SQL2
        EXEC SP_EXECUTESQL @SQL 
    END 
    ELSE 
    BEGIN
        EXEC SP_EXECUTESQL @SQL 
    END 
    IF @@ERROR <> 0  RETURN    
    RETURN
go
exec hencom_SSLUserInvoiceReplaceListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMChannel />
    <EmpName>강용규</EmpName>
    <FrDate>20170301</FrDate>
    <ToDate>20170425</ToDate>
    <QueryType>1</QueryType>
    <IsGoods>0</IsGoods>
    <DeptSeq>0</DeptSeq>
    <CustSeq />
    <PJTSeq />
    <ItemName />
    <IsDeptName>1</IsDeptName>
    <IsResultDate>1</IsResultDate>
    <IsCustName>1</IsCustName>
    <IsUMChannelName>1</IsUMChannelName>
    <IsPJTName>1</IsPJTName>
    <IsEmpName>1</IsEmpName>
    <IsItemName>1</IsItemName>
    <IsPrice>1</IsPrice>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511471,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033026