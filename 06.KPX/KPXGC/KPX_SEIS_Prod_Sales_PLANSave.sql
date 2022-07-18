  
IF OBJECT_ID('KPX_SEIS_Prod_Sales_PLANSave') IS NOT NULL   
    DROP PROC KPX_SEIS_Prod_Sales_PLANSave  
GO  
  
-- v2014.11.24  
  
-- (경영정보)생산 판매계획-저장 by 이재천   
CREATE PROC KPX_SEIS_Prod_Sales_PLANSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TEIS_PROD_SALES_PLAN( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PROD_SALES_PLAN'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #KPX_TEIS_BC_UR_PLAN( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TEIS_BC_UR_PLAN'   
    IF @@ERROR <> 0 RETURN 
    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PROD_SALES_PLAN WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
    
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_PROD_SALES_PLAN')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_PROD_SALES_PLAN'    , -- 테이블명        
                      '#KPX_TEIS_PROD_SALES_PLAN'    , -- 임시 테이블명        
                      'PlanYM,BizUnit'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        DELETE B   
          FROM #KPX_TEIS_PROD_SALES_PLAN AS A   
          JOIN KPX_TEIS_PROD_SALES_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND A.BizUnit = B.BizUnit AND B.PlanYM = A.PlanYM )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PROD_SALES_PLAN WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
    
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_BC_UR_PLAN')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_BC_UR_PLAN'    , -- 테이블명        
                      '#KPX_TEIS_BC_UR_PLAN'    , -- 임시 테이블명        
                      'PlanYM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        DELETE B   
          FROM #KPX_TEIS_BC_UR_PLAN AS A   
          JOIN KPX_TEIS_BC_UR_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PROD_SALES_PLAN WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_PROD_SALES_PLAN')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_PROD_SALES_PLAN'    , -- 테이블명        
                      '#KPX_TEIS_PROD_SALES_PLAN'    , -- 임시 테이블명        
                      'PlanYM,BizUnit,UMItemClassL'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B   
           SET B.ProdQty   = A.ProdQty,  
               B.SalesQty = A.SalesQty, 
               B.SalesAmt = A.SalesAmt, 
               B.SpendQty = A.SpendQty, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
          FROM #KPX_TEIS_PROD_SALES_PLAN AS A   
          JOIN KPX_TEIS_PROD_SALES_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND A.BizUnit = B.BizUnit AND A.PlanYM = B.PlanYM AND B.UMItemClassL = A.UMItemClassL )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_BC_UR_PLAN WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_BC_UR_PLAN')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_BC_UR_PLAN'    , -- 테이블명        
                      '#KPX_TEIS_BC_UR_PLAN'    , -- 임시 테이블명        
                      'PlanYM,BizUnit,UMURType'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B   
           SET B.PlanAmt   = A.PlanAmt,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
          FROM #KPX_TEIS_BC_UR_PLAN AS A   
          JOIN KPX_TEIS_BC_UR_PLAN AS B ON ( B.CompanySeq = @CompanySeq AND A.BizUnit = B.BizUnit AND A.PlanYM = B.PlanYM AND B.UMURType = A.UMURType )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
    IF @@ERROR <> 0  RETURN  
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_PROD_SALES_PLAN WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TEIS_PROD_SALES_PLAN  
        (   
            CompanySeq,BizUnit,PlanYM,UMItemClassL,ProdQty,
            SalesQty,SalesAmt,SpendQty,LastUserSeq,LastDateTime 
        )   
        SELECT @CompanySeq, A.BizUnit, A.PlanYM, A.UMItemClassL, A.ProdQty, 
               A.SalesQty, A.SalesAmt, A.SpendQty, @UserSeq, GETDATE()   
          FROM #KPX_TEIS_PROD_SALES_PLAN AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_BC_UR_PLAN WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TEIS_BC_UR_PLAN  
        (   
            CompanySeq,BizUnit,PlanYM,UMURType,PlanAmt,
            LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.BizUnit, A.PlanYM, A.UMURType, A.PlanAmt, 
               @UserSeq, GETDATE()   
          FROM #KPX_TEIS_BC_UR_PLAN AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TEIS_PROD_SALES_PLAN   
    
    SELECT * FROM #KPX_TEIS_BC_UR_PLAN 
    
    RETURN  