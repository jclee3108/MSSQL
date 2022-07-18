  
IF OBJECT_ID('lumim_SPDMClassWorkReportQuery') IS NOT NULL   
    DROP PROC lumim_SPDMClassWorkReportQuery  
GO  
  
-- v2013.08.19  
  
-- 모델별생산실적조회_lumim(조회) by이재천   
CREATE PROC lumim_SPDMClassWorkReportQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @WorkTeamSeq    INT,  
            @WorkDateFr     NVARCHAR(8), 
            @WorkDateTo     NVARCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkTeamSeq = ISNULL(WorkTeamSeq, 0), 
           @WorkDateFr  = ISNULL(WorkDateFr, ''), 
           @WorkDateTo  = ISNULL(WorkDateTo, '')  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkTeamSeq    INT,  
            WorkDateFr     NVARCHAR(8),
            WorkDateTo     NVARCHAR(8) 
           )    
    
    -- 헤더부
    CREATE TABLE #Title
    (
     ColIdx     INT IDENTITY(0, 1), 
     Title      NVARCHAR(100), 
     TitleSeq   INT
    )
    
    INSERT INTO #Title(Title, TitleSeq)
    SELECT A.ProcName, A.ProcSeq
      FROM _TPDBaseProcess AS A WITH(NOLOCK)
      JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ValueSeq = A.ProcSeq AND MajorSeq = 1008383 )  
      JOIN _TDAUMinor AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 

     ORDER BY C.MinorSort
    
    SELECT * FROM #Title
    
    -- 고정행
    
    CREATE TABLE #FixCol
    (
     RowIdx     INT IDENTITY(0, 1), 
     ModelName  NVARCHAR(100), 
     ModelSeq   INT
    )
    
    INSERT INTO #FixCol (ModelName, ModelSeq)
    SELECT CASE WHEN ISNULL(R.ValueSeq,0) = 0 THEN ''     
                ELSE ( SELECT ISNULL(MinorName,'')       
                         FROM _TDAUMinor WITH(NOLOCK)       
                        WHERE CompanySeq = @CompanySeq AND MinorSeq = R.ValueSeq ) END,  -- 품목중분류 
           R.ValueSeq -- 품목중분류코드 
      FROM _TPDSFCWorkReport AS A
      JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq 
                                       AND C.AssetSeq = (
                                                         SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1
                                                        ) 
                                         )   
      LEFT OUTER JOIN _TDAItemClass        AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.ItemSeq = C.ItemSeq AND P.UMajorItemClass = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor           AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MajorSeq = LEFT( P.UMItemClass, 4 ) AND P.UMItemClass = Q.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue      AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MajorSeq = 2001 AND R.MinorSeq = Q.MinorSeq AND R.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo 
       AND A.WorkTimeGroup = @WorkTeamSeq 
     GROUP BY R.ValueSeq
     ORDER BY R.ValueSeq
    
    SELECT * FROM #FixCol
    
    -- 가변행
    
    CREATE TABLE #Value
    (
     Qty            DECIMAL(19, 5), 
     ProcSeq        INT, 
     ModelSeq       INT
    )
    
    INSERT INTO #Value (Qty, ProcSeq, ModelSeq) 
    SELECT SUM(A.ProdQty), MAX(A.ProcSeq), R.ValueSeq
      FROM _TPDSFCWorkReport AS A
      JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq 
                                       AND C.AssetSeq = (
                                                         SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1
                                                        ) 
                                         )   
      LEFT OUTER JOIN _TDAItemClass        AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.ItemSeq = C.ItemSeq AND P.UMajorItemClass = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor           AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MajorSeq = LEFT( P.UMItemClass, 4 ) AND P.UMItemClass = Q.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue      AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MajorSeq = 2001 AND R.MinorSeq = Q.MinorSeq AND R.Serl = 1001 ) 
      
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo 
       AND A.WorkTimeGroup = @WorkTeamSeq 
     GROUP BY R.ValueSeq, A.ProcSeq
    
    SELECT B.RowIdx, A.ColIdx, C.Qty AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.ProcSeq ) 
      JOIN #FixCol AS B ON ( B.ModelSeq = C.ModelSeq ) 
     ORDER BY A.ColIdx, B.RowIdx

    RETURN  
GO
exec lumim_SPDMClassWorkReportQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkDateFr>20130701</WorkDateFr>
    <WorkDateTo>20130830</WorkDateTo>
    <WorkTeamSeq>6017001</WorkTeamSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017192,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014710