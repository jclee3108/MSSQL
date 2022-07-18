  
IF OBJECT_ID('KPX_SPDMRPMonthSave') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthSave  
GO  
  
-- v2014.12.16  
  
-- 월별자재소요계산-저장 by 이재천   
CREATE PROC KPX_SPDMRPMonthSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TPDMRPMonth (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDMRPMonth'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @EmpSeq     INT, 
            @PlanDate   NCHAR(8), 
            @PlanTime   NCHAR(4) 
    
    SELECT @EmpSeq = (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) 
    SELECT @PlanDate = (SELECT CONVERT(NCHAR(8), GETDATE(),112)) 
    SELECT @PlanTime = (SELECT LEFT(REPLACE(CONVERT(NVARCHAR(10),GETDATE(),108),':',''),4)) 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDMRPMonth WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPDMRPMonth  
        (   
            CompanySeq,MRPMonthSeq,ProdPlanYM,MRPNo,SMInOutTypePur,  
            EmpSeq,PlanDate,PlanTime,LastUserSeq,LastDateTime  
               
        )   
        SELECT @CompanySeq, A.MRPMonthSeq, A.ProdPlanYM, A.MRPNo, A.SMInOutTypePur,  
               @EmpSeq, @PlanDate, @PlanTime, @UserSeq, GETDATE()  
                  
          FROM #KPX_TPDMRPMonth AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A
       SET PlanDateTime = STUFF(STUFF(@PlanDate, 5,0,'-'),8,0,'-') + ' ' + STUFF(@PlanTime,3,0,':') 
      FROM #KPX_TPDMRPMonth AS A 
    
    SELECT * FROM #KPX_TPDMRPMonth   
      
    RETURN  