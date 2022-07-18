  
IF OBJECT_ID('KPX_SACDailyExpPlanItemSubCheck') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanItemSubCheck  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-차익 체크 by 이재천   
CREATE PROC KPX_SACDailyExpPlanItemSubCheck  
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
      
    CREATE TABLE #KPX_TACDailyExpPlanExRate( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TACDailyExpPlanExRate'   
    IF @@ERROR <> 0 RETURN     
    
    /*
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #TSample  
       SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #TSample AS A   
      JOIN (SELECT S.SampleName  
              FROM (SELECT A1.SampleName  
                      FROM #TSample AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.SampleName  
                      FROM _TSample AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #TSample   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND SampleSeq = A1.SampleSeq  
                                      )  
                   ) AS S  
             GROUP BY S.SampleName  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.SampleName = B.SampleName )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    */
    
    DECLARE @MaxSerl INT 
    
    SELECT @MaxSerl = (SELECT MAX(Serl) FROM KPX_TACDailyExpPlanExRate WHERE CompanySeq = @CompanySeq AND BaseDate = (SELECT TOP 1 BaseDate FROM #KPX_TACDailyExpPlanExRate WHERE WorkingTag = 'A'))
    
    UPDATE A 
       SET Serl = ISNULL(@MaxSerl,0) + A.DataSeq 
      FROM #KPX_TACDailyExpPlanExRate AS A 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0 
    
    SELECT * FROM #KPX_TACDailyExpPlanExRate   
    
    RETURN  