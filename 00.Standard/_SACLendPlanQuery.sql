    
IF OBJECT_ID('_SACLendPlanQuery') IS NOT NULL 
    DROP PROC _SACLendPlanQuery 
GO

-- v2103.12.19 

-- 대여금납입계획생성 by이재천  
CREATE PROCEDURE _SACLendPlanQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10) = '',    
    @CompanySeq     INT = 0,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    
    DECLARE @docHandle          INT,    
            @LendSeq            INT,    
            @OddTime            INT    
            --@IsCalcAuto         nchar(1)    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT @LendSeq     = LendSeq--,    
           --@IsCalcAuto  = IsCalcAuto    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (LendSeq     INT)    
    
    SELECT @OddTime     = OddTime  -- 단수차이조정회차    
      FROM _TACLendRepayOpt AS A WITH (NOLOCK)    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.LendSeq    = @LendSeq    
       AND A.ChgDate    = (SELECT MAX(ChgDate) FROM _TACLendRepayOpt WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND LendSeq = @LendSeq)    
    

    -- 서비스 마스타 등록 생성    
    CREATE TABLE #tmp (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#tmp'         
    IF @@ERROR <> 0 RETURN     
    
    ALTER TABLE #tmp ADD SMRepayType        INT NULL
    ALTER TABLE #tmp ADD Amt                DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD InterestRate       DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD LendDate           NVARCHAR(8) NULL
    ALTER TABLE #tmp ADD ForAmt             DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD CurrSeq            INT NULL
    ALTER TABLE #tmp ADD ExRate             DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD FrDateRepOfRepay   NVARCHAR(8) NULL
    ALTER TABLE #tmp ADD ToDateRepOfRepay   NVARCHAR(8) NULL
    ALTER TABLE #tmp ADD FrDateRepOfInt     NVARCHAR(8) NULL
    ALTER TABLE #tmp ADD ToDateRepOfInt     NVARCHAR(8) NULL
    ALTER TABLE #tmp ADD SMCalcMethod       INT NULL
    ALTER TABLE #tmp ADD InterestTerm       INT NULL
    ALTER TABLE #tmp ADD DeferYear          INT NULL
    ALTER TABLE #tmp ADD DeferMonth         INT NULL
    ALTER TABLE #tmp ADD RepayTerm          INT NULL
    ALTER TABLE #tmp ADD RepayCnt           INT NULL
    ALTER TABLE #tmp ADD OddTime            INT NULL
    ALTER TABLE #tmp ADD OddUnitAmt         DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD BalanceAmt         DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD PayForIntAmt       DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD PayForAmt          DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD TotForAmt          DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD BalanceForAmt      DECIMAL(19,5) NULL
    ALTER TABLE #tmp ADD SMInterestOrCapital INT NULL
    ALTER TABLE #tmp ADD IsOddTime          INT NULL
    ALTER TABLE #tmp ADD IntDayCountType    INT NULL 
    
    UPDATE #tmp
       SET SMRepayType      = C.SMRepayType, 
           Amt              = B.Amt,  
           InterestRate     = D.InterestRate, 
           LendDate         = B.LendDate, 
           ForAmt           = ISNULL(B.ForAmt,0), 
           CurrSeq          = ISNULL(B.CurrSeq,0), 
           ExRate           = ISNULL(B.ExRate,0), 
           FrDateRepOfRepay = C.FrDate, 
           ToDateRepOfRepay = C.ToDate, 
           FrDateRepOfInt   = D.FrDate, 
           ToDateRepOfInt   = D.ToDate, 
           SMCalcMethod     = D.SMCalcMethod, 
           InterestTerm     = D.InterestTerm, 
           DeferYear        = C.DeferYear, 
           DeferMonth       = C.DeferMonth, 
           RepayTerm        = C.RepayTerm, 
           RepayCnt         = C.RepayCnt, 
           OddTime          = C.OddTime, 
           OddUnitAmt       = C.OddUnitAmt, 
           IntDayCountType  = D.IntDayCountType
    
      FROM #tmp                 AS A 
      LEFT OUTER JOIN _TACLend             AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
      LEFT OUTER JOIN _TACLendRePayOpt     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.LendSeq = A.LendSeq ) 
      LEFT OUTER JOIN _TACLendInterestOpt  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.LendSeq = A.LendSeq ) 
    
    --select * from #tmp
    --return 
        EXEC _SUTACMakeLendPlan @CompanySeq, '#tmp'    
    
        IF @@ERROR <> 0 RETURN     
    
    --select * from #tmp
    --return 

        SELECT A.LendSeq,               -- 대여금내부코드   
               A.Serl,                  -- 일련번호    
               A.PayDate,               -- 납입일   
               ISNULL((SELECT MAX(payCnt)   FROM _TACLendPlan WHERE CompanySeq = @CompanySeq AND LendSeq = @LendSeq),0 ) --  AND ISNULL(RepaySlipSeq, 0) > 0 ) ,0)    
               + ROW_NUMBER() OVER(ORDER BY PayCnt) AS PayCnt,                -- 지급회차    
               A.FrDate,                -- 지급기간시작    
               A.ToDate,                -- 지급기간끝    
               A.PayAmt,                -- 원금상환액      
               A.PayIntAmt,             -- 이자지급액    
               A.TotAmt,                -- 원리금    
               A.BalanceAmt            -- 잔액    
          
          FROM #tmp AS A      
         WHERE A.PayCnt IS NOT NULL    
           AND A.FrDate  > ISNULL((SELECT MAX(FrDate) FROM _TACLendPlan WHERE CompanySeq = @CompanySeq AND LendSeq = @LendSeq),0)-- AND ISNULL(RepaySlipSeq, 0) > 0),'')    
    
   
         UNION ALL    
    
        SELECT A.LendSeq,               -- 차입내부코드    
               A.Serl,                  -- 일련번호    
               A.PayDate,               -- 지급일자     
               A.PayCnt,                -- 지급회차    
               A.FrDate,                -- 지급기간시작    
               A.ToDate,                -- 지급기간끝    
               A.PayAmt,                -- 원금상환액    
               A.PayIntAmt,             -- 이자지급액    
               A.PayAmt + A.PayIntAmt       AS TotAmt,          -- 원리금    
               B.Amt - (    SELECT SUM(PayAmt)    
                                  FROM _TACLendPlan    
                                 WHERE CompanySeq   = A.CompanySeq    
                                   AND LendSeq      = A.LendSeq    
                                   AND PayCnt       <= A.PayCnt)    AS BalanceAmt      -- 잔액    

          FROM _TACLendPlan AS A WITH (NOLOCK)    
          LEFT OUTER JOIN _TACLend AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.LendSeq = A.LendSeq ) 
         WHERE A.CompanySeq = @CompanySeq    
           AND A.LendSeq    = @LendSeq    
         ORDER BY PayCnt    
    
        RETURN     
GO
exec _SACLendPlanQuery @xmlDocument=N'<ROOT>
  <DataBlock4>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock4</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <LendSeq>37</LendSeq>
  </DataBlock4>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392