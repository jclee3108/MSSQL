IF OBJECT_ID('HYE_SCMEnvQuery') IS NOT NULL 
    DROP PROC HYE_SCMEnvQuery
GO 

-- v2016.07.20 
       
 -- 환경설정(한유에너지)-조회 by 이재천 
 CREATE PROC HYE_SCMEnvQuery
     @xmlDocument    NVARCHAR(MAX) ,        
     @xmlFlags       INT     = 0,        
     @ServiceSeq     INT     = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT     = 1,        
     @LanguageSeq    INT     = 1,        
     @UserSeq        INT     = 0,        
     @PgmSeq         INT     = 0        
 AS        
    
    -- 코드헬프Name 가져오는 임시Table        
    CREATE TABLE #GetName        
    (        
        EnvSeq          INT,        
        EnvValueName    NVARCHAR(100)        
    )        
         
     DECLARE @EnvValue       NVARCHAR(500),        
             @SqlState       NVARCHAR(MAX),        
             @EnvSeq         INT,       
             @CodeHelpSeq    INT,        
             @MinorSeq       INT        
           
    SELECT B.EnvSeq        ,-- B.EnvSerl,       
           B.EnvName       , B.Description   ,-- B.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
             B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,      
           D.CodeHelpTitle  AS CodeHelpName  ,      
        --   B.EnvValue       AS EnvValueName  ,      
           B.AddCheckScript,      
           B.AddSaveScript         
      FROM HYE_TCOMEnv                 AS B WITH(NOLOCK)      
      LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON ( B.LastUserSeq = C.UserSeq )      
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
     WHERE B.CompanySeq = @CompanySeq      
       AND (B.SMControlType IN (84001, 84002, 84005, 84006, 84007, 84008)      -- 문자, 숫자, 날짜, 체크, 다이얼로그, 마스크        
        OR (B.SMControlType = 84004 AND B.MinorSeq <> 0)                      -- 사용자정의 코드헬프(콤보)        
        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq = 0) -- 값이 없는 코드헬프(콤보)        
           )        
          
    UNION ALL        
          
    SELECT DISTINCT        
           B.EnvSeq        ,-- B.EnvSerl,       
           B.EnvName       , B.Description   , --B.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
           B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,      
           D.CodeHelpTitle  AS CodeHelpName  ,      
       --    ISNULL(E.EnvValueName, '') AS EnvValueName,      
           B.AddCheckScript,      
           B.AddSaveScript       
      FROM HYE_TCOMEnv                 AS B WITH(NOLOCK)      
      LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON ( B.LastUserSeq = C.UserSeq )       
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
      --LEFT OUTER JOIN #GetName          AS E WITH(NOLOCK) ON ( B.EnvSeq = E.EnvSeq AND B.EnvSerl = E.EnvSerl )       
     WHERE B.CompanySeq = @CompanySeq        
       AND (B.SMControlType = 84003                                            -- 코드헬프         
        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq <> 0) -- 코드헬프(콤보)        
           )       
     ORDER BY B.EnvSeq, B.QuerySort        
           
    SELECT *  
      FROM HYE_TCOMEnvMapping AS A  
     WHERE A.CompanySeq = @CompanySeq  
     ORDER BY TableName, TableTask, Field  
       
RETURN 
GO



