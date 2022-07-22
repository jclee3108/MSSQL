  
IF OBJECT_ID('hencom_SPNPLCostReductionSave') IS NOT NULL   
    DROP PROC hencom_SPNPLCostReductionSave  
GO  
  
-- v2017.04.27 
  
-- 원가절감목표금액등록_hencom-저장 by 이재천
CREATE PROC hencom_SPNPLCostReductionSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TPNPLCostReduction (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLCostReduction'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기 
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TPNPLCostReduction')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TPNPLCostReduction'    , -- 테이블명        
                  '#hencom_TPNPLCostReduction'    , -- 임시 테이블명        
                  'DeptSeq,PlanSeq,PlanSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLCostReduction WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #hencom_TPNPLCostReduction   AS A   
          JOIN hencom_TPNPLCostReduction    AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND B.DeptSeq = A.DeptSeq 
                                                  AND B.PlanSeq = A.PlanSeq 
                                                  AND B.PlanSerl = A.PlanSerl 
                                                    )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLCostReduction WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.Month01    = A.Month01,  
               B.Month02    = A.Month02,  
               B.Month03    = A.Month03,  
               B.Month04    = A.Month04,  
               B.Month05    = A.Month05,  
               B.Month06    = A.Month06,  
               B.Month07    = A.Month07,  
               B.Month08    = A.Month08,  
               B.Month09    = A.Month09,  
               B.Month10    = A.Month10,  
               B.Month11    = A.Month11,  
               B.Month12    = A.Month12,  
               B.Remark     = A.Remark ,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #hencom_TPNPLCostReduction   AS A   
          JOIN hencom_TPNPLCostReduction    AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND B.DeptSeq = A.DeptSeq 
                                                  AND B.PlanSeq = A.PlanSeq 
                                                  AND B.PlanSerl = A.PlanSerl 
                                                    )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLCostReduction WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TPNPLCostReduction  
        (   
            CompanySeq, DeptSeq, PlanSeq, PlanSerl, Month01, 
            Month02, Month03, Month04, Month05, Month06, 
            Month07, Month08, Month09, Month10, Month11, 
            Month12, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.DeptSeq, A.PlanSeq, A.PlanSerl, A.Month01, 
               A.Month02, A.Month03, A.Month04, A.Month05, A.Month06, 
               A.Month07, A.Month08, A.Month09, A.Month10, A.Month11, 
               A.Month12, A.Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #hencom_TPNPLCostReduction AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #hencom_TPNPLCostReduction   
    
    RETURN  
