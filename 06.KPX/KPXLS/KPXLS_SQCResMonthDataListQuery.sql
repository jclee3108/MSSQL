  
IF OBJECT_ID('KPXLS_SQCResMonthDataListQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCResMonthDataListQuery  
GO  
  
-- v2016.03.14  
  
-- 월별품질분석현황-조회 by 이재천   
CREATE PROC KPXLS_SQCResMonthDataListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYear    NCHAR(4)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear   = ISNULL( StdYear, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYear   NCHAR(4))    
    
    
    CREATE TABLE #Result 
    (
        KindName    NVARCHAR(200), 
        KindSeq     INT, 
        Month1      DECIMAL(19,5), 
        Month2      DECIMAL(19,5), 
        Month3      DECIMAL(19,5), 
        Month4      DECIMAL(19,5), 
        Month5      DECIMAL(19,5), 
        Month6      DECIMAL(19,5), 
        Month7      DECIMAL(19,5), 
        Month8      DECIMAL(19,5), 
        Month9      DECIMAL(19,5), 
        Month10     DECIMAL(19,5), 
        Month11     DECIMAL(19,5), 
        Month12     DECIMAL(19,5), 
        Total       DECIMAL(19,5) 
    )
    -------------------
    -- 구분값 넣기 
    -------------------
    INSERT INTO #Result ( KindName, KindSeq ) 
    SELECT '최종검사', 1 
    UNION ALL 
    SELECT '공정검사', 2 
    UNION ALL 
    SELECT '수입검사', 3 
    UNION ALL 
    SELECT '특별검사(재고)', 4 
    UNION ALL 
    SELECT '특별검사(유효기간)', 5 
    UNION ALL 
    SELECT '특별검사(공정)', 6 
    -------------------
    -- 구분값 넣기, END 
    -------------------
    
    -------------------------------------------------
    -- 최종검사 
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN Z.Cnt ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN Z.Cnt ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN Z.Cnt ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN Z.Cnt ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN Z.Cnt ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN Z.Cnt ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN Z.Cnt ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN Z.Cnt ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN Z.Cnt ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN Z.Cnt ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN Z.Cnt ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN Z.Cnt ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(D.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A 
                      LEFT OUTER JOIN KPXLS_TQCRequest              AS H ON ( H.CompanySeq = @CompanySeq AND A.ReqSeq = H.ReqSeq ) 
                      LEFT OUTER JOIN ( 
                                        SELECT DISTINCT ReqSeq, UMQCSeq 
                                          FROM KPXLS_TQCRequestItemAdd_PDB 
                                         WHERE CompanySeq = @CompanySeq 
                                       ) AS C ON ( A.ReqSeq = C.ReqSeq ) 
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS D ON ( D.CompanySeq = @CompanySeq AND D.QCSeq = A.QCSeq ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND H.PgmSeq IN (1027855,1027791)   
                       AND C.UMQCSeq = 1011958001 
                       AND LEFT(D.TestDate,4) = @StdYear 
                     GROUP BY LEFT(D.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 1 
    -------------------------------------------------
    -- 최종검사, END 
    -------------------------------------------------
    
    -------------------------------------------------
    -- 공정검사
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN Z.Cnt ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN Z.Cnt ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN Z.Cnt ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN Z.Cnt ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN Z.Cnt ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN Z.Cnt ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN Z.Cnt ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN Z.Cnt ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN Z.Cnt ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN Z.Cnt ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN Z.Cnt ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN Z.Cnt ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(D.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A 
                      LEFT OUTER JOIN KPXLS_TQCRequest              AS H ON ( H.CompanySeq = @CompanySeq AND A.ReqSeq = H.ReqSeq ) 
                      LEFT OUTER JOIN ( 
                                        SELECT DISTINCT ReqSeq, UMQCSeq 
                                          FROM KPXLS_TQCRequestItemAdd_PDB 
                                         WHERE CompanySeq = @CompanySeq 
                                       ) AS C ON ( A.ReqSeq = C.ReqSeq ) 
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS D ON ( D.CompanySeq = @CompanySeq AND D.QCSeq = A.QCSeq ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND H.PgmSeq IN (1027855,1027791)   
                       AND C.UMQCSeq = 1011958002 
                       AND LEFT(D.TestDate,4) = @StdYear 
                     GROUP BY LEFT(D.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 2  
    -------------------------------------------------
    -- 공정검사, END 
    -------------------------------------------------
    
    -------------------------------------------------
    -- 수입검사 
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN Z.Cnt ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN Z.Cnt ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN Z.Cnt ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN Z.Cnt ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN Z.Cnt ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN Z.Cnt ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN Z.Cnt ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN Z.Cnt ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN Z.Cnt ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN Z.Cnt ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN Z.Cnt ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN Z.Cnt ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(D.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A 
                      LEFT OUTER JOIN KPXLS_TQCRequest              AS C ON ( C.CompanySeq = A.CompanySeq AND C.ReqSeq = A.ReqSeq ) 
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS D ON ( D.CompanySeq = @CompanySeq AND D.QCSeq = A.QCSeq ) 
                     WHERE A.CompanySeq = @CompanySeq  
                       AND C.SMSourceType  in ( 1000522008, 1000522007 ) 
                       AND LEFT(D.TestDate,4) = @StdYear 
                     GROUP BY LEFT(D.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 3 
    -------------------------------------------------
    -- 수입검사, END  
    -------------------------------------------------
    
    -------------------------------------------------
    -- 특별검사(재고)
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)   
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN Z.Cnt ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN Z.Cnt ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN Z.Cnt ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN Z.Cnt ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN Z.Cnt ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN Z.Cnt ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN Z.Cnt ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN Z.Cnt ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN Z.Cnt ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN Z.Cnt ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN Z.Cnt ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN Z.Cnt ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(B.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A  
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS B ON ( A.CompanySeq = B.CompanySeq AND A.QCSeq = B.QCSeq ) 
                                 JOIN KPXLS_TQCRequestItemAdd_STK   AS C ON ( A.CompanySeq = C.CompanySeq AND A.ReqSeq = C.ReqSeq AND A.ReqSerl = C.ReqSerl ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND LEFT(B.TestDate,4) = @StdYear 
                     GROUP BY LEFT(B.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 4  
    -------------------------------------------------
    -- 특별검사(재고), END 
    -------------------------------------------------
    
    -------------------------------------------------
    -- 특별검사(유효기간)
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)   
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(B.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A  
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS B ON ( A.CompanySeq = B.CompanySeq AND A.QCSeq = B.QCSeq ) 
                                 JOIN KPXLS_TACRequestItemAdd_EXP   AS C ON ( A.CompanySeq = C.CompanySeq AND A.ReqSeq = C.ReqSeq AND A.ReqSerl = C.ReqSerl ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND LEFT(B.TestDate,4) = @StdYear 
                     GROUP BY LEFT(B.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 5   
    -------------------------------------------------
    -- 특별검사(유효기간), END 
    -------------------------------------------------
    
    -------------------------------------------------
    -- 특별검사(공정)
    -------------------------------------------------
    UPDATE Q
       SET Month1 = ISNULL(Y.Month1,0),  
           Month2 = ISNULL(Y.Month2,0),  
           Month3 = ISNULL(Y.Month3,0),  
           Month4 = ISNULL(Y.Month4,0),  
           Month5 = ISNULL(Y.Month5,0),  
           Month6 = ISNULL(Y.Month6,0),  
           Month7 = ISNULL(Y.Month7,0),  
           Month8 = ISNULL(Y.Month8,0),  
           Month9 = ISNULL(Y.Month9,0),  
           Month10 = ISNULL(Y.Month10,0),  
           Month11 = ISNULL(Y.Month11,0),  
           Month12 = ISNULL(Y.Month12,0),  
           Total = ISNULL(Y.Total,0)  
      FROM #Result AS Q
      JOIN (
            SELECT SUM(CASE WHEN RIGHT(Z.TestYM,2) = '01' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month1, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '02' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month2, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '03' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month3, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '04' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month4, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '05' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month5, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '06' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month6, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '07' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month7, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '08' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month8, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '09' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month9, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '10' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month10, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '11' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month11, 
                   SUM(CASE WHEN RIGHT(Z.TestYM,2) = '12' THEN ISNULL(Z.Cnt,0) ELSE 0 END) AS Month12, 
                   SUM(Z.Cnt) AS Total
                   
              FROM ( 
                    SELECT LEFT(B.TestDate,6) AS TestYM, COUNT(1) AS Cnt 
                      FROM KPX_TQCTestResult                        AS A  
                      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS B ON ( A.CompanySeq = B.CompanySeq AND A.QCSeq = B.QCSeq ) 
                                 JOIN KPXLS_TQCRequestItemAdd_PDI   AS C ON ( A.CompanySeq = C.CompanySeq AND A.ReqSeq = C.ReqSeq AND A.ReqSerl = C.ReqSerl ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND LEFT(B.TestDate,4) = @StdYear 
                     GROUP BY LEFT(B.TestDate,6)
                   ) AS Z
           ) AS Y ON ( 1 = 1 ) 
     WHERE Q.KindSeq = 6 
    -------------------------------------------------
    -- 특별검사(공정), END 
    -------------------------------------------------
    
    -- Row Total 
    INSERT INTO #Result ( KindName, KindSeq, Month1, Month2, Month3, Month4, Month5, Month6, Month7, Month8, Month9, Month10, Month11, Month12, Total ) 
    SELECT 'Total', 99, SUM(Month1), SUM(Month2), SUM(Month3), SUM(Month4), SUM(Month5), SUM(Month6), SUM(Month7), SUM(Month8), SUM(Month9), SUM(Month10), SUM(Month11), SUM(Month12), SUM(Total)
      FROM #Result 
    
    
    SELECT * FROM #Result 
    
    RETURN 
    
    
    -- 최종조회   
    
    
    RETURN  
    go
    exec KPXLS_SQCResMonthDataListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYear>2016</StdYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035746,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029436