  
IF OBJECT_ID('KPX_SARBizTripCostSave') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostSave  
GO  
  
-- v2015.01.08  
  
-- 출장비지출품의서-저장 by 이재천   
CREATE PROC KPX_SARBizTripCostSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TARBizTripCost (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TARBizTripCost'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TARBizTripCost')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TARBizTripCost'    , -- 테이블명        
                  '#KPX_TARBizTripCost'    , -- 임시 테이블명        
                  'BizTripSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCost WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TARBizTripCost AS A   
          JOIN KPX_TARBizTripCost AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCost WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN   
    
        UPDATE B   
           SET B.EmpSeq         = A.EmpSeq         ,
               B.SMTripKind     = A.SMTripKind     ,
               B.CCtrSeq        = A.CCtrSeq        ,
               B.TripFrDate     = A.TripFrDate     ,
               B.TripToDate     = A.TripToDate     ,
               B.TermNight      = A.TermNight      ,
               B.TermDay        = A.TermDay        ,
               B.TripPlace      = A.TripPlace      ,
               B.Purpose        = A.Purpose        ,
               B.TransCost      = A.TransCost      ,
               B.DailyCost      = A.DailyCost      ,
               B.LodgeCost      = A.LodgeCost      ,
               B.EctCost        = A.EctCost        ,
               B.CardOutCost    = A.CardOutCost    ,
               B.CostSeq        = A.CostSeq        ,
               B.SlipUnit       = A.SlipUnit       , 
               B.LastUserSeq    = @UserSeq         ,  
               B.LastDateTime   = GETDATE()  
          FROM #KPX_TARBizTripCost AS A   
          JOIN KPX_TARBizTripCost AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCost WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TARBizTripCost  
        (   
            CompanySeq, BizTripSeq, BizTripNo, EmpSeq, SMTripKind, 
            CCtrSeq, TripFrDate, TripToDate, TermNight, TermDay, 
            TripPlace, Purpose, TransCost, DailyCost, LodgeCost, 
            EctCost, CardOutCost, CostSeq, RegDate, SlipUnit, 
            SlipMstSeq, SlipSeq, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BizTripSeq, A.BizTripNo, A.EmpSeq, A.SMTripKind, 
               A.CCtrSeq, A.TripFrDate, A.TripToDate, A.TermNight, A.TermDay, 
               A.TripPlace, A.Purpose, A.TransCost, A.DailyCost, A.LodgeCost, 
               A.EctCost, A.CardOutCost, A.CostSeq, A.RegDate, A.SlipUnit, 
               0, 0, @UserSeq, GETDATE()
          FROM #KPX_TARBizTripCost AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TARBizTripCost   
    
    RETURN  
GO 
begin tran 
exec KPX_SARBizTripCostSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <AccName>복리후생비1</AccName>
    <AccSeq>1182</AccSeq>
    <BizTripNo>201501092</BizTripNo>
    <BizTripSeq>8</BizTripSeq>
    <CCtrName>(프로젝트별)과세10% - X 품목 생성</CCtrName>
    <CCtrSeq>1239</CCtrSeq>
    <CostName>교육훈련비</CostName>
    <CostSeq>3</CostSeq>
    <DailyCost>2323.00000</DailyCost>
    <DeptName>생산2팀</DeptName>
    <EctCost>2323.00000</EctCost>
    <EmpName>윤삼혁</EmpName>
    <EmpSeq>1317</EmpSeq>
    <LodgeCost>2323.00000</LodgeCost>
    <OppAccName>현금</OppAccName>
    <OppAccSeq>5</OppAccSeq>
    <Purpose>123</Purpose>
    <RegDate>20150109</RegDate>
    <SlipMstID />
    <SlipUnit>1</SlipUnit>
    <SlipUnitName>전사</SlipUnitName>
    <SMTripKind>1013002</SMTripKind>
    <SMTripKindName>해외</SMTripKindName>
    <SumCost>9292.00000</SumCost>
    <TermDay>2.00000</TermDay>
    <TermNight>1.00000</TermNight>
    <TransCost>2323.00000</TransCost>
    <TripFrDate>20150101</TripFrDate>
    <TripPlace>123</TripPlace>
    <TripToDate>20150102</TripToDate>
    <UMCostType>4001001</UMCostType>
    <UMCostTypeName>제조</UMCostTypeName>
    <UMJpName />
    <CardOutCost>123124124.00000</CardOutCost>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022816
select * from KPX_TARBizTripCost 
rollback 