  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimListQuery') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimListQuery  
GO  
  
-- v2016.02.05  
  
-- 자금운용대행수수료청구현황-조회 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimListQuery  
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
            @StdYMFr    NCHAR(6), 
            @StdYMTo    NCHAR(6), 
            @UMHelpCom  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYMFr = ISNULL( StdYMFr, '' ),  
           @StdYMTo = ISNULL( StdYMTo, '' ), 
           @UMHelpCom = ISNULL( UMHelpCom, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYMFr     NCHAR(6), 
            StdYMTo     NCHAR(6), 
            UMHelpCom   INT 
           )    
    
    -- 기초데이터   
    SELECT A.StdYM, 
           C.MinorName AS UMHelpComName, 
           A.UMHelpCom, 
           B.FundName,
           B.ActAmt, 
           B.CancelDate, 
           B.ProfitRate, 
           B.ProfitAmt, 
           B.SrtDate, 
           B.EndDate, 
           B.FromToDate, 
           B.StdProfitRate, 
           B.ExcessProfitAmt, 
           B.AdviceAmt, 
           A.LastYMClaimAmt AS LastYMClaimAmt, 
           A.StdYMClaimAmt AS StdYMClaimAmt, 
           1 AS Sort, 
           B.FundCode
      INTO #Result 
      FROM KPXHD_TFAFundChargeClaim                 AS A 
                 JOIN KPXHD_TFAFundChargeClaimItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.FundChargeSeq = A.FundChargeSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMHelpCom ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.StdYM BETWEEN @StdYMFr AND @StdYMTo 
       AND ( @UMHelpCom = 0 OR A.UMHelpCom = @UMHelpCom ) 
     ORDER BY A.UMHelpCom, A.StdYM
    
    
    -- 기준수익률미달분정산, 당월청구분 값 화사구분으로 구하기 
    SELECT UMHelpCom, SUM(LastYMClaimAmt) AS LastYMClaimAmt, SUM(StdYMClaimAmt) AS StdYMClaimAmt 
      INTO #SUMAmt 
      FROM ( 
            SELECT DISTINCT StdYM, UMHelpCom, LastYMClaimAmt, StdYMClaimAmt 
              FROM #Result 
           ) AS A 
     GROUP BY A.UMHelpCom
    
    
    IF EXISTS (SELECT 1 FROM #Result)
    BEGIN 
            -- 소계 행 넣기 
            INSERT INTO #Result 
            (
                StdYM, UMHelpComName, UMHelpCom, FundName, ActAmt, 
                CancelDate, ProfitRate, ProfitAmt, SrtDate, EndDate, 
                FromToDate, StdProfitRate, ExcessProfitAmt, AdviceAmt, LastYMClaimAmt, 
                StdYMClaimAmt, Sort, FundCode
            )
            SELECT '', '소  계', A.UMHelpCom, '', SUM(ActAmt), 
                   '', 0, SUM(ProfitAmt), '', '', 
                   0, 0, SUM(ExcessProfitAmt), SUM(AdviceAmt), MAX(B.LastYMClaimAmt), 
                   MAX(B.StdYMClaimAmt), 2, ''
              FROM #Result AS A 
              JOIN #SUMAmt   AS B ON ( B.UMHelpCom = A.UMHelpCom ) 
             GROUP BY A.UMHelpCom, A.UMHelpComName
            
            
            -- 합계 행 넣기 
            INSERT INTO #Result 
            (
                StdYM, UMHelpComName, UMHelpCom, FundName, ActAmt, 
                CancelDate, ProfitRate, ProfitAmt, SrtDate, EndDate, 
                FromToDate, StdProfitRate, ExcessProfitAmt, AdviceAmt, LastYMClaimAmt, 
                StdYMClaimAmt, Sort, FundCode
            )
            SELECT '', '합  계', 1010494999, '', SUM(A.ActAmt), 
                   '', 0, SUM(A.ProfitAmt), '', '', 
                   0, 0, SUM(A.ExcessProfitAmt), SUM(A.AdviceAmt), SUM(A.LastYMClaimAmt), 
                   SUM(A.StdYMClaimAmt), 3, ''
              FROM #Result AS A 
             WHERE Sort = 2 
    END  
    
    -- 최종 조회 
    SELECT StdYM, UMHelpComName, UMHelpCom, FundName, ActAmt, 
           CancelDate, ProfitRate, ProfitAmt, SrtDate, EndDate, 
           FromToDate, StdProfitRate, ExcessProfitAmt, AdviceAmt, 
           CASE WHEN Sort = 1 THEN 0 ELSE LastYMClaimAmt END AS LastYMClaimAmt, CASE WHEN Sort = 1 THEN 0 ELSE StdYMClaimAmt END AS StdYMClaimAmt, Sort, FundCode
      FROM #Result 
     ORDER BY UMHelpCom, Sort, StdYM, FundCode
     
     
     
    
    RETURN  
    GO
exec KPXHD_SFAFundChargeClaimListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYMFr>201501</StdYMFr>
    <StdYMTo>201602</StdYMTo>
    <UMHelpCom>1010494002</UMHelpCom>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034672,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028958