  
IF OBJECT_ID('KPX_SACFundListQuery') IS NOT NULL   
    DROP PROC KPX_SACFundListQuery  
GO  
  
-- v2014.12.29  
  
-- 상품운용현황-조회 by 이재천   
CREATE PROC KPX_SACFundListQuery  
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
            @UMHelpCom  INT, 
            @UMBond     INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @StdDate     = ISNULL( StdDate, '' ),  
           @UMHelpCom   = ISNULL( UMHelpCom, 0 ), 
           @UMBond      = ISNULL( UMBond, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate    NCHAR(8), 
            UMHelpCom  INT, 
            UMBond     INT 
           )    
    
    DECLARE @BeforeDate NCHAR(8) 
    
    SELECT @BeforeDate = MAX(StdDate) FROM KPX_TACEvalProfitItemMaster WHERE CompanySeq = @CompanySeq AND LEFT(StdDate,4) = CONVERT(NCHAR(4),DATEADD(YEAR, -1, @StdDate),112)
    
    
    -- 기본데이터   
    SELECT --*
           C.FundName, 
           A.StdDate, 
           A.UMHelpCom, 
           MAX(AddAmt) AS AddAmt, 
           MIN(SrtDate) AS SrtDate, 
           MAX(C.UMBond) AS UMBond, 
           MAX(C.TitileName) AS TitileName, 
           MAX(C.FundKindM) AS FundKindM, 
           MAX(C.FundKindS) AS FundKindS, 
           SUM(A.ActAmt) AS ActAmt, 
           SUM(A.PrevAmt) AS PrevAmt, 
           SUM(A.InvestAmt) AS InvestAmt, 
           SUM(A.TestAmt) AS TestAmt, 
           SUM(B.SliptAmt) AS SliptAmt, 
           SUM(B.ResultReAmt) AS ResultReAmt
      INTO #BaseData 
      FROM KPX_TACEvalProfitItemMaster              AS A 
      LEFT OUTER JOIN KPX_TACResultProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND B.StdDate = A.StdDate 
                                                          AND B.UMHelpCom = A.UMHelpCom 
                                                          AND B.FundSeq = A.FundSeq 
                                                            ) 
      LEFT OUTER JOIN KPX_TACFundMaster             AS C ON ( C.CompanySeq = @CompanySeq AND C.FundSeq = A.FundSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND (LEFT(A.StdDate,4) = LEFT(@StdDate,4) OR LEFT(A.StdDate,6) = LEFT(@BeforeDate,6))
       
       AND ISNULL(B.AllCancelDate,'') = '' 
       AND (@UMBond = 0 OR C.UMBond = @UMBond)
       AND (A.UMHelpCom IN ( SELECT A.MinorSeq 
                              FROM _TDAUMinor AS A 
                              JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.ValueText = CONVERT(NVARCHAR(3),@CompanySeq) ) 
                             WHERE A.CompanySeq = @CompanySeq 
                               AND A.MajorSeq= 1010494 
                           ) 
           )
     GROUP BY C.FundName, A.StdDate, A.UMHelpCom 
    
    
    CREATE TABLE #Result 
    (
        FundName        NVARCHAR(100), 
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
        FundKindSSeq    INT 

    )
    
    INSERT INTO #Result 
    (
        FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       , 
        SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,
        TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   , 
        FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     , 
        FundKindSSeq
    ) 
    SELECT A.FundName, 
           SUM(A.ActAmt), 
           SUM(A.PrevAmt), 
           SUM(A.InvestAmt), 
           SUM(B.LYTestAmt), 
           SUM(C.SumSliptAmt), 
           SUM(A.SliptAmt), 
           SUM(D.SumResultReAmt), 
           SUM(A.ResultReAmt), 
           SUM(A.TestAmt), 
           MAX(A.TitileName), 
           MAX(A.UMBond), 
           MAX(E.MinorName) AS FundKindSName, 
           MAX(F.MinorName) AS FundKindMName, 
           MAX(H.MinorName) AS FundKindLName, 
           MAX(J.MinorName) AS FundKindName, 
           MAX(M.MinorName) AS UMBondName, -- 시세/채권 구분 
           
           
           MIN(A.SrtDate), 
           MAX(A.AddAmt), 
           MAX(J.MinorSeq) AS FundKindSeq, 
           MAX(E.MinorSeq) AS FundKindSSeq 
    
      FROM #BaseData AS A 
      OUTER APPLY ( SELECT TestAmt AS LYTestAmt 
                      FROM #BaseData AS Z 
                     WHERE Z.StdDate = @BeforeDate 
                       AND Z.TitileName = A.TitileName 
                       AND Z.UMHelpCom = A.UMHelpCom
                  ) AS B 
      OUTER APPLY ( SELECT SUM(SliptAmt) AS SumSliptAmt 
                      FROM #BaseData AS Z 
                     WHERE LEFT(Z.StdDate,4) = LEFT(@StdDate,4) 
                       AND Z.StdDate <= @StdDate 
                       AND Z.TitileName = A.TitileName 
                       AND Z.UMHelpCom = A.UMHelpCom
                  ) AS C 
      OUTER APPLY ( SELECT SUM(ResultReAmt) AS SumResultReAmt
                      FROM #BaseData AS Z 
                     WHERE LEFT(Z.StdDate,4) = LEFT(@StdDate,4) 
                       AND Z.StdDate <= @StdDate 
                       AND Z.TitileName = A.TitileName 
                       AND Z.UMHelpCom = A.UMHelpCom
                  ) AS D 
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.FundKindS ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.FundKindM ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.MinorSeq AND I.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = I.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMBond )  
     WHERE StdDate = @StdDate 
     GROUP BY FundName 
    

    UPDATE A
       SET SumResultAmt     = A.TestAmt - A.LYTestAmt + A.SumSliptAmt - A.SumResultReAmt, -- 현재평가금액 - 평가금액(직전년도말) + 배당금(연초누적) - 성과보수(연초누적)
           ResultAmt        = A.TestAmt - A.InvestAmt + A.SliptAmt - A.ResultReAmt, -- 현재평가금액 - 투자원금 + 배당금(가입일누적) - 성과보수(가입일누적)
           SumProfitRate    = CASE WHEN A.InvestAmt = 0 THEN 0 ELSE (A.TestAmt - A.InvestAmt + A.SliptAmt - A.ResultReAmt) / A.InvestAmt * 100 END,  -- (수익금액(누적)/투자원금) * 100 
           ChProfitRate     = CASE WHEN DATEDIFF(DAY,A.SrtDate, @StdDate) = 0 THEN 0 
                                   ELSE (CASE WHEN A.InvestAmt = 0 THEN 0 
                                              ELSE (A.TestAmt - A.InvestAmt + A.SliptAmt - A.ResultReAmt) / A.InvestAmt * 100 
                                              END * 365) / (DATEDIFF(DAY,A.SrtDate, @StdDate)) 
                                   END, -- (누적수익율(가입일이후) * 365)/(기준일자-최초 가입일자) 
           PeProfitRate     = CASE WHEN A.LYTestAmt = 0 THEN 0 ELSE (A.TestAmt - A.LYTestAmt + A.SumSliptAmt - A.SumResultReAmt) / A.LYTestAmt * 100 END -- (수익금액(연초이후)/평가금액(직전년도말))*100 
      FROM #Result AS A 
     WHERE A.UMBond = 1010563001 
     
    UPDATE A
       SET ChProfitRate     = A.AddAmt, -- 연수익율
           PeProfitRate     = (A.AddAmt * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(기준일자-최초 가입일자)/365
           SumProfitRate    = (A.AddAmt * (DATEDIFF(DAY,@BeforeDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(기준일자-직전년도 마지막 기준일자)/365
           SumResultAmt     = A.InvestAmt * (A.AddAmt * (DATEDIFF(DAY,@BeforeDate, @StdDate)) / 365), -- 투자원금 * 기간수익율(연초이후) 
           ResultAmt        = A.InvestAmt * (A.AddAmt * (DATEDIFF(DAY,A.SrtDate, @StdDate)) / 365) -- 투자원금 * 누적수익율(가입일이후) 
      FROM #Result AS A 
     WHERE A.UMBond = 1010563002 
    
    
    SELECT * FROM #Result ORDER BY UMBond, FundName 
    
   
    RETURN  
GO 

exec KPX_SACFundListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdDate>20141225</StdDate>
    <UMHelpCom>1010494001</UMHelpCom>
    <UMBond>1010563001</UMBond>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027152,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021337