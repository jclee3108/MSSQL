  
IF OBJECT_ID('KPX_SEIS_DEBT_STATUSCheck') IS NOT NULL   
    DROP PROC KPX_SEIS_DEBT_STATUSCheck  
GO  
  
-- v2014.11.24  
  
-- (경영정보)매입채무-체크 by 이재천   
CREATE PROC KPX_SEIS_DEBT_STATUSCheck  
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
      
    CREATE TABLE #KPX_TEIS_DEBT_STATUS( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_DEBT_STATUS'   
    IF @@ERROR <> 0 RETURN     
    
    ---- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    ----IF NOT EXISTS ( SELECT 1   
    ----                  FROM #KPX_TEIS_DEBT_STATUS AS A   
    ----                  JOIN KPX_TEIS_DEBT_STATUS AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM )  
    ----                 WHERE A.WorkingTag IN ( 'U', 'D' )  
    ----                   AND Status = 0   
    ----              )  
    ----BEGIN  
    ----    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    ----                          @Status      OUTPUT,  
    ----                          @Results     OUTPUT,  
    ----                          7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
    ----                          @LanguageSeq               
          
    ----    UPDATE #KPX_TEIS_DEBT_STATUS  
    ----       SET Result       = @Results,  
    ----           MessageType  = @MessageType,  
    ----           Status       = @Status  
    ----     WHERE WorkingTag IN ( 'U', 'D' )  
    ----       AND Status = 0   
    ----END   
      
    ---- 중복여부 체크 :   
    ----EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    ----                      @Status      OUTPUT,  
    ----                      @Results     OUTPUT,  
    ----                      6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
    ----                      @LanguageSeq       ,  
    ----                      3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
    ----                      --3543, '값2'  
      
    ----UPDATE #KPX_TEIS_DEBT_STATUS  
    ----   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
    ----       MessageType  = @MessageType,  
    ----       Status       = @Status  
    ----  FROM #KPX_TEIS_DEBT_STATUS AS A   
    ----  JOIN (SELECT S.SampleName  
    ----          FROM (SELECT A1.SampleName  
    ----                  FROM #KPX_TEIS_DEBT_STATUS AS A1  
    ----                 WHERE A1.WorkingTag IN ('A', 'U')  
    ----                   AND A1.Status = 0  
                                              
    ----                UNION ALL  
                                             
    ----                SELECT A1.SampleName  
    ----                  FROM KPX_TEIS_DEBT_STATUS AS A1  
    ----                 WHERE A1.CompanySeq = @CompanySeq   
    ----                   AND NOT EXISTS (SELECT 1 FROM #KPX_TEIS_DEBT_STATUS   
    ----                                           WHERE WorkingTag IN ('U','D')   
    ----                                             AND Status = 0   
    ----                                             AND PlanYM = A1.PlanYM  
    ----                                  )  
    ----               ) AS S  
    ----         GROUP BY S.SampleName  
    ----        HAVING COUNT(1) > 1  
    ----       ) AS B ON ( A.SampleName = B.SampleName )  
    ---- WHERE A.WorkingTag IN ('A', 'U')  
    ----   AND A.Status = 0  
    
    SELECT * FROM #KPX_TEIS_DEBT_STATUS   
      
    RETURN  