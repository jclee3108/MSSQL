  
IF OBJECT_ID('KPX_SPDWasteSumAmtListQuery') IS NOT NULL   
    DROP PROC KPX_SPDWasteSumAmtListQuery  
GO  
  
-- v2014.12.22  
  
-- 폐기물 총비용-조회 by 이재천   
CREATE PROC KPX_SPDWasteSumAmtListQuery  
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
            @Cnt        INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FactUnit = ISNULL( FactUnit, 0 ),  
           @StdYM    = ISNULL( StdYM, '' )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit INT,   
            StdYM   NCHAR(6)  
           )  
    
    CREATE TABLE #tTPDWasteDairySum  
    (  
        ItemSeq     INT             ,  
        FactUnit    INT             ,  
        BaseDateYM  NCHAR(6)        ,  
        UseCount    DECIMAL(19, 5)  
    )  
    
    INSERT #tTPDWasteDairySum  
    SELECT UMWaste                      ,  
           FactUnit                     ,  
           LEFT(BaseDate, 6)            ,  
           SUM(ISNULL(A.Qty, 0))  
      FROM KPX_TPDWasteDaily AS A 
     WHERE 1=1  
       AND CompanySeq = @CompanySeq  
       AND FactUnit = @FactUnit  
       AND LEFT(BaseDate, 6) = @StdYM  
     GROUP BY UMWaste, FactUnit, LEFT(BaseDate, 6)  
    
    
    SELECT @Sql = '  SELECT A.ItemSeq AS ItemSeq, B.LastAmt, B.LastPirce, U.LastYMAmt, U.LastYMPrice' 
    
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
        SELECT @Sql = @Sql + 'Amt,0) AS ' + 'M' + CONVERT(NVARCHAR(5),@Cnt) 
        
        IF @Cnt = (SELECT CONVERT(INT,RIGHT(@StdYM,2)))
        BEGIN 
            BREAK 
        END 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 

    END 
    
    SELECT @Sql = @Sql + ' , Q.MinorName AS ItemName, X.UnitName
                            FROM #tTPDWasteDairySum               AS A 
                            LEFT OUTER JOIN _TDAUMinor      AS Q ON Q.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND A.ItemSeq = Q.MinorSeq  
                            LEFT OUTER JOIN _TDAUMinorValue AS W ON W.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND Q.MinorSeq = W.MinorSeq AND W.Serl = 1000001  
                            LEFT OUTER JOIN _TDAUnit        AS X ON X.CompanySeq = '+ CONVERT(NVARCHAR(5),@CompanySeq) + ' AND X.UnitSeq = W.ValueSeq
                            OUTER APPLY ( SELECT Z.Amt AS LastAmt, Z.Price AS LastPirce 
                                            FROM KPX_TPDWasteMonth AS Z 
                                           WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                             AND Z.UMWaste = A.ItemSeq 
                                             AND Z.FactUnit = A.FactUnit 
                                             AND CONVERT(NCHAR(6),DATEADD(YEAR, -1, A.BaseDateYM  + '''+ '01' +'''),112) = Z.YYMM
                                        ) AS B 
                            OUTER APPLY ( SELECT Z.Amt AS LastYMAmt, Z.Price AS LastYMPrice 
                                            FROM KPX_TPDWasteMonth AS Z 
                                           WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                             AND Z.UMWaste = A.ItemSeq 
                                             AND Z.FactUnit = A.FactUnit 
                                             AND CONVERT(NCHAR(6),DATEADD(MONTH, -1, A.BaseDateYM  + '''+ '01' +'''),112) = Z.YYMM
                                        ) AS U '   
    
    
    SELECT @Cnt = 1 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        SELECT @Sql = @Sql + 
                               ' OUTER APPLY ( SELECT Z.Amt
                                               FROM KPX_TPDWasteMonth AS Z 
                                              WHERE Z.CompanySeq = ' + CONVERT(NVARCHAR(5),@CompanySeq) +'
                                                AND Z.UMWaste = A.ItemSeq 
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
    
    -- SS1 조회 
    EXEC SP_EXECUTESQL @Sql 

      
    RETURN  
GO 
exec KPX_SPDWasteSumAmtListQuery @xmlDocument=N'<ROOT>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=1027011,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020614