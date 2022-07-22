 
IF OBJECT_ID('hncom_SPRAdjWithHoldListSumQuery') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListSumQuery  
GO  
  
-- v2017.02.08
  
-- 원천세신고목록집계-조회 by 이재천
CREATE PROC hncom_SPRAdjWithHoldListSumQuery  
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
            @StdYM      NCHAR(6)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYM   NCHAR(6))    
    
    --select * from hncom_TAdjWithHoldList
    /***************************************
        사업소			DeptName
        사업소코드		DeptSeq
        총소득금액		TotAmt1
        비과세			TaxDiffAmt1
        신고소득금액		TaxAmt1
        소득세			IncomeTaxAmt1
        주민세			ResidentTaxAmt1
        소득금액			TotAmt2
        소득세			IncomeTaxAmt2
        주민세			ResidentTaxAmt2
        소득금액			TotAmt3
        소득세			IncomeTaxAmt3
        주민세			ResidentTaxAmt3
        소득금액			TotAmt4
        소득세			IncomeTaxAmt4
        주민세			ResidentTaxAmt4
        상근인원			EmpCnt
        소득세			IncomeTaxAmt5
        주민세			ResidentTaxAmt5
        소득세			IncomeTaxAmt6
        주민세			ResidentTaxAmt6
    ****************************************/
    CREATE TABLE #Result 
    (
        BizSeq          INT
       ,TotAmt1         DECIMAL(19,5)
       ,TaxDiffAmt1     DECIMAL(19,5)
       ,TaxAmt1         DECIMAL(19,5)
       ,IncomeTaxAmt1   DECIMAL(19,5)
       ,ResidentTaxAmt1 DECIMAL(19,5)
       ,TotAmt2         DECIMAL(19,5)
       ,IncomeTaxAmt2   DECIMAL(19,5)
       ,ResidentTaxAmt2 DECIMAL(19,5)
       ,TotAmt3         DECIMAL(19,5)
       ,IncomeTaxAmt3   DECIMAL(19,5)
       ,ResidentTaxAmt3 DECIMAL(19,5)
       ,TotAmt4         DECIMAL(19,5)
       ,IncomeTaxAmt4   DECIMAL(19,5)
       ,ResidentTaxAmt4 DECIMAL(19,5)
       ,EmpCnt          DECIMAL(19,5)
       ,IncomeTaxAmt5   DECIMAL(19,5)
       ,ResidentTaxAmt5 DECIMAL(19,5)
       ,IncomeTaxAmt6   DECIMAL(19,5) 
       ,ResidentTaxAmt6 DECIMAL(19,5)
    )
    
    -- 정산사업장 넣기
    INSERT INTO #Result (BizSeq)
    SELECT ValueSeq 
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014724 
       AND A.Serl = 1000001
    
    ------------------------------------------------------------------
    -- 근로소득 
    ------------------------------------------------------------------
    SELECT MinorSeq 
      INTO #MinorSeq1
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
       AND A.Serl = 1000003 
       AND A.ValueText = '1' -- 근로소득 체크되어 있는 소분류

    SELECT A.BizSeq, SUM(TotAmt) AS TotAmt, SUM(TaxAmt) AS TaxAmt, SUM(IncomeTaxAmt) AS IncomeTaxAmt, SUM(ResidentTaxAmt) AS ResidentTaxAmt
      INTO #Sub_Result1
      FROM hncom_TAdjWithHoldList AS A 
      JOIN #MinorSeq1             AS B ON ( B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET TotAmt1 = ISNULL(B.TotAmt,0) 
          ,TaxAmt1 = ISNULL(B.TaxAmt,0) 
          ,TaxDiffAmt1 = ISNULL(B.TotAmt,0) - ISNULL(B.TaxAmt,0)
          ,IncomeTaxAmt1 = ISNULL(B.IncomeTaxAmt,0)
          ,ResidentTaxAmt1 = ISNULL(B.ResidentTaxAmt,0)
      FROM #Result      AS A 
      LEFT OUTER JOIN #Sub_Result1 AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 근로소득, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 퇴직소득
    ------------------------------------------------------------------
    SELECT MinorSeq 
      INTO #MinorSeq2
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
       AND A.Serl = 1000004 
       AND A.ValueText = '1' -- 퇴직소득 체크되어 있는 소분류

    SELECT A.BizSeq, SUM(TotAmt) AS TotAmt, SUM(TaxAmt) AS TaxAmt, SUM(IncomeTaxAmt) AS IncomeTaxAmt, SUM(ResidentTaxAmt) AS ResidentTaxAmt
      INTO #Sub_Result2
      FROM hncom_TAdjWithHoldList AS A 
      JOIN #MinorSeq2             AS B ON ( B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET TotAmt2 = ISNULL(B.TotAmt,0) 
          ,IncomeTaxAmt2 = ISNULL(B.IncomeTaxAmt,0)
          ,ResidentTaxAmt2 = ISNULL(B.ResidentTaxAmt,0)
      FROM #Result                  AS A 
      LEFT OUTER JOIN #Sub_Result2  AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 퇴직소득, END
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 연말정산 / 퇴직소득 
    ------------------------------------------------------------------
    SELECT MinorSeq 
      INTO #MinorSeq3
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
       AND A.Serl = 1000005 
       AND A.ValueText = '1' -- 연말정산/퇴직소득 체크되어 있는 소분류

    SELECT A.BizSeq, SUM(TotAmt) AS TotAmt, SUM(TaxAmt) AS TaxAmt, SUM(IncomeTaxAmt) AS IncomeTaxAmt, SUM(ResidentTaxAmt) AS ResidentTaxAmt
      INTO #Sub_Result3
      FROM hncom_TAdjWithHoldList AS A 
      JOIN #MinorSeq3             AS B ON ( B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET TotAmt3 = ISNULL(B.TotAmt,0) 
          ,IncomeTaxAmt3 = ISNULL(B.IncomeTaxAmt,0)
          ,ResidentTaxAmt3 = ISNULL(B.ResidentTaxAmt,0)
      FROM #Result                  AS A 
      LEFT OUTER JOIN #Sub_Result3  AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 연말정산 / 퇴직소득, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 일용근로 / 기타소득
    ------------------------------------------------------------------
    SELECT MinorSeq 
      INTO #MinorSeq4
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
       AND A.Serl = 1000006 
       AND A.ValueText = '1' -- 일용근로/기타소득 있는 소분류

    SELECT A.BizSeq, SUM(TotAmt) AS TotAmt, SUM(TaxAmt) AS TaxAmt, SUM(IncomeTaxAmt) AS IncomeTaxAmt, SUM(ResidentTaxAmt) AS ResidentTaxAmt
      INTO #Sub_Result4
      FROM hncom_TAdjWithHoldList AS A 
      JOIN #MinorSeq4             AS B ON ( B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET TotAmt4 = ISNULL(B.TotAmt,0) 
          ,IncomeTaxAmt4 = ISNULL(B.IncomeTaxAmt,0)
          ,ResidentTaxAmt4 = ISNULL(B.ResidentTaxAmt,0)
      FROM #Result                  AS A 
      LEFT OUTER JOIN #Sub_Result4  AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 일용근로 / 기타소득, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 전월미환급
    ------------------------------------------------------------------
    SELECT MinorSeq 
      INTO #MinorSeq5
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
       AND A.Serl = 1000006 
       AND A.ValueText = '1' -- 일용근로/기타소득 있는 소분류

    SELECT A.BizSeq, SUM(TotAmt) AS TotAmt, SUM(TaxAmt) AS TaxAmt, SUM(IncomeTaxAmt) AS IncomeTaxAmt, SUM(ResidentTaxAmt) AS ResidentTaxAmt
      INTO #Sub_Result5
      FROM hncom_TAdjWithHoldList AS A 
      JOIN #MinorSeq5             AS B ON ( B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET IncomeTaxAmt5 = ISNULL(B.IncomeTaxAmt,0)
          ,ResidentTaxAmt5 = ISNULL(B.ResidentTaxAmt,0)
      FROM #Result                  AS A 
      LEFT OUTER JOIN #Sub_Result5  AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 전월미환급, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 상근인원
    ------------------------------------------------------------------
    SELECT A.BizSeq, SUM(EmpCnt) AS EmpCnt 
      INTO #EmpCnt 
      FROM hncom_TAdjWithHoldList AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
       AND UMTypeSeq IN ( 1014736001, 1014736002 ) 
     GROUP BY A.BizSeq 
    
    UPDATE A
       SET EmpCnt = ISNULL(B.EmpCnt,0)
      FROM #Result              AS A 
      LEFT OUTER JOIN #EmpCnt   AS B ON ( B.BizSeq = A.BizSeq ) 
    ------------------------------------------------------------------
    -- 상근인원, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 납부(환급)세액
    ------------------------------------------------------------------
    UPDATE A
       SET IncomeTaxAmt6 = A.IncomeTaxAmt1 + A.IncomeTaxAmt2 + A.IncomeTaxAmt3 + A.IncomeTaxAmt4 + A.IncomeTaxAmt5
          ,ResidentTaxAmt6 = A.ResidentTaxAmt1 + A.ResidentTaxAmt2 + A.ResidentTaxAmt3 + A.ResidentTaxAmt4 + A.ResidentTaxAmt5
      FROM #Result AS A 
    ------------------------------------------------------------------
    -- 납부(환급)세액, END 
    ------------------------------------------------------------------
    
    -- 최종조회
    SELECT B.BizName, A.*
      FROM #Result                  AS A 
      LEFT OUTER JOIN _THRBasBiz    AS B ON ( B.CompanySeq = @CompanySeq AND B.BizSeq = A.BizSeq ) 
    
    RETURN  
    GO

begin tran 
exec hncom_SPRAdjWithHoldListSumQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201701</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511161,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032798
rollback 