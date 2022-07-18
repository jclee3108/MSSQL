  
IF OBJECT_ID('KPX_SQCCycleInspectionSave') IS NOT NULL   
    DROP PROC KPX_SQCCycleInspectionSave  
GO  
  
-- v2014.12.04  
  
-- 공정검사주기등록-저장 by 이재천   
CREATE PROC KPX_SQCCycleInspectionSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCPlantCycle (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCPlantCycle'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCPlantCycle')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQCPlantCycle'    , -- 테이블명        
                  '#KPX_TQCPlantCycle'    , -- 임시 테이블명        
                  'PlantSeq,CycleSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantCycle WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TQCPlantCycle AS A   
          JOIN KPX_TQCPlantCycle AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq AND B.CycleSerl = A.CycleSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantCycle WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.CycleTime = A.CycleTime,  
               B.Remark = A.Remark,  
               B.IsUse = A.IsUse,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TQCPlantCycle AS A   
          JOIN KPX_TQCPlantCycle AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq AND B.CycleSerl = A.CycleSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantCycle WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TQCPlantCycle  
        (   
            CompanySeq,PlantSeq,CycleSerl,CycleTime,Remark,  
            IsUse,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.PlantSeq,A.CycleSerl,A.CycleTime,A.Remark,  
               A.IsUse,@UserSeq,GETDATE()   
          FROM #KPX_TQCPlantCycle AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TQCPlantCycle   
      
    RETURN  