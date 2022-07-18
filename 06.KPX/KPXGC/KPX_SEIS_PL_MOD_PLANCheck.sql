  
IF OBJECT_ID('KPX_SEIS_PL_MOD_PLANCheck') IS NOT NULL   
    DROP PROC KPX_SEIS_PL_MOD_PLANCheck  
GO  
  
-- v2014.11.24  
  
-- (경영정보)손익 수정 계획-체크 by 이재천   
CREATE PROC KPX_SEIS_PL_MOD_PLANCheck  
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
      
    CREATE TABLE #KPX_TEIS_PL_MOD_PLAN( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PL_MOD_PLAN'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0 
      
    UPDATE #KPX_TEIS_PL_MOD_PLAN  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TEIS_PL_MOD_PLAN AS A   
      JOIN (SELECT S.BizUnit, S.PlanYM
              FROM (SELECT A1.BizUnit, A1.PlanYM  
                      FROM #KPX_TEIS_PL_MOD_PLAN AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.BizUnit, A1.PlanYM  
                      FROM KPX_TEIS_PL_MOD_PLAN AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TEIS_PL_MOD_PLAN   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND BizUnit = A1.BizUnit 
                                                 AND PlanYM = A1.PlanYM 
                                      )  
                   ) AS S  
             GROUP BY S.BizUnit, S.PlanYM  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.BizUnit = B.BizUnit AND A.PlanYM = B.PlanYM )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TEIS_PL_MOD_PLAN   
      
    RETURN  