
IF OBJECT_ID('KPX_SCMEnvSubQuery') IS NOT NULL 
    DROP PROC KPX_SCMEnvSubQuery
GO 

-- v2014.08.25    
     
 -- 환경설정(KPX)-조회 by서보영 Save as by이재천
  
  CREATE PROC KPX_SCMEnvSubQuery      
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
          EnvSerl         INT,      
          EnvValueName    NVARCHAR(100)      
      )      
        
      DECLARE @EnvValue       NVARCHAR(500),      
              @SqlState       NVARCHAR(MAX),      
              @EnvSeq         INT,     
              @EnvSerl        INT,      
              @CodeHelpSeq    INT,      
              @MinorSeq       INT,
              @docHandle	  INT,      
			  @EnvSeqM        INT
			  
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   			  
	
	-- @EnvSeq 파라미터 추가		-- 13.06.08 BY 김세호 
	SELECT @EnvSeqM  = ISNULL(EnvSeq               , 0)         
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)    
        WITH (EnvSeq        INT)
        
                  
      DECLARE Name_cursor CURSOR FOR       
       SELECT B.EnvSeq, I.EnvSerl, I.EnvValue, B.CodeHelpSeq, B.MinorSeq      
        FROM KPX_TCOMEnv          AS B WITH(NOLOCK) 
        JOIN KPX_TCOMEnvItem      AS I WITH(NOLOCK) ON B.EnvSeq = I.EnvSeq
                                                   AND B.CompanySeq = I.CompanySeq
        JOIN _TCACodeHelpData     AS C WITH(NOLOCK) ON B.CodeHelpSeq = C.CodeHelpSeq      
       WHERE B.CompanySeq = @CompanySeq      
         AND (B.SMControlType  = 84003 OR ( B.SMControlType = 84004 AND B.MinorSeq = 0 ))      
         AND B.CodeHelpSeq   <> 0      
         AND I.EnvValue       > ''      
         AND C.NameColumnName > ''      
         AND C.TableName      > ''      
         AND C.SeqColumnName  > ''   
         AND B.EnvSeq = @EnvSeqM				-- 14.06.08 김세호 추가
       ORDER BY B.EnvSeq      
          
      OPEN Name_cursor      
          
      FETCH NEXT FROM Name_cursor INTO @EnvSeq, @EnvSerl, @EnvValue, @CodeHelpSeq, @MinorSeq      
          
      WHILE @@FETCH_STATUS = 0      
      BEGIN      
          IF @CodeHelpSeq = 19998 -- 시스템제공기타코드      
          BEGIN     
                  
              SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + A.NameColumnName +       
                                 ' FROM ' + A.TableName + ' WITH(NOLOCK)' +      
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
                  
              SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + NameColumnName +       
                ' FROM ' + TableName + ' WITH(NOLOCK)' +      
                                 ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(10), @CompanySeq) +      
         '   AND ' + SeqColumnName + ' = ' + @EnvValue      
                FROM _TCACodeHelpData WITH(NOLOCK)     
               WHERE CodeHelpSeq = @CodeHelpSeq      
                  
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
       FROM KPX_TCOMEnv                  AS B WITH(NOLOCK)   
       JOIN KPX_TCOMEnvItem              AS I WITH(NOLOCK) ON B.EnvSeq     = I.EnvSeq
                                                          AND B.CompanySeq = I.CompanySeq
       LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq
                                                          AND B.CompanySeq  = C.CompanySeq
       LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )     
      WHERE B.CompanySeq = @CompanySeq    
        AND (B.SMControlType IN (84001, 84002, 84005, 84006, 84007, 84008)      -- 문자, 숫자, 날짜, 체크, 다이얼로그, 마스크      
          OR (B.SMControlType = 84004 AND B.MinorSeq <> 0)                      -- 사용자정의 코드헬프(콤보)      
          OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq = 0) -- 값이 없는 코드헬프(콤보)      
            ) 
		AND B.EnvSeq = @EnvSeqM			-- 14.06.08 김세호 추가                   
         
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
       FROM KPX_TCOMEnv                  AS B WITH(NOLOCK)    
       JOIN KPX_TCOMEnvItem              AS I WITH(NOLOCK) ON B.EnvSeq      = I.EnvSeq
                                                          AND B.CompanySeq  = I.CompanySeq
       LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq
                                                          AND B.CompanySeq  = C.CompanySeq
       LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )     
       LEFT OUTER JOIN #GetName          AS E WITH(NOLOCK) ON ( I.EnvSeq = E.EnvSeq AND I.EnvSerl = E.EnvSerl )     
      WHERE B.CompanySeq = @CompanySeq      
        AND (B.SMControlType = 84003                                            -- 코드헬프       
         OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq <> 0) -- 코드헬프(콤보)      
            ) 
		AND B.EnvSeq = @EnvSeqM			-- 14.06.08 김세호 추가                                   
      ORDER BY B.QuerySort      
          

      
 RETURN
 go
exec KPX_SCMEnvSubQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EnvSeq>2</EnvSeq>
    <RealEnvSeq>2</RealEnvSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022586,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019000