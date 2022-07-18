  
IF OBJECT_ID('KPX_SACDailyExpPlanSave') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanSave  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-저장 by 이재천   
CREATE PROC KPX_SACDailyExpPlanSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_TACDailyExpPlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACDailyExpPlan'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACDailyExpPlan')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACDailyExpPlan'    , -- 테이블명        
                  '#KPX_TACDailyExpPlan'    , -- 임시 테이블명        
                  'BaseDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlan WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TACDailyExpPlan AS A   
          JOIN KPX_TACDailyExpPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlan WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.DeptSeq = A.DeptSeq, 
               B.BegExRate = A.BegExRate, 
               B.ExRateSpread = A.ExRateSpread, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TACDailyExpPlan AS A   
          JOIN KPX_TACDailyExpPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlan WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACDailyExpPlan  
        (   
            CompanySeq, BaseDate, DeptSeq, BegExRate, ExRateSpread, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BaseDate, A.DeptSeq, A.BegExRate, A.ExRateSpread, 
               @UserSeq, GETDATE() 
          FROM #KPX_TACDailyExpPlan AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
      
    SELECT * FROM #KPX_TACDailyExpPlan   
    
    RETURN  
GO 
begin tran 
exec KPX_SACDailyExpPlanSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BaseDate>20141209</BaseDate>
    <BegExRate>123.00000</BegExRate>
    <DeptName>@Cobuy/NT6500</DeptName>
    <DeptSeq>70</DeptSeq>
    <ExRateSpread>323.00000</ExRateSpread>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026596,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021334
rollback 