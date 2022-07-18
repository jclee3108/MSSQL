IF OBJECT_ID('KPX_SACFundManageConfirmQuery') IS NOT NULL 
    DROP PROC KPX_SACFundManageConfirmQuery
GO 

-- v2016.01.07 
          
-- 상품운용검증-조회 by 이재천   
CREATE PROC KPX_SACFundManageConfirmQuery          
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
            @SubStdDate NCHAR(8),         
            @MultiUMHelpCom NVARCHAR(MAX),         
            @FundName   NVARCHAR(100),         
            @MultiUMHelpComName    NVARCHAR(200),   
            @IsDetail   NCHAR(1)   
            
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument           
            
    SELECT @StdDate     = ISNULL( StdDate, '' ),          
           @UMHelpCom   = ISNULL( UMHelpCom, 0 ),         
           @SubStdDate  = ISNULL( SubStdDate, ''),         
           @MultiUMHelpCom = ISNULL ( MultiUMHelpCom, ''),         
           @FundName    = ISNULL( FundName , ''),   
           @IsDetail    = ISNULL( IsDetail, '0')  
            
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )               
      WITH (        
            StdDate         NCHAR(8),         
            UMHelpCom       INT,         
            SubStdDate      NCHAR(8),         
            MultiUMHelpCom  NVARCHAR(MAX),         
            FundName        NVARCHAR(100),   
            IsDetail        NCHAR(1)  
           )            
      
    SELECT @MultiUMHelpCom = CASE WHEN @MultiUMHelpCom = '&lt;XmlString&gt;&lt;/XmlString&gt;' THEN '' ELSE @MultiUMHelpCom END   
      
    DECLARE @XmlData NVARCHAR(MAX)         
            
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
        UMBond           INT,         
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
        UMHelpCom       INT, 
        FundKindMSeq    INT, 
        FundKindLSeq    INT       
    )        
        
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT @StdDate AS StdDate, @UMHelpCom AS UMHelpCom, @SubStdDate AS SubStdDate, 0 AS UMBond, @MultiUMHelpCom AS MultiUMHelpCom, @FundName AS FundName, @IsDetail AS IsDetail  
                                                         
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                 ))         
        
        
    INSERT INTO #Result         
    EXEC KPX_SACFundManageListSubQuery         
         @xmlDocument  = @XmlData,           
         @xmlFlags     = 2,           
         @ServiceSeq   = 0,           
         @WorkingTag   = '',           
           @CompanySeq   = @CompanySeq,           
         @LanguageSeq  = 1,           
         @UserSeq      = @UserSeq,           
         @PgmSeq       = @PgmSeq         
      
  
  
    --===================================================================================================================================================================================  
    -- 출력물의 회사명칭 -- START  2016.01.04 by bgKeum  
    --===================================================================================================================================================================================  
    DECLARE @ComCount   INT  
  
    CREATE TABLE #MultiComALL (  
        Kind            NVARCHAR(10),  
        Code            INT)  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494001 -- KPXHD  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494002 -- KPXCM  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494004 -- KPXGC  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494005 -- KPXLS  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494006 -- KPXDV  
    INSERT INTO #MultiComALL SELECT 'KPX', 1010494007 -- KPXID  
    INSERT INTO #MultiComALL SELECT 'CY',  1010494008 -- CYHD  
    INSERT INTO #MultiComALL SELECT 'CY',  1010494009 -- CY물산  
  
    SELECT @ComCount = COUNT(*) FROM _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom)  
  
    IF @ComCount = 8 AND   
             8 = (SELECT COUNT(*)  
                    FROM _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS A JOIN #MultiComALL AS B ON A.Code = B.Code)  
    BEGIN  
        SELECT @MultiUMHelpComName = 'KPX,진양홀딩스,진양물산'  
    END  
    ELSE IF @ComCount = 6 AND  
             6 = (SELECT COUNT(*)  
                   FROM _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS A JOIN #MultiComALL AS B ON A.Code = B.Code  
                  WHERE B.Kind = 'KPX')  
    BEGIN  
        SELECT @MultiUMHelpComName = 'KPX전체'  
    END  
    ELSE IF @ComCount = 2 AND   
             2 = (SELECT COUNT(*)  
                   FROM _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS A JOIN #MultiComALL AS B ON A.Code = B.Code  
                  WHERE B.Kind = 'CY')  
    BEGIN  
        SELECT @MultiUMHelpComName = '진양홀딩스+진양물산'  
    END  
    ELSE  
    BEGIN  
        SELECT @MultiUMHelpComName =  REPLACE(REPLACE(REPLACE((        
                                                            SELECT B.MinorName AS UMHelpComName         
                                                              FROM _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom) AS A         
                                                        LEFT OUTER JOIN _TDAUMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) FOR XML AUTO, ELEMENTS        
                                               ),'</UMHelpComName></B><B><UMHelpComName>',', '), '<B><UMHelpComName>', ''), '</UMHelpComName></B>', '')        
            
        SELECT @MultiUMHelpComName = CASE WHEN @MultiUMHelpComName = '<B/>' THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @UMHelpCom)         
                                       ELSE @MultiUMHelpComName         
                                       END         
            
    END   
    --===================================================================================================================================================================================  
    -- 출력물의 회사명칭 -- END  
    --===================================================================================================================================================================================  
            
    DECLARE @Count INT           
              
    SELECT @Count = COUNT(1)          
      FROM (          
            SELECT DISTINCT UMHelpCom           
              FROM #Result          
           ) AS A           
      
            
    CREATE TABLE #Result_Sub         
    (        
        FundName        NVARCHAR(100),         
        FundSeq         INT,         
        ActAmt          DECIMAL(19,5),         
          PrevAmt          DECIMAL(19,5),         
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
        UMHelpCom       INT,   
        UMHelpComName   NVARCHAR(100),   
        FundCode        NVARCHAR(100)   
        
    )        
        
    IF @IsDetail = '0'   
    BEGIN  -- 멀티 법인   
        INSERT INTO #Result_Sub        
        (        
            FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       ,         
            SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,        
            TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   ,         
            FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     ,         
            FundKindSSeq    , UMHelpCom       , UMHelpComName   , FundCode   
        )         
        SELECT FundName            , SUM(ActAmt)          , SUM(PrevAmt)         , SUM(InvestAmt)       , SUM(LYTestAmt)       ,         
               SUM(SumSliptAmt)    , SUM(SliptAmt)        , SUM(SumResultReAmt)  , SUM(ResultReAmt)     , SUM(TestAmt)         ,        
               MAX(TitileName)     , MAX(UMBond)          , MAX(FundKindSName)   , MAX(FundKindMName)   , MAX(FundKindLName)   ,         
               MAX(FundKindName)   , MAX(UMBondName)      , MAX(SrtDate)         , MAX(AddAmt)          , MAX(FundKindSeq)     ,         
               MAX(FundKindSSeq)   , 0                    , ''                   , ''   
          FROM #Result        
         GROUP BY FundName        
    END   
    ELSE   
    BEGIN -- 개인 법인   
        INSERT INTO #Result_Sub        
        (        
            FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       ,         
            SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,        
            TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   ,         
            FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     ,         
            FundKindSSeq    , UMHelpCom       , UMHelpComName   , FundCode  
        )         
        SELECT FundName        , ActAmt          , PrevAmt         , InvestAmt       , LYTestAmt       ,         
               SumSliptAmt     , SliptAmt        , SumResultReAmt  , ResultReAmt     , TestAmt         ,        
               TitileName      , UMBond          , FundKindSName   , FundKindMName   , FundKindLName   ,         
               FundKindName    , UMBondName      , SrtDate         , AddAmt          , FundKindSeq     ,         
               FundKindSSeq    , UMHelpCom       , (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND A.UMHelpCom = MinorSeq),   
               (SELECT FundCode FROM KPX_TACFundMaster WHERE CompanySeq = @CompanySeq AND FundSeq = A.FundSeq)  
          FROM #Result AS A   
    END   
      
    --select * from #Result_Sub   
    --return   
      -- SumResultAmt 는 수익률 계산     
    -- SumResultAmtSub 는 수익률 합계 계산     
    ALTER TABLE #Result ADD SumResultAmtSub DECIMAL(19,5) NULL     
    --ALTER TABLE #Result ADD ResultAmtSub DECIMAL(19,5) NULL     
    --ALTER TABLE #Result_Sub ADD SumResultAmtSub DECIMAL(19,5) NULL     
    --ALTER TABLE #Result_Sub ADD ResultAmtSub DECIMAL(19,5) NULL     
      
    UPDATE A          
       SET SumResultAmt     = (ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) * 100, -- 현재평가금액 - 평가금액(직전년도말) + 배당금(연초누적) - 성과보수(연초누적)          
             ResultAmt        = (ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) * 100, -- 현재평가금액 - 투자원금 + 배당금(가입일누적) - 성과보수(가입일누적)          
           SumProfitRate    = CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0 ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0)) * 100 END,  -- (수익금액(누적)/투자원금) * 100           
           ChProfitRate     = CASE WHEN DATEDIFF(DAY,A.SrtDate, @StdDate) = 0 THEN 0           
                                   ELSE (ROUND(CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0           
                                              ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0)) * 100          
                                              END,2)  * 365) / (DATEDIFF(DAY,A.SrtDate, @StdDate))           
                                   END, -- (누적수익율(가입일이후) * 365)/(기준일자-최초 가입일자)           
             PeProfitRate     = CASE WHEN ISNULL(A.LYTestAmt,0) = 0 THEN 0 ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) / ISNULL(A.LYTestAmt,0)) * 100 END -- (수익금액(연초이후)/평가금액(직전년도말))*100           
             --SumResultAmtSub = ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)    
      FROM #Result_Sub AS A           
     WHERE A.UMBond = 1010563001           
               
        
    UPDATE A          
       SET ChProfitRate     = ISNULL(A.AddAmt,0), -- 연수익율          
           SumProfitRate     = (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(평가일자-최초 가입일자)/365          
           PeProFitRate     = CASE WHEN A.SrtDate >= @SubStdDate     
                                   THEN (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
                                   ELSE (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
                                   END,     
           SumResultAmt     = ISNULL(A.InvestAmt,0) *     
                              CASE WHEN A.SrtDate >= @SubStdDate     
                                   THEN (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
                                   ELSE (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
                                   END, -- 투자원금 * 기간수익율(연초이후)           
           ResultAmt        = ISNULL(A.InvestAmt,0) * ((ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365) -- 투자원금 * 누적수익율(가입일이후)           
           --,SumResultAmtSub = ISNULL(A.InvestAmt,0) *     
           --                   CASE WHEN A.SrtDate >= @SubStdDate     
           --                        THEN (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
           --                        ELSE (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
           --                        END -- 투자원금 * 기간수익율(연초이후)      
      FROM #Result_Sub AS A           
     WHERE A.UMBond = 1010563002           
               
               
        
    UPDATE A          
       SET SumResultAmt     = (ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) * 100, -- 현재평가금액 - 평가금액(직전년도말) + 배당금(연초누적) - 성과보수(연초누적)          
             ResultAmt        = (ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) * 100, -- 현재평가금액 - 투자원금 + 배당금(가입일누적) - 성과보수(가입일누적)          
           SumProfitRate    = CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0 ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0)) * 100 END,  -- (수익금액(누적)/투자원금) * 100           
           ChProfitRate     = CASE WHEN DATEDIFF(DAY,A.SrtDate, @StdDate) = 0 THEN 0           
                                   ELSE (ROUND(CASE WHEN ISNULL(A.InvestAmt,0) = 0 THEN 0           
                                              ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.InvestAmt,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0)) / ISNULL(A.InvestAmt,0)) * 100          
                                              END,2)  * 365) / (DATEDIFF(DAY,A.SrtDate, @StdDate))           
                                   END, -- (누적수익율(가입일이후) * 365)/(기준일자-최초 가입일자)           
           PeProfitRate     = CASE WHEN ISNULL(A.LYTestAmt,0) = 0 THEN 0 ELSE ((ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) / ISNULL(A.LYTestAmt,0)) * 100 END, -- (수익금액(연초이후)/평가금액(직전년도말))*100           
           SumResultAmtSub = ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)    
           --,SumResultAmtSub     = (ISNULL(A.TestAmt,0) - ISNULL(A.LYTestAmt,0) + ISNULL(A.SumSliptAmt,0) - ISNULL(A.SumResultReAmt,0)) -- 현재평가금액 - 평가금액(직전년도말) + 배당금(연초누적) - 성과보수(연초누적)          
                
      FROM #Result AS A           
     WHERE A.UMBond = 1010563001           
               
    UPDATE A          
       SET ChProfitRate     = ISNULL(A.AddAmt,0), -- 연수익율          
           SumProfitRate     = (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365, -- 연환산수익율(가입일이후)*(평가일자-최초 가입일자)/365          
           PeProFitRate     = CASE WHEN A.SrtDate >= @SubStdDate     
                                   THEN (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
                                   ELSE (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
                                   END,     
           SumResultAmt     = ISNULL(A.InvestAmt,0) *     
                              CASE WHEN A.SrtDate >= @SubStdDate     
                                   THEN (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
                                   ELSE (ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
                                   END, -- 투자원금 * 기간수익율(연초이후)           
           ResultAmt        = ISNULL(A.InvestAmt,0) * ((ISNULL(A.AddAmt,0) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365) -- 투자원금 * 누적수익율(가입일이후)           
           ,SumResultAmtSub = ISNULL(A.InvestAmt,0) *     
                              CASE WHEN A.SrtDate >= @SubStdDate     
                                   THEN ((ISNULL(A.AddAmt,0) / 100) * (DATEDIFF(DAY,A.SrtDate, @StdDate))) / 365     
                                   ELSE ((ISNULL(A.AddAmt,0) / 100)* (DATEDIFF(DAY,@SubStdDate, @StdDate))) / 365     
                                   END -- 투자원금 * 기간수익율(연초이후)      
      FROM #Result AS A           
     WHERE A.UMBond = 1010563002               
        
    --select * from #Result     
        
    --select * From #Result_Sub    
        
    -- 상품유형으로 정렬을 위한 추가         
    ALTER TABLE #Result ADD MinorSort INT NULL         
            
    UPDATE A         
         SET MinorSort = B.MinorSort        
      FROM #Result AS A         
      LEFT OUTER JOIN _TDAUMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.FundKindSeq )         
              
    ALTER TABLE #Result_Sub ADD MinorSort INT NULL         
            
    UPDATE A         
       SET MinorSort = B.MinorSort        
      FROM #Result_Sub AS A         
        LEFT OUTER JOIN _TDAUMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.FundKindSeq )          
        
        
        
--    SELECT (SUM(Z.ResultAmt) / SUM(InvestAmt)) AS SumProfitRate,           
--           (SUM(Z.InvestAmt * Z.ChProfitRate) / SUM(Z.InvestAmt)) AS ChProfitRate,           
--           (SUM(Z.SumResultAmt) / SUM(LYTestAmt)) AS PeProfitRate,           
--           Z.FundName          
--      FROM #Result AS Z           
--     GROUP BY Z.FundName         
--return     
      
      
    CREATE TABLE #TEMP   
    (   
        FundKindName    NVARCHAR(200),   
        FundKindSeq     DECIMAL(19,0),    
        FundName        NVARCHAR(100),   
        PortionRate     DECIMAL(19,5),   
        Amt             DECIMAL(19,5),   
        SumProfitRate    DECIMAL(19,5),   
        ChProfitRate     DECIMAL(19,5),   
        PeProfitRate     DECIMAL(19,5),   
        FundKindLName   NVARCHAR(200),   
        FundKindMName   NVARCHAR(200),   
        FundKindSName   NVARCHAR(200),   
        Sort            INT,   
        StdDate         NCHAR(8),   
        MultiUMHelpComName  NVARCHAR(200),   
        FundKindSSeq    INT,   
        MinorSort       INT,   
        FundKindSort    DECIMAL(19,0),   
        UMHelpComName   NVARCHAR(100),   
        FundCode        NVARCHAR(100)   
    )   
      
      
    IF @IsDetail = '0'   
    BEGIN   
        -- SS1 담기     
        INSERT INTO #TEMP   
        (  
           FundKindName   ,FundKindSeq    ,FundName       ,PortionRate    ,Amt            ,  
           SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,FundKindLName  ,FundKindMName  ,  
           FundKindSName  ,Sort           ,StdDate        ,MultiUMHelpComName,FundKindSSeq   ,  
           MinorSort      ,FundKindSort   ,UMHelpComName  ,FundCode  
        )    
        SELECT MAX(A.FundKindName) AS FundKindName,             
               MAX(A.FundKindSeq) AS FundKindSeq,         
               A.FundName,             
                 CASE WHEN ISNULL(MAX(B.SumInvestAmt),0) = 0 THEN 0 ELSE SUM(A.InvestAmt) / MAX(B.SumInvestAmt) * 100 END AS PortionRate,           
               ROUND(SUM(A.InvestAmt)/1000000,0) AS Amt,           
               CASE WHEN @Count > 1 THEN MAX(ISNULL(C.SumProfitRate,0)) ELSE MAX(A.SumProfitRate) END AS SumProfitRate,           
               CASE WHEN @Count > 1 THEN MAX(ISNULL(C.ChProfitRate,0)) ELSE MAX(A.ChProfitRate) END AS ChProfitRate,           
               CASE WHEN @Count > 1 THEN MAX(ISNULL(C.PeProfitRate,0)) ELSE MAX(A.PeProfitRate) END AS PeProfitRate,            
               MAX(A.FundKindLName) AS FundKindLName,             
               MAX(A.FundKindMName) AS FundKindMName,             
               MAX(A.FundKindSName) AS FundKindSName,             
               1 AS Sort,             
               @StdDate AS StdDate,             
                 '( ' + @MultiUMHelpComName + ' )' AS MultiUMHelpComName,             
               MAX(A.FundKindSSeq) AS FundKindSSeq,             
               MAX(A.MinorSort) AS MinorSort,           
               MAX(D.MinorSort) AS FundKindSort,   
               '',   
               ''  
          --INTO #TEMP             
          FROM #Result_Sub AS A             
          OUTER APPLY ( SELECT SUM(InvestAmt) AS SumInvestAmt            
                          FROM #Result             
                      ) AS B             
          LEFT OUTER JOIN (          
                            SELECT (SUM(Z.ResultAmt) / NULLIF(SUM(InvestAmt),0)) AS SumProfitRate,           
                                   (SUM(Z.InvestAmt * Z.ChProfitRate) / NULLIF(SUM(Z.InvestAmt),0)) AS ChProfitRate,           
                                   (SUM(Z.SumResultAmt) / NULLIF(SUM(LYTestAmt),0))  AS PeProfitRate,           
                                   Z.FundName          
                              FROM #Result AS Z           
                             GROUP BY Z.FundName         
                          ) AS C ON ( C.FundName = A.FundName )           
            LEFT OUTER JOIN _TDAUMinor AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.FundKindSSeq )            
         GROUP BY A.FundName         
    END   
    ELSE   
    BEGIN  
        -- SS1 담기      
        INSERT INTO #TEMP   
        (  
           FundKindName   ,FundKindSeq    ,FundName       ,PortionRate    ,Amt            ,  
           SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,FundKindLName  ,FundKindMName  ,  
           FundKindSName  ,Sort           ,StdDate        ,MultiUMHelpComName,FundKindSSeq   ,  
           MinorSort      ,FundKindSort   ,UMHelpComName  ,FundCode  
        )           
        SELECT (A.FundKindName) AS FundKindName,             
               (A.FundKindSeq) AS FundKindSeq,         
               A.FundName,             
                 CASE WHEN ISNULL((B.SumInvestAmt),0) = 0 THEN 0 ELSE (A.InvestAmt) / (B.SumInvestAmt) * 100 END AS PortionRate,           
               ROUND(A.InvestAmt/1000000,0) AS Amt,           
               CASE WHEN @Count > 1 THEN (ISNULL(C.SumProfitRate,0)) ELSE (A.SumProfitRate) END AS SumProfitRate,           
               CASE WHEN @Count > 1 THEN (ISNULL(C.ChProfitRate,0)) ELSE (A.ChProfitRate) END AS ChProfitRate,           
               CASE WHEN @Count > 1 THEN (ISNULL(C.PeProfitRate,0)) ELSE (A.PeProfitRate) END AS PeProfitRate,            
               (A.FundKindLName) AS FundKindLName,             
               (A.FundKindMName) AS FundKindMName,             
               (A.FundKindSName) AS FundKindSName,             
               1 AS Sort,             
               @StdDate AS StdDate,             
                 '( ' + @MultiUMHelpComName + ' )' AS MultiUMHelpComName,             
               (A.FundKindSSeq) AS FundKindSSeq,             
               (A.MinorSort) AS MinorSort,           
               (D.MinorSort) AS FundKindSort      ,   
               A.UMHelpComName,   
               A.FundCode  
          FROM #Result_Sub AS A             
          OUTER APPLY ( SELECT SUM(InvestAmt) AS SumInvestAmt            
                          FROM #Result             
                      ) AS B             
          LEFT OUTER JOIN (          
                            SELECT (SUM(Z.ResultAmt) / NULLIF(SUM(InvestAmt),0)) AS SumProfitRate,           
                                   (SUM(Z.InvestAmt * Z.ChProfitRate) / NULLIF(SUM(Z.InvestAmt),0)) AS ChProfitRate,           
                                   (SUM(Z.SumResultAmt) / NULLIF(SUM(LYTestAmt),0))  AS PeProfitRate,           
                                   Z.FundName          
                              FROM #Result AS Z           
                             GROUP BY Z.FundName         
                          ) AS C ON ( C.FundName = A.FundName )           
          LEFT OUTER JOIN _TDAUMinor AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.FundKindSSeq )            
         --GROUP BY A.FundName       
    END   
         
    INSERT INTO #TEMP   
    (  
       FundKindName   ,FundKindSeq    ,FundName       ,PortionRate    ,Amt            ,  
       SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,FundKindLName  ,FundKindMName  ,  
       FundKindSName  ,Sort           ,StdDate        ,MultiUMHelpComName,FundKindSSeq   ,  
       MinorSort      ,FundKindSort     
    )      
    SELECT A.FundKindName, --FundKindSName + ' 소계' + ' (' +FundKindName + ')',         
           1010428002 AS FundKindSeq,         
           A.FundKindSName + ' 소계 (채권형)',         
           CASE WHEN ISNULL(MAX(B.SumInvestAmt),0) = 0 THEN 0 ELSE SUM(A.InvestAmt) / MAX(B.SumInvestAmt) * 100 END AS PortionRate,         
           ROUND(SUM(A.InvestAmt)/1000000,0) AS Amt,         
           MAX(ISNULL(C.SumProfitRate,0)) AS SumProfitRate,         
           MAX(ISNULL(C.ChProfitRate,0)) AS ChProfitRate,         
           MAX(ISNULL(C.PeProfitRate,0)) AS PeProfitRate,         
           '' AS FundKindLName,         
           '' AS FundKindMName,         
           '' AS FundKindSName,         
      2 AS Sort,         
           @StdDate,         
             '( ' + @MultiUMHelpComName + ' )' AS MultiUMHelpComName,         
           MAX(A.FundKindSSeq) AS FundKindSSeq,         
           MAX(A.MinorSort) AS MinorSort,         
           MAX(D.MinorSort) AS FundKindSort        
      FROM #Result AS A         
      OUTER APPLY ( SELECT SUM(InvestAmt) AS SumInvestAmt        
                      FROM #Result         
                  ) AS B         
     LEFT OUTER JOIN (        
                       SELECT (SUM(Z.ResultAmt) / NULLIF(SUM(InvestAmt),0)) AS SumProfitRate,         
                              (SUM(Z.InvestAmt * Z.ChProfitRate) / ISNULL(SUM(Z.InvestAmt),0)) AS ChProfitRate,         
                              (SUM(Z.SumResultAmt) / NULLIF(SUM(LYTestAmt),0)) AS PeProfitRate,         
                                Z.FundKindSeq,         
                              Z.FundKindSSeq        
                         FROM #Result AS Z         
                        GROUP BY Z.FundKindSeq, Z.FundKindSSeq        
                     ) AS C ON ( C.FundKindSeq = A.FundKindSeq AND C.FundKindSSeq = A.FundKindSSeq )         
      LEFT OUTER JOIN _TDAUMinor AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.FundKindSSeq )         
     WHERE A.FundKindSeq = 1010428002         
     GROUP BY A.FundKindName, A.FundKindSName         
        
    INSERT INTO #TEMP   
    (  
       FundKindName   ,FundKindSeq    ,FundName       ,PortionRate    ,Amt            ,  
       SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,FundKindLName  ,FundKindMName  ,  
       FundKindSName  ,Sort           ,StdDate        ,MultiUMHelpComName,FundKindSSeq   ,  
       MinorSort      ,FundKindSort     
    )      
    SELECT A.FundKindName,         
           A.FundKindSeq,         
           A.FundKindName + ' 소계',         
           CASE WHEN ISNULL(MAX(B.SumInvestAmt),0) = 0 THEN 0 ELSE SUM(A.InvestAmt) / MAX(B.SumInvestAmt) * 100 END AS PortionRate,         
             ROUND(SUM(A.InvestAmt)/1000000,0) AS Amt,         
           MAX(ISNULL(C.SumProfitRate,0)) AS SumProfitRate,         
           MAX(ISNULL(C.ChProfitRate,0)) AS ChProfitRate,         
           MAX(ISNULL(C.PeProfitRate,0)) AS PeProfitRate,         
           '' AS FundKindLName,         
           '' AS FundKindMName,         
           '' AS FundKindSName,         
           3 AS Sort,         
           @StdDate,         
           '( ' + @MultiUMHelpComName + ' )' AS MultiUMHelpComName,         
           MAX(FundKindSSeq) AS FundKindSSeq,         
           MAX(A.MinorSort) AS MinorSort,         
             999999 AS FundKindSort        
      FROM #Result AS A         
      OUTER APPLY ( SELECT SUM(InvestAmt) AS SumInvestAmt        
                      FROM #Result         
                  ) AS B        
      LEFT OUTER JOIN (        
                        SELECT (SUM(Z.ResultAmt) / NULLIF(SUM(InvestAmt),0)) AS SumProfitRate,         
                               (SUM(Z.InvestAmt * Z.ChProfitRate) / NULLIF(SUM(Z.InvestAmt),0)) AS ChProfitRate,         
                               (SUM(Z.SumResultAmt) / NULLIF(SUM(LYTestAmt),0)) AS PeProfitRate,          
                               Z.FundKindSeq        
                          FROM #Result AS Z         
                         GROUP BY Z.FundKindSeq        
                      ) AS C ON ( C.FundKindSeq = A.FundKindSeq )         
     GROUP BY A.FundKindName, A.FundKindSeq        
            
  
        
   -- --return     
   -- INSERT INTO #TEMP   
   -- (  
   --    FundKindName   ,FundKindSeq    ,FundName       ,PortionRate    ,Amt            ,  
   --    SumProfitRate   ,ChProfitRate    ,PeProfitRate    ,FundKindLName  ,FundKindMName  ,  
   --    FundKindSName  ,Sort           ,StdDate        ,MultiUMHelpComName,FundKindSSeq   ,  
   --    MinorSort      ,FundKindSort     
   --)      
   -- SELECT '',         
   --        9999999999,         
   --        '합계',         
   --        100 AS PortionRate,         
   --        ROUND(SUM(InvestAmt)/1000000,0) AS Amt,         
   --          MAX(ISNULL(C.SumProfitRate,0)) AS SumProfitRate,          
   --        MAX(ISNULL(C.ChProfitRate,0)) AS ChProfitRate,         
   --        MAX(ISNULL(C.PeProfitRate,0)) AS PeProfitRate,         
   --        '' AS FundKindLName,         
   --'' AS FundKindMName,         
   --        '' AS FundKindSName,         
   --        4 AS Sort,         
   --        @StdDate,         
   --        '( ' + @MultiUMHelpComName + ' )' AS MultiUMHelpComName,         
   --        MAX(A.FundKindSSeq) AS FundKindSSeq,         
   --        MAX(A.MinorSort) AS MinorSort,         
   --        99999999999 AS FundKindSort        
   --   FROM #Result AS A         
   --   OUTER APPLY (          
   -- SELECT (SUM(Z.ResultAmt) / NULLIF(SUM(InvestAmt),0)) AS SumProfitRate,         
   --                        (SUM(Z.InvestAmt * Z.ChProfitRate) / NULLIF(SUM(Z.InvestAmt),0)) AS ChProfitRate,         
   --                        (SUM(Z.SumResultAmt) / NULLIF(SUM(LYTestAmt),0)) AS PeProfitRate       
   --                   FROM #Result AS Z           
   --               ) AS C         
      
    
    --select FundName, SrtDate, SumResultAmt, TestAmt, *
    --  from #Result 
    ----where FundName = '신한은행외화표시채권' 
    ----order by TestAmt 
    --return 

    
    CREATE TABLE #Amt  
    (  
        UMHelpCom       INT,   
        FundSeq         INT,   
        Amt1            DECIMAL(19,5), -- 총실현금액   
        Amt2            DECIMAL(19,5), -- 기준일자의 투자원금 및 평가금액   
        SliptAmt        DECIMAL(19,5), -- 배당금액   
        ResultReAmt     DECIMAL(19,5), -- 성과보수금액   
        KindSeq         INT, 
        SrtDate         NCHAR(8) 
    )  
       
       
       
       
    SELECT DISTINCT A.UMHelpCom, A.FundSeq, A.SrtDate   
      INTO #SubTable  
      FROM KPX_TACEvalProfitItemMaster AS A   
      JOIN _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom)  AS B ON ( B.Code = A.UMHelpCom )   
     WHERE A.StdDate BETWEEN @SubStdDate AND @StdDate   
       
        
    -- 전부해지가 있는 실현손익   
    INSERT INTO #Amt ( UMHelpCom, FundSeq, Amt1, Amt2, SliptAmt, ResultReAmt, KindSeq, SrtDate )   
    SELECT A.UMHelpCom,   
           A.FundSeq ,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN ISNULL(I.AllCancelResultAmt,0) ELSE ISNULL(O.AllCancelResultAmt,0) END,0) AS Amt1,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN C.TestAmt ELSE H.InvestAmt END,0) Amt2,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN F.SliptAmt ELSE E.SliptAmt END,0) AS SliptAmt,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN F.ResultReAmt ELSE E.ResultReAmt END,0) AS ResultReAmt, 
           1, 
           A.SrtDate 
      FROM #SubTable                                AS A   
                 JOIN KPX_TACResultProfitItemMaster  AS B ON ( B.UMHelpCom = A.UMHelpCom AND B.FundSeq = A.FundSeq )   
      LEFT OUTER JOIN KPX_TACEvalProfitItemMaster    AS C ON ( C.UMHelpCom = A.UMHelpCom AND C.FundSeq = A.FundSeq AND C.StdDate = @SubStdDate )   
      LEFT OUTER JOIN (   
                        SELECT Z.FundSeq, Z.UMHelpCom, Z.InvestAmt  
                          FROM KPX_TACEvalProfitItemMaster AS Z    
                          JOIN (   
                                SELECT Y.UMHelpCom, Y.FundSeq , MIN(Y.StdDate) AS StdDate  
                                  FROM KPX_TACEvalProfitItemMaster AS Y   
                                 GROUP BY Y.UMHelpCom, Y.FundSeq   
                                ) AS Q ON ( Q.UMHelpCom = Z.UMHelpCom AND Q.FundSeq = Z.FundSeq AND Q.StdDate = Z.StdDate )  
                      ) AS H ON ( H.UMHelpCom = A.UMHelpCom AND H.FundSeq = A.FundSeq )   
      LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS IQ ON ( IQ.UMHelpCom = A.UMHelpCom AND IQ.FundSeq = A.FundSeq AND IQ.StdDate = @StdDate )   
      OUTER APPLY (SELECT SUM(AllCancelResultAmt) AS AllCancelResultAmt  
                     FROM KPX_TACResultProfitItemMaster AS Z   
                    WHERE Z.UMHelpCom = A.UMHelpCom  
                      AND Z.FundSeq = A.FundSeq   
                      AND Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                  ) AS I   
      OUTER APPLY (SELECT SUM(AllCancelResultAmt) AS AllCancelResultAmt  
                     FROM KPX_TACResultProfitItemMaster AS Z   
                    WHERE Z.UMHelpCom = A.UMHelpCom  
                      AND Z.FundSeq = A.FundSeq   
                      AND Z.StdDate BETWEEN A.SrtDate AND @StdDate   
        ) AS O   
      OUTER APPLY ( SELECT SUM(Z.SliptAmt) AS SliptAmt, SUM(Z.ResultReAmt) AS ResultReAmt, SUM(Z.CancelAmt) AS CancelAmt, SUM(Z.AllCancelAmt) AS AllCancelAmt  
                      FROM KPX_TACResultProfitItemMaster AS Z   
                     WHERE Z.StdDate BETWEEN A.SrtDate AND @StdDate   
                       AND Z.UMHelpCom = A.UMHelpCom AND Z.FundSeq = A.FundSeq   
                  ) AS E   
      OUTER APPLY ( SELECT SUM(Z.SliptAmt) AS SliptAmt, SUM(Z.ResultReAmt) AS ResultReAmt, SUM(Z.CancelAmt) AS CancelAmt, SUM(Z.AllCancelAmt) AS AllCancelAmt  
                      FROM KPX_TACResultProfitItemMaster AS Z   
                     WHERE Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                       AND Z.UMHelpCom = A.UMHelpCom AND Z.FundSeq = A.FundSeq   
                  ) AS F  
                JOIN (   
                        SELECT DISTINCT Z.UMHelpCom, Z.FundSeq   
                          FROM KPX_TACResultProfitItemMaster AS Z   
                         WHERE Z.AllCancelDate <> ''   
                           AND Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                      ) AS D ON ( D.UMHelpCom = A.UMHelpCom AND D.FundSeq = A.FundSeq )   
    -- 전부해지가 없는(일부해지인경우) 실현손익   
    INSERT INTO #Amt ( UMHelpCom, FundSeq, Amt1, Amt2, SliptAmt, ResultReAmt, KindSeq, SrtDate )   
    SELECT A.UMHelpCom,   
           A.FundSeq ,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN F.CancelResultAmt ELSE E.CancelResultAmt END,0) AS Amt1,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN CONVERT(DECIMAL(19,5),H.CancelAmt) / CONVERT(DECIMAL(19,5),C.InvestAmt) * C.TestAmt ELSE H.CancelAmt END,0) AS Amt2,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN F.SliptAmt ELSE E.SliptAmt END,0) AS SliptAmt,   
           ISNULL(CASE WHEN @SubStdDate >= A.SrtDate THEN F.ResultReAmt ELSE E.ResultReAmt END,0) AS ResultReAmt, 
           2,
           A.SrtDate 
      FROM #SubTable                                AS A   
      --LEFT OUTER JOIN KPX_TACResultProfitItemMaster  AS B ON ( B.UMHelpCom = A.UMHelpCom AND B.FundSeq = A.FundSeq )   
      LEFT OUTER JOIN KPX_TACEvalProfitItemMaster    AS C ON ( C.UMHelpCom = A.UMHelpCom AND C.FundSeq = A.FundSeq AND C.StdDate = @SubStdDate )   
      LEFT OUTER JOIN KPX_TACEvalProfitItemMaster    AS G ON ( G.UMHelpCom = A.UMHelpCom AND G.FundSeq = A.FundSeq AND G.StdDate = A.SrtDate )   
      OUTER APPLY ( SELECT SUM(Z.SliptAmt) AS SliptAmt, SUM(Z.ResultReAmt) AS ResultReAmt, SUM(Z.CancelResultAmt) AS CancelResultAmt--, SUM(Z.AllCancelAmt) AS AllCancelAmt  
                      FROM KPX_TACResultProfitItemMaster AS Z   
                     WHERE Z.StdDate BETWEEN A.SrtDate AND @StdDate   
                       AND Z.UMHelpCom = A.UMHelpCom AND Z.FundSeq = A.FundSeq   
                  ) AS E   
      OUTER APPLY ( SELECT SUM(Z.SliptAmt) AS SliptAmt, SUM(Z.ResultReAmt) AS ResultReAmt, SUM(Z.CancelResultAmt) AS CancelResultAmt--, SUM(Z.AllCancelAmt) AS AllCancelAmt  
                      FROM KPX_TACResultProfitItemMaster AS Z   
                     WHERE Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                       AND Z.UMHelpCom = A.UMHelpCom AND Z.FundSeq = A.FundSeq   
                  ) AS F   
      OUTER APPLY ( SELECT SUM(Z.CancelAmt) AS CancelAmt  
                      FROM KPX_TACResultProfitItemMaster AS Z   
                     WHERE Z.UMHelpCom = A.UMHelpCom   
                       AND Z.FundSeq = A.FundSeq   
                       AND Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                  ) AS H   
      LEFT OUTER JOIN (   
                        SELECT DISTINCT Z.UMHelpCom, Z.FundSeq   
                          FROM KPX_TACResultProfitItemMaster AS Z   
                         WHERE Z.AllCancelDate <> ''   
                           AND Z.StdDate BETWEEN @SubStdDate AND @StdDate   
                      ) AS D ON ( D.UMHelpCom = A.UMHelpCom AND D.FundSeq = A.FundSeq )   
     WHERE D.UMHelpCom IS NULL   
    
    
    
    
    --select * From #Result 
    --return 
    
    
    CREATE TABLE #Confirm 
    (
        KindName        NVARCHAR(200), 
        FundCode        NVARCHAR(200), 
        FundName        NVARCHAR(200), 
        KindName2       NVARCHAR(200), 
        SrtDate         NCHAR(8), 
        SumResultAmt    DECIMAL(19,5), 
        Amt2            DECIMAL(19,5), 
        Amt1            DECIMAL(19,5), 
        SliptAmt        DECIMAL(19,5), 
        ResultReAmt     DECIMAL(19,5), 
        CalcAmt         DECIMAL(19,5), 
        LYTestAmt       DECIMAL(19,5), 
        AllProfitRate    DECIMAL(19,5),  
        InvestAmtStd    DECIMAL(19,5),  
        InvestAmt       DECIMAL(19,5),  
        CancelAmt       DECIMAL(19,5), 
        Sort            INT 
        
    )
    
    INSERT INTO #Confirm 
    (
        KindName, FundCode, FundName, KindName2, SrtDate, 
        SumResultAmt, Amt2, Amt1, SliptAmt, ResultReAmt, 
        CalcAmt, LYTestAmt, AllProfitRate, InvestAmtStd, InvestAmt, 
        CancelAmt, Sort 
    ) 
    SELECT '평가손익' AS KindName, 
           B.FundCode, 
           A.FundName, 
           '운용' AS KindName2, 
           A.SrtDate,
           ROUND(A.SumResultAmt / 100,0), 
           0 AS Amt2, 
           0 AS Amt1, 
           0 AS SliptAmt, 
           0 AS ResultReAmt, 
           0 AS CalcAmt, 
           ISNULL(C.TestAmt,0) AS LYTestAmt, 
           0 AS AllProfitRate, 
           ISNULL(D.InvestAmt,0), 
           ISNULL(E.InvestAmt,0), 
           ISNULL(F.CancelAmt,0), 
           1
           
           
      FROM #Result                      AS A 
      LEFT OUTER JOIN KPX_TACFundMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT A.FundSeq, SUM(TestAmt) AS TestAmt   
                          FROM KPX_TACEvalProfitItemMaster AS A   
                          JOIN _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom)  AS B ON ( B.Code = A.UMHelpCom )   
                          LEFT OUTER JOIN KPX_TACFundMaster as c on ( C.CompanySeq = A.CompanySeq AND C.FundSeq = A.FundSeq ) 
                         WHERE A.StdDate = @SubStdDate  
                         GROUP BY A.FundSeq             
                      ) AS C ON ( C.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.InvestAmt) AS InvestAmt 
                          FROM KPX_TACEvalProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate = @SubStdDate 
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS D ON ( D.UMHelpCom = A.UMHelpCom AND D.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.InvestAmt) AS InvestAmt 
                          FROM KPX_TACEvalProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate = @StdDate 
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS E ON ( E.UMHelpCom = A.UMHelpCom AND E.FundSeq = A.FundSeq )     
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.CancelAmt) + SUM(Z.AllCancelAmt) AS CancelAmt 
                          FROM KPX_TACResultProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate BETWEEN @SubStdDate AND @StdDate
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS F ON ( F.UMHelpCom = A.UMHelpCom AND F.FundSeq = A.FundSeq )     
    
    INSERT INTO #Confirm 
    (
        KindName, FundCode, FundName, KindName2, SrtDate, 
        SumResultAmt, Amt2, Amt1, SliptAmt, ResultReAmt, 
        CalcAmt, LYTestAmt, AllProfitRate, InvestAmtStd, InvestAmt, 
        CancelAmt, Sort 
    ) 
    SELECT '실현손익' AS KindName, 
           B.FundCode, 
           B.FundName, 
           CASE WHEN A.KindSeq = 1 THEN '전부해지' ELSE '일부해지' END AS KindName2, 
           A.SrtDate, 
           0 AS SumResultAmt, 
           A.Amt2, 
           A.Amt1, 
           A.SliptAmt, 
           A.ResultReAmt, 
           ISNULL(A.Amt1,0) - ISNULL(A.Amt2,0) + ISNULL(A.SliptAmt,0) - ISNULL(A.ResultReAmt,0) AS CalcAmt, 
           CASE WHEN A.KindSeq = 2 THEN 0 ELSE ISNULL(C.TestAmt,0) END AS LYTestAmt, 
           0 AS AllProfitRate, 
           ISNULL(D.InvestAmt,0), 
           ISNULL(E.InvestAmt,0), 
           ISNULL(F.CancelAmt,0), 
           2 
           
      FROM #Amt AS A 
      LEFT OUTER JOIN KPX_TACFundMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT A.FundSeq, SUM(TestAmt) AS TestAmt   
                          FROM KPX_TACEvalProfitItemMaster AS A   
                          JOIN _FCOMXmlToSeq(@UMHelpCom, @MultiUMHelpCom)  AS B ON ( B.Code = A.UMHelpCom )   
                          LEFT OUTER JOIN KPX_TACFundMaster as c on ( C.CompanySeq = A.CompanySeq AND C.FundSeq = A.FundSeq ) 
                         WHERE A.StdDate = @SubStdDate  
                         GROUP BY A.FundSeq             
                      ) AS C ON ( C.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.InvestAmt) AS InvestAmt 
                          FROM KPX_TACEvalProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate = @SubStdDate 
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS D ON ( D.UMHelpCom = A.UMHelpCom AND D.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.InvestAmt) AS InvestAmt 
                          FROM KPX_TACEvalProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate = @StdDate 
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS E ON ( E.UMHelpCom = A.UMHelpCom AND E.FundSeq = A.FundSeq )    
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, Z.FundSeq, SUM(Z.CancelAmt) + SUM(Z.AllCancelAmt) AS CancelAmt 
                          FROM KPX_TACResultProfitItemMaster AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.StdDate BETWEEN @SubStdDate AND @StdDate
                         GROUP BY Z.UMHelpCom, Z.FundSeq 
                      ) AS F ON ( F.UMHelpCom = A.UMHelpCom AND F.FundSeq = A.FundSeq ) 
     WHERE Amt1 <> 0 
    
    
    INSERT INTO #Confirm 
    (
        KindName, FundCode, FundName, KindName2, SrtDate, 
        SumResultAmt, Amt2, Amt1, SliptAmt, ResultReAmt, 
        CalcAmt, LYTestAmt, AllProfitRate, InvestAmtStd, InvestAmt, 
        CancelAmt, Sort
    ) 
    SELECT '합계', 
           '', 
           '',
           '',
           '', 
           SUM(SumResultAmt), 
           0, 
           0, 
           0, 
           0, 
           SUM(CalcAmt), 
           SUM(LYTestAmt), 
           (SUM(SumResultAmt) + SUM(CalcAmt)) * 100 / SUM(LYTestAmt), 
           0, 
           0,
           0, 
           3
      FROM #Confirm 
    
    SELECT * 
      FROM #Confirm 
     ORDER BY Sort, FundCode
    
    
    RETURN          
go
exec KPX_SACFundManageConfirmQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SubStdDate>20141226</SubStdDate>
    <StdDate>20151030</StdDate>
    <UMHelpCom>1010494001</UMHelpCom>
    <MultiUMHelpCom>&amp;lt;XmlString&amp;gt;&amp;lt;Code&amp;gt;1010494001&amp;lt;/Code&amp;gt;&amp;lt;/XmlString&amp;gt;</MultiUMHelpCom>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034278,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028349