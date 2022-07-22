  
IF OBJECT_ID('hencom_SACFundSendPlanSave') IS NOT NULL   
    DROP PROC hencom_SACFundSendPlanSave  
GO  
  
-- v2017.07.07
  
-- 정기분대금지급계획-저장 by 이재천
CREATE PROC hencom_SACFundSendPlanSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACFundSendPlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACFundSendPlan'   
    IF @@ERROR <> 0 RETURN    


    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACFundSendPlan')    
        
    EXEC _SCOMLog @CompanySeq   ,        
                    @UserSeq      ,        
                    'hencom_TACFundSendPlan'    , -- 테이블명        
                    '#hencom_TACFundSendPlan'    , -- 임시 테이블명        
                    'StdDate,SlipUnit'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                    @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACFundSendPlan WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #hencom_TACFundSendPlan AS A   
          JOIN hencom_TACFundSendPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.StdDate = B.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACFundSendPlan WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  


        UPDATE B   
           SET B.InSendAmt  = A.InSendAmt, 
               B.SendAmt1   = A.SendAmt1, 
               B.SendAmt2   = A.SendAmt2, 
               B.SendAmt3   = A.SendAmt3, 
               B.SendAmt4   = A.SendAmt4, 
               B.SendAmt5   = A.SendAmt5, 
               B.SendAmt6   = A.SendAmt6, 
               B.SendAmt7   = A.SendAmt7, 
               B.SendAmt8   = A.SendAmt8, 
               B.AccSendAmt = A.AccSendAmt, 
               B.Remark     = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #hencom_TACFundSendPlan  AS A   
          JOIN hencom_TACFundSendPlan   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACFundSendPlan WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACFundSendPlan  
        (   
            CompanySeq, StdDate, SlipUnit, InSendAmt, SendAmt1, 
            SendAmt2, SendAmt3, SendAmt4, SendAmt5, SendAmt6, 
            SendAmt7, SendAmt8, AccSendAmt, Remark, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, StdDate, SlipUnit, InSendAmt, SendAmt1, 
               SendAmt2, SendAmt3, SendAmt4, SendAmt5, SendAmt6, 
               SendAmt7, SendAmt8, AccSendAmt, Remark, @UserSeq,
               GETDATE(), @PgmSeq
          FROM #hencom_TACFundSendPlan AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_TACFundSendPlan   
    
    RETURN  

--go
--begin tran 
--exec hencom_SACPaymentPricePlanSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <StdDate>20170602</StdDate>
--    <SlipUnitName>담양사업소</SlipUnitName>
--    <MatAmt1>1232.00000</MatAmt1>
--    <MatAmt2>0.00000</MatAmt2>
--    <MatAmt3>0.00000</MatAmt3>
--    <MatAmt4>0.00000</MatAmt4>
--    <SumMatAmt>1232.00000</SumMatAmt>
--    <GoodsAmt1>0.00000</GoodsAmt1>
--    <GoodsAmt3>234.00000</GoodsAmt3>
--    <GoodsAmt4>0.00000</GoodsAmt4>
--    <SumGoodsAmt>234.00000</SumGoodsAmt>
--    <ReAmt1>0.00000</ReAmt1>
--    <ReAmt2>0.00000</ReAmt2>
--    <SumReAmt>0.00000</SumReAmt>
--    <EtcAmt1>0.00000</EtcAmt1>
--    <SumEtcAmt>0.00000</SumEtcAmt>
--    <SumAmt>1466.00000</SumAmt>
--    <Remark />
--    <SlipUnit>4</SlipUnit>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <StdDate>20170602</StdDate>
--    <SlipUnitName>당진사업소</SlipUnitName>
--    <MatAmt1>0.00000</MatAmt1>
--    <MatAmt2>423.00000</MatAmt2>
--    <MatAmt3>0.00000</MatAmt3>
--    <MatAmt4>234.00000</MatAmt4>
--    <SumMatAmt>657.00000</SumMatAmt>
--    <GoodsAmt1>0.00000</GoodsAmt1>
--    <GoodsAmt3>0.00000</GoodsAmt3>
--    <GoodsAmt4>0.00000</GoodsAmt4>
--    <SumGoodsAmt>0.00000</SumGoodsAmt>
--    <ReAmt1>0.00000</ReAmt1>
--    <ReAmt2>0.00000</ReAmt2>
--    <SumReAmt>0.00000</SumReAmt>
--    <EtcAmt1>0.00000</EtcAmt1>
--    <SumEtcAmt>0.00000</SumEtcAmt>
--    <SumAmt>657.00000</SumAmt>
--    <Remark />
--    <SlipUnit>5</SlipUnit>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <StdDate>20170602</StdDate>
--    <SlipUnitName>대전사업소</SlipUnitName>
--    <MatAmt1>0.00000</MatAmt1>
--    <MatAmt2>0.00000</MatAmt2>
--    <MatAmt3>0.00000</MatAmt3>
--    <MatAmt4>234.00000</MatAmt4>
--    <SumMatAmt>234.00000</SumMatAmt>
--    <GoodsAmt1>0.00000</GoodsAmt1>
--    <GoodsAmt3>234.00000</GoodsAmt3>
--    <GoodsAmt4>0.00000</GoodsAmt4>
--    <SumGoodsAmt>234.00000</SumGoodsAmt>
--    <ReAmt1>0.00000</ReAmt1>
--    <ReAmt2>0.00000</ReAmt2>
--    <SumReAmt>0.00000</SumReAmt>
--    <EtcAmt1>0.00000</EtcAmt1>
--    <SumEtcAmt>0.00000</SumEtcAmt>
--    <SumAmt>468.00000</SumAmt>
--    <Remark />
--    <SlipUnit>6</SlipUnit>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>4</IDX_NO>
--    <DataSeq>4</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <StdDate>20170602</StdDate>
--    <SlipUnitName>서대전사업소</SlipUnitName>
--    <MatAmt1>0.00000</MatAmt1>
--    <MatAmt2>23234.00000</MatAmt2>
--    <MatAmt3>234.00000</MatAmt3>
--    <MatAmt4>0.00000</MatAmt4>
--    <SumMatAmt>23468.00000</SumMatAmt>
--    <GoodsAmt1>0.00000</GoodsAmt1>
--    <GoodsAmt3>0.00000</GoodsAmt3>
--    <GoodsAmt4>0.00000</GoodsAmt4>
--    <SumGoodsAmt>0.00000</SumGoodsAmt>
--    <ReAmt1>0.00000</ReAmt1>
--    <ReAmt2>0.00000</ReAmt2>
--    <SumReAmt>0.00000</SumReAmt>
--    <EtcAmt1>0.00000</EtcAmt1>
--    <SumEtcAmt>0.00000</SumEtcAmt>
--    <SumAmt>23468.00000</SumAmt>
--    <Remark />
--    <SlipUnit>7</SlipUnit>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1512352,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033717
----select * from hencom_TACFundSendPlan 
--rollback 