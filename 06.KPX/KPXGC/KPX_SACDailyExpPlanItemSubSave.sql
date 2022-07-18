  
IF OBJECT_ID('KPX_SACDailyExpPlanItemSubSave') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanItemSubSave  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-차익 저장 by 이재천   
CREATE PROC KPX_SACDailyExpPlanItemSubSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_TACDailyExpPlanExRate (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TACDailyExpPlanExRate'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACDailyExpPlanExRate')    
    
    IF @WorkingTag = 'Del' -- 삭제 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanExRate'    , -- 테이블명        
                      '#KPX_TACDailyExpPlanExRate'    , -- 임시 테이블명        
                      'BaseDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 ) 
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    ELSE 
    BEGIN -- 수정, 시트삭제 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanExRate'    , -- 테이블명        
                      '#KPX_TACDailyExpPlanExRate'    , -- 임시 테이블명        
                      'BaseDate,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 ) 
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanExRate WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        
        IF @WorkingTag = 'Del' 
        BEGIN -- 삭제 
            DELETE B   
              FROM #KPX_TACDailyExpPlanExRate AS A   
              JOIN KPX_TACDailyExpPlanExRate AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
        ELSE 
        BEGIN -- 시트 삭제 
            DELETE B   
              FROM #KPX_TACDailyExpPlanExRate AS A   
              JOIN KPX_TACDailyExpPlanExRate AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND B.Serl = A.Serl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanExRate WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UMBankSeq = A.UMBankSeq, 
               B.Amt = A.Amt, 
               B.ListExRate = A.ListExRate, 
               B.ExRate = A.ExRate, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TACDailyExpPlanExRate AS A   
          JOIN KPX_TACDailyExpPlanExRate AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND A.Serl = B.Serl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanExRate WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACDailyExpPlanExRate  
        (   
            CompanySeq, BaseDate, Serl, UMBankSeq, Amt, 
            ListExRate, ExRate, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BaseDate, A.Serl, A.UMBankSeq, A.Amt, 
               A.ListExRate, A.ExRate, @UserSeq, GETDATE()
          FROM #KPX_TACDailyExpPlanExRate AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    SELECT * FROM #KPX_TACDailyExpPlanExRate   
    
    RETURN  
GO 
begin tran 
exec KPX_SACDailyExpPlanItemSubSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <Amt>2.00000</Amt>
    <DiffAmt>0.00000</DiffAmt>
    <ExRate>2.00000</ExRate>
    <ListExRate>2.00000</ListExRate>
    <Serl>1</Serl>
    <UMBankName>(주) 국민은행</UMBankName>
    <UMBankSeq>4003013</UMBankSeq>
    <BaseDate>20141209</BaseDate>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026596,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021334
select * From KPX_TACDailyExpPlanExRate 
rollback 