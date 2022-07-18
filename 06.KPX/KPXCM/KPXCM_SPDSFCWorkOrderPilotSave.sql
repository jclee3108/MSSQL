  
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotSave  
GO  
  
-- v2016.03.02  
  
-- 긴급작업지시입력-저장 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCWorkOrderPilot (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDSFCWorkOrderPilot'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCWorkOrderPilot')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCWorkOrderPilot'    , -- 테이블명        
                  '#KPXCM_TPDSFCWorkOrderPilot'    , -- 임시 테이블명        
                  'PilotSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TPDSFCWorkOrderPilot AS A   
          JOIN KPXCM_TPDSFCWorkOrderPilot AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WorkCenterSeq = A.WorkCenterSeq,  
               B.ItemSeq = A.ItemSeq,  
               B.LotNo = A.LotNo,  
               B.SrtDate = A.SrtDate,  
               B.EndDate = A.EndDate,  
               B.SrtHour = A.SrtHour,  
               B.EndHour = A.EndHour,  
               B.Duration = A.Duration,  
               B.DurHour = A.DurHour,  
               B.ProdQty = A.ProdQty, 
               B.PatternSeq = A.WorkCond6,  
               B.Remark = A.Remark,  
               B.SubItemSeq = A.SubItemSeq,  
               B.AfterWorkSeq = A.AfterWorkSeq,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TPDSFCWorkOrderPilot AS A   
          JOIN KPXCM_TPDSFCWorkOrderPilot AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
      IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TPDSFCWorkOrderPilot  
        (   
            CompanySeq,PilotSeq,ProdPlanSeq,WorkOrderSeq,WorkCenterSeq,  
            ItemSeq,LotNo,SrtDate,EndDate,SrtHour,  
            EndHour,Duration,DurHour,ProdQty,PatternSeq,
            Remark,SubItemSeq,AfterWorkSeq,IsCfm,LastUserSeq,
            LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.PilotSeq,A.ProdPlanSeq,A.WorkOrderSeq,A.WorkCenterSeq,  
               A.ItemSeq,A.LotNo,A.SrtDate,A.EndDate,A.SrtHour,  
               A.EndHour,A.Duration,A.DurHour,A.ProdQty,A.WorkCond6,
               A.Remark,A.SubItemSeq,A.AfterWorkSeq,'0',@UserSeq,
               GETDATE(),@PgmSeq   
          FROM #KPXCM_TPDSFCWorkOrderPilot AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot   
      
    RETURN  
    go
    begin tran
    exec KPXCM_SPDSFCWorkOrderPilotSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <AfterWorkName>이송</AfterWorkName>
    <AfterWorkSeq>1010671001</AfterWorkSeq>
    <Duration>60.00000</Duration>
    <DurHour>01:0</DurHour>
    <EndDate>20160301</EndDate>
    <EndHour>03:0</EndHour>
    <IsCfm>0</IsCfm>
    <ItemName />
    <ItemSeq>3748</ItemSeq>
    <LotNo />
    <LotNOSeq>0</LotNOSeq>
    <OriDuration>60.00000</OriDuration>
    <OriDurHour>01:0</OriDurHour>
    <PilotSeq>1</PilotSeq>
    <ProdPlanNo />
    <ProdPlanSeq>0</ProdPlanSeq>
    <ProdQty>2.00000</ProdQty>
    <Remark />
    <SrtDate>20160301</SrtDate>
    <SrtHour>02:0</SrtHour>
    <SubItemName />
    <SubItemSeq>0</SubItemSeq>
    <WorkCenterName>1가공실_소형관 라인</WorkCenterName>
    <WorkCenterSeq>100002</WorkCenterSeq>
    <WorkCond6>0</WorkCond6>
    <WorkCond6Name />
    <WorkCond6Old>0</WorkCond6Old>
    <WorkOrderNo />
    <WorkOrderSeq>0</WorkOrderSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029271
select * from KPXCM_TPDSFCWorkOrderPilot 
rollback 