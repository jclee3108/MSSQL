  
IF OBJECT_ID('hencom_SACPaymentPricePlanSave') IS NOT NULL   
    DROP PROC hencom_SACPaymentPricePlanSave  
GO  
  
-- v2017.06.02
  
-- 정기분대금지급계획-저장 by 이재천
CREATE PROC hencom_SACPaymentPricePlanSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACPaymentPricePlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACPaymentPricePlan'   
    IF @@ERROR <> 0 RETURN    


    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACPaymentPricePlan')    
        
    EXEC _SCOMLog @CompanySeq   ,        
                    @UserSeq      ,        
                    'hencom_TACPaymentPricePlan'    , -- 테이블명        
                    '#hencom_TACPaymentPricePlan'    , -- 임시 테이블명        
                    'StdDate,SlipUnit'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                    @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACPaymentPricePlan WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #hencom_TACPaymentPricePlan AS A   
          JOIN hencom_TACPaymentPricePlan AS B ON ( B.CompanySeq = @CompanySeq AND A.StdDate = B.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACPaymentPricePlan WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  


        UPDATE B   
           SET B.MatAmt1    = A.MatAmt1, 
               B.MatAmt2    = A.MatAmt2, 
               B.MatAmt3    = A.MatAmt3, 
               B.MatAmt4    = A.MatAmt4, 
               B.GoodsAmt1  = A.GoodsAmt1, 
               B.GoodsAmt3  = A.GoodsAmt3, 
               B.GoodsAmt4  = A.GoodsAmt4, 
               B.ReAmt1     = A.ReAmt1, 
               B.ReAmt2     = A.ReAmt2, 
               B.EtcAmt1    = A.EtcAmt1, 
               B.Remark     = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #hencom_TACPaymentPricePlan  AS A   
          JOIN hencom_TACPaymentPricePlan   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACPaymentPricePlan WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACPaymentPricePlan  
        (   
            CompanySeq, StdDate, SlipUnit, MatAmt1, MatAmt2, 
            MatAmt3, MatAmt4, GoodsAmt1, GoodsAmt3, GoodsAmt4, 
            ReAmt1, ReAmt2, EtcAmt1, Remark, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, StdDate, SlipUnit, MatAmt1, MatAmt2, 
               MatAmt3, MatAmt4, GoodsAmt1, GoodsAmt3, GoodsAmt4, 
               ReAmt1, ReAmt2, EtcAmt1, Remark, @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #hencom_TACPaymentPricePlan AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_TACPaymentPricePlan   
    
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
----select * from hencom_TACPaymentPricePlan 
--rollback 