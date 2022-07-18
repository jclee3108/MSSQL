  
IF OBJECT_ID('KPX_SPDMPSDailyProdPlanQuickQuery') IS NOT NULL   
    DROP PROC KPX_SPDMPSDailyProdPlanQuickQuery  
GO  
  
-- v2014.10.06  
  
-- 선택배치-조회 by 이재천   
CREATE PROC KPX_SPDMPSDailyProdPlanQuickQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    -- 최종조회   
    SELECT A.WorkCenterSeq, 
           A.WorkCenterName, 
           A.CapaRate AS WCCapacity 
      FROM _TPDBaseWorkCenter AS A   
     WHERE A.CompanySeq = @CompanySeq 
    
    RETURN  
GO 
exec KPX_SPDMPSDailyProdPlanQuickQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1024882,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020927


