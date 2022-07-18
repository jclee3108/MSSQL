
IF OBJECT_ID('KPX_SCMEnvSave') IS NOT NULL 
    DROP PROC KPX_SCMEnvSave
GO 

-- v2014.08.25    
     
 -- 환경설정(KPX)-저장 by 서보영 Save as by이재천
 CREATE PROC KPX_SCMEnvSave      
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
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TCOMEnv'      
     IF @@ERROR <> 0 RETURN      
         
     -- 로그 남기기        
     DECLARE @TableColumns NVARCHAR(4000)        
         
     -- Master 로그       
     SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TCOMEnvItem')        
         
     EXEC _SCOMLog @CompanySeq   ,            
                   @UserSeq      ,            
                   'KPX_TCOMEnvItem'    , -- 테이블명      -- JYO_TSLYearSalesPlanItemLog      
                   '#TCOMEnv'    , -- 임시 테이블명            
                   'EnvSeq, EnvSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )            
                   @TableColumns, '', @PgmSeq  -- 테이블 모든 필드명       
         

           
     -- DELETE        
     IF EXISTS (SELECT TOP 1 1 FROM #TCOMEnv WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN        
         DELETE KPX_TCOMEnvItem        
           FROM #TCOMEnv AS A        
           JOIN KPX_TCOMEnvItem AS B ON A.EnvSeq     = B.EnvSeq
                                    AND A.EnvSerl    = B.EnvSerl
           JOIN KPX_TCOMEnv     AS C ON B.EnvSeq     = C.EnvSeq
                                    AND B.CompanySeq = C.CompanySeq
          WHERE A.WorkingTag = 'D'        
            AND A.Status = 0        
            AND B.CompanySeq = @CompanySeq    
                
         IF @@ERROR <> 0  RETURN        
     END        
           
     -- UPDATE        
     IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'U' AND Status = 0)        
     BEGIN        
               
         UPDATE B        
            SET EnvValue        = A.EnvValue,        
                LastUserSeq     = @UserSeq,        
                LastDateTime    = GETDATE()        
           FROM #TCOMEnv         AS A  
           JOIN KPX_TCOMEnvItem  AS B ON A.EnvSeq     = B.EnvSeq 
                                     AND A.EnvSerl    = B.EnvSerl
           JOIN KPX_TCOMEnv      AS C ON B.EnvSeq     = C.EnvSeq
                                     AND B.CompanySeq = C.CompanySeq
          WHERE A.WorkingTag = 'U'        
            AND A.Status = 0        
            AND B.CompanySeq = @CompanySeq        
               
         IF @@ERROR <> 0  RETURN        
           
     END -- end if       
         
         
     -- INSERT        
     IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'A' AND Status = 0)        
     BEGIN        
         INSERT INTO KPX_TCOMEnvItem       
         (      
             CompanySeq, EnvSeq, EnvSerl, EnvValue, LastUserSeq, LastDateTime      
         )        
         SELECT @CompanySeq, EnvSeq, EnvSerl, EnvValue, @UserSeq, GETDATE()        
           FROM #TCOMEnv AS A        
          WHERE A.WorkingTag = 'A'        
            AND A.Status = 0        
            
         IF @@ERROR <> 0 RETURN        
     END        
     
     
     ---- AddSave 추가저장SP가 있을경우      
     --IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND Status = 0 AND ISNULL(AddSaveScript, '') <> '')      
     --BEGIN      
     --    DECLARE @EnvSeq         INT,      
     --            @AddSaveScript  NVARCHAR(100),      
     --            @EnvValue       NVARCHAR(50)            
       
     --    DECLARE Check_cursor CURSOR FOR      
     --          SELECT EnvSeq, AddSaveScript,EnvValue      
     --          FROM #TCOMEnv      
     --         WHERE  WorkingTag IN ('A','U')      
     --            AND Status = 0      
     --            AND ISNULL(AddSaveScript, '') <> ''      
     --         ORDER BY EnvSeq      
     --    OPEN Check_cursor      
     --    FETCH NEXT FROM Check_cursor INTO @EnvSeq, @AddSaveScript,@EnvValue      
     --    WHILE @@FETCH_STATUS = 0      
     --    BEGIN      
       
     --          EXEC @AddSaveScript @EnvSeq, @CompanySeq, @LanguageSeq, @UserSeq, @PgmSeq,@EnvValue      
       
     --        FETCH NEXT FROM Check_cursor      
     --        INTO @EnvSeq, @AddSaveScript,@EnvValue      
     --    END      
     --END      
         
     SELECT * FROM #TCOMEnv      
         
     RETURN
     go
     
     
     
     --BEGIN TRAN
--     exec KPX_SCMEnvSave @xmlDocument=N'<ROOT>
--  <DataBlock3>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvValue>42336</EnvValue>
--    <EnvValueName>"ttttt''8888"""</EnvValueName>
--    <EnvSerl>1</EnvSerl>
--  </DataBlock3>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1019442,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50333,@PgmSeq=1016424
--EXEC KPX_SCMEnvSave @xmlDocument = N'<ROOT>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>1</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>2</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>3</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>4</IDX_NO>
--    <DataSeq>4</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>4</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>5</IDX_NO>
--    <DataSeq>5</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>5</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>6</IDX_NO>
--    <DataSeq>6</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>6</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>7</IDX_NO>
--    <DataSeq>7</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>7</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>8</IDX_NO>
--    <DataSeq>8</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>8</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>9</IDX_NO>
--    <DataSeq>9</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>9</EnvSerl>
--  </DataBlock3>
--  <DataBlock3>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>10</IDX_NO>
--    <DataSeq>10</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EnvSeq>1</EnvSeq>
--    <EnvSerl>10</EnvSerl>
--  </DataBlock3>
--</ROOT>', @xmlFlags = 2, @ServiceSeq = 1024248, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1000219, @PgmSeq = 1020394

----SELECT * FROM KPX_TCOMEnvItem
--ROLLBACK TRAN
