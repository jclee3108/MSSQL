 
IF OBJECT_ID('hencom_SACSubContrAmtListQuery') IS NOT NULL   
    DROP PROC hencom_SACSubContrAmtListQuery  
GO  
  
-- v2017.07.07
  
-- 도급비지급내역-조회 by 이재천
CREATE PROC hencom_SACSubContrAmtListQuery  
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
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000004 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015263 
       AND C.ValueText = '1' 
       AND A.IsUse = '1' 
    
    
    -- 기준일의 데이터 
    SELECT * 
      INTO #hencom_TACSubContrAmtList 
      FROM hencom_TACSubContrAmtList AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate = @StdDate 
    
    
    -- 최종 조회 
    SELECT A.SlipUnit, 
           C.SlipUnitName, 
           ISNULL(B.SubContrAmt1,0) AS SubContrAmt1, 
           ISNULL(B.SubContrAmt2,0) AS SubContrAmt2, 
           ISNULL(B.SubContrAmt3,0) AS SubContrAmt3, 
           ISNULL(B.SubContrAmt4,0) AS SubContrAmt4, 
           ISNULL(B.SubContrAmt5,0) AS SubContrAmt5, 
           ISNULL(B.SubContrAmt6,0) AS SubContrAmt6, 

           ISNULL(B.SubContrAmt1,0) + ISNULL(B.SubContrAmt2,0) + ISNULL(B.SubContrAmt3,0) + 
           ISNULL(B.SubContrAmt4,0) + ISNULL(B.SubContrAmt5,0) + ISNULL(B.SubContrAmt6,0) AS TotSubContrAmt, 

           ISNULL(B.DeductAmt1,0) AS DeductAmt1, 
           ISNULL(B.DeductAmt2,0) AS DeductAmt2, 
           ISNULL(B.DeductAmt3,0) AS DeductAmt3, 
           ISNULL(B.DeductAmt4,0) AS DeductAmt4, 
           ISNULL(B.DeductAmt5,0) AS DeductAmt5, 
           ISNULL(B.DeductAmt6,0) AS DeductAmt6, 

           ISNULL(B.DeductAmt1,0) + ISNULL(B.DeductAmt2,0) + ISNULL(B.DeductAmt3,0) + 
           ISNULL(B.DeductAmt4,0) + ISNULL(B.DeductAmt5,0) + ISNULL(B.DeductAmt6,0) AS TotDeductAmt, 

           ISNULL(B.ThisMonthAmt,0) AS ThisMonthAmt, 
            
           B.Remark, 
           A.MinorSort, 
           CASE WHEN B.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsSave
      INTO #Result 
      FROM #SlipUnit                                AS A 
      LEFT OUTER JOIN #hencom_TACSubContrAmtList   AS B ON ( B.SlipUnit = A.SlipUnit ) 
      LEFT OUTER JOIN _TACSlipUnit                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
      WHERE (@SlipUnit = 0 OR A.SlipUnit = @SlipUnit) 
    

    IF EXISTS (SELECT 1 FROM #Result) 
    BEGIN 
        INSERT INTO #Result 
        SELECT 99999 AS SlipUnit, 
               'TOTAL' AS SlipUnitName, 
               SUM(A.SubContrAmt1) AS SubContrAmt1, 
               SUM(A.SubContrAmt2) AS SubContrAmt2, 
               SUM(A.SubContrAmt3) AS SubContrAmt3, 
               SUM(A.SubContrAmt4) AS SubContrAmt4, 
               SUM(A.SubContrAmt5) AS SubContrAmt5, 
               SUM(A.SubContrAmt6) AS SubContrAmt6, 
               SUM(A.TotSubContrAmt) AS TotSubContrAmt, 

               SUM(A.DeductAmt1) AS DeductAmt1, 
               SUM(A.DeductAmt2) AS DeductAmt2, 
               SUM(A.DeductAmt3) AS DeductAmt3, 
               SUM(A.DeductAmt4) AS DeductAmt4, 
               SUM(A.DeductAmt5) AS DeductAmt5, 
               SUM(A.DeductAmt6) AS DeductAmt6, 
               SUM(A.TotDeductAmt) AS TotDeductAmt, 

               SUM(A.ThisMonthAmt) AS ThisMonthAmt, 

               '' AS Remark, 
               0 AS MinorSort, 
               '' AS IsSave 
          FROM #Result AS A 
    END 
    
    SELECT * FROM #Result ORDER BY MinorSort 

    
    RETURN  
GO