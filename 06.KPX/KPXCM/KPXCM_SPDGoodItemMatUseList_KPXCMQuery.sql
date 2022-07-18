  
IF OBJECT_ID('KPXCM_SPDGoodItemMatUseList_KPXCMQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDGoodItemMatUseList_KPXCMQuery  
GO  
  
-- v2016.05.12  
  
-- [年]제품별원부원료사용현황-조회 by 이재천   
CREATE PROC KPXCM_SPDGoodItemMatUseList_KPXCMQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @StdYear        NCHAR(4), 
            @FactUnit       INT, 
            @GoodItemName   NVARCHAR(100), 
            @GoodItemNo     NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear         = ISNULL( StdYear      , '' ),  
           @FactUnit        = ISNULL( FactUnit     , 0 ),  
           @GoodItemName    = ISNULL( GoodItemName , '' ),  
           @GoodItemNo      = ISNULL( GoodItemNo   , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYear        NCHAR(4), 
            FactUnit       INT,       
            GoodItemName   NVARCHAR(100),      
            GoodItemNo     NVARCHAR(100)       
           )    
    
    CREATE TABLE #Result 
    (
        GoodItemName        NVARCHAR(100), 
        GoodItemNo          NVARCHAR(100), 
        GoodItemSeq         INT, 
        MatItemName         NVARCHAR(100), 
        MatItemNo           NVARCHAR(100), 
        MatItemSeq          INT, 
        Month01             DECIMAL(19,5), 
        Month02             DECIMAL(19,5), 
        Month03             DECIMAL(19,5), 
        Month04             DECIMAL(19,5),
        Month05             DECIMAL(19,5),
        Month06             DECIMAL(19,5),
        Month07             DECIMAL(19,5),
        Month08             DECIMAL(19,5),
        Month09             DECIMAL(19,5),
        Month10             DECIMAL(19,5),
        Month11             DECIMAL(19,5),
        Month12             DECIMAL(19,5),
        MonthSum            DECIMAL(19,5),
        Sort                INT 
    )
    
    
    
    
    
    SELECT LEFT(A.WorkDate,6) AS WorkYM, A.GoodItemSeq, A.StdUnitProdQty AS ProdQty, C.MatItemSeq, C.MatQty AS MatQty , A.WorkReportSeq 
      INTO #TPDSFCWorkReport
      FROM _TPDSFCWorkReport    AS A 
      LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = A.CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
                 JOIN (
                       SELECT Z.MatItemSeq, Z.WorkReportSeq, SUM(ISNULL(StdUnitQty,0)) AS MatQty 
                         FROM _TPDSFCMatinput AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                        GROUP BY Z.MatItemSeq, Z.WorkReportSeq 
                      ) AS C ON ( C.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WorkDate,4) = @StdYear 
       AND A.FactUnit = @FactUnit 
       AND ( @GoodItemName = '' OR B.ItemName LIKE '%' + @GoodItemName + '%' ) 
       AND ( @GoodItemNo = '' OR B.ItemNo LIKE '%' + @GoodItemNo + '%' ) 
       --AND A.WorkOrderSeq = 1569 4150 
       --AND A.GoodItemSeq = 817
     --GROUP BY LEFT(A.WorkDate,6), A.GoodItemSeq, C.MatItemSeq 
     ORDER BY WorkYM, GoodItemSeq, MatItemSeq
    
    -- 기본데이터 
    INSERT INTO #Result 
    (
        GoodItemName     , GoodItemNo       , GoodItemSeq      , MatItemName      , MatItemNo        , 
        MatItemSeq       , Month01          , Month02          , Month03          , Month04          , 
        Month05          , Month06          , Month07          , Month08          , Month09          , 
        Month10          , Month11          , Month12          , MonthSum         , Sort             
     )
    SELECT CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END AS GoodItemName, 
           B.ItemNo         AS GoodItemNo,
           A.GoodItemSeq    AS GoodItemSeq, -- 제품 코드 
            CASE WHEN (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END) = '' 
                THEN C.ItemName 
                ELSE (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END)
                END AS MatItemName, 
           C.ItemNo         AS MatItemNo, 
           A.MatItemSeq     AS MatItemSeq, -- 자재 코드 
           SUM(CASE WHEN A.WorkYM = @StdYear + '01' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month01, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '02' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month02, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '03' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month03, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '04' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month04, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '05' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month05, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '06' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month06, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '07' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month07, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '08' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month08, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '09' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month09, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '10' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month10, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '11' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month11, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '12' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month12,  
           SUM(ISNULL(A.MatQty,0)) AS MonthSum, 
           1 AS Sort 
      FROM #TPDSFCWorkReport    AS A 
      LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAItem  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.MatItemSeq ) 
     GROUP BY CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END, 
              B.ItemNo, 
              A.GoodItemSeq, 
              CASE WHEN (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END) = '' 
                THEN C.ItemName 
                ELSE (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END)
                END, 
              C.ItemNo, 
              A.MatItemSeq 
     ORDER BY GoodItemName, MatItemName
    
    

    -- TOTAL(KG) 
    INSERT INTO #Result 
    (
        GoodItemName     , GoodItemNo       , GoodItemSeq      , MatItemName      , MatItemNo        , 
        MatItemSeq       , Month01          , Month02          , Month03          , Month04          , 
        Month05          , Month06          , Month07          , Month08          , Month09          , 
        Month10          , Month11          , Month12          , MonthSum         , Sort             
     )
    SELECT CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END + ' TOTAL(KG)' AS GoodItemName, 
           '',
           A.GoodItemSeq, 
           '', 
           '', 
           999999997,
           SUM(CASE WHEN A.WorkYM = @StdYear + '01' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month01, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '02' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month02, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '03' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month03, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '04' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month04, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '05' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month05, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '06' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month06, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '07' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month07, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '08' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month08, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '09' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month09, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '10' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month10, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '11' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month11, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '12' THEN ISNULL(A.MatQty,0) ELSE 0 END) AS Month12,  
           SUM(ISNULL(A.MatQty,0)) AS MonthSum, 
           2 AS Sort 
      FROM #TPDSFCWorkReport    AS A 
      LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
     GROUP BY CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END, 
              B.ItemNo, 
              A.GoodItemSeq
     ORDER BY GoodItemName
    
    -- 생산량 
    INSERT INTO #Result 
    (
        GoodItemName     , GoodItemNo       , GoodItemSeq      , MatItemName      , MatItemNo        , 
        MatItemSeq       , Month01          , Month02          , Month03          , Month04          , 
        Month05          , Month06          , Month07          , Month08          , Month09          , 
        Month10          , Month11          , Month12          , MonthSum         , Sort             
     )
    SELECT CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END + ' 생산량(KG)' AS GoodItemName, 
           '',
           A.GoodItemSeq, 
           '', 
           '', 
           999999998,
           SUM(CASE WHEN A.WorkYM = @StdYear + '01' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month01, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '02' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month02, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '03' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month03, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '04' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month04, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '05' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month05, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '06' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month06, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '07' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month07, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '08' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month08, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '09' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month09, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '10' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month10, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '11' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month11, 
           SUM(CASE WHEN A.WorkYM = @StdYear + '12' THEN ISNULL(A.ProdQty,0) ELSE 0 END) AS Month12,  
           SUM(ISNULL(A.ProdQty,0)) AS MonthSum, 
           3 AS Sort 
      FROM ( 
            SELECT DISTINCT Z.WorkYM, Z.WorkReportSeq, Z.GoodItemSeq, Z.ProdQty 
              FROM #TPDSFCWorkReport AS Z 
           ) AS A 
      LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
     GROUP BY CASE WHEN (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END) = '' 
                THEN B.ItemName 
                ELSE (CASE WHEN ISNULL(B.ItemEngSName,'') = '' THEN ISNULL(B.ItemSName,'') ELSE ISNULL(B.ItemEngSName,'') END)
                END, 
              B.ItemNo, 
              A.GoodItemSeq
     ORDER BY GoodItemName
    
    -- 수율 
    INSERT INTO #Result 
    (
        GoodItemName     , GoodItemNo       , GoodItemSeq      , MatItemName      , MatItemNo        , 
        MatItemSeq       , Month01          , Month02          , Month03          , Month04          , 
        Month05          , Month06          , Month07          , Month08          , Month09          , 
        Month10          , Month11          , Month12          , MonthSum         , Sort             
     )
    SELECT CASE WHEN (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END) = '' 
                THEN C.ItemName 
                ELSE (CASE WHEN ISNULL(C.ItemEngSName,'') = '' THEN ISNULL(C.ItemSName,'') ELSE ISNULL(C.ItemEngSName,'') END)
                END + ' 수  율(%)' AS GoodItemName, 
           '',
           A.GoodItemSeq, 
           '', 
           '', 
           999999999,
           B.Month01 / NULLIF(ISNULL(A.Month01,0),0) * 100 AS Month01, 
           B.Month02 / NULLIF(ISNULL(A.Month02,0),0) * 100 AS Month02, 
           B.Month03 / NULLIF(ISNULL(A.Month03,0),0) * 100 AS Month03, 
           B.Month04 / NULLIF(ISNULL(A.Month04,0),0) * 100 AS Month04, 
           B.Month05 / NULLIF(ISNULL(A.Month05,0),0) * 100 AS Month05, 
           B.Month06 / NULLIF(ISNULL(A.Month06,0),0) * 100 AS Month06, 
           B.Month07 / NULLIF(ISNULL(A.Month07,0),0) * 100 AS Month07, 
           B.Month08 / NULLIF(ISNULL(A.Month08,0),0) * 100 AS Month08, 
           B.Month09 / NULLIF(ISNULL(A.Month09,0),0) * 100 AS Month09, 
           B.Month10 / NULLIF(ISNULL(A.Month10,0),0) * 100 AS Month10, 
           B.Month11 / NULLIF(ISNULL(A.Month11,0),0) * 100 AS Month11, 
           B.Month12 / NULLIF(ISNULL(A.Month12,0),0) * 100 AS Month12, 
           B.MonthSum / NULLIF(ISNULL(A.MonthSum,0),0) * 100 AS MonthSum, 
           4 AS Sort 
      FROM ( 
            SELECT GoodItemSeq, 
                   Month01, 
                   Month02, 
                   Month03, 
                   Month04, 
                   Month05, 
                   Month06, 
                   Month07, 
                   Month08, 
                   Month09, 
                   Month10, 
                   Month11, 
                   Month12, 
                   MonthSum 
              FROM #Result 
             WHERE Sort = 2 
           ) AS A 
      LEFT OUTER JOIN ( 
                        SELECT GoodItemSeq, 
                               Month01, 
                               Month02, 
                               Month03, 
                               Month04, 
                               Month05, 
                               Month06, 
                               Month07, 
                               Month08, 
                               Month09, 
                               Month10, 
                               Month11, 
                               Month12, 
                               MonthSum 
                          FROM #Result 
                         WHERE Sort = 3 
                      ) AS B ON ( B.GoodItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAItem AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq ) 
    
    
     
     
    SELECT GoodItemName     , GoodItemNo       , GoodItemSeq      , MatItemName      , MatItemNo        , 
           MatItemSeq       , Month01          , Month02          , Month03          , Month04          , 
           Month05          , Month06          , Month07          , Month08          , Month09          , 
           Month10          , Month11          , Month12          , MonthSum         , Sort     
      FROM #Result 
     ORDER BY GoodItemSeq, Sort, MatItemName
    
    
    RETURN  
GO
exec KPXCM_SPDGoodItemMatUseList_KPXCMQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>3</FactUnit>
    <StdYear>2016</StdYear>
    <GoodItemName />
    <GoodItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036993,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030321