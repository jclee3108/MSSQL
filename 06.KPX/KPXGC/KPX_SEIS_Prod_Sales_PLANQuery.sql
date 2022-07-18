  
IF OBJECT_ID('KPX_SEIS_Prod_Sales_PLANQuery') IS NOT NULL   
    DROP PROC KPX_SEIS_Prod_Sales_PLANQuery  
GO  
  
-- v2014.11.24  
  
-- (경영정보)생산 판매계획-조회 by 이재천   
CREATE PROC KPX_SEIS_Prod_Sales_PLANQuery  
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
            @PlanYM     NCHAR(6), 
            @BizUnit    INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYM = ISNULL( PlanYM, '' ), 
           @BizUnit = ISNULL( BizUnit, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PlanYM   NCHAR(6),
            BizUnit  INT
           )    
    
    IF EXISTS (SELECT 1 FROM KPX_TEIS_PROD_SALES_PLAN WHERE CompanySeq = @CompanySeq AND PlanYM = @PlanYM AND BizUnit = @BizUnit) 
    BEGIN
        SELECT B.MinorName AS UMItemClassLName, 
               A.UMItemClassL, 
               A.ProdQty, 
               A.SalesQty, 
               A.SalesAmt, 
               A.SpendQty, 
               '1' AS IsExists 
          FROM KPX_TEIS_PROD_SALES_PLAN     AS A 
          LEFT OUTER JOIN _TDAUMInor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMItemClassL ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.PlanYM = @PlanYM 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
    END 
    ELSE 
    BEGIN
        SELECT A.MinorName AS UMItemClassLName, 
               A.MinorSeq AS UMItemClassL, 
               '0' AS IsExists
          FROM _TDAUMinor                   AS A 
          LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.MajorSeq = 2003
           AND A.IsUse = '1' 
           AND (@BizUnit = 0 OR B.ValueSeq = @BizUnit)
    END 
    
    
    IF EXISTS (SELECT 1 FROM KPX_TEIS_BC_UR_PLAN WHERE CompanySeq = @CompanySeq AND PlanYM = @PlanYM) 
    BEGIN
        SELECT B.BizUnitName, 
               A.BizUnit,
               A.UMURType, 
               C.MinorName AS UMURTypeName, 
               PlanAmt, 
               '1' AS IsExists
               
          FROM KPX_TEIS_BC_UR_PLAN      AS A 
          LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
          LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = UMURType AND C.IsUse = '1' ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.PlanYM = @PlanYM 
    END 
    ELSE 
    BEGIN
        SELECT A.BizUnit, 
               A.BizUnitName, 
               C.MinorSeq AS UMURType, 
               C.MinorName AS UMURTypeName, 
               '0' AS IsExists
          FROM _TDABizUnit              AS A 
          LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 1010342 AND C.IsUse = '1' ) 
         WHERE A.CompanySeq = @CompanySeq 
    END 
    
    RETURN 
GO 
exec KPX_SEIS_Prod_Sales_PLANQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanYM>201411</PlanYM>
    <BizUnit>1</BizUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026127,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021922