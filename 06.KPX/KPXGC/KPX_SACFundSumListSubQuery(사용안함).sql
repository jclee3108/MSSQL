 
IF OBJECT_ID('KPX_SACFundSumListSubQuery') IS NOT NULL 
   DROP PROC KPX_SACFundSumListSubQuery
GO   
-- v2015.06.19
  
-- 상품운용명세서(Sub)-조회 by 이재천   
CREATE PROC KPX_SACFundSumListSubQuery  
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
            @StdDate            NCHAR(8), 
            @UMHelpCom          INT, 
            @UMBond             INT, 
            @SubStdDate         NCHAR(8), 
            @MultiUMHelpCom     NVARCHAR(MAX), 
            @FundName           NVARCHAR(100)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @StdDate     = ISNULL( StdDate, '' ),  
           @UMHelpCom   = ISNULL( UMHelpCom, 0 ), 
           @UMBond      = ISNULL( UMBond, 0 ), 
           @SubStdDate  = ISNULL( SubStdDate, '' ), 
           @MultiUMHelpCom = ISNULL ( MultiUMHelpCom, ''), 
           @FundName    = ISNULL( FundName , '') 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate             NCHAR(8), 
            UMHelpCom           INT, 
            UMBond              INT, 
            SubStdDate          NCHAR(8), 
            MultiUMHelpCom      NVARCHAR(MAX), 
            FundName            NVARCHAR(100)
           )    
    
    --select * from _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom)  
    
    --return 
    
    -- 기본데이터     
    SELECT --*  
           ROW_NUMBER() OVER(Order BY A.FundSeq) AS IDX_NO, 
           A.FundSeq,     
           B.FundName,     
           A.StdDate AS StdDate,     
           A.UMHelpCom,     
           ISNULL(AddAmt,0) AS AddAmt,     
           SrtDate AS SrtDate,     
           B.UMBond AS UMBond,     
           B.TitileName AS TitileName,     
           B.FundKindM AS FundKindM,     
           B.FundKindS AS FundKindS,     
           ISNULL(A.ActAmt,0) AS ActAmt,     
           ISNULL(A.PrevAmt,0) AS PrevAmt,     
           ISNULL(A.InvestAmt,0) AS InvestAmt,     
           ISNULL(A.TestAmt,0) AS TestAmt,   
           A.SliptAmt AS SliptAmt,   
           A.ResultReAmt AS ResultReAmt, 
           A.SplitDate, 
           A.ResultReDate   
           
      INTO #BaseData  
      FROM KPX_TACEvalProfitItemMaster               AS A   
      LEFT OUTER JOIN KPX_TACFundMaster             AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq )   
      OUTER APPLY (SELECT MAX(Z.AllCancelDate) AS AllCancelDate, SUM(Z.CancelAmt) AS CancelAmt  
                     FROM KPX_TACResultProfitItemMaster AS Z   
                    WHERE Z.CompanySeq = A.CompanySeq   
                      AND Z.AllCancelDate <= @StdDate   
                      AND Z.FundSeq = A.FundSeq   
                      AND Z.UMHelpCom = A.UMHelpCom   
                  ) AS C   
      OUTER APPLY (SELECT SUM(Z.CancelAmt) AS CancelAmt  
                     FROM KPX_TACResultProfitItemMaster AS Z   
                    WHERE Z.CompanySeq = A.CompanySeq   
                      AND Z.CancelDate BETWEEN @SubStdDate AND @StdDate   
                      AND Z.FundSeq = A.FundSeq   
                      AND Z.UMHelpCom = A.UMHelpCom   
                  ) AS D   
                 JOIN _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS E ON ( E.Code = A.UMHelpCom ) 
     WHERE A.StdDate <= @StdDate   
       AND ISNULL(C.AllCancelDate,'') = ''   
       AND (@UMBond = 0 OR B.UMBond = @UMBond)   
       AND (@FundName = '' OR B.FundName LIKE @FundName + '%')
    
    
    CREATE TABLE #Result_Sub 
    (
        FundName        NVARCHAR(100), 
        FundSeq         INT, 
        ActAmt          DECIMAL(19,5), 
        PrevAmt         DECIMAL(19,5), 
        InvestAmt       DECIMAL(19,5), 
        LYTestAmt       DECIMAL(19,5), 
        SumSliptAmt     DECIMAL(19,5), 
        SliptAmt        DECIMAL(19,5), 
        SumResultReAmt  DECIMAL(19,5), 
        ResultReAmt     DECIMAL(19,5), 
        TestAmt         DECIMAL(19,5), 
        TitileName      NVARCHAR(100), 
        UMBond          INT, 
        FundKindSName   NVARCHAR(100), 
        FundKindMName   NVARCHAR(100),  
        FundKindLName   NVARCHAR(100), 
        FundKindName    NVARCHAR(100), 
        UMBondName      NVARCHAR(100), 
        SrtDate         NCHAR(8), 
        AddAmt          DECIMAL(19,5), 
        SumResultAmt    DECIMAL(19,5), 
        ResultAmt       DECIMAL(19,5), 
        SumProfitRate   DECIMAL(19,5), 
        ChProfitRate    DECIMAL(19,5), 
        PeProfitRate    DECIMAL(19,5), 
        FundKindSeq     INT, 
        FundKindSSeq    INT, 
        UMHelpCom       INT 
     )
    
    INSERT INTO #Result_Sub
    (
        FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       , 
        SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,
        TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   , 
        FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     , 
        FundKindSSeq    , FundSeq         , UMHelpCom 
    ) 
    SELECT A.FundName,   
           R.ActAmt, --(Q.ActAmt * (Q.InvestAmt - Q.CanCelAmt)) / Q.InvestAmt AS ActAmt,   
           R.PrevAmt, --(Q.PrevAmt * (Q.InvestAmt - Q.CanCelAmt)) / Q.InvestAmt AS PrevAmt,   
           R.InvestAmt,  --Q.InvestAmt - Q.CanCelAmt AS InvestAmt,   
           (B.LYTestAmt * R.InvestAmt) / Q.InvestAmt AS LYTestAmt,  --(ISNULL(B.LYTestAmt,0) * (Q.InvestAmt - Q.CanCelAmt)) / Q.InvestAmt AS LYTestAmt,   
           0, 
           0, 
           0, 
           0,
           R.TestAmt,  --(R.TestAmt * (Q.InvestAmt - Q.CanCelAmt)) / Q.InvestAmt AS TestAmt,   
           A.TitileName,   
           A.UMBond,   
           E.MinorName AS FundKindSName,   
           F.MinorName AS FundKindMName,   
           H.MinorName AS FundKindLName,   
           J.MinorName AS FundKindName,   
           M.MinorName AS UMBondName, -- 시세/채권 구분   
             
             
           Q.SrtDate,   
           Q.AddAmt,   
           J.MinorSeq AS FundKindSeq,   
           E.MinorSeq AS FundKindSSeq, 
           A.FundSeq, 
           A.UMHelpCom 
      
      FROM (  
              SELECT DISTINCT FundName, FundSeq, UMHelpCom, FundKindS, FundKindM, UMBond, TitileName -- , SliptAmt , ResultReAmt, SumSliptAmt, SumResultReAmt  
              FROM #BaseData   
           )AS A   
      OUTER APPLY ( SELECT TestAmt AS LYTestAmt   
                      FROM #BaseData AS Z   
                     WHERE Z.StdDate = @SubStdDate    
                       AND Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS B   
      OUTER APPLY ( SELECT SUM(SliptAmt) AS SumSliptAmt   
                      FROM #BaseData AS Z   
                     WHERE Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                       AND Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS C   
      OUTER APPLY ( SELECT SUM(SliptAmt) AS SliptAmt   
                      FROM #BaseData AS Z   
                     WHERE Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS D   
      OUTER APPLY ( SELECT SUM(ResultReAmt) AS SumResultReAmt  
                      FROM #BaseData AS Z   
                     WHERE Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                       AND Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS O    
      OUTER APPLY ( SELECT SUM(ResultReAmt) AS ResultReAmt   
                    FROM #BaseData AS Z   
                     WHERE Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS P   
      OUTER APPLY ( SELECT Z.TestAmt, Z.ActAmt, Z.PrevAmt, Z.InvestAmt, Z.AddAmt, Z.SrtDate  
                      FROM #BaseData AS Z   
                     WHERE Z.StdDate = @SubStdDate   
                       AND Z.FundSeq = A.FundSeq   
                       AND Z.UMHelpCom = A.UMHelpCom  
                  ) AS Q   
      OUTER APPLY ( SELECT Z.TestAmt, Z.ActAmt, Z.PrevAmt, Z.InvestAmt, Z.AddAmt, Z.SrtDate  
                      FROM #BaseData AS Z     
                     WHERE Z.StdDate = @StdDate     
                         AND Z.FundSeq = A.FundSeq     
                       AND Z.UMHelpCom = A.UMHelpCom    
                  ) AS R       
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.FundKindS )   
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.FundKindM )   
      LEFT OUTER JOIN _TDAUMinorValue   AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 )   
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.ValueSeq )   
      LEFT OUTER JOIN _TDAUMinorValue   AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.MinorSeq AND I.Serl = 1000002 )   
      LEFT OUTER JOIN _TDAUMinor        AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = I.ValueSeq )   
      LEFT OUTER JOIN _TDAUMinor        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMBond )    
     ORDER BY A.FundSeq   
    
    
    IF NOT EXISTS (SELECT 1 FROM #Result_Sub) 
    BEGIN
        
        SELECT * FROM #Result_Sub ORDER BY UMBond, FundName   
          
        RETURN    
        
    END 
    
    CREATE TABLE #FundSeq 
    ( 
        Cnt     INT IDENTITY, 
        FundSeq INT
    ) 
        
    INSERT INTO #FundSeq (FundSeq) 
    SELECT A.FundSeq 
      FROM (SELECT DISTINCT FundSeq 
              FROM #BaseData 
           ) AS A 
     
    
    
    CREATE TABLE #BaseData_Sub 
    (
        IDX_NO      INT IDENTITY, 
        FundSeq     INT, 
        FundName    NVARCHAR(100), 
        StdDate     NCHAR(8), 
        UMHelpCom   INT, 
        AddAmt      DECIMAL(19,5), 
        SrtDate     NCHAR(8), 
        UMBond      INT, 
        TitileName  NVARCHAR(100), 
        FundKindM   INT, 
        FundKindS   INT, 
        ActAmt      DECIMAL(19,5), 
        PrevAmt     DECIMAL(19,5), 
        InvestAmt   DECIMAL(19,5), 
        TestAmt     DECIMAL(19,5),  
        SliptAmt    DECIMAL(19,5),  
        ResultReAmt DECIMAL(19,5),  
        SplitDate   NCHAR(8), 
        ResultReDate NCHAR(8) 
    ) 
    
    CREATE TABLE #Table 
    (
        InvestAmt       DECIMAL(19,5), 
        SrtDate         NCHAR(8), 
        EndDate         NCHAR(8), 
        SplitDate       NCHAR(8), 
        SliptAmt        DECIMAL(19,5), 
        ResultInvestAmt DECIMAL(19,5),  
        FundSeq         INT 
    )
    
    CREATE TABLE #Table2 
    (
        InvestAmt       DECIMAL(19,5), 
        SrtDate         NCHAR(8), 
        EndDate         NCHAR(8), 
        ResultReDate    NCHAR(8), 
        ResultReAmt     DECIMAL(19,5), 
        ResultInvestAmt DECIMAL(19,5),  
        FundSeq         INT 
    )
    
    DECLARE @Cnt                INT, 
            @CancelResultAmt    DECIMAL(19,5), 
            @InvestAmt          DECIMAL(19,5), 
            @ResultInvestAmt    DECIMAL(19,5), 
            @MainCnt INT 
    
    SELECT @MainCnt = 1 
    
      --return     
    WHILE ( 1 = 1 ) 
    BEGIN  
        
        TRUNCATE TABLE #Table 
        TRUNCATE TABLE #Table2 
        TRUNCATE TABLE #BaseData_Sub 
        
        INSERT INTO #BaseData_Sub 
        SELECT FundSeq     ,
     FundName    ,
               StdDate     ,
               UMHelpCom   ,
               AddAmt      ,
               SrtDate     ,
               UMBond      ,
               TitileName  ,
               FundKindM   ,
               FundKindS   ,
               ActAmt      ,
               PrevAmt     ,
          InvestAmt   ,
               TestAmt     ,
               SliptAmt    ,
               ResultReAmt ,
               SplitDate   ,
               ResultReDate
          FROM #BaseData 
         WHERE FundSeq = (SELECT FundSeq FROM #FundSeq WHERE Cnt = @MainCnt) 
         --select * from #BaseData_Sub where idx_no = 1 
        --        select * from #BaseData_Sub where idx_no = 2 
                
        --        return 
    
         ---------------------------------------------------------------------------------------------------------
        -- 배당금액 계산 
        --------------------------------------------------------------------------------------------------------- 
        
        SELECT @Cnt = 1, 
               @CancelResultAmt = 0, 
               @InvestAmt = 0 
         
        SELECT @ResultInvestAmt = InvestAmt 
          FROM #BaseData_Sub 
        WHERE StdDate = @StdDate 
        
         WHILE( 1 = 1 ) 
         BEGIN
             
             SELECT @InvestAmt = A.InvestAmt
               FROM #BaseData_Sub AS A 
              WHERE A.IDX_NO = 1
            
            
            
            INSERT INTO #Table ( InvestAmt, SrtDate, EndDate, SplitDate, SliptAmt, ResultInvestAmt, FundSeq ) 
            SELECT @InvestAmt - ISNULL(@CancelResultAmt,0), '', '', A.SplitDate, A.SliptAmt, @ResultInvestAmt, A.FundSeq 
              FROM #BaseData_Sub AS A 
              LEFT OUTER JOIN #BaseData_Sub                     AS B ON ( B.FundSeq = A.FundSeq AND B.IDX_NO = @Cnt + 1 )
              LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS C ON ( C.CompanySeq = @CompanySeq AND C.FundSeq = A.FundSeq AND C.SplitDate BETWEEN A.StdDate AND B.StdDate ) 
             WHERE A.IDX_NO = @Cnt 
             --AND (A.StdDate <> ISNULL(C.CancelDate  ,''))
               AND A.SplitDate <> '' 
            
            SELECT @CancelResultAmt = SUM(ISNULL(C.CancelAmt,0))
              FROM #BaseData_Sub AS A 
              LEFT OUTER JOIN #BaseData_Sub                     AS B ON ( B.FundSeq = A.FundSeq AND B.IDX_NO = @Cnt + 1 )
              LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS C ON ( C.CompanySeq = @CompanySeq AND C.FundSeq = A.FundSeq AND C.CancelDate <= B.StdDate ) 
             WHERE A.IDX_NO = @Cnt 
             --AND (A.StdDate <> ISNULL(C.CancelDate  ,''))
              AND ISNULL(C.CancelDate,'') <> '' 
               
            
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #BaseData_Sub) 
            BEGIN
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
             
         END 
        
        
         UPDATE A 
            SET SumSliptAmt = C.SliptAmt, 
                SliptAmt = B.SliptAmt 
           FROM #Result_Sub AS A 
           JOIN ( 
                 SELECT SUM( ResultInvestAmt / InvestAmt * SliptAmt) AS SliptAmt, 
                        FundSeq 
                    FROM #Table 
                  WHERE SplitDate <= @StdDate 
                  GROUP BY FundSeq 
                ) AS B ON ( B.FundSeq = A.FundSeq ) 
           JOIN ( 
                 SELECT SUM(ResultInvestAmt /InvestAmt * SliptAmt) AS SliptAmt, 
                        FundSeq 
                   FROM #Table 
                  WHERE SplitDate BETWEEN @SubStdDate AND @StdDate 
                  GROUP BY FundSeq 
                ) AS C ON ( C.FundSeq = A.FundSeq ) 
        ---------------------------------------------------------------------------------------------------------
        -- 배당금액 계산, END  
        ---------------------------------------------------------------------------------------------------------
        
        ------------------------------------------------------------------------------------------------------------
        -- 성과보수 계산
        ------------------------------------------------------------------------------------------------------------
         SELECT @Cnt = 1, 
               @CancelResultAmt = 0, 
               @InvestAmt = 0
        
        WHILE( 1 = 1 ) 
        BEGIN
            
            SELECT @InvestAmt = A.InvestAmt
              FROM #BaseData_Sub AS A 
             WHERE A.IDX_NO = 1 
              
             INSERT INTO #Table2 ( InvestAmt, SrtDate, EndDate, ResultReDate, ResultReAmt, ResultInvestAmt, FundSeq ) 
             SELECT @InvestAmt - ISNULL(@CancelResultAmt,0), '', '', A.ResultReDate, A.ResultReAmt, @ResultInvestAmt, A.FundSeq 
               FROM #BaseData_Sub AS A 
               LEFT OUTER JOIN #BaseData_Sub                     AS B ON ( B.FundSeq = A.FundSeq AND B.IDX_NO = @Cnt + 1 )
               LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS C ON ( C.CompanySeq = @CompanySeq AND C.FundSeq = A.FundSeq AND C.ResultReDate BETWEEN A.StdDate AND B.StdDate ) 
              WHERE A.IDX_NO = @Cnt 
                AND (A.StdDate <> ISNULL(C.CancelDate  ,''))
                AND A.ResultReDate <> '' 
                
            
            SELECT @CancelResultAmt = SUM(ISNULL(C.CancelAmt,0))
              FROM #BaseData_Sub AS A 
              LEFT OUTER JOIN #BaseData_Sub                     AS B ON ( B.FundSeq = A.FundSeq AND B.IDX_NO = @Cnt + 1 )
              LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS C ON ( C.CompanySeq = @CompanySeq AND C.FundSeq = A.FundSeq AND C.CancelDate <= B.StdDate ) 
             WHERE A.IDX_NO = @Cnt 
             --AND (A.StdDate <> ISNULL(C.CancelDate  ,''))
              AND ISNULL(C.CancelDate,'') <> '' 
               
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #BaseData_Sub) 
            BEGIN
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
            
       END 
        
       UPDATE A 
          SET SumResultReAmt = C.ResultReAmt, 
              ResultReAmt = B.ResultReAmt 
         FROM #Result_Sub AS A 
         JOIN ( 
               SELECT SUM(ResultInvestAmt / InvestAmt * ResultReAmt) AS ResultReAmt, 
                      FundSeq 
                 FROM #Table2 
                WHERE ResultReDate <= @StdDate 
                GROUP BY FundSeq 
              ) AS B ON ( B.FundSeq = A.FundSeq ) 
         JOIN ( 
               SELECT SUM(ResultInvestAmt / InvestAmt * ResultReAmt) AS ResultReAmt, 
                      FundSeq 
                 FROM #Table2 
                WHERE ResultReDate BETWEEN @SubStdDate AND @StdDate 
                GROUP BY FundSeq 
              ) AS C ON ( C.FundSeq = A.FundSeq ) 
        ------------------------------------------------------------------------------------------------------------
        -- 성과보수 계산, END 
        ------------------------------------------------------------------------------------------------------------
        
        
        IF @MainCnt = (SELECT MAX(Cnt) FROM #FundSeq) 
        BEGIN
            BREAK
        END 
        ELSE
        BEGIN
            SELECT @MainCnt = @MainCnt + 1 
        END 
    
    END 
    
    
    CREATE TABLE #Result 
    (
        FundName        NVARCHAR(100), 
        FundSeq         INT, 
        ActAmt          DECIMAL(19,5), 
        PrevAmt         DECIMAL(19,5), 
        InvestAmt       DECIMAL(19,5), 
        LYTestAmt       DECIMAL(19,5), 
        SumSliptAmt     DECIMAL(19,5), 
        SliptAmt        DECIMAL(19,5), 
        SumResultReAmt  DECIMAL(19,5), 
        ResultReAmt     DECIMAL(19,5), 
        TestAmt         DECIMAL(19,5), 
        TitileName      NVARCHAR(100), 
        UMBond          INT, 
        FundKindSName   NVARCHAR(100), 
        FundKindMName   NVARCHAR(100),  
        FundKindLName   NVARCHAR(100), 
        FundKindName    NVARCHAR(100), 
        UMBondName      NVARCHAR(100), 
        SrtDate         NCHAR(8), 
        AddAmt          DECIMAL(19,5), 
        SumResultAmt    DECIMAL(19,5), 
        ResultAmt       DECIMAL(19,5), 
        SumProfitRate   DECIMAL(19,5), 
        ChProfitRate    DECIMAL(19,5), 
        PeProfitRate    DECIMAL(19,5), 
        FundKindSeq     INT, 
        FundKindSSeq    INT, 
        UMHelpCom       INT 
     )
    
    INSERT INTO #Result
    (
        FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       , 
        SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,
        TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   , 
        FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     , 
        FundKindSSeq    , FundSeq         , UMHelpCom 
    ) 
    SELECT MAX(FundName)       , SUM(ActAmt)          , SUM(PrevAmt)         , SUM(InvestAmt)       , SUM(LYTestAmt)       , 
           SUM(SumSliptAmt)    , SUM(SliptAmt)        , SUM(SumResultReAmt)  , SUM(ResultReAmt)     , SUM(TestAmt)         ,
           MAX(TitileName)     , MAX(UMBond)          , MAX(FundKindSName)   , MAX(FundKindMName)   , MAX(FundKindLName)   , 
           MAX(FundKindName)   , MAX(UMBondName)      , MAX(SrtDate)         , AVG(AddAmt)          , MAX(FundKindSeq)     , 
           MAX(FundKindSSeq)   , FundSeq              , UMHelpCom 
      FROM #Result_Sub 
     GROUP BY FundSeq, UMHelpCom 
     
     
     
    
    UPDATE A
       SET SumResultAmt     = ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0), -- 현재평가금액 - 평가금액(직전년도말) + 배당금(연초누적) - 성과보수(연초누적)
           ResultAmt        = ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0), -- 현재평가금액 - 투자원금 + 배당금(가입일누적) - 성과보수(가입일누적)
           SumProfitRate    = CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0 ELSE (ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0) * 100 END,  -- (수익금액(누적)/투자원금) * 100 
           ChProfitRate     = CASE WHEN DATEDIFF(DAY,A.SrtDate, @StdDate) = 0 THEN 0 
                                   ELSE (CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0 
                                              ELSE (ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0) * 100
                                              END * 365) / (DATEDIFF(DAY,A.SrtDate, @StdDate)) 
                                   END, -- (누적수익율(가입일이후) * 365)/(기준일자-최초 가입일자) 
           PeProfitRate     = CASE WHEN ISNULL(A.LYTestAmt,0) = 0 THEN 0 ELSE (ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) / ISNULL(A.LYTestAmt,0) * 100 END -- (수익금액(연초이후)/평가금액(직전년도말))*100 
      FROM #Result AS A 
     WHERE A.UMBond = 1010563001 
     
    UPDATE A
       SET ChProfitRate     = ISNULL(A.AddAmt,0), -- 연수익율
           SumProfitRate     = (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(기준일자-최초 가입일자)/365
           PeProfitRate    = (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(평가일자-기준일자)/365
           SumResultAmt     = ISNULL(A.InvestAmt,0) * ((ISNULL(A.AddAmt,0)/100) * (DATEDIFF(DAY,@SubStdDate, @StdDate)) / 365), -- 투자원금 * 기간수익율(연초이후) 
           ResultAmt        = ISNULL(A.InvestAmt,0) * ((ISNULL(A.AddAmt,0)/100) * (DATEDIFF(DAY,A.SrtDate, @StdDate)) / 365) -- 투자원금 * 누적수익율(가입일이후) 
      FROM #Result AS A 
     WHERE A.UMBond = 1010563002 
    
    
    SELECT * FROM #Result ORDER BY UMBond, FundName 
    
    
    RETURN  