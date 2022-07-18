  
IF OBJECT_ID('KPX_SACFundDailyPlanSave') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanSave  
GO  
  
-- v2014.12.23  
  
-- 일자금계획입력(자금일보)-SS1 저장 by 이재천   
CREATE PROC KPX_SACFundDailyPlanSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TACFundDailyPlanOut (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACFundDailyPlanOut'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACFundDailyPlanOut')    
    
    
    IF @WorkingTag = 'Del' 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACFundDailyPlanOut'    , -- 테이블명        
                      '#KPX_TACFundDailyPlanOut'    , -- 임시 테이블명        
                      'FundDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    ELSE
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACFundDailyPlanOut'    , -- 테이블명        
                      '#KPX_TACFundDailyPlanOut'    , -- 임시 테이블명        
                      'PlanOutSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundDailyPlanOut WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del' 
        BEGIN 
            DELETE B   
              FROM #KPX_TACFundDailyPlanOut AS A   
              JOIN KPX_TACFundDailyPlanOut AS B ON ( B.CompanySeq = @CompanySeq AND A.FundDate = B.FundDate )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
            
            IF @@ERROR <> 0  RETURN  
        END 
        BEGIN
            DELETE B   
              FROM #KPX_TACFundDailyPlanOut AS A   
              JOIN KPX_TACFundDailyPlanOut AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanOutSeq = B.PlanOutSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
            
            IF @@ERROR <> 0  RETURN  
        END 
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundDailyPlanOut WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.Sort           = A.Sort        ,
               B.Summary        = A.Summary     ,
               B.ExRate         = A.ExRate      ,
               B.CurAmt         = A.CurAmt      ,
               B.DomAmt         = A.DomAmt      ,
               B.Remark1        = A.Remark1     ,
               B.Remark2        = A.Remark2     ,
               B.SlipSeq        = A.SlipSeq     ,
               B.LastUserSeq    = @UserSeq      ,
               B.LastDateTime   = GETDATE()     
          FROM #KPX_TACFundDailyPlanOut AS A   
          JOIN KPX_TACFundDailyPlanOut AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanOutSeq = B.PlanOutSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundDailyPlanOut WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACFundDailyPlanOut  
        (   
            CompanySeq, PlanOutSeq, FundDate, Sort, Summary, 
            ExRate, CurAmt, DomAmt, Remark1, Remark2, 
            SlipSeq, LastUserSeq, LastDateTime  
        )   
        SELECT @CompanySeq, A.PlanOutSeq, A.FundDate, A.Sort, A.Summary, 
               A.ExRate, A.CurAmt, A.DomAmt, A.Remark1, A.Remark2, 
               A.SlipSeq, @UserSeq, GETDATE() 
          FROM #KPX_TACFundDailyPlanOut AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TACFundDailyPlanOut   
      
    RETURN  
GO

begin tran 

exec KPX_SACFundDailyPlanSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccDate>20141223</AccDate>
    <AccName>외화현금</AccName>
    <AccSeq>1000022</AccSeq>
    <BankAccName>012-041441-04-019</BankAccName>
    <BankAccNo>012-041441-04-019</BankAccNo>
    <BankName>기업은행 염창동</BankName>
    <BankSeq>0</BankSeq>
    <CurAmt>10000.00000</CurAmt>
    <CurrName>USD</CurrName>
    <CurrSeq>2</CurrSeq>
    <DomAmt>10000.00000</DomAmt>
    <ExRate>1.000000</ExRate>
    <FundDate>20141223</FundDate>
    <PlanOutSeq>1</PlanOutSeq>
    <Remark1>satase</Remark1>
    <Remark2>saetaset</Remark2>
    <SlipMstID>A0-S1-20141223-0001</SlipMstID>
    <SlipMstSeq>0</SlipMstSeq>
    <SlipSummary>test1</SlipSummary>
    <Sort>1</Sort>
    <Summary>rsetse</Summary>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021333

rollback 