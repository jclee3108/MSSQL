  
IF OBJECT_ID('KPX_SEIS_PL_MOD_PLANSave') IS NOT NULL   
    DROP PROC KPX_SEIS_PL_MOD_PLANSave  
GO  
  
-- v2014.11.24  
  
-- (경영정보)손익 수정 계획-저장 by 이재천   
CREATE PROC KPX_SEIS_PL_MOD_PLANSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TEIS_PL_MOD_PLAN (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PL_MOD_PLAN'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_PL_MOD_PLAN')    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PL_MOD_PLAN WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TEIS_PL_MOD_PLAN'    , -- 테이블명        
              '#KPX_TEIS_PL_MOD_PLAN'    , -- 임시 테이블명        
              'BizUnit,PlanYM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        DELETE B   
          FROM #KPX_TEIS_PL_MOD_PLAN AS A   
          JOIN KPX_TEIS_PL_MOD_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PL_MOD_PLAN WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
    
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TEIS_PL_MOD_PLAN'    , -- 테이블명        
              '#KPX_TEIS_PL_MOD_PLAN'    , -- 임시 테이블명        
              'BizUnit,PlanYM,AccSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B   
           SET B.ModAmt = A.ModAmt,  
               B.EstAmt = A.EstAmt,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TEIS_PL_MOD_PLAN AS A   
          JOIN KPX_TEIS_PL_MOD_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.AccSeq = A.AccSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PL_MOD_PLAN WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEIS_PL_MOD_PLAN  
        (   
            CompanySeq,BizUnit,PlanYM,AccSeq,ModAmt,  
            EstAmt,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.BizUnit,A.PlanYM,A.AccSeq,A.ModAmt,  
               A.EstAmt,@UserSeq,GETDATE()   
          FROM #KPX_TEIS_PL_MOD_PLAN AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     

    
    
    SELECT * FROM #KPX_TEIS_PL_MOD_PLAN   
      
 RETURN  
 
 GO 