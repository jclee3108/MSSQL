  
IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanScenarioSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanScenarioSave  
GO  
  
-- v2016.05.26 
  
-- 원부원료 사용계획서(생산계획시나리오)-저장 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanScenarioSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCMonthMatUsePlanScenario (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthMatUsePlanScenario'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCMonthMatUsePlanScenario')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCMonthMatUsePlanScenario'    , -- 테이블명        
                  '#KPXCM_TPDSFCMonthMatUsePlanScenario'    , -- 임시 테이블명        
                  'FactUnit,PlanYM,PlanRev,ItemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthMatUsePlanScenario WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.RepalceQtyM = A.RepalceQtyM, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TPDSFCMonthMatUsePlanScenario AS A   
          JOIN KPXCM_TPDSFCMonthMatUsePlanScenario  AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND B.FactUnit = A.FactUnit 
                                                          AND B.PlanYM = A.PlanYM 
                                                          AND B.ItemSeq = A.ItemSeq 
                                                          AND B.PlanRev = A.PlanRev
                                                            )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    SELECT * FROM #KPXCM_TPDSFCMonthMatUsePlanScenario   
      
    RETURN  