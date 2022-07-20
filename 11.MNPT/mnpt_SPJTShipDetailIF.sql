IF OBJECT_ID('mnpt_SPJTShipDetailIF') IS NOT NULL 
    DROP PROC mnpt_SPJTShipDetailIF
GO 

-- 모선항차연동 by이재천
CREATE PROC mnpt_SPJTShipDetailIF
    @CompanySeq INT, 
    @UserSeq    INT, 
    @PgmSeq     INT, 
    @FrIFDate   NVARCHAR(8), 
    @ToIFDate   NVARCHAR(8)
AS 
    
    SELECT * 
      INTO #DVESSEL
      FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSEL')
    
    --select * from #DVESSEL where VESSEL = 'SKDK'and VES_YY = '2007' AND VES_SEq = 2

    --select * from mnpt_TMoseonD where VESSEL = 'SKDK' and VES_YY = '2007' AND VES_SEq = 2 
    --return 
    IF @FrIFDate IS NULL SELECT @FrIFDate = '' 
    IF @ToIFDate IS NULL OR @ToIFDate = '' SELECT @ToIFDate = '99991231'
    
    -- A, U, D 형식 데이터 담기 
    CREATE TABLE #mnpt_TPJTShipDetail 
    (
        IDX_NO              INT IDENTITY, 
        WorkingTag          NCHAR(1), 
        Status              INT, 
        ErrMessage          NVARCHAR(2000), 
        IFShipCode          NVARCHAR(200),
        ShipSerlNo          NVARCHAR(200), 
        InPlanDateTime      NVARCHAR(200), 
        OutPlanDateTime     NVARCHAR(200), 
        InDateTime          NVARCHAR(200), 
        ApproachDateTime    NVARCHAR(200), 
        WorkSrtDateTime     NVARCHAR(200),
        WorkEndDateTime     NVARCHAR(200), 
        OutDateTime         NVARCHAR(200),
        DiffApproachTime    DECIMAL(19,5), 
        BERTH               NVARCHAR(200),
        BRIDGE              NVARCHAR(200),
        FROM_BIT            NVARCHAR(200),
        TO_BIT              NVARCHAR(200),
        PORT                NVARCHAR(200), 
        TRADECode           NVARCHAR(200), 
        BULKCNTR            NVARCHAR(200), 
        BizUnitCode         NVARCHAR(200), 
        AgentName           NVARCHAR(200), 
        LastWorkTime        NCHAR(12), 
        ShipSeq             INT, 
        ShipSerl            INT 
    ) 

    INSERT INTO #mnpt_TPJTShipDetail 
    ( 
        WorkingTag       , Status           , IFShipCode       , ShipSerlNo       , InPlanDateTime   , 
        OutPlanDateTime  , InDateTime       , ApproachDateTime , WorkSrtDateTime  , WorkEndDateTime  , 
        OutDateTime      , BERTH            , BRIDGE           , FROM_BIT         , TO_BIT           , 
        PORT             , TRADECode        , BULKCNTR         , BizUnitCode      , AgentName        , 
        LastWorkTime     , ShipSeq          , ShipSerl         , DiffApproachTime
    ) 
    -- 인터페이스 테이블에 없는 데이터 담기 (INSERT) 
    SELECT 'A' AS WorkingTag, 
           0 AS Status, 

           A.VESSEL,                -- 모선코드 
           CONVERT(NVARCHAR(100),A.VES_YY) + RIGHT('00' + CONVERT(NVARCHAR(50),A.VES_SEQ),3) AS ShipSerlNo, -- 항차
           A.ETA,                   -- 입항예정일시
           A.ETD,                   -- 출항예정일시
           A.ATA,                   -- 입항일시
           A.ATB,                   -- 접안일시 
           A.DIS_STR,               -- 하역개시일시
           A.DIS_END,               -- 하역종료일시 
           A.ATD,                   -- 출항일시 
           A.BERTH,                 -- 선석
           A.BIT,                   -- BRIDGE 
           A.FROM_BIT,              -- FromBIT 
           A.TO_BIT,                -- ToBIT 
           A.PORT,                  -- 전출항PORT 
           A.TRADE,                 -- 항로 
           A.CNTR_BULK,             -- 벌크컨테이너구분 
           A.SAUPCH,                -- 사업부문코드 
           A.AGENT_NM,              -- 대리점 
           CASE WHEN A.UPD_DATE IS NULL OR A.UPD_DATE = '' THEN A.INS_DATE ELSE A.UPD_DATE END AS LastWorkTime, -- 최종등록 및 수정 시간
           B.ShipSeq AS ShipSeq, 
           0 AS ShipSerl, 

           CEILING(DATEDIFF(MI,
                               STUFF(STUFF(LEFT(A.ATB,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ATB,4),3,0,':') + ':00.000', 
                               STUFF(STUFF(LEFT(A.ATD,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ATD,4),3,0,':') + ':00.000'
                           ) / 60.
                  )  AS DiffApproachTime -- 접안시간

      FROM #DVESSEL                 AS A 
      JOIN mnpt_TPJTShipMaster_IF   AS B ON ( B.CompanySeq = @CompanySeq AND B.IFShipCode = A.VESSEL ) 
     WHERE NOT EXISTS (SELECT 1 FROM mnpt_TPJTShipDetail_IF WHERE CompanySeq = @CompanySeq AND IFShipCode = A.VESSEL AND ShipYear = A.VES_YY AND SerlNo = A.VES_SEQ)
       AND LEFT(ISNULL(A.ETA,''),8) BETWEEN @FrIFDate AND @ToIFDate 
    
    
    INSERT INTO #mnpt_TPJTShipDetail 
    ( 
        WorkingTag       , Status           , IFShipCode       , ShipSerlNo       , InPlanDateTime   , 
        OutPlanDateTime  , InDateTime       , ApproachDateTime , WorkSrtDateTime  , WorkEndDateTime  , 
        OutDateTime      , BERTH            , BRIDGE           , FROM_BIT         , TO_BIT           , 
        PORT             , TRADECode        , BULKCNTR         , BizUnitCode      , AgentName        , 
        LastWorkTime     , ShipSeq          , ShipSerl         , DiffApproachTime
    ) 
    -- 인터페이스 있고, 수정날짜가 최신 데이터 담기 (UPDATE) 
    SELECT 'U' AS WorkingTag, 
           0 AS Status, 
           B.VESSEL,                -- 모선코드 
           CONVERT(NVARCHAR(100),B.VES_YY) + RIGHT('00' + CONVERT(NVARCHAR(50),B.VES_SEQ),3) AS ShipSerlNo, -- 항차
           B.ETA,                   -- 입항예정일시
           B.ETD,                   -- 출항예정일시
           B.ATA,                   -- 입항일시
           B.ATB,                   -- 접안일시 
           B.DIS_STR,               -- 하역개시일시
           B.DIS_END,               -- 하역종료일시 
           B.ATD,                   -- 출항일시 
           B.BERTH,                 -- 선석
           B.BIT,                   -- BRIDGE 
           B.FROM_BIT,              -- FromBIT 
           B.TO_BIT,                -- ToBIT 
           B.PORT,                  -- 전출항PORT 
           B.TRADE,                 -- 항로 
           B.CNTR_BULK,             -- 벌크컨테이너구분 
           B.SAUPCH,                -- 사업부문코드 
           B.AGENT_NM,              -- 대리점 
           CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END AS LastWorkTime, -- 최종등록 및 수정 시간
           A.ShipSeq AS ShipSeq, 
           A.ShipSerl AS ShipSerl, 

           CEILING(DATEDIFF(MI,
                               STUFF(STUFF(LEFT(B.ATB,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(B.ATB,4),3,0,':') + ':00.000', 
                               STUFF(STUFF(LEFT(B.ATD,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(B.ATD,4),3,0,':') + ':00.000'
                           ) / 60.
                  )  AS DiffApproachTime -- 접안시간
      FROM mnpt_TPJTShipDetail_IF   AS A 
      JOIN #DVESSEL                 AS B WITH(NOLOCK) ON ( B.VESSEL = A.IFShipCode AND B.VES_YY = A.ShipYear AND B.VES_SEQ = A.SerlNo ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END) > A.LastWorkTime 
       AND LEFT(ISNULL(B.ETA,''),8) BETWEEN @FrIFDate AND @ToIFDate 


    INSERT INTO #mnpt_TPJTShipDetail 
    ( 
        WorkingTag       , Status           , IFShipCode       , ShipSerlNo       , InPlanDateTime   , 
        OutPlanDateTime  , InDateTime       , ApproachDateTime , WorkSrtDateTime  , WorkEndDateTime  , 
        OutDateTime      , BERTH            , BRIDGE           , FROM_BIT         , TO_BIT           , 
        PORT             , TRADECode        , BULKCNTR         , BizUnitCode      , AgentName        , 
        LastWorkTime     , ShipSeq          , ShipSerl         , DiffApproachTime
    ) 
    -- 원천 테이블에 없는 데이터 담기 (DELETE) 
    SELECT 'D' AS WorkingTag, 
           0 AS Status, 
           A.IFShiPCode,        -- 모선코드 
           CONVERT(NVARCHAR(100),A.ShipYear) + RIGHT('00' + CONVERT(NVARCHAR(50),A.SerlNo),3) AS ShipSerlNo,    -- 항차
           '',                  -- 입항예정일시
           '',                  -- 출항예정일시
           '',                  -- 입항일시
           '',                  -- 접안일시 
           '',                  -- 하역개시일시
           '',                  -- 하역종료일시 
           '',                  -- 출항일시 
           '',                  -- 선석
           '',                  -- BRIDGE 
           '',                  -- FromBIT 
           '',                  -- ToBIT 
           '',                  -- 전출항PORT 
           '',                  -- 항로 
           '',                  -- 벌크컨테이너구분 
           '',                  -- 사업부문코드 
           '',                  -- 대리점 
           '' AS LastWorkTime,  -- 최종등록 및 수정 시간
           A.ShipSeq AS ShipSeq, 
           A.ShipSerl AS ShipSerl, 
           0 
      FROM mnpt_TPJTShipDetail_IF    AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND NOT EXISTS (SELECT 1 FROM #DVESSEL WHERE VESSEL = A.IFShipCode AND VES_YY = A.ShipYear AND VES_SEQ = A.SerlNo)

        
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipDetail WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN  
        -- 각 모선별 MaxSerl 구하기 
        SELECT DISTINCT Z.ShipSeq, ISNULL(Y.MaxShipSerl,0) AS MaxShipSerl 
          INTO #MaxSerl 
          FROM #mnpt_TPJTShipDetail AS Z 
          LEFT OUTER JOIN ( 
                            SELECT ShipSeq, MAX(ShipSerl) AS MaxShipSerl 
                              FROM mnpt_TPJTShipDetail 
                             GROUP BY ShipSeq 
                          ) AS Y ON ( Y.ShipSeq = Z.ShipSeq ) 
    
        -- Serl 채번 
        UPDATE A 
           SET ShipSerl = B.MaxShipSerl + A.IDX_NO
          FROM #mnpt_TPJTShipDetail  AS A 
          JOIN #MaxSerl             AS B ON ( B.ShipSeq = A.ShipSeq ) 
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0 
    END 
    
    
    -- 이안정보가 있는경우 접안시간을 다시 계산해준다. 
    UPDATE A
       SET DiffApproachTime = B.DiffApproachTime
      FROM #mnpt_TPJTShipDetail                 AS A 
      OUTER APPLY(
                    SELECT Z.ShipSeq, Z.ShipSerl, CEILING(SUM(DiffApproachTime)) AS DiffApproachTime
                      FROM  mnpt_TPJTShipDetailChange AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl 
                     GROUP BY Z.ShipSeq, Z.ShipSerl
                 ) AS B 
     WHERE B.ShipSeq IS NOT NULL 
    
    ----------------------------------------------------------------------------------------
    -- 체크, 본선작업계획, 작업계획, 작업실적 존재하여 삭제되지 않습니다. (삭제시 체크 후 Temp(처리되는테이블) 삭제)
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET ErrMessage = '본선작업계획, 작업계획, 작업실적 존재하여 삭제되지 않습니다.', 
           Status = 1234
      FROM #mnpt_TPJTShipDetail AS A 
     WHERE A.WorkingTag = 'D' 
       AND (EXISTS (SELECT 1 FROM mnpt_TPJTWorkPlan WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
            OR EXISTS (SELECT 1 FROM mnpt_TPJTShipWorkPlanFinish WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
            OR EXISTS (SELECT 1 FROM mnpt_TPJTWorkReport WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
           ) 
    
    UPDATE A
       SET ErrMessage = B.ErrMessage
      FROM mnpt_TPJTShipDetail_IF           AS A 
      LEFT OUTER JOIN #mnpt_TPJTShipDetail  AS B ON ( B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag = 'D' 
       AND B.Status <> 0 
    
    DELETE A
      FROM #mnpt_TPJTShipDetail AS A 
     WHERE A.Status <> 0 
       AND A.WorkingTag = 'D'  
    ----------------------------------------------------------------------------------------
    -- 체크, End
    ----------------------------------------------------------------------------------------


    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetail')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  1             ,        
                  'mnpt_TPJTShipDetail'    , -- 테이블명        
                  '#mnpt_TPJTShipDetail'    , -- 임시 테이블명        
                  'ShipSeq,ShipSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipDetail WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        -- ERP 모선테이블 
        DELETE B   
          FROM #mnpt_TPJTShipDetail  AS A   
          JOIN mnpt_TPJTShipDetail   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        -- 중간 IF 테이블 
        DELETE B   
          FROM #mnpt_TPJTShipDetail      AS A   
          JOIN mnpt_TPJTShipDetail_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipDetail WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- 중간 IF 테이블 
        UPDATE B
           SET LastWorkTime = A.LastWorkTime, 
               ErrMessage = '',  
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE(), 
               PgmSeq = @PgmSeq
          FROM #mnpt_TPJTShipDetail      AS A   
          JOIN mnpt_TPJTShipDetail_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    
        -- ERP 모선테이블 
        UPDATE B   
           SET B.InPlanDateTime    = A.InPlanDateTime    ,
               B.OutPlanDateTime   = A.OutPlanDateTime   ,
               B.InDateTime        = A.InDateTime        ,
               B.ApproachDateTime  = A.ApproachDateTime  ,
               B.WorkSrtDateTime   = A.WorkSrtDateTime   ,
               B.WorkEndDateTime   = A.WorkEndDateTime   ,
               B.OutDateTime       = A.OutDateTime       ,
               B.DiffApproachTime  = A.DiffApproachTime  , 
               B.BERTH             = A.BERTH             ,
               B.BRIDGE            = A.BRIDGE            ,
               B.FROM_BIT          = A.FROM_BIT          ,
               B.TO_BIT            = A.TO_BIT            ,
               B.PORT              = A.PORT              ,
               B.TRADECode         = A.TRADECode         ,
               B.BULKCNTR          = A.BULKCNTR          ,
               B.BizUnitCode       = A.BizUnitCode       ,
               B.AgentName         = A.AgentName         ,
               B.FirstUserSeq      = @UserSeq            ,
               B.FirstDateTime     = GETDATE()           ,
               B.LastUserSeq       = @UserSeq, 
               B.LastDateTime      = GETDATE(), 
               B.PgmSeq            = @PgmSeq
          FROM #mnpt_TPJTShipDetail  AS A   
          JOIN mnpt_TPJTShipDetail   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipDetail WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- 중간 IF 테이블 
        INSERT INTO mnpt_TPJTShipDetail_IF
        ( 
            CompanySeq, ShipSeq, ShipSerl, IFShipCode, ShipYear, 
            SerlNo, LastWorkTime, ErrMessage, LastUserSeq, LastDateTime, 
            PgmSeq
        ) 
        SELECT @CompanySeq, ShipSeq, ShipSerl, IFShipCode, LEFT(ShipSerlNo,4),
               CONVERT(INT,RIGHT(ShipSerlNo,3)),  LastWorkTime, '', @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #mnpt_TPJTShipDetail AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0     
        
        IF @@ERROR <> 0 RETURN  

        -- ERP 모선테이블 
        INSERT INTO mnpt_TPJTShipDetail  
        (   
            CompanySeq, ShipSeq, ShipSerl, IFShipCode, ShipSerlNo, 
            InPlanDateTime, OutPlanDateTime, InDateTime, ApproachDateTime, WorkSrtDateTime, 
            WorkEndDateTime, OutDateTime, DiffApproachTime, BERTH, BRIDGE, 
            FROM_BIT, TO_BIT, PORT, TRADECode, BULKCNTR, 
            BizUnitCode, AgentName, FirstUserSeq, FirstDateTime, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ShipSeq, ShipSerl, IFShipCode, ShipSerlNo,
               InPlanDateTime, OutPlanDateTime, InDateTime, ApproachDateTime, WorkSrtDateTime, 
               WorkEndDateTime, OutDateTime, DiffApproachTime, BERTH, BRIDGE, 
               FROM_BIT, TO_BIT, PORT, TRADECode, BULKCNTR, 
               BizUnitCode, AgentName, @UserSeq, GETDATE(), @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #mnpt_TPJTShipDetail AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
        
    SELECT * FROM #mnpt_TPJTShipDetail 
    
RETURN 
GO

begin tran 

exec mnpt_SPJTShipDetailIF @CompanySeq = 1, @UserSeq = 1, @PgmSeq = 1, @FrIFDate = '', @ToIFDate = ''

--select * from mnpt_TPJTShipDetail 

rollback 


