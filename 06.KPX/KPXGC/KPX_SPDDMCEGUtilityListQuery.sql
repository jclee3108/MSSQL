  
IF OBJECT_ID('KPX_SPDDMCEGUtilityListQuery') IS NOT NULL   
    DROP PROC KPX_SPDDMCEGUtilityListQuery  
GO  
  
-- v2014.12.22  
  
-- DMC,EG Utility-조회 by 이재천   
CREATE PROC KPX_SPDDMCEGUtilityListQuery  
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
            @FactUnit   INT, 
            @StdYM      NCHAR(6), 
            @Sql        NVARCHAR(MAX), 
            @Sql2       NVARCHAR(MAX), 
            @Sql3       NVARCHAR(MAX), 
            @Cnt        INT, 
            @ProdQty    DECIMAL(19,5) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit = ISNULL( FactUnit, 0 ),  
           @StdYM    = ISNULL( StdYM, '' )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit INT,   
            StdYM   NCHAR(6)  
           )    
    
    
    CREATE TABLE #tTPDUtilityDairySum  
    (  
        ItemSeq     INT             ,  
        FactUnit    INT             ,  
        BaseDateYM  NCHAR(6)        ,  
        UseCount    DECIMAL(19, 5)  
    )  
  
    INSERT #tTPDUtilityDairySum  
    SELECT ItemSeq                      ,  
           FactUnit                     ,  
           LEFT(BaseDate, 6)            ,  
           SUM(ISNULL(UseCount, 0))  
      FROM KPX_TPDUtilityDairy  
     WHERE 1=1  
       AND CompanySeq = @CompanySeq  
       AND FactUnit = @FactUnit  
       AND LEFT(BaseDate, 6) = @StdYM  
     GROUP BY ItemSeq, FactUnit, LEFT(BaseDate, 6)  
    
    CREATE TABLE #ProdQty 
    (
        WorkDate    NVARCHAR(6), 
        ProdQty     DECIMAL(19,5) 
    )
    INSERT INTO #ProdQty ( WorkDate, ProdQty ) 
    SELECT LEFT(WorkDate,6) AS WorkDate, SUM(ProdQty) AS ProdQty 
      FROM _TPDSFCWorkReport 
     WHERE CompanySeq = @CompanySeq
       AND FactUnit = @FactUnit 
       AND LEFT(WorkDate,4) = LEFT(@StdYM,4) 
     GROUP BY LEFT(WorkDate,6) 
    
    INSERT INTO #ProdQty ( WorkDate, ProdQty )  
    SELECT LEFT(WorkDate,6), SUM(ProdQty) AS ProdQty 
      FROM _TPDSFCWorkReport 
     WHERE CompanySeq = @CompanySeq 
       AND FactUnit = @FactUnit 
       AND LEFT(WorkDate,6) = CONVERT(NCHAR(6),DATEADD(Year, -1, @StdYM + '01'),112)
     GROUP BY LEFT(WorkDate,6) 
    
    INSERT INTO #ProdQty ( WorkDate, ProdQty )  
    SELECT LEFT(WorkDate,4), SUM(ProdQty) AS ProdQty 
      FROM _TPDSFCWorkReport 
     WHERE CompanySeq = @CompanySeq 
       AND FactUnit = @FactUnit 
       AND LEFT(WorkDate,4) = LEFT(@StdYM,4) 
     GROUP BY LEFT(WorkDate,4)
    
    -----------------------------------------------------------
    -- SS1 
    -----------------------------------------------------------
    
    SELECT @Sql = '  SELECT A.ItemSeq AS ItemSeq, ISNULL(B.UseCount,0) AS LastYM' 
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @Sql = @Sql + ',' + CASE WHEN @Cnt = 1 THEN ' ISNULL(C.'
                                        WHEN @Cnt = 2 THEN ' ISNULL(D.'
                                        WHEN @Cnt = 3 THEN ' ISNULL(E.'
                                        WHEN @Cnt = 4 THEN ' ISNULL(F.'
                                        WHEN @Cnt = 5 THEN ' ISNULL(G.'
                                        WHEN @Cnt = 6 THEN ' ISNULL(H.'
                                        WHEN @Cnt = 7 THEN ' ISNULL(I.'
                                        WHEN @Cnt = 8 THEN ' ISNULL(J.'
                                        WHEN @Cnt = 9 THEN ' ISNULL(K.'
                                        WHEN @Cnt = 10 THEN ' ISNULL(L.'
                                        WHEN @Cnt = 11 THEN ' ISNULL(M.'
                                        WHEN @Cnt = 12 THEN ' ISNULL(N.'
                                        END 
        SELECT @Sql = @Sql + 'UseCount,0) AS ' + 'M' + CONVERT(NVARCHAR(5),@Cnt) 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 

    END 
    
    SELECT @Sql = @Sql + ' ,ISNULL(O.SumYear,0) AS SumYear, Q.ItemName AS ItemName, W.UnitName
                            FROM #tTPDUtilityDairySum             AS A 
                            LEFT OUTER JOIN _TDAItem              AS Q ON ( Q.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND Q.ItemSeq = A.ItemSeq ) 
                            LEFT OUTER JOIN _TDAUnit              AS W ON ( W.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND W.UnitSeq = Q.UnitSeq ) 
                            OUTER APPLY ( SELECT Z.UseCount
                                            FROM KPX_TPDUtilityMonth AS Z 
                                           WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                             AND Z.ItemSeq = A.ItemSeq 
                                             AND Z.FactUnit = A.FactUnit 
                                             AND CONVERT(NCHAR(6),DATEADD(YEAR, -1, A.BaseDateYM  + '''+ '01' +'''),112) = Z.YYMM 
                                        ) AS B' 
                               
    
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        SELECT @Sql = @Sql + 
                               ' OUTER APPLY ( SELECT Z.UseCount
                                               FROM KPX_TPDUtilityMonth AS Z 
                                              WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                                AND Z.ItemSeq = A.ItemSeq 
                                                AND Z.FactUnit = A.FactUnit 
                                                AND LEFT(A.BaseDateYM ,4) + '+ '''' +RIGHT('0' + CONVERT(NVARCHAR(5),@Cnt),2) + '''' +' = Z.YYMM
                                            ) AS ' + CASE WHEN @Cnt = 1 THEN 'C'
                                                          WHEN @Cnt = 2 THEN 'D'
                                                          WHEN @Cnt = 3 THEN 'E'
                                                          WHEN @Cnt = 4 THEN 'F'
                                                          WHEN @Cnt = 5 THEN 'G'
                                                          WHEN @Cnt = 6 THEN 'H'
                                                          WHEN @Cnt = 7 THEN 'I'
                                                          WHEN @Cnt = 8 THEN 'J'
                                                          WHEN @Cnt = 9 THEN 'K'
                                                          WHEN @Cnt = 10 THEN 'L'
                                                          WHEN @Cnt = 11 THEN 'M'
                                                          WHEN @Cnt = 12 THEN 'N'
                                                          END 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
    
    SELECT @Sql = @Sql + 
                        ' OUTER APPLY ( SELECT SUM(ISNULL(Z.UseCount,0)) AS SumYear
                                          FROM KPX_TPDUtilityMonth AS Z 
                                         WHERE Z.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) +' 
                                           AND Z.ItemSeq = A.ItemSeq 
                                           AND Z.FactUnit = A.FactUnit 
                                           AND LEFT(Z.YYMM,4) = LEFT(+' + @StdYM + ',4) 
                                      ) AS O ' 
    
    -- SS1 조회 
    EXEC SP_EXECUTESQL @Sql 
    
    -----------------------------------------------------------
    -- SS2 
    -----------------------------------------------------------
    SELECT @Sql2 = '  SELECT A.ItemSeq AS ItemSeq, ISNULL(B.UseCount,0) AS LastYM' 
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @Sql2 = @Sql2 + ',' + CASE WHEN @Cnt = 1 THEN ' ISNULL(C.'
                                        WHEN @Cnt = 2 THEN ' ISNULL(D.'
                                        WHEN @Cnt = 3 THEN ' ISNULL(E.'
                                        WHEN @Cnt = 4 THEN ' ISNULL(F.'
                                        WHEN @Cnt = 5 THEN ' ISNULL(G.'
                                        WHEN @Cnt = 6 THEN ' ISNULL(H.'
                                        WHEN @Cnt = 7 THEN ' ISNULL(I.'
                                        WHEN @Cnt = 8 THEN ' ISNULL(J.'
                                        WHEN @Cnt = 9 THEN ' ISNULL(K.'
                                        WHEN @Cnt = 10 THEN ' ISNULL(L.'
                                        WHEN @Cnt = 11 THEN ' ISNULL(M.'
                                        WHEN @Cnt = 12 THEN ' ISNULL(N.'
                                        END 
        SELECT @Sql2 = @Sql2 + 'UseCount,0) AS ' + 'M' + CONVERT(NVARCHAR(5),@Cnt) 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 

    END 
    
    SELECT @Sql2 = @Sql2 + ' ,ISNULL(O.SumYear,0) AS SumYear, Q.ItemName AS ItemName, W.UnitName
                            FROM #tTPDUtilityDairySum             AS A 
                            LEFT OUTER JOIN _TDAItem              AS Q ON ( Q.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND Q.ItemSeq = A.ItemSeq ) 
                            LEFT OUTER JOIN _TDAUnit              AS W ON ( W.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND W.UnitSeq = Q.UnitSeq ) 
                            OUTER APPLY ( SELECT CASE WHEN ISNULL(Y.ProdQty,0) = 0 THEN 0 ELSE Z.UseCount / Y.ProdQty END AS UseCount
                                            FROM KPX_TPDUtilityMonth AS Z 
                                            LEFT OUTER JOIN #ProdQty AS Y ON ( Y.WorkDate = Z.YYMM ) 
                                           WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                             AND Z.ItemSeq = A.ItemSeq 
                                             AND Z.FactUnit = A.FactUnit 
                                             AND CONVERT(NCHAR(6),DATEADD(YEAR, -1, A.BaseDateYM + '''+ '01' +'''),112) = Z.YYMM 
                                        ) AS B' 
                               
    
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        SELECT @Sql2 = @Sql2 + 
                               ' OUTER APPLY ( SELECT CASE WHEN ISNULL(Y.ProdQty,0) = 0 THEN 0 ELSE Z.UseCount / Y.ProdQty END AS UseCount
                                               FROM KPX_TPDUtilityMonth AS Z 
                                               LEFT OUTER JOIN #ProdQty AS Y ON ( Y.WorkDate = LEFT(Z.YYMM,4) + '+ '''' +RIGHT('0' + CONVERT(NVARCHAR(5),@Cnt),2) + '''' +' ) 
                                              WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                                AND Z.ItemSeq = A.ItemSeq 
                                                AND Z.FactUnit = A.FactUnit 
                                                AND LEFT( A.BaseDateYM ,4) + '+ '''' +RIGHT('0' + CONVERT(NVARCHAR(5),@Cnt),2) + '''' +' = Z.YYMM
                                            ) AS ' + CASE WHEN @Cnt = 1 THEN 'C'
                                                          WHEN @Cnt = 2 THEN 'D'
                                                          WHEN @Cnt = 3 THEN 'E'
                                                          WHEN @Cnt = 4 THEN 'F'
                                                          WHEN @Cnt = 5 THEN 'G'
                                                          WHEN @Cnt = 6 THEN 'H'
                                                          WHEN @Cnt = 7 THEN 'I'
                                                          WHEN @Cnt = 8 THEN 'J'
                                                          WHEN @Cnt = 9 THEN 'K'
                                                          WHEN @Cnt = 10 THEN 'L'
                                                          WHEN @Cnt = 11 THEN 'M'
                                                          WHEN @Cnt = 12 THEN 'N'
                                                          END 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
    
    SELECT @Sql2 = @Sql2 + 
                        ' OUTER APPLY ( SELECT CASE WHEN ISNULL(MAX(Y.ProdQty),0) = 0 THEN 0 ELSE SUM(ISNULL(Z.UseCount,0)) / MAX(Y.ProdQty) END AS SumYear
                                          FROM KPX_TPDUtilityMonth AS Z 
                                          LEFT OUTER JOIN #ProdQty AS Y ON ( Y.WorkDate = LEFT(Z.YYMM,4) ) 
                                         WHERE Z.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) +' 
                                           AND Z.ItemSeq = A.ItemSeq 
                                           AND Z.FactUnit = A.FactUnit 
                                           AND LEFT(Z.YYMM,4) = LEFT(+' + @StdYM + ',4) 
                                      ) AS O ' 
    -- SS2 조회 
    EXEC SP_EXECUTESQL @Sql2 
    
    
    -----------------------------------------------------------
    -- SS3 
    -----------------------------------------------------------
    SELECT @Sql3 = '  SELECT A.ItemSeq AS ItemSeq, ISNULL(B.Amt,0) AS LastYM' 
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @Sql3 = @Sql3 + ',' + CASE WHEN @Cnt = 1 THEN ' ISNULL(C.'
                                        WHEN @Cnt = 2 THEN ' ISNULL(D.'
                                        WHEN @Cnt = 3 THEN ' ISNULL(E.'
                                        WHEN @Cnt = 4 THEN ' ISNULL(F.'
                                        WHEN @Cnt = 5 THEN ' ISNULL(G.'
                                        WHEN @Cnt = 6 THEN ' ISNULL(H.'
                                        WHEN @Cnt = 7 THEN ' ISNULL(I.'
                                        WHEN @Cnt = 8 THEN ' ISNULL(J.'
                                        WHEN @Cnt = 9 THEN ' ISNULL(K.'
                                        WHEN @Cnt = 10 THEN ' ISNULL(L.'
                                        WHEN @Cnt = 11 THEN ' ISNULL(M.'
                                        WHEN @Cnt = 12 THEN ' ISNULL(N.'
                                        END 
        SELECT @Sql3 = @Sql3 + 'Amt,0) AS ' + 'M' + CONVERT(NVARCHAR(5),@Cnt) 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 

    END 
    
    SELECT @Sql3 = @Sql3 + ' ,ISNULL(O.SumYear,0) AS SumYear, Q.ItemName AS ItemName, W.UnitName
                            FROM #tTPDUtilityDairySum             AS A 
                            LEFT OUTER JOIN _TDAItem              AS Q ON ( Q.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND Q.ItemSeq = A.ItemSeq ) 
                            LEFT OUTER JOIN _TDAUnit              AS W ON ( W.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND W.UnitSeq = Q.UnitSeq ) 
                            OUTER APPLY ( SELECT Z.Amt
                                            FROM KPX_TPDUtilityMonth AS Z 
                                           WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                             AND Z.ItemSeq = A.ItemSeq 
                                             AND Z.FactUnit = A.FactUnit 
                                             AND CONVERT(NCHAR(6),DATEADD(YEAR, -1, A.BaseDateYM  + '''+ '01' +'''),112) = Z.YYMM 
                                        ) AS B' 
                               
    
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        SELECT @Sql3 = @Sql3 + 
                               ' OUTER APPLY ( SELECT Z.Amt 
                                               FROM KPX_TPDUtilityMonth AS Z 
                                              WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                                AND Z.ItemSeq = A.ItemSeq 
                                                AND Z.FactUnit = A.FactUnit 
                                                AND LEFT(A.BaseDateYM ,4) + '+ '''' +RIGHT('0' + CONVERT(NVARCHAR(5),@Cnt),2) + '''' +' = Z.YYMM
                                            ) AS ' + CASE WHEN @Cnt = 1 THEN 'C'
                                                          WHEN @Cnt = 2 THEN 'D'
                                                          WHEN @Cnt = 3 THEN 'E'
                                                          WHEN @Cnt = 4 THEN 'F'
                                                          WHEN @Cnt = 5 THEN 'G'
                                                          WHEN @Cnt = 6 THEN 'H'
                                                          WHEN @Cnt = 7 THEN 'I'
                                                          WHEN @Cnt = 8 THEN 'J'
                                                          WHEN @Cnt = 9 THEN 'K'
                                                          WHEN @Cnt = 10 THEN 'L'
                                                          WHEN @Cnt = 11 THEN 'M'
                                                          WHEN @Cnt = 12 THEN 'N'
                                                          END 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
    
    SELECT @Sql3 = @Sql3 + 
                        ' OUTER APPLY ( SELECT AVG(ISNULL(Z.Amt,0)) AS SumYear
                                          FROM KPX_TPDUtilityMonth AS Z 
                                         WHERE Z.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) +' 
                                           AND Z.ItemSeq = A.ItemSeq 
                                           AND Z.FactUnit = A.FactUnit 
                                           AND LEFT(Z.YYMM,4) = LEFT(+' + @StdYM + ',4) 
                                      ) AS O ' 
    -- SS3 조회 
    EXEC SP_EXECUTESQL @Sql3 
    
    
    RETURN  
GO 
EXEC KPX_SPDDMCEGUtilityListQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <StdYM>201411</StdYM>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1026989, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1020608
