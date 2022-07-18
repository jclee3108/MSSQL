
IF OBJECT_ID('KPX_SPDMPSDailyProdPlanQuickApplyCheck') IS NOT NULL 
    DROP PROC KPX_SPDMPSDailyProdPlanQuickApplyCheck
GO 

-- v2014.10.08 

-- 선택배치(생산계획체크) by이재천 
CREATE PROC dbo.KPX_SPDMPSDailyProdPlanQuickApplyCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #TPDMPSDailyProdPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'
    
    SELECT * FROM #TPDMPSDailyProdPlan 
    
RETURN    
