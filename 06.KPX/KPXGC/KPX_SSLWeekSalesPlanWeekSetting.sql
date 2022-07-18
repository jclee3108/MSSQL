
IF OBJECT_ID('KPX_SSLWeekSalesPlanWeekSetting') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanWeekSetting
GO 

-- v2014.11.17   
  
-- 주간판매계획입력(초기주차셋팅) by이재천   
CREATE PROC KPX_SSLWeekSalesPlanWeekSetting                  
    @xmlDocument    NVARCHAR(MAX) ,              
    @xmlFlags       INT = 0,              
    @ServiceSeq     INT = 0,              
    @WorkingTag     NVARCHAR(10)= '',                    
    @CompanySeq     INT = 1,              
    @LanguageSeq    INT = 1,              
    @UserSeq        INT = 0,              
    @PgmSeq         INT = 0         
AS          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
    DECLARE @docHandle      INT  
    
    
    SELECT ProdWeekName AS WeekName,   
           Serl AS WeekSeq,   
           DateFr AS FromDate,   
           DateTo AS ToDate   
      FROM _TPDBaseProdWeek     
     WHERE CompanySeq = @CompanySeq  
       AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN DateFr AND DateTo
    
    RETURN  
go 
exec KPX_SSLWeekSalesPlanWeekSetting @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1025887,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021321