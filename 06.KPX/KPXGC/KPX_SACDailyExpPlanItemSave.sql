  
IF OBJECT_ID('KPX_SACDailyExpPlanItemSave') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanItemSave  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-매각 저장 by 이재천   
CREATE PROC KPX_SACDailyExpPlanItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_TACDailyExpPlanItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TACDailyExpPlanItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACDailyExpPlanItem')    
    
    IF @WorkingTag = 'Del' -- 삭제 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanItem'    , -- 테이블명        
                      '#KPX_TACDailyExpPlanItem'    , -- 임시 테이블명        
                      'BaseDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 ) 
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    ELSE 
    BEGIN -- 수정, 시트삭제 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanItem'    , -- 테이블명        
                      '#KPX_TACDailyExpPlanItem'    , -- 임시 테이블명        
                      'BaseDate,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 ) 
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        
        IF @WorkingTag = 'Del' 
        BEGIN -- 삭제 
            DELETE B   
              FROM #KPX_TACDailyExpPlanItem AS A   
              JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
        ELSE 
        BEGIN -- 시트 삭제 
            DELETE B   
              FROM #KPX_TACDailyExpPlanItem AS A   
              JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND B.Serl = A.Serl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UMExpPlanSeq = A.UMExpPlanSeq, 
               B.UMBankSeq = A.UMBankSeq, 
               B.Amt = A.Amt, 
               B.ExRate = A.ExRate, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TACDailyExpPlanItem AS A   
          JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND A.Serl = B.Serl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACDailyExpPlanItem  
        (   
            CompanySeq, BaseDate, Serl, UMExpPlanSeq, UMBankSeq, 
            Amt, ExRate, Remark, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BaseDate, A.Serl, A.UMExpPlanSeq, A.UMBankSeq, 
               A.Amt, A.ExRate, A.Remark, @UserSeq, GETDATE()
          FROM #KPX_TACDailyExpPlanItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    SELECT * FROM #KPX_TACDailyExpPlanItem   
    
    RETURN  