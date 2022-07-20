IF OBJECT_ID('mnpt_SPJTShipMasterIF') IS NOT NULL 
    DROP PROC mnpt_SPJTShipMasterIF
GO 

-- 모선연동 by이재천
CREATE PROC mnpt_SPJTShipMasterIF
    @CompanySeq INT, 
    @UserSeq    INT, 
    @PgmSeq     INT 
AS 
    

    SELECT * 
      INTO #DVESSELC
      FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSELC')
    

    --select * from mnpt_TMoseonM where IFSHipCode = 'MOQN'
    --SELECT * FROM #DVESSELC where VESSEL_CD = 'MOQN'
    --return 
    -- A, U, D 형식 데이터 담기 
    CREATE TABLE #mnpt_TPJTShipMaster 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        Status          INT, 
        ErrMessage      NVARCHAR(2000),
        IFShipCode      NVARCHAR(200),
        EnShipName      NVARCHAR(200), 
        ShipName        NVARCHAR(200), 
        LINECode        NVARCHAR(200), 
        CodeLetters     NVARCHAR(200), 
        NationCode      NVARCHAR(200), 
        TotalTON        DECIMAL(19,5), 
        LoadTON         DECIMAL(19,5), 
        LOA             DECIMAL(19,5), 
        Breadth         DECIMAL(19,5), 
        DRAFT           DECIMAL(19,5), 
        BULKCNTR        NVARCHAR(200), 
        LastWorkTime    NCHAR(12), 
        ShipSeq         INT 
    ) 

    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- 인터페이스 테이블에 없는 데이터 담기 (INSERT) 
    SELECT 'A' AS WorkingTag, 
           A.VESSEL_CD,             -- 모선코드 
           A.VESSEL_ENM,            -- 모선명(영문) 
           A.VESSEL_KNM,            -- 모선명(한글) 
           A.LINE,                  -- LINE코드
           A.CALL_SIGN,             -- 신호부호 
           A.COUNTRY_CD,            -- 국가코드 
           A.TOT_DISP,              -- 총톤수
           A.NET_DISP,              -- 적재톤수
           A.LOA,                   -- 전장 
           A.LBP,                   -- 전폭
           A.SUM_DRAFT,             -- 하계만재홀수 
           A.CNTR_BULK,             -- 벌크 컨테이너구분
           CASE WHEN A.UPD_DATE IS NULL OR A.UPD_DATE = '' THEN A.INS_DATE ELSE A.UPD_DATE END AS LastWorkTime, -- 최종등록 및 수정 시간
           0 AS ShipSeq, 
           0 AS Status 
      FROM #DVESSELC    AS A 
     WHERE NOT EXISTS (SELECT 1 FROM mnpt_TPJTShipMaster_IF WHERE CompanySeq = @CompanySeq AND IFShipCode = A.VESSEL_CD)
    
    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- 인터페이스 있고, 수정날짜가 최신 데이터 담기 (UPDATE) 
    SELECT 'U' AS WorkingTag, 
           B.VESSEL_CD,             -- 모선코드 
           B.VESSEL_ENM,            -- 모선명(영문) 
           B.VESSEL_KNM,            -- 모선명(한글) 
           B.LINE,                  -- LINE코드
           B.CALL_SIGN,             -- 신호부호 
           B.COUNTRY_CD,            -- 국가코드 
           B.TOT_DISP,              -- 총톤수
           B.NET_DISP,              -- 적재톤수
           B.LOA,                   -- 전장 
           B.LBP,                   -- 전폭
           B.SUM_DRAFT,             -- 하계만재홀수 
           B.CNTR_BULK,             -- 벌크 컨테이너구분
           CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END AS LastWorkTime, -- 최종등록 및 수정 시간
           A.ShipSeq AS ShipSeq, 
           0 AS Status
      FROM mnpt_TPJTShipMaster_IF   AS A 
      JOIN #DVESSELC                AS B WITH(NOLOCK) ON ( B.VESSEL_CD = A.IFShipCode ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END) > A.LastWorkTime
    
    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- 원천 테이블에 없는 데이터 담기 (DELETE) 
    SELECT 'D' AS WorkingTag, 
           A.IFShipCode,                -- 모선코드 
           '' AS EnShipName,            -- 모선명(영문) 
           '' AS ShipName,              -- 모선명(한글) 
           '' AS LINECode,              -- LINE코드
           '' AS CodeLetters,           -- 신호부호 
           '' AS NationCode,            -- 국가코드 
           0 AS TotalTON,               -- 총톤수
           0 AS LoadTON,                -- 적재톤수
           0 AS LOA,                    -- 전장 
           0 AS Breadth,                -- 전폭
           0 AS DRAFT,                  -- 하계만재홀수 
           '' AS BULKCNTR,              -- 벌크 컨테이너구분
           '' AS LastWorkTime,          -- 최종등록 및 수정 시간
           A.ShipSeq, 
           0 AS Status 
      FROM mnpt_TPJTShipMaster_IF    AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND NOT EXISTS (SELECT 1 FROM #DVESSELC WHERE VESSEL_CD = A.IFShipCode)
    
    ----------------------------------------------------------------------------------------
    -- 체크, 모선항차 또는 계약에 존재하여 삭제되지 않습니다. (삭제시 체크 후 Temp(처리되는테이블) 삭제)
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET ErrMessage = '모선항차 또는 계약에 존재하여 삭제되지 않습니다.', 
           Status = 1234
      FROM #mnpt_TPJTShipMaster AS A 
     WHERE A.WorkingTag = 'D' 
       AND (EXISTS (SELECT 1 FROM mnpt_TPJTShipDetail WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq) 
            OR EXISTS (SELECT 1 FROM mnpt_TPJTContract WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq)
           )
    UPDATE A
       SET ErrMessage = B.ErrMessage
      FROM mnpt_TPJTShipMaster_IF           AS A 
      LEFT OUTER JOIN #mnpt_TPJTShipMaster  AS B ON ( B.ShipSeq = A.ShipSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag = 'D' 
       AND B.Status <> 0 
    
    DELETE A
      FROM #mnpt_TPJTShipMaster AS A 
     WHERE A.Status <> 0 
       AND A.WorkingTag = 'D'  
    ----------------------------------------------------------------------------------------
    -- 체크, End
    ----------------------------------------------------------------------------------------

    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'A' AND Status = 0 
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTShipMaster', 'ShipSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #mnpt_TPJTShipMaster
           SET ShipSeq = @Seq + IDX_NO  
         WHERE WorkingTag = 'A' 
           AND Status = 0 
    END 
    

    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  1             ,        
                  'mnpt_TPJTShipMaster'    , -- 테이블명        
                  '#mnpt_TPJTShipMaster'    , -- 임시 테이블명        
                  'ShipSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
      

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        -- ERP 모선테이블 
        DELETE B   
          FROM #mnpt_TPJTShipMaster  AS A   
          JOIN mnpt_TPJTShipMaster   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        -- 중간 IF 테이블 
        DELETE B   
          FROM #mnpt_TPJTShipMaster      AS A   
          JOIN mnpt_TPJTShipMaster_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- 중간 IF 테이블 
        UPDATE B
           SET LastWorkTime = A.LastWorkTime, 
               ErrMessage = '',  
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE(), 
               PgmSeq = @PgmSeq
          FROM #mnpt_TPJTShipMaster      AS A   
          JOIN mnpt_TPJTShipMaster_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
        -- ERP 모선테이블 
        UPDATE B   
           SET B.EnShipName     = A.EnShipName   ,
               B.ShipName       = A.ShipName     ,
               B.LINECode       = A.LINECode     ,
               --B.EnLINEName     = A.EnLINEName   ,
               --B.LINEName       = A.LINEName     ,
               B.NationCode     = A.NationCode   ,
               --B.NationName     = A.NationName   , 
               B.CodeLetters    = A.CodeLetters  ,
               B.TotalTON       = A.TotalTON     ,
               B.LoadTON        = A.LoadTON      ,
               B.LOA            = A.LOA          ,
               B.Breadth        = A.Breadth      ,
               B.DRAFT          = A.DRAFT        ,
               B.BULKCNTR       = A.BULKCNTR     , 
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq
          FROM #mnpt_TPJTShipMaster  AS A   
          JOIN mnpt_TPJTShipMaster   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- 중간 IF 테이블 
        INSERT INTO mnpt_TPJTShipMaster_IF
        ( 
            CompanySeq, ShipSeq, IFShipCode, LastWorkTime, ErrMessage, 
            LastUserSeq, LastDateTime, PgmSeq
        ) 
        SELECT @CompanySeq, ShipSeq, IFShipCode, LastWorkTime, '', 
               @UserSeq, GETDATE(), @PgmSEq
          FROM #mnpt_TPJTShipMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0     
        
        IF @@ERROR <> 0 RETURN  

        -- ERP 모선테이블 
        INSERT INTO mnpt_TPJTShipMaster  
        (   
            CompanySeq, ShipSeq, IFShipCode, EnShipName, ShipName, 
            LINECode, EnLINEName, LINEName, NationCode, NationName, 
            CodeLetters, TotalTON, LoadTON, LOA, Breadth, 
            DRAFT, BULKCNTR, IsImagine, Remark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ShipSeq, IFShipCode, EnShipName, ShipName, 
               LINECode, '', '', NationCode, '', 
               CodeLetters, TotalTON, LoadTON, LOA, Breadth, 
               DRAFT, BULKCNTR, '0', '', @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #mnpt_TPJTShipMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #mnpt_TPJTShipMaster 
    
RETURN 
GO

begin tran 

exec mnpt_SPJTShipMasterIF @CompanySeq = 1, @UserSeq = 1, @PgmSeq = 1 

rollback 