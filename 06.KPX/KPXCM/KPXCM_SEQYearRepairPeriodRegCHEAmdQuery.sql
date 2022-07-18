  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHEAmdQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHEAmdQuery  
GO  
  
-- v2015.07.13
  
-- 연차보수기간등록-차수조회 by 이재천 
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHEAmdQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @RepairYear NCHAR(4), 
            @FactUnit   INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @RepairYear  = ISNULL( RepairYear, '' ),  
           @FactUnit    = ISNULL( FactUnit, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            RepairYear   NCHAR(4), 
            FactUnit     INT 
           )    
    
    -- 최종조회   
    SELECT ISNULL(MAX(Amd),0) AS Amd
      FROM KPXCM_TEQYearRepairPeriodCHE AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.FactUnit = @FactUnit 
       AND A.RepairYear = @RepairYear 
      
    RETURN  
GO 
exec KPXCM_SEQYearRepairPeriodRegCHEAmdQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RepairYear>2014</RepairYear>
    <FactUnit>1</FactUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030822,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025712