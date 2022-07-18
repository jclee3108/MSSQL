  
IF OBJECT_ID('KPXLS_SQCInspecHistoryQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCInspecHistoryQuery  
GO  
  
-- v2016.03.15  
  
-- 검사이력조회-조회 by 이재천   
CREATE PROC KPXLS_SQCInspecHistoryQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT, 
            -- 조회조건   
            @BizUnit            INT, 
            @ItemName           NVARCHAR(200), 
            @TestDateTo         NCHAR(8), 
            @MultiQCType        NVARCHAR(MAX), 
            @FactUnit           INT, 
            @QCType             INT, 
            @MultiSMTestResult  NVARCHAR(MAX), 
            @LotNo              NVARCHAR(200), 
            @ItemNo             NVARCHAR(200), 
            @TestDateFr         NCHAR(8), 
            @SMTestResult       INT 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit            = ISNULL( BizUnit            , 0 ),  
           @ItemName           = ISNULL( ItemName           , '' ),  
           @TestDateTo         = ISNULL( TestDateTo         , '' ),  
           @MultiQCType        = ISNULL( MultiQCType        , '' ),  
           @FactUnit           = ISNULL( FactUnit           , 0 ),  
           @QCType             = ISNULL( QCType             , 0 ),  
           @MultiSMTestResult  = ISNULL( MultiSMTestResult  , '' ),  
           @LotNo              = ISNULL( LotNo              , '' ),  
           @ItemNo             = ISNULL( ItemNo             , '' ),  
           @TestDateFr         = ISNULL( TestDateFr         , '' ),  
           @SMTestResult       = ISNULL( SMTestResult       , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit            INT, 
            ItemName           NVARCHAR(200), 
            TestDateTo         NCHAR(8), 
            MultiQCType        NVARCHAR(MAX), 
            FactUnit           INT, 
            QCType             INT, 
            MultiSMTestResult  NVARCHAR(MAX), 
            LotNo              NVARCHAR(200), 
            ItemNo             NVARCHAR(200), 
            TestDateFr         NCHAR(8), 
            SMTestResult       INT 
           )    
    
    IF @TestDateTo = '' 
    BEGIN
        SELECT @TestDateTo = '99991231'
    END 
    
    -- 최종조회  
    SELECT CONVERT(INT,0) AS FactUnit, 
           CONVERT(INT,0) AS BizUnit, 
           C.ItemName,  
           C.ItemNo, 
           A.ItemSeq, 
           F.AssetName, 
           C.AssetSeq, 
           A.LotNo, 
           G.QCTypeName, 
           A.QCType, 
           H.MinorName AS SMTestResultName, 
           A.SMTestResult, 
           B.TestDate, 
           I.ReqDate, 
           A.QCNo, 
           B.SubQCNo, 
           A.QCSeq, 
           I.ReqSeq, 
           I.FromPgmSeq, 
           I.SMSourceType, 
           I.SourceSeq 
      INTO #Result 
      FROM KPX_TQCTestResult                    AS A 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd    AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
                 JOIN _FCOMXmlToSeq(@SMTestResult, @MultiSMTestResult)  AS D ON ( D.Code = 0 OR D.Code = A.SMTestResult ) 
                 JOIN _FCOMXmlToSeq(@QCType, @MultiQCType)              AS E ON ( E.Code = 0 OR E.Code = A.QCType ) 
      LEFT OUTER JOIN _TDAItemAsset             AS F ON ( F.CompanySeq = @CompanySeq AND F.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS G ON ( G.CompanySeq = @CompanySeq AND G.QCType = A.QCType ) 
      LEFT OUTER JOIN _TDAUMinor                AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.SMTestResult ) 
      LEFT OUTER JOIN KPXLS_TQCRequest          AS I ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = A.ReqSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (B.TestDate BETWEEN @TestDateFr AND @TestDateTo)
       AND (@LotNo = '' OR A.LotNo LIKE @LotNo + '%')
    
    ---------------------------------------------------------
    -- 사업부문, 생산사업장 Update 
    ---------------------------------------------------------
    -- 특별검사(재고) 
    UPDATE A
       SET BizUnit = B.BizUnit 
      FROM #Result AS A 
      JOIN (
            SELECT DISTINCT ReqSeq, BizUnit 
              FROM KPXLS_TQCRequestItemAdd_STK 
             WHERE CompanySeq = @CompanySeq 
           ) AS B ON ( B.ReqSeq = A.ReqSeq ) 
    
    -- 특별검사(공정)  
    UPDATE A
       SET FactUnit = B.FactUnit 
      FROM #Result AS A 
      JOIN (
            SELECT DISTINCT ReqSeq, FactUnit  
              FROM KPXLS_TQCRequestItemAdd_PDI 
             WHERE CompanySeq = @CompanySeq 
           ) AS B ON ( B.ReqSeq = A.ReqSeq ) 
    
    -- 특별검사(유효)  
    UPDATE A
       SET BizUnit = B.BizUnit 
      FROM #Result AS A 
      JOIN (
            SELECT DISTINCT ReqSeq, BizUnit  
              FROM KPXLS_TACRequestItemAdd_EXP 
             WHERE CompanySeq = @CompanySeq 
           ) AS B ON ( B.ReqSeq = A.ReqSeq ) 
    
    -- 공정검사
    UPDATE A
       SET FactUnit = B.FactUnit 
      FROM #Result AS A 
      JOIN (
            SELECT DISTINCT Z.ReqSeq, Z.FactUnit   
              FROM KPXLS_TQCRequestItemAdd_PDB  AS Z 
              JOIN KPXLS_TQCRequest             AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ReqSeq = Z.ReqSeq ) 
             WHERE Z.CompanySeq = @CompanySeq 
               AND Y.PgmSeq = 1027791 -- 공정검사  
           ) AS B ON ( B.ReqSeq = A.ReqSeq ) 
    
    -- 최종검사
    UPDATE A
       SET FactUnit = B.FactUnit 
      FROM #Result AS A 
      JOIN (
            SELECT DISTINCT Z.ReqSeq, Z.FactUnit   
              FROM KPXLS_TQCRequestItemAdd_PDB  AS Z 
              JOIN KPXLS_TQCRequest             AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ReqSeq = Z.ReqSeq ) 
             WHERE Z.CompanySeq = @CompanySeq 
               AND Y.PgmSeq = 1027855 -- 최종검사 
           ) AS B ON ( B.ReqSeq = A.ReqSeq ) 
    
    -- 수입검사(내수구매) 
    UPDATE A
       SET BizUnit = B.BizUnit 
      FROM #Result  AS A 
      JOIN _TPUDelv AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.SourceSeq ) 
     WHERE A.FromPgmSeq = 1027813 
     
    -- 수입검사(수입구매) 
    UPDATE A
       SET BizUnit = B.BizUnit 
      FROM #Result      AS A 
      JOIN _TUIImpDelv  AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.SourceSeq ) 
     WHERE A.FromPgmSeq = 1028086 
     
    -- 수입검사(외주납품) 
    UPDATE A
       SET FactUnit = B.FactUnit 
      FROM #Result      AS A 
      JOIN _TPDOSPDelv  AS B ON ( B.CompanySeq = @CompanySeq AND B.OSPDelvSeq = A.SourceSeq ) 
     WHERE A.FromPgmSeq = 1028274 
    ---------------------------------------------------------
    -- 사업부문, 생산사업장 Update, END 
    ---------------------------------------------------------
    
    SELECT A.*, 
           B.FactUnitName, 
           C.BizUnitName 
      FROM #Result AS A 
      LEFT OUTER JOIN _TDAFactUnit  AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDABizUnit   AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = A.BizUnit ) 
     WHERE ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( @FactUnit = 0 OR A.FactUnit = @FactUnit ) 
    
    

    RETURN  
GO
exec KPXLS_SQCInspecHistoryQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <TestDateFr>20160101</TestDateFr>
    <TestDateTo>20160331</TestDateTo>
    <BizUnit />
    <FactUnit />
    <SMTestResult />
    <MultiSMTestResult>&amp;lt;XmlString&amp;gt;&amp;lt;/XmlString&amp;gt;</MultiSMTestResult>
    <ItemName />
    <ItemNo />
    <LotNo />
    <QCType />
    <MultiQCType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035772,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029461