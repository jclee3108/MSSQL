  
IF OBJECT_ID('KPX_SACFundManageListQuery') IS NOT NULL   
    DROP PROC KPX_SACFundManageListQuery  
GO  
  
-- v2014.12.29  
  
-- 상품운용명세서-조회 by 이재천   
CREATE PROC KPX_SACFundManageListQuery  
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
            @UMHelpCom  INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @StdDate     = ISNULL( StdDate, '' ),  
           @UMHelpCom   = ISNULL( UMHelpCom, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate    NCHAR(8), 
            UMHelpCom  INT 
           )    
    
    DECLARE @XmlData NVARCHAR(MAX) 
    
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
    
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT @StdDate AS StdDate, @UMHelpCom AS UMHelpCom
                                                 
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS   
                                                 )) 
    INSERT INTO #Result 
    EXEC KPX_SACFundListQuery 
         @xmlDocument  = @XmlData,   
         @xmlFlags     = 2,   
         @ServiceSeq   = 2537,   
         @WorkingTag   = '',   
         @CompanySeq   = @CompanySeq,   
         @LanguageSeq  = 1,   
         @UserSeq      = @UserSeq,   
         @PgmSeq       = @PgmSeq 
    
    --select * from #Result 
    
    SELECT FundKindName, 
           FundKindSeq, 
           FundName, 
           0 AS PortionRate, 
           SUM(InvestAmt)/1000000 AS InvestAmt, 
           AVG(SumProfitRate) AS SumProfitRate, 
           AVG(ChProfitRate) AS ChProfitRate, 
           AVG(PeProfitRate) AS PeProfitRate, 
           MAX(FundKindLName) AS FundKindLName, 
           MAX(FundKindMName) AS FundKindMName, 
           MAX(FundKindSName) AS FundKindSName, 
           1 AS Sort 
      FROM #Result 
     GROUP BY FundKindName, FundKindSeq, FundName 
    
    UNION ALL 
    
    SELECT FundKindName + ' 소계', 
           FundKindSeq, 
           '', 
           CASE WHEN ISNULL(MAX(B.SumInvestAmt),0) = 0 THEN 0 ELSE SUM(InvestAmt) / MAX(B.SumInvestAmt) * 100 END AS PortionRate, 
           SUM(InvestAmt)/1000000 AS InvestAmt, 
           AVG(SumProfitRate) AS SumProfitRate, 
           AVG(ChProfitRate) AS ChProfitRate, 
           AVG(PeProfitRate) AS PeProfitRate, 
           MAX(FundKindLName) AS FundKindLName, 
           MAX(FundKindMName) AS FundKindMName, 
           MAX(FundKindSName) AS FundKindSName, 
           2 AS Sort 
      FROM #Result 
      OUTER APPLY ( SELECT SUM(InvestAmt) AS SumInvestAmt
                      FROM #Result 
                  ) AS B 
     GROUP BY FundKindName, FundKindSeq
    
    UNION ALL 
    
    SELECT '합계', 
           9999999999, 
           '', 
           100 AS PortionRate, 
           SUM(InvestAmt)/1000000 AS InvestAmt, 
           AVG(SumProfitRate) AS SumProfitRate, 
           AVG(ChProfitRate) AS ChProfitRate, 
           AVG(PeProfitRate) AS PeProfitRate, 
           MAX(FundKindLName) AS FundKindLName, 
           MAX(FundKindMName) AS FundKindMName, 
           MAX(FundKindSName) AS FundKindSName, 
           3 AS Sort 
      FROM #Result 
    
    ORDER BY Sort 
    
    
    SELECT A.MinorName AS AssetGubun, 
           MAX(B.ValueText) AS AppStdRate, 
           CASE WHEN MAX(E.InvestAmt) = 0 THEN 0 ELSE SUM(ISNULL(D.InvestAmt,0)) / MAX(E.InvestAmt) * 100 END AS NPortionRate, 
           SUM(ISNULL(D.InvestAmt,0)) / 1000000 AS AppAmt, 
           '' AS Remark 
           
      FROM _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 1010431 AND C.Serl = 1000001 AND C.ValueSeq = A.MinorSeq ) 
      LEFT OUTER JOIN #Result         AS D ON ( D.FundKindSSeq = C.MinorSeq ) 
      OUTER APPLY ( SELECT SUM(Z.InvestAmt) AS InvestAmt
                      FROM #Result AS Z  
                  ) AS E 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1010564 
     GROUP BY A.MinorName 
    
    
    RETURN  
GO 

exec KPX_SACFundManageListQuery @xmlDocument=N'<ROOT>
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
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027152,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021337