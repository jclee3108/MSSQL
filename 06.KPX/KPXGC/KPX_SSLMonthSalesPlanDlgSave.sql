  
IF OBJECT_ID('KPX_SSLMonthSalesPlanDlgSave') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanDlgSave  
GO  
  
-- v2014.11.14  
  
-- 월간판매계획입력Dlg-저장 by 이재천   
CREATE PROC KPX_SSLMonthSalesPlanDlgSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSLMonthSalesPlanRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLMonthSalesPlanRev'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlanRev')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSLMonthSalesPlanRev'    , -- 테이블명        
                  '#KPX_TSLMonthSalesPlanRev'    , -- 임시 테이블명        
                  'BizUnit,PlanYM,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLMonthSalesPlanRev WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TSLMonthSalesPlanRev  
        (   
            CompanySeq,BizUnit,PlanYM,PlanRev,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.BizUnit,A.PlanYM,A.PlanRev,@UserSeq,  
               GETDATE()   
          FROM #KPX_TSLMonthSalesPlanRev AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    IF EXISTS (SELECT 1 
                 FROM #KPX_TSLMonthSalesPlanRev AS A 
                 JOIN KPX_TSLMonthSalesPlanRev  AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
              ) 
    BEGIN 
        UPDATE A
           SET IsApply = '1' 
          FROM #KPX_TSLMonthSalesPlanRev AS A 
    END 
    
    SELECT * FROM #KPX_TSLMonthSalesPlanRev   
      
    RETURN  