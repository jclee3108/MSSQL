
IF OBJECT_ID('KPX_SSLWeekSalesPlanQueryLIst') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanQueryLIst
GO 

 -- v2015.05.14  
  CREATE PROC [dbo].[KPX_SSLWeekSalesPlanQueryLIst]                
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
             @ItemClassSSeq INT,
             @ItemClassLSeq INT,
             @FirstPlanRev  NCHAR(2),
             @PrePlanRev    NCHAR(2)  
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
     
     SELECT @WeekSeq        = ISNULL(WeekSeq, 0), 
            @BizUnit        = ISNULL(BizUnit, 0), 
            @CustName       = ISNULL(CustName, ''), 
            @PlanRev        = ISNULL(PlanRev, ''), 
            @ItemName       = ISNULL(ItemName, ''), 
            @ItemNo         = ISNULL(ItemNo, ''), 
            @ItemClassSSeq  = ISNULL(ItemClassSSeq,0),
            @ItemClassLSeq  = ISNULL(ItemClassLSeq,0)  
            
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (
             WeekSeq        INT ,
             BizUnit        INT ,
             CustName       NVARCHAR(100) ,
             PlanRev        NCHAR(2) ,
             ItemName       NVARCHAR(200) ,
             ItemNo         NVARCHAR(100) ,
             ItemClassSSeq  INT,
             ItemClassLSeq  INT  
            )
     
  
  
    CREATE TABLE #Tbl
    (
         BizUnit       INT
        ,CustSeq       INT
        ,ItemSeq       INT
        ,DVPlaceSeq    INT
        ,FirstPlanRev  NCHAR(8)
        ,PrePlanRev    NCHAR(8)
        ,LastPlanRev   NCHAR(8)
    )
    
     INSERT INTO #Tbl(BizUnit,CustSeq,ItemSeq,DVPlaceSeq,FirstPlanRev)
          SELECT BizUnit,CustSeq,ItemSeq,DVPlaceSeq,MIN(PlanRev) AS FirstPlanRev 
      FROM KPX_TSLWeekSalesPlan
     WHERE CompanySeq=@CompanySeq
    AND WeekSeq=@WeekSeq
     GROUP BY BizUnit,CustSeq,ItemSeq,DVPlaceSeq
    
 
     
   INSERT INTO #Tbl(BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PrePlanRev)
   SELECT BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev
  FROM 
  ( 
     SELECT   BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev, ROW_NUMBER() OVER(Partition By BizUnit,CustSeq,ItemSeq,DVPlaceSeq  ORDER BY BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev DESC) AS RK 
     FROM (SELECT DISTINCT BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev FROM KPX_TSLWeekSalesPlan
      WHERE CompanySeq=@CompanySeq
     AND WeekSeq=@WeekSeq
     )AA
   )BB
  WHERE RK = 2
    
    INSERT INTO #Tbl(BizUnit,CustSeq,ItemSeq,DVPlaceSeq,LastPlanRev)
   SELECT BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev
  FROM 
  ( 
     SELECT   BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev, ROW_NUMBER() OVER(Partition By BizUnit,CustSeq,ItemSeq  ORDER BY BizUnit,CustSeq,ItemSeq,PlanRev DESC) AS RK 
     FROM (SELECT DISTINCT BizUnit,CustSeq,ItemSeq,DVPlaceSeq,PlanRev FROM KPX_TSLWeekSalesPlan
      WHERE CompanySeq=@CompanySeq
     AND WeekSeq=@WeekSeq
     )AA
   )BB
  WHERE RK = 1
  
    

    
        SELECT Bizunit
     ,CustSeq
     ,ItemSeq
     ,DVPlaceSeq
     ,FirstPlanRev
     ,PrePlanRev
     ,LastPlanRev
     ,(SELECT MAX(CONVERT(NVARCHAR(8),LastDateTime,112)) 
         FROM KPX_TSLWeekSalesPlan 
        WHERE CompanySeq=@CompanySeq 
          AND WeekSeq=@WeekSeq 
          AND BizUnit = A.BizUnit 
          AND CustSeq=A.CustSeq 
          AND ItemSeq = A.ItemSeq 
          AND DVPlaceSeq = A.DVPlaceSeq 
          AND PlanRev=A.FirstPlanRev
      ) AS FirstRegDate
     ,(SELECT MAX(CONVERT(NVARCHAR(8),LastDateTime,112)) 
         FROM KPX_TSLWeekSalesPlan 
        WHERE CompanySeq=@CompanySeq 
          AND WeekSeq=@WeekSeq 
          AND BizUnit = A.BizUnit 
          AND CustSeq=A.CustSeq 
          AND ItemSeq = A.ItemSeq 
          AND DVPlaceSeq = A.DVPlaceSeq 
          AND PlanRev=A.PrePlanRev
      ) AS PreRegDate
     ,(SELECT MAX(CONVERT(NVARCHAR(8),LastDateTime,112)) 
         FROM KPX_TSLWeekSalesPlan 
        WHERE CompanySeq=@CompanySeq 
          AND WeekSeq=@WeekSeq 
          AND BizUnit = A.BizUnit 
          AND CustSeq=A.CustSeq 
          AND ItemSeq = A.ItemSeq 
          AND DVPlaceSeq = A.DVPlaceSeq 
          AND PlanRev=A.LastPlanRev
      )  AS LastRegDate
      INTO #Tbl2 
         FROM 
                ( SELECT Bizunit,CustSeq,ItemSeq,DVPlaceSeq,MAX(FirstPlanRev) AS FirstPlanRev ,MAX(PrePlanRev) AS PrePlanRev,MAX(LastPlanRev) AS LastPlanRev
        FROM #Tbl
       GROUP BY Bizunit,CustSeq,ItemSeq,DVPlaceSeq
       )A 
    
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
    
    SELECT @EnvValue4 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 4 AND EnvSerl = 1 ),1025001)
    SELECT @EnvValue5 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 5 AND EnvSerl = 1 ),0)
    
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
        PlanDate            NCHAR(8),
        FirstRegDate        NCHAR(8),
        PreRegDate          NCHAR(8),
        LastRegDate         NCHAR(8),
        BizUnitName         NVARCHAR(60), 
        DVPlaceSeqOld       INT, 
        DVPlaceSeq          INT, 
        DVPlaceName         NVARCHAR(100) 
    )
     
  
  
    INSERT INTO #TEMP
    (
        UMCustClassName,    CustSeq,        CustName,           CustNo,         ItemClassLName,
        ItemClassMName,     ItemClassName,  ItemSeq,            ItemName,       ItemNo, 
        Spec,               UMPackingType,  UMPackingTypeName,  CustSeqOld,     ItemSeqOld, 
        BizUnit,            WeekSeq,        PlanRev,            PlanDate,       FirstRegDate,   
        PreRegDate,         LastRegDate,    BizUnitName,        DVPlaceSeqOld,  DVPlaceSeq, 
        DVPlaceName 
    )
    SELECT G.MinorName, A.CustSeq, C.CustName, C.CustNo, E.ItemClasLName, 
           E.ItemClasMName, E.ItemClasSName, A.ItemSeq, D.ItemName, D.ItemNo, 
           D.Spec, A.UMPackingType, H.MinorName, A.CustSeq, A.ItemSeq, 
           A.BizUnit, A.WeekSeq, A.PlanRev, A.PlanDate, I.FirstRegDate, 
           I.PreRegDate, CONVERT(NVARCHAR(8),A.LastDateTime,112) AS LastRegDate, B.BizUnitName, A.DVPlaceSeq, A.DVPlaceSeq, 
           J.DVPlaceName 
      FROM KPX_TSLWeekSalesPlan         AS A 
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem          AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS E ON ( E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACustClass     AS F ON ( F.CompanySeq = @CompanySeq AND F.UMajorCustClass = 8004 AND A.CustSeq = F.CustSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMCustClass ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMPackingType ) 
                 JOIN #Tbl2             AS I ON A.BizUnit=I.BizUnit AND A.CustSeq=I.CustSeq AND A.ItemSeq=I.ItemSeq AND A.PlanRev=I.LastPlanRev
      LEFT OUTER JOIN _TSLDeliveryCust  AS J ON ( J.CompanySeq = @CompanySEq AND J.DVPlaceSeq = A.DVPlaceSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WeekSeq = @WeekSeq 
       AND (@BizUnit=0 OR A.BizUnit = @BizUnit )
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%') 
       AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%') 
       AND (@ItemClassSSeq = 0 OR E.ItemClassSSeq = @ItemClassSSeq) 
       AND (@ItemClassLSeq = 0 OR E.ItemClassLSeq = @ItemClassLSeq) 
    
    CREATE TABLE #FixCol 
    (
        RowIdx              INT IDENTITY(0,1), 
        BizUnit             INT,
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
        FirstRegDate        NCHAR(8),
        PreRegDate          NCHAR(8),
        LastRegDate         NCHAR(8),
        BizUnitName         NVARCHAR(60), 
        DVPlaceSeqOld       INT, 
        DVPlaceSeq          INT, 
        DVPlaceName         NVARCHAR(100) 
    )
    
    INSERT INTO #FixCol
    (
        BizUnit,        UMCustClassName,    CustSeq,        CustName,           CustNo,     
        ItemClassLName, ItemClassMName,     ItemClassName,  ItemSeq,            ItemName,   
        ItemNo,         Spec,               UMPackingType,  UMPackingTypeName,  CustSeqOld, 
        ItemSeqOld,     FirstRegDate,       PreRegDate,     LastRegDate,        BizUnitName, 
        DVPlaceSeqOld,  DVPlaceSeq,         DVPlaceName
    )
     SELECT BizUnit,                MAX(UMCustClassName),    CustSeq,               MAX(CustName),              MAX(CustNo),        
            MAX(ItemClassLName),    MAX(ItemClassMName),     MAX(ItemClassName),    ItemSeq,                    MAX(ItemName),      
            MAX(ItemNo),            MAX(Spec),               MAX(UMPackingType),    MAX(UMPackingTypeName),     MAX(CustSeqOld),    
            MAX(ItemSeqOld),        MAX(FirstRegDate),       MAX(PreRegDate),       MAX(LastRegDate),           MAX(BizUnitName), 
            MAX(DVPlaceSeqOld),     DVPlaceSeq,              MAX(DVPlaceName) 
       FROM #TEMP 
      GROUP BY BizUnit,CustSeq, ItemSeq, DVPlaceSeq 
       
    
     SELECT * FROM #FixCol 
    --------------
    -- 가변값 
    --------------
    CREATE TABLE #Value 
    (
        Value       DECIMAL(19,5), 
        BizUnit     INT,
        CustSeq     INT, 
        ItemSeq     INT, 
        DVPlaceSeq  INT, 
        PlanDate    NCHAR(8) 
    ) 
    
    INSERT INTO #Value (Value, BizUnit, CustSeq, ItemSeq, DVPlaceSeq, PlanDate)
    SELECT B.Qty, B.BizUnit,B.CustSeq, B.ItemSeq, B.DVPlaceSeq, B.PlanDate
      FROM #TEMP AS A 
      JOIN KPX_TSLWeekSalesPlan AS B ON ( B.CompanySeq = @CompanySeq 
                                      AND B.BizUnit = A.BizUnit 
                                      AND B.WeekSeq = A.WeekSeq 
                                      AND B.PlanRev = A.PlanRev 
                                      AND B.CustSeq = A.CustSeq 
                                      AND B.ItemSeq = A.ItemSeq 
                                      AND B.DVPlaceSeq = A.DVPlaceSeq 
                                      AND B.PlanDate = A.PlanDate 
                                        ) 
     
    SELECT B.RowIdx, A.ColIdx, C.Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.PlanDate ) 
      JOIN #FixCol AS B ON ( B.BizUnit = C.BizUnit AND B.CustSeq = C.CustSeq AND B.ItemSeq = C.ItemSeq AND B.DVPlaceSeq = C.DVPlaceSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
     
    RETURN
GO 

exec KPX_SSLWeekSalesPlanQueryLIst @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanRevSeq>0</PlanRevSeq>
    <WeekSeq>6001</WeekSeq>
    <BizUnit>2</BizUnit>
    <CustName />
    <ItemClassSSeq />
    <ItemName />
    <ItemNo />
    <ItemClassLSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025887,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1023890