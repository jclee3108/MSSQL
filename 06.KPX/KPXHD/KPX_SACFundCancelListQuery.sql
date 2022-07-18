IF OBJECT_ID('KPX_SACFundCancelListQuery') IS NOT NULL 
    DROP PROC KPX_SACFundCancelListQuery
GO 

-- v2016.03.10 
    
-- 상품운용현황-조회 by 이재천     
CREATE PROC KPX_SACFundCancelListQuery    
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
      
    DECLARE @docHandle      INT,    
            -- 조회조건     
            @StdDate        NCHAR(8),   
            @UMHelpCom      INT,   
            @UMBond         INT,   
            @SubStdDate     NCHAR(8),   
            @FundName       NVARCHAR(100), 
            @FundCode       NVARCHAR(100), 
            @MultiUMHelpCom NVARCHAR(MAX)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
      
    SELECT @StdDate         = ISNULL( StdDate, '' ),    
           @UMHelpCom       = ISNULL( UMHelpCom, 0 ),   
           @UMBond          = ISNULL( UMBond, 0 ),   
           @SubStdDate      = ISNULL( SubStdDate, '' ),   
           @FundName        = ISNULL( FundName , ''), 
           @FundCode        = ISNULL( FundCode , ''), 
           @MultiUMHelpCom  = ISNULL ( MultiUMHelpCom, '') 
           
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
            StdDate         NCHAR(8),   
            UMHelpCom       INT,   
            UMBond          INT,   
            SubStdDate      NCHAR(8),   
            FundName        NVARCHAR(100), 
            FundCode        NVARCHAR(100), 
            MultiUMHelpCom  NVARCHAR(MAX)
           )      
    
    CREATE TABLE #Result 
    (
        FundCode        NVARCHAR(200), 
        UMHelpComName   NVARCHAR(200), 
        FundName        NVARCHAR(200), 
        UMBondName      NVARCHAR(200), 
        UMBond          INT, 
        FundKindName    NVARCHAR(200),
        FundKindLName   NVARCHAR(200),
        FundKindMName   NVARCHAR(200),
        FundKindSName   NVARCHAR(200),
        TitileName      NVARCHAR(200),
        SrtDate         NCHAR(8), 
        DurDate         NCHAR(8), 
        CancelDate      NCHAR(8), 
        CancelKindName  NVARCHAR(100), 
        DiffActDate     INT, 
        ActAmt          DECIMAL(19,5), 
        PrevAmt         DECIMAL(19,5), 
        InvestAmt       DECIMAL(19,5), 
        LYTestAmt       DECIMAL(19,5), 
        SumSliptAmt     DECIMAL(19,5), 
        SliptAmt        DECIMAL(19,5), 
        SumResultReAmt  DECIMAL(19,5), 
        ResultReAmt     DECIMAL(19,5), 
        TestAmt         DECIMAL(19,5), 
        SumResultAmt    DECIMAL(19,5), 
        ResultAmt       DECIMAL(19,5), 
        SumProfitRate    DECIMAL(19,5), 
        ChProfitRate     DECIMAL(19,5), 
        PeProfitRate     DECIMAL(19,5), 
        UMHelpCom       INT, 
        FundSeq         INT 
    ) 
    -- 기본데이터 
    INSERT INTO #Result 
    (
        FundCode       ,UMHelpComName  ,FundName       ,UMBondName     ,UMBond         ,
        FundKindName   ,FundKindLName  ,FundKindMName  ,FundKindSName  ,TitileName     ,
        SrtDate        ,DurDate        ,CancelDate     ,CancelKindName ,DiffActDate    ,
        ActAmt         ,PrevAmt        ,InvestAmt      ,LYTestAmt      ,SumSliptAmt    ,
        SliptAmt       ,SumResultReAmt ,ResultReAmt    ,TestAmt        ,SumResultAmt   ,
        ResultAmt      ,SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,UMHelpCom      , 
        FundSeq 
    ) 
    SELECT D.FundCode     ,C.MinorName    ,D.FundName     ,E.MinorName    ,D.UMBond       ,
    
           L.MinorName    ,J.MinorName    ,H.MinorName    ,G.MinorName    ,D.TitileName   ,
           
           F.SrtDate      ,F.DurDate      ,
           CASE WHEN ISNULL(A.CancelDate,'') = '' THEN A.AllCancelDate ELSE A.CancelDate END,
           CASE WHEN ISNULL(A.CancelDate,'') = '' THEN '전부해지' ELSE '일부해지' END AS CancelKindName, 
           DATEDIFF(DAY, F.SrtDate, CASE WHEN ISNULL(A.CancelDate,'') = '' THEN A.AllCancelDate ELSE A.CancelDate END) AS DiffActDate,
           
           0, 0, 
           CASE WHEN ISNULL(A.AllCancelAmt,0) = 0 THEN A.CancelAmt ELSE A.AllCancelAmt END, 
           0, A.SliptAmt,
           
           A.SliptAmt, A.ResultReAmt, A.ResultReAmt, 
           CASE WHEN ISNULL(A.AllCancelResultAmt,0) = 0 THEN A.CancelResultAmt ELSE A.AllCancelResultAmt END, 
           0, 
           
           0, 0, 0, 0, A.UMHelpCom, 
           
           A.FundSeq 
      FROM KPX_TACResultProfitItemMaster             AS A 
                 JOIN _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS B ON ( B.Code = A.UMHelpCom )   
      LEFT OUTER JOIN _TDAUMinor                    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMHelpCom ) 
      LEFT OUTER JOIN KPX_TACFundMaster             AS D ON ( D.CompanySeq = @CompanySeq AND D.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.UMBond ) 
      LEFT OUTER JOIN (
                        SELECT DISTINCT Z.SrtDate, Z.DurDate, Z.FundSeq, Z.UMHelpCom
                          FROM KPX_TACEvalProfitItemMaster AS Z
                      ) AS F ON ( F.FundSeq = A.FundSeq AND F.UMHelpCom = A.UMHelpCom ) 
      LEFT OUTER JOIN _TDAUMinor                    AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = D.FundKindS ) 
      LEFT OUTER JOIN _TDAUMinor                    AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = D.FundKindM ) 
      LEFT OUTER JOIN _TDAUMinorValue               AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = D.FundKindM AND I.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor                    AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = I.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue               AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = I.ValueSeq AND K.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor                    AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
     WHERE A.StdDate BETWEEN @SubStdDate AND @StdDate 
       AND (@FundName = '' OR D.FundName LIKE @FundName + '%') 
       AND (@FundCode = '' OR D.FundCode LIKE @FundCode + '%') 
       AND (@UMBond = 0 OR D.UMBond = @UMBond) 
       AND A.StdDate <> @SubStdDate -- 실현손익마스터의 일자와 기준일자가 동일한 건은 제외 처리(당일자 평가손익마스터가 없어서 평가금액(기준일)이 0이 되어 수익율이 이상해 짐) 
    
    
    
    
    ---------------------------------------------------------------------------------
    -- 상품운용금액, 선취수수료(선납세금), 평가금액 Update 
    ---------------------------------------------------------------------------------
    --최초가입한 상품 (평가손익)
    SELECT A.UMHelpCom, A.FundSeq, MIN(A.StdDate) AS StdDate
      INTO #SrtData 
      FROM KPX_TACEvalProfitItemMaster   AS A 
                 JOIN #Result           AS B ON ( B.UMHelpCom = A.UMHelpCom AND B.FundSeq = A.FundSeq ) 
     GROUP BY A.UMHelpCom, A.FundSeq 
    
    UPDATE A 
       SET ActAmt = (ISNULL(A.InvestAmt,0) / NULLIF(ISNULL(B.InvestAmt,0),0)) * ISNULL(B.ActAmt,0), -- 상품운용금액 
           PrevAmt = (ISNULL(A.InvestAmt,0) / NULLIF(ISNULL(B.InvestAmt,0),0)) * ISNULL(B.PrevAmt,0), -- 선취수수료(선납세금)
           -- 평가금액(기준일) 
           /*
            1) 기준일 이전 가입 건(기준일자 포함)
               -. (해지원금액(일부,해지) / 기준일자 투자원금) * 기준일자 평가금액(NAV)
            2) 기준일 이후 가입 건(기준일자 미포함)
               -. (해지원금액(일부,해지) / 최초 투자원금) * 최초 투자원금
           */
           LYTestAmt = CASE WHEN A.SrtDate <= @SubStdDate THEN (ISNULL(A.InvestAmt,0) / NULLIF(ISNULL(C.InvestAmt,0),0)) * ISNULL(C.TestAmt,0) 
                            ELSE (ISNULL(A.InvestAmt,0) / NULLIF(ISNULL(B.InvestAmt,0),0)) * ISNULL(B.InvestAmt,0) 
                            END 
      FROM #Result AS A 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, Z.ActAmt, Z.PrevAmt, Z.InvestAmt 
                          FROM KPX_TACEvalProfitItemMaster   AS Z 
                          JOIN #SrtData                     AS Y ON ( Y.UMHelpCom = Z.UMHelpCom AND Y.FundSeq = Z.FundSeq AND Y.StdDate = Z.StdDate ) 
                      ) AS B ON ( B.UMHelpCom= A.UMHelpCom AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.UMHelpCom, Z.FundSeq, Z.TestAmt, Z.InvestAmt
                          FROM KPX_TACEvalProfitItemMaster AS Z 
                         WHERE Z.StdDate = @SubStdDate
                      ) AS C ON ( C.UMHelpCom = A.UMHelpCom AND C.FundSeq = A.FundSeq ) 
    ---------------------------------------------------------------------------------
    -- 상품운용금액, 선취수수료(선납세금), 평가금액 Update, END 
    ---------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------
    -- 수익금액(기준일이후), 수익금액(누적) Update 
    ---------------------------------------------------------------------------------
    UPDATE A 
       SET -- 수익금액(기준일이후) : (9) 실현금액 - (4) 평가금액(기준일) + (5) 배당금(기준일) - (7) 성과보수(기준일)
           SumResultAmt = ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0), 
           -- 수익금액(누적) : (9) 실현금액 - (3) 투자원금 + (6) 배당금(누적) - (8) 성과보수(누적)
           ResultAmt = ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)
      FROM #Result AS A 
    ---------------------------------------------------------------------------------
    -- 수익금액(기준일이후), 수익금액(누적) Update, END 
    ---------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------
    -- 누적수익율(가입일이후), 기간수익율(기준일이후) Update 
    ---------------------------------------------------------------------------------
    UPDATE A
       SET -- 누적수익율(가입일이후) : (11) 수익금액(누적) * 100 /  (3) 투자원금
           SumProfitRate = ISNULL(A.ResultAmt,0) * 100 / NULLIF(ISNULL(A.InvestAmt,0),0), 
           -- 기간수익율(기준일이후) : (10) 수익금액(기준일이후) * 100 / (4) 평가금액(기준일)
           PeProfitRate = ISNULL(A.SumResultAmt,0) * 100 / NULLIF(ISNULL(A.LYTestAmt,0),0)
      FROM #Result AS A 
    ---------------------------------------------------------------------------------
    -- 누적수익율(가입일이후), 기간수익율(기준일이후) Update, END 
    ---------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------
    -- 연환산수익율(가입일이후) Update
    ---------------------------------------------------------------------------------
    UPDATE A
       SET -- 연환산수익율(가입일이후) : (12) 누적수익율(가입일이후) * 365 / 운용기간
           ChProfitRate = ISNULL(A.SumProfitRate,0) * 365 / NULLIF(ISNULL(A.DiffActDate,0),0)
      FROM #Result AS A 
    ---------------------------------------------------------------------------------
    -- 연환산수익율(가입일이후) Update, END 
    ---------------------------------------------------------------------------------
    
    SELECT * 
      FROM #Result 
     ORDER BY UMHelpCom, FundCode
    
    RETURN    
GO
begin tran

--SELECT * FROM _TDAUMinor WHERE CompanySeq = 4 AND MinorSeq = 1010494001
exec KPX_SACFundCancelListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FundCode />
    <SubStdDate>20151231</SubStdDate>
    <StdDate>20160225</StdDate>
    <UMHelpCom>1010494001</UMHelpCom>
    <MultiUMHelpCom>&amp;lt;XmlString&amp;gt;&amp;lt;Code&amp;gt;1010494001&amp;lt;/Code&amp;gt;&amp;lt;/XmlString&amp;gt;</MultiUMHelpCom>
    <UMBond />
    <FundName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027152,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029342
rollback 
