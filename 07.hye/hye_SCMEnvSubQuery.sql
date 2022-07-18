IF OBJECT_ID('HYE_SCMEnvSubQuery') IS NOT NULL 
    DROP PROC HYE_SCMEnvSubQuery
GO 

-- v2016.07.20 
       
 -- 환경설정(한유에너지)-Sub조회 by 이재천 
CREATE PROC HYE_SCMEnvSubQuery
    @xmlDocument    NVARCHAR(MAX) ,        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
   
    DECLARE @docHandle   INT,  
    @RealEnvSeq  INT  

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  

    SELECT @RealEnvSeq = ISNULL(RealEnvSeq,  0)   

    FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)  

    WITH (RealEnvSeq      INT )  

    -- 코드헬프Name 가져오는 임시Table        
    CREATE TABLE #GetName        
    (        
        EnvSeq          INT,        
        EnvSerl         INT,        
        EnvValueName    NVARCHAR(100)        
    )        

    DECLARE @EnvValue       NVARCHAR(500),        
            @SqlState       NVARCHAR(MAX),        
            @EnvSeq         INT,       
            @EnvSerl        INT,        
            @CodeHelpSeq    INT,        
            @MinorSeq       INT        

    DECLARE Name_cursor CURSOR FOR         
    SELECT B.EnvSeq, I.EnvSerl, I.EnvValue, B.CodeHelpSeq, B.MinorSeq        
      FROM HYE_TCOMEnv          AS B WITH(NOLOCK)   
      JOIN HYE_TCOMEnvItem      AS I WITH(NOLOCK) ON B.EnvSeq = I.EnvSeq  
                                                  AND B.CompanySeq = I.CompanySeq  
      JOIN _TCACodeHelpData      AS C WITH(NOLOCK) ON B.CodeHelpSeq = C.CodeHelpSeq        
    WHERE B.CompanySeq = @CompanySeq        
      AND (B.SMControlType  = 84003 OR ( B.SMControlType = 84004 AND B.MinorSeq = 0 ))        
      AND B.CodeHelpSeq   <> 0        
      AND I.EnvValue       > ''        
      AND C.NameColumnName > ''        
      AND C.TableName      > ''        
      AND C.SeqColumnName  > ''          
    ORDER BY B.EnvSeq        

    OPEN Name_cursor        

    FETCH NEXT FROM Name_cursor INTO @EnvSeq, @EnvSerl, @EnvValue, @CodeHelpSeq, @MinorSeq        

    WHILE @@FETCH_STATUS = 0        
    BEGIN        
    IF @CodeHelpSeq = 19998 -- 시스템제공기타코드        
    BEGIN       
       
    SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + A.NameColumnName +         
                       '  FROM ' + A.TableName + ' WITH(NOLOCK)' +        
                       ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(10), @CompanySeq) +        
                       '   AND MajorSeq = ' + CONVERT(NVARCHAR(10), @MinorSeq) +        
                       '   AND ' + (CASE B.SysType WHEN '1' THEN 'MinorSeq'        
                                                WHEN '2' THEN 'MinorValue' END) + ' = ' + '''' + @EnvValue + ''''        
      FROM _TCACodeHelpData AS A WITH(NOLOCK)        
      JOIN _TDASMajor       AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.MajorSeq = @MinorSeq        
     WHERE A.CodeHelpSeq = @CodeHelpSeq        
       
    END      
    ELSE      
    BEGIN         
        IF @CodeHelpSeq = 10001 --법인 코드도움 (2015.05.22 장지연)
        BEGIN 
            SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + NameColumnName +         
                               '  FROM ' + TableName + ' WITH(NOLOCK)' +        
                               ' WHERE ' + SeqColumnName + ' = ' + @EnvValue        
              FROM _TCACodeHelpData WITH(NOLOCK)       
             WHERE CodeHelpSeq = @CodeHelpSeq    
        END
        ELSE
        BEGIN 
            SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + NameColumnName +         
                               '  FROM ' + TableName + ' WITH(NOLOCK)' +        
                          ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(10), @CompanySeq) +        
                               '   AND ' + SeqColumnName + ' = ' + @EnvValue        
              FROM _TCACodeHelpData WITH(NOLOCK)       
             WHERE CodeHelpSeq = @CodeHelpSeq        
        END
    END -- end if       

    INSERT #GetName EXEC ( @SqlState )        

    FETCH NEXT FROM Name_cursor INTO @EnvSeq, @EnvSerl, @EnvValue, @CodeHelpSeq, @MinorSeq        

    END -- end while       

    CLOSE Name_cursor        

    DEALLOCATE Name_cursor        

    SELECT B.EnvSeq        , I.EnvSerl,       
           B.EnvName       , B.Description   , I.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
           B.QuerySort  , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,       
           D.CodeHelpTitle  AS CodeHelpName  ,      
           I.EnvValue       AS EnvValueName  ,      
           B.AddCheckScript,      
           B.AddSaveScript         
      FROM HYE_TCOMEnv                  AS B WITH(NOLOCK)     
      JOIN HYE_TCOMEnvItem              AS I WITH(NOLOCK) ON B.EnvSeq     = I.EnvSeq  
                                                          AND B.CompanySeq = I.CompanySeq  
      LEFT OUTER JOIN _TCAUser           AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq  
                                                          AND B.CompanySeq  = C.CompanySeq  
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
     WHERE B.CompanySeq = @CompanySeq      
       AND B.EnvSeq     = @RealEnvSeq  
       AND (B.SMControlType IN (84001, 84002, 84005, 84006, 84007, 84008)      -- 문자, 숫자, 날짜, 체크, 다이얼로그, 마스크        
        OR (B.SMControlType = 84004 AND B.MinorSeq <> 0)                      -- 사용자정의 코드헬프(콤보)        
        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq = 0) -- 값이 없는 코드헬프(콤보)        
           )        

     UNION ALL        

    SELECT DISTINCT        
           B.EnvSeq        , I.EnvSerl,       
           B.EnvName       , B.Description   , I.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
           B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,      
           D.CodeHelpTitle  AS CodeHelpName  ,      
           ISNULL(E.EnvValueName, '') AS EnvValueName,      
           B.AddCheckScript,      
           B.AddSaveScript       
      FROM HYE_TCOMEnv                  AS B WITH(NOLOCK)      
      JOIN HYE_TCOMEnvItem              AS I WITH(NOLOCK) ON B.EnvSeq      = I.EnvSeq  
                                                          AND B.CompanySeq  = I.CompanySeq  
      LEFT OUTER JOIN _TCAUser           AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq  
                                                          AND B.CompanySeq  = C.CompanySeq  
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
      LEFT OUTER JOIN #GetName          AS E WITH(NOLOCK) ON ( I.EnvSeq = E.EnvSeq AND I.EnvSerl = E.EnvSerl )       
     WHERE B.CompanySeq = @CompanySeq        
       AND b.EnvSeq     = @RealEnvSeq  
       AND (B.SMControlType = 84003                                            -- 코드헬프         
        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq <> 0) -- 코드헬프(콤보)        
           )       
     ORDER BY B.QuerySort        

RETURN  




GO


