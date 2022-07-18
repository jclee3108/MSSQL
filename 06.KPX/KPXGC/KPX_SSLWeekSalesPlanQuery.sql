
IF OBJECT_ID('KPX_SSLWeekSalesPlanQuery') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanQuery
GO 

-- v2014.11.17 

-- 주간판매계획입력(조회) by이재천 
CREATE PROC KPX_SSLWeekSalesPlanQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0       
AS        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,
            @WeekSeq        INT ,
            @BizUnit        INT ,
            @CustName       NVARCHAR(100) ,
            @PlanRev        NCHAR(2) ,
            @ItemName       NVARCHAR(200) ,
            @ItemNo         NVARCHAR(100) ,
            @ItemSClass     INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @WeekSeq        = ISNULL(WeekSeq, 0), 
           @BizUnit        = ISNULL(BizUnit, 0), 
           @CustName       = ISNULL(CustName, ''), 
           @PlanRev        = ISNULL(PlanRev, ''), 
           @ItemName       = ISNULL(ItemName, ''), 
           @ItemNo         = ISNULL(ItemNo, ''), 
           @ItemSClass     = ISNULL(ItemSClass,0)    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            WeekSeq        INT ,
            BizUnit        INT ,
            CustName       NVARCHAR(100) ,
            PlanRev        NCHAR(2) ,
            ItemName       NVARCHAR(200) ,
            ItemNo         NVARCHAR(100) ,
            ItemSClass     INT  
           )
    
    -- 이전차수 복사 
    IF @WorkingTag = 'Copy'  
    BEGIN  
          
        DECLARE @TableColumns NVARCHAR(4000)      
          
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLWeekSalesPlan')      
          
        SELECT DISTINCT 1 AS IDX_NO,   
               'D' AS WorkingTag,   
               0 AS Status,   
               A.BizUnit,   
               A.WeekSeq,   
               A.PlanRev  
          INTO #Rev_Log  
          FROM KPX_TSLWeekSalesPlan AS A  
         WHERE CompanySeq = @CompanySeq   
           AND BizUnit = @BizUnit   
           AND WeekSeq = @WeekSeq   
           AND PlanRev = @PlanRev  
    
        EXEC _SCOMLog @CompanySeq   ,          
                      @UserSeq      ,          
                      'KPX_TSLWeekSalesPlan'    , -- 테이블명          
                      '#Rev_Log'    , -- 임시 테이블명          
                      'BizUnit,WeekSeq,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
  
        DELETE A  
          FROM KPX_TSLWeekSalesPlan AS A  
         WHERE CompanySeq = @CompanySeq   
           AND BizUnit = @BizUnit   
           AND WeekSeq = @WeekSeq
           AND PlanRev = @PlanRev  
      
        SELECT @PlanRev = RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,@PlanRev) - 1 ),2)  
    END 
    
    
    
    
    --------------
    -- 헤더
    --------------
    DECLARE @EnvValue4 INT, 
            @EnvValue5 INT, 
            @DayKind   INT, 
            @SDate     NCHAR(8), 
            @Cnt       INT, 
            @FromDate  NCHAR(8), 
            @ToDate    NCHAR(8) 
    
    SELECT @FromDate = DateFr, 
           @ToDate = DateTo 
      FROM _TPDBaseProdWeek AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.Serl = @WeekSeq 
    
    SELECT @EnvValue4 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 4 AND EnvSerl = 1 ),1025001)
    SELECT @EnvValue5 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 5 AND EnvSerl = 1 ),0)
    
    SELECT @DayKind = CASE WHEN A.MinorValue = 7 THEN 0 ELSE A.MinorValue END 
      FROM _TDASMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND MinorSeq = @EnvValue4 
    
    
    SELECT @SDate = A.Solar
      FROM _TCOMCalendar AS A
     WHERE A.Solar BETWEEN @FromDate AND @ToDate 
       AND A.SWeek0 = @DayKind 
    
    
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(100), 
        TitleSeq    INT
    ) 
    
    SELECT @Cnt = 0 
    
    WHILE( 1 = 1 ) 
    BEGIN
        INSERT INTO #Title (Title, TitleSeq)
        SELECT STUFF(RIGHT(Solar,4),3,0,'월 ') + '일', CONVERT(INT,Solar) 
          FROM _TCOMCalendar
         WHERE Solar = CONVERT(NCHAR(8),DATEADD(DAY,@Cnt,@SDate),112)
        
        IF @Cnt = @EnvValue5 - 1 
        BEGIN
            BREAK
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
        
    END 
    
    SELECT * FROM #Title 
    
    --------------
    -- 고정값 
    --------------
    CREATE TABLE #TEMP 
    (
        RowIdx              INT IDENTITY, 
        UMCustClassName     NVARCHAR(100), 
        CustSeq             INT, 
        CustName            NVARCHAR(100), 
        CustNo              NVARCHAR(100), 
        ItemClassLName      NVARCHAR(100), 
        ItemClassMName      NVARCHAR(100), 
        ItemClassName       NVARCHAR(100), 
        ItemSeq             INT, 
        ItemName            NVARCHAR(100), 
        ItemNo              NVARCHAR(100), 
        Spec                NVARCHAR(100), 
        UMPackingType       INT, 
        UMPackingTypeName   NVARCHAR(100), 
        CustSeqOld          INT, 
        ItemSeqOld          INT, 
        BizUnit             INT, 
        WeekSeq             INT, 
        PlanRev             NCHAR(2), 
        PlanDate            NCHAR(8)
    )
    

    INSERT INTO #TEMP
    (
        UMCustClassName,    CustSeq,        CustName,           CustNo,     ItemClassLName,
        ItemClassMName,     ItemClassName,  ItemSeq,            ItemName,   ItemNo, 
        Spec,               UMPackingType,  UMPackingTypeName,  CustSeqOld, ItemSeqOld, 
        BizUnit,            WeekSeq,        PlanRev,            PlanDate 
    )
    SELECT G.MinorName, A.CustSeq, C.CustName, C.CustNo, E.ItemClasLName, 
           E.ItemClasMName, E.ItemClasSName, A.ItemSeq, D.ItemName, D.ItemNo, 
           D.Spec, A.UMPackingType, H.MinorName, A.CustSeq, A.ItemSeq, 
           A.BizUnit, A.WeekSeq, A.PlanRev, A.PlanDate
      FROM KPX_TSLWeekSalesPlan     AS A 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust      AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem      AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS E ON ( E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACustClass AS F ON ( F.CompanySeq = @CompanySeq AND F.UMajorCustClass = 8004 AND A.CustSeq = F.CustSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMCustClass ) 
      LEFT OUTER JOIN _TDAUMinor    AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMPackingType ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WeekSeq = @WeekSeq 
       AND A.BizUnit = @BizUnit 
       AND A.PlanRev = @PlanRev 
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%') 
       AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%') 
       AND (@ItemSClass = 0 OR E.ItemClassSSeq = @ItemSClass) 
    
    
    CREATE TABLE #FixCol 
    (
        RowIdx              INT IDENTITY(0,1), 
        UMCustClassName     NVARCHAR(100), 
        CustSeq             INT, 
        CustName            NVARCHAR(100), 
        CustNo              NVARCHAR(100), 
        ItemClassLName      NVARCHAR(100), 
        ItemClassMName      NVARCHAR(100), 
        ItemClassName       NVARCHAR(100), 
        ItemSeq             INT, 
        ItemName            NVARCHAR(100), 
        ItemNo              NVARCHAR(100), 
        Spec                NVARCHAR(100), 
        UMPackingType       INT, 
        UMPackingTypeName   NVARCHAR(100), 
        CustSeqOld          INT, 
        ItemSeqOld          INT 
    )
    
    INSERT INTO #FixCol
    (
        UMCustClassName,    CustSeq,        CustName,           CustNo,     ItemClassLName,
        ItemClassMName,     ItemClassName,  ItemSeq,            ItemName,   ItemNo, 
        Spec,               UMPackingType,  UMPackingTypeName,  CustSeqOld, ItemSeqOld 
    )
    SELECT MAX(UMCustClassName),    CustSeq,               MAX(CustName),              MAX(CustNo),        MAX(ItemClassLName),
           MAX(ItemClassMName),     MAX(ItemClassName),    ItemSeq,                    MAX(ItemName),      MAX(ItemNo), 
           MAX(Spec),               MAX(UMPackingType),    MAX(UMPackingTypeName),     MAX(CustSeqOld),    MAX(ItemSeqOld) 
      FROM #TEMP 
     GROUP BY CustSeq, ItemSeq  
      
    
    SELECT * FROM #FixCol 
    
    --------------
    -- 가변값 
    --------------
    CREATE TABLE #Value 
    (
        Value       DECIMAL(19,5), 
        CustSeq     INT, 
        ItemSeq     INT, 
        PlanDate    NCHAR(8) 
    ) 
    
    INSERT INTO #Value (Value, CustSeq, ItemSeq, PlanDate)
    SELECT B.Qty, B.CustSeq, B.ItemSeq, B.PlanDate
      FROM #TEMP AS A 
      JOIN KPX_TSLWeekSalesPlan AS B ON ( B.CompanySeq = @CompanySeq 
                                    AND B.BizUnit = A.BizUnit 
                                    AND B.WeekSeq = A.WeekSeq 
                                    AND B.PlanRev = A.PlanRev 
                                    AND B.CustSeq = A.CustSeq 
                                    AND B.ItemSeq = A.ItemSeq 
                                    AND B.PlanDate = A.PlanDate 
                                        ) 
    
    SELECT B.RowIdx, A.ColIdx, C.Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.PlanDate ) 
      JOIN #FixCol AS B ON ( B.CustSeq = C.CustSeq AND B.ItemSeq = C.ItemSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN

GO 
exec KPX_SSLWeekSalesPlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanRevSeq>1</PlanRevSeq>
    <PlanRev>01    </PlanRev>
    <WeekSeq>7</WeekSeq>
    <BizUnit>2</BizUnit>
    <CustName />
    <ItemSClass />
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025887,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021321