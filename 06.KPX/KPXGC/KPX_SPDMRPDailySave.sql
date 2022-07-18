  
IF OBJECT_ID('KPX_SPDMRPDailySave') IS NOT NULL   
    DROP PROC KPX_SPDMRPDailySave  
GO  
  
-- v2014.12.15  
  
-- 일별자재소요계산-저장 by 이재천   
CREATE PROC KPX_SPDMRPDailySave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDMRPDaily (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDMRPDaily'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @EmpSeq     INT, 
            @PlanDate   NCHAR(8), 
            @PlanTime   NCHAR(4) 
    
    SELECT @EmpSeq = (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) 
    SELECT @PlanDate = (SELECT CONVERT(NCHAR(8), GETDATE(),112)) 
    SELECT @PlanTime = (SELECT LEFT(REPLACE(CONVERT(NVARCHAR(10),GETDATE(),108),':',''),4)) 
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDMRPDaily WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDMRPDaily  
        (   
            CompanySeq, MRPDailySeq, DateFr, DateTo, MRPNo, 
            SMInOutTypePur , EmpSeq, PlanDate, PlanTime, LastUserSeq, 
            LastDateTime  
        )   
        SELECT @CompanySeq, A.MRPDailySeq, A.DateFr, A.DateTo, A.MRPNo, 
               A.SMInOutTypePur, @EmpSeq, @PlanDate, @PlanTime, @UserSeq, 
               GETDATE() 
          FROM #KPX_TPDMRPDaily AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A
       SET PlanDateTime = STUFF(STUFF(@PlanDate, 5,0,'-'),8,0,'-') + ' ' + STUFF(@PlanTime,3,0,':') 
      FROM #KPX_TPDMRPDaily AS A 
    
    SELECT * FROM #KPX_TPDMRPDaily   
      
    RETURN  
GO 
begin tran 
exec KPX_SPDMRPDailySave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DateFr>20141201</DateFr>
    <DateTo>20141215</DateTo>
    <MRPDailySeq>1</MRPDailySeq>
    <MRPNo />
    <MRPType>6403002</MRPType>
    <MRPTypeName>생산계획</MRPTypeName>
    <PlanDateTime />
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <SMMrpKind>6004001</SMMrpKind>
    <SMMrpKindName>MRP</SMMrpKindName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414
rollback 

