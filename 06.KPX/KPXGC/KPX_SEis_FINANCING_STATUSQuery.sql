  
IF OBJECT_ID('KPX_SEis_FINANCING_STATUSQuery') IS NOT NULL   
    DROP PROC KPX_SEis_FINANCING_STATUSQuery  
GO  
  
-- v2014.11.26  
  
-- (경영정보)자금 조달 현황-조회 by 이재천   
CREATE PROC KPX_SEis_FINANCING_STATUSQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PlanYM     NCHAR(6)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYM   = ISNULL( PlanYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlanYM   INT)    
    
    IF EXISTS ( SELECT 1 FROM KPX_TEIS_FINANCING_STATUS WHERE CompanySeq = @CompanySeq AND PlanYM = @PlanYM ) 
    BEGIN
        SELECT A.BizUnit, 
               B.BizUnitName, 
               A.UMSupply, 
               C.MinorName AS UMSupplyName, 
               A.ResultUpAmt, 
               A.ResultDownAmt, 
               A.PlanUpAmt, 
               A.PlanDownAmt, 
               A.AmtRate, 
               '1' AS IsExists
          FROM KPX_TEIS_FINANCING_STATUS    AS A 
          LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
          LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMSupply ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.PlanYM = @PlanYM 
         ORDER BY A.BizUnit, C.MinorSort
    END 
    ELSE 
    BEGIN
        SELECT A.BizUnit, 
               A.BizUnitName, 
               B.MinorSeq AS UMSupply, 
               B.MinorName AS UMSupplyName, 
               '0' AS IsExists, 
               B.IsUse 
          FROM _TDABizUnit AS A 
          JOIN _TDAUMinor  AS B ON ( B.CompanySeq = @CompanySeq AND B.IsUse = '1' AND B.MajorSeq = 1010333 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.IsUse = '1'
         ORDER BY A.BizUnit, B.MinorSort
    END 
    
    RETURN  
GO 
exec KPX_SEis_FINANCING_STATUSQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026207,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021968
