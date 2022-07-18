  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHECheck') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHECheck  
GO  
  
-- v2014.12.12  
  
-- 변경위험성평가등록-체크 by 이재천   
CREATE PROC KPX_SEQChangeRiskRstCHECheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPX_TEQChangeRiskRstCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQChangeRiskRstCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    --IF NOT EXISTS ( SELECT 1   
    --                  FROM #KPX_TEQChangeRiskRstCHE AS A   
    --                  JOIN KPX_TEQChangeRiskRstCHE AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.RiskRstSeq = B.RiskRstSeq )  
    --                 WHERE A.WorkingTag IN ( 'U', 'D' )  
    --                   AND Status = 0   
    --              )  
    --BEGIN  
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
    --                          @LanguageSeq               
          
    --    UPDATE #KPX_TEQChangeRiskRstCHE  
    --       SET Result       = @Results,  
    --           MessageType  = @MessageType,  
    --           Status       = @Status  
    --     WHERE WorkingTag IN ( 'U', 'D' )  
    --       AND Status = 0   
    --END   
      
    -- 중복여부 체크 :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
    --                      @LanguageSeq       ,  
    --                      3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
    --                      --3543, '값2'  
      
    --UPDATE #KPX_TEQChangeRiskRstCHE  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPX_TEQChangeRiskRstCHE AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPX_TEQChangeRiskRstCHE AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPX_TEQChangeRiskRstCHE AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPX_TEQChangeRiskRstCHE   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND RiskRstSeq = A1.RiskRstSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
      
    -- 사용여부체크 : K-Studio -> 설정관리 -> 삭제코드 -> 코드삭제시 사용여부체크 화면에서 등록을 해야 체크됨    
    --IF EXISTS ( SELECT 1 FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'D' )    
    --BEGIN    
      --    EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TEQChangeRiskRstCHE', '#KPX_TEQChangeRiskRstCHE', 'RiskRstSeq'    
    --END    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TEQChangeRiskRstCHE', 'RiskRstSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TEQChangeRiskRstCHE  
           SET RiskRstSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TEQChangeRiskRstCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TEQChangeRiskRstCHE  
     WHERE Status = 0  
       AND ( RiskRstSeq = 0 OR RiskRstSeq IS NULL )  
      
    SELECT * FROM #KPX_TEQChangeRiskRstCHE   
      
    RETURN  