  
IF OBJECT_ID('KPX_SPDMRPMonthItemSave') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthItemSave  
GO  
  
-- v2014.12.16 
  
-- 월별자재소요계산-품목 저장 by 이재천   
CREATE PROC KPX_SPDMRPMonthItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDMRPMonthItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDMRPMonthItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDMRPMonthItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDMRPMonthItem  
        (   
            CompanySeq, MRPMonthSeq, Serl, MRPMonth, ItemSeq, 
            CalcType, UnitSeq, Qty, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.MRPMonthSeq, A.Serl, A.TITLE_IDX0_SEQ, A.ItemSeq, 
               A.KindSeq, A.UnitSeq, A.Value, @UserSeq, GETDATE() 
          FROM #KPX_TPDMRPMonthItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    SELECT * FROM #KPX_TPDMRPMonthItem   
    
    RETURN  
GO 

