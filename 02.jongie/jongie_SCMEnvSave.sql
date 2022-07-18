
IF OBJECT_ID('jongie_SCMEnvSave') IS NOT NULL
    DROP PROC jongie_SCMEnvSave
GO
    
-- v2013.08.07   
  
-- (종이나라) 추가개발 Mapping정보 설정_jongie-저장 by 김철웅 (copy 이재천)      
CREATE PROC jongie_SCMEnvSave        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
    CREATE TABLE #TCOMEnv (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TCOMEnv'        
    IF @@ERROR <> 0 RETURN        
          
    -- 로그 남기기          
    DECLARE @TableColumns NVARCHAR(4000)          
          
    -- Master 로그         
    SELECT @TableColumns = dbo._FGetColumnsForLog('jongie_TCOMEnv')          
          
    EXEC _SCOMLog @CompanySeq   ,              
                  @UserSeq      ,              
                  'jongie_TCOMEnv'    , -- 테이블명      -- JYO_TSLYearSalesPlanItemLog        
                  '#TCOMEnv'    , -- 임시 테이블명              
                  'EnvSeq, EnvSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )              
                  @TableColumns, '', @PgmSeq  -- 테이블 모든 필드명         
          
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT        
          
    -- DELETE        
    --IF EXISTS (SELECT TOP 1 1 FROM #TCOMEnv WHERE WorkingTag = 'D' AND Status = 0)        
    --BEGIN        
    --    DELETE _TCOMEnv        
    --      FROM #TCOMEnv AS A        
    --        JOIN _TCOMEnv AS B ON (A.EnvSeq = B.EnvSeq)        
    --     WHERE  A.WorkingTag = 'D'        
    --        AND A.Status = 0        
    --        AND B.CompanySeq = @CompanySeq        
    --    IF @@ERROR <> 0  RETURN        
    --END        
          
    -- UPDATE        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'U' AND Status = 0)        
    BEGIN        
              
        UPDATE B        
           SET EnvValue        = A.EnvValue,        
               LastUserSeq     = @UserSeq,        
               LastDateTime    = GETDATE()        
          FROM #TCOMEnv     AS A        
          JOIN jongie_TCOMEnv  AS B ON ( A.EnvSeq = B.EnvSeq AND A.EnvSerl = B.EnvSerl )        
         WHERE  A.WorkingTag = 'U'        
           AND A.Status = 0        
           AND B.CompanySeq = @CompanySeq        
              
        IF @@ERROR <> 0  RETURN        
          
    END -- end if       
        
    -- INSERT        
    --IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'A' AND Status = 0)        
    --BEGIN        
    --    INSERT INTO _TCOMEnv       
    --    (      
    --        CompanySeq, EnvSeq, EnvName, Description, EnvValue,       
    --        ModuleSeq, SMControlType, CodeHelpSeq, MinorSeq, SMUseType,       
    --        QuerySort, DecLength, AddCheckScript, AddSaveScript, LastUserSeq,       
    --        LastDateTime      
    --    )        
    --    SELECT @CompanySeq, EnvSeq, EnvName, Description, EnvValue, ModuleSeq, SMControlType, CodeHelpSeq, MinorSeq, SMUseType, QuerySort, DecLength, AddCheckScript, AddSaveScript, @UserSeq, GETDATE()        
    --          FROM #TCOMEnv AS A        
    --         WHERE  A.WorkingTag = 'A'        
    --            AND A.Status = 0        
    --    IF @@ERROR <> 0 RETURN        
    --END        
          
    -- AddSave 추가저장SP가 있을경우        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND Status = 0 AND ISNULL(AddSaveScript, '') <> '')        
    BEGIN        
        DECLARE @EnvSeq         INT,        
                @AddSaveScript  NVARCHAR(100),        
                @EnvValue       NVARCHAR(50)              
        
        DECLARE Check_cursor CURSOR FOR        
              SELECT EnvSeq, AddSaveScript,EnvValue        
              FROM #TCOMEnv        
             WHERE  WorkingTag IN ('A','U')        
                AND Status = 0        
                AND ISNULL(AddSaveScript, '') <> ''        
               ORDER BY EnvSeq         
        OPEN Check_cursor        
        FETCH NEXT FROM Check_cursor INTO @EnvSeq, @AddSaveScript,@EnvValue        
        WHILE @@FETCH_STATUS = 0        
        BEGIN        
        
            EXEC @AddSaveScript @EnvSeq, @CompanySeq, @LanguageSeq, @UserSeq, @PgmSeq,@EnvValue        
        
            FETCH NEXT FROM Check_cursor        
            INTO @EnvSeq, @AddSaveScript,@EnvValue        
        END        
    END        
          
    SELECT * FROM #TCOMEnv        
          
    RETURN        