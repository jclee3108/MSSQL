 
IF OBJECT_ID('hencom_SACSendAmtListQuery') IS NOT NULL   
    DROP PROC hencom_SACSendAmtListQuery  
GO  
  
-- v2017.07.10
  
-- 전도금내역-조회 by 이재천
CREATE PROC hencom_SACSendAmtListQuery  
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
            @StdDate    NCHAR(8), 
            @SlipUnit   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate   = ISNULL( StdDate, '' ), 
           @SlipUnit  = ISNULL( SlipUnit, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate     NCHAR(8),
            SlipUnit    INT 
           )    
    
    -- 기준 된 사업소 
    CREATE TABLE #SlipUnit  
    (
        SlipUnit    INT, 
        MinorSort   INT 
    )

    INSERT INTO #SlipUnit ( SlipUnit, MinorSort ) 
    SELECT B.ValueSeq, A.MinorSort
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000005 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015263 
       AND C.ValueText = '1' 
       AND A.IsUse = '1' 
    
    
    -- 기준일의 데이터 
    SELECT * 
      INTO #hencom_TACSendAmtList 
      FROM hencom_TACSendAmtList AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate = @StdDate 
    
    
    -- 최종 조회 
    SELECT A.SlipUnit, 
           C.SlipUnitName, 
           ISNULL(B.Amt1,0) AS Amt1, 
           ISNULL(B.Amt2,0) AS Amt2, 
           ISNULL(B.Amt3,0) AS Amt3, 
           ISNULL(B.Amt4,0) AS Amt4, 
           ISNULL(B.Amt5,0) AS Amt5, 
           ISNULL(B.Amt6,0) AS Amt6, 
           ISNULL(B.Amt7,0) AS Amt7, 
           ISNULL(B.Amt8,0) AS Amt8, 
           ISNULL(B.Amt9,0) AS Amt9, 
           ISNULL(B.Amt10,0) AS Amt10, 
           ISNULL(B.Amt11,0) AS Amt11, 
           ISNULL(B.Amt12,0) AS Amt12, 
           ISNULL(B.Amt13,0) AS Amt13, 
           ISNULL(B.Amt14,0) AS Amt14, 
           ISNULL(B.Amt15,0) AS Amt15, 
           
           ISNULL(B.Amt1,0) + ISNULL(B.Amt2,0) + ISNULL(B.Amt3,0) + ISNULL(B.Amt4,0) + ISNULL(B.Amt5,0) + 
           ISNULL(B.Amt6,0) + ISNULL(B.Amt7,0) + ISNULL(B.Amt8,0) + ISNULL(B.Amt9,0) + ISNULL(B.Amt10,0) + 
           ISNULL(B.Amt11,0) + ISNULL(B.Amt12,0) + ISNULL(B.Amt13,0) + ISNULL(B.Amt14,0) + ISNULL(B.Amt15,0) AS TotAmt, 
           
           B.Remark, 
           A.MinorSort, 
           CASE WHEN B.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsSave
      INTO #Result 
      FROM #SlipUnit                                AS A 
      LEFT OUTER JOIN #hencom_TACSendAmtList   AS B ON ( B.SlipUnit = A.SlipUnit ) 
      LEFT OUTER JOIN _TACSlipUnit                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
      WHERE (@SlipUnit = 0 OR A.SlipUnit = @SlipUnit) 
    

    IF EXISTS (SELECT 1 FROM #Result) 
    BEGIN 
        INSERT INTO #Result 
        SELECT 99999 AS SlipUnit, 
               'TOTAL' AS SlipUnitName, 
               SUM(A.Amt1) AS Amt1, 
               SUM(A.Amt2) AS Amt2, 
               SUM(A.Amt3) AS Amt3, 
               SUM(A.Amt4) AS Amt4, 
               SUM(A.Amt5) AS Amt5, 
               SUM(A.Amt6) AS Amt6, 
               SUM(A.Amt7) AS Amt7, 
               SUM(A.Amt8) AS Amt8, 
               SUM(A.Amt9) AS Amt9, 
               SUM(A.Amt10) AS Amt10, 
               SUM(A.Amt11) AS Amt11, 
               SUM(A.Amt12) AS Amt12, 
               SUM(A.Amt13) AS Amt13, 
               SUM(A.Amt14) AS Amt14, 
               SUM(A.Amt15) AS Amt15, 
               SUM(A.TotAmt) AS TotAmt,

               '' AS Remark, 
               0 AS MinorSort, 
               '' AS IsSave 
          FROM #Result AS A 
    END 
    
    SELECT * FROM #Result ORDER BY MinorSort 

    
    RETURN  
GO