
IF OBJECT_ID('_SACLendListQuery') IS NOT NULL
    DROP PROC _SACLendListQuery
GO

-- v2014.02.07 

-- 대여금현황 By이재천
CREATE PROC dbo._SACLendListQuery                
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
		    @LendDateFr     NCHAR(8) ,
            @UMLendKind     INT ,
            @ExpireDateFr   NCHAR(8) ,
            @LendDateTo     NCHAR(8) ,
            @ExpireDateTo   NCHAR(8) ,
            @SMLendType     INT ,
            @LendNo         NVARCHAR(100), 
            @PivotDate      NCHAR(8) 
    
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
	SELECT  @LendDateFr     = ISNULL(LendDateFr,''), 
            @UMLendKind     = ISNULL(UMLendKind,0), 
            @ExpireDateFr   = ISNULL(ExpireDateFr,''), 
            @LendDateTo     = ISNULL(LendDateTo,''), 
            @ExpireDateTo   = ISNULL(ExpireDateTo,''), 
            @SMLendType     = ISNULL(SMLendType,0), 
            @LendNo         = ISNULL(LendNo,''), 
            @PivotDate      = ISNULL(PivotDate,'') 
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (LendDateFr      NCHAR(8) ,
            UMLendKind      INT ,
            ExpireDateFr    NCHAR(8) ,
            LendDateTo      NCHAR(8) ,
            ExpireDateTo    NCHAR(8) ,
            SMLendType      INT ,
            LendNo          NVARCHAR(100), 
            PivotDate       NCHAR(8) 
           )
            
    IF @LendDateTo = '' SELECT @LendDateTo = '99991231' 
    IF @ExpireDateTo = '' SELECT @ExpireDateTo = '99991231' 
    
    CREATE TABLE #AMT 
    (
        LendSeq         INT, 
        RePayAmt        DECIMAL(19,5), 
        LendBalanceAmt  DECIMAL(19,5), 
        TotIntAmt       DECIMAL(19,5), 
        IntPlanAmt      DECIMAL(19,5), 
        PayIntAmt       DECIMAL(19,5)
        
    )
    
    INSERT INTO #AMT(LendSeq, RePayAmt, LendBalanceAmt)--, PayIntAmt)
    SELECT A.LendSeq, 
           SUM(D.CrAmt), 
           MAX(ISNULL(A.Amt,0)) - SUM(ISNULL(D.CrAmt,0)) 
      FROM _TACLend    AS A 
      LEFT OUTER JOIN _TACSlipRem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.RemSeq = 2059 AND B.RemValSeq = A.LendSeq ) 
                 JOIN _TACSlipRem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.RemSeq = 2042 AND C.SlipSeq = B.SlipSeq AND C.RemValSeq = 4025001 ) 
      LEFT OUTER JOIN _TACSlipRow AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = C.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.SlipMstSeq = D.SlipMstSeq ) 
     WHERE D.AccDate <= @PivotDate
       AND E.IsSet = '1' 
     GROUP BY A.LendSeq 

    INSERT INTO #AMT(LendSeq, TotIntAmt, IntPlanAmt, PayIntAmt)
    SELECT A.LendSeq, 
           (SELECT SUM(PayIntAmt) FROM _TACLendPlan WHERE CompanySeq = @CompanySeq AND LendSeq = A.LendSeq GROUP BY LendSeq), 
           (SELECT SUM(PayIntAmt) FROM _TACLendPlan WHERE CompanySeq = @CompanySeq AND LendSeq = A.LendSeq GROUP BY LendSeq) - SUM(ISNULL(D.CrAmt,0)), 
           SUM(D.CrAmt)
      FROM _TACLend    AS A 
      LEFT OUTER JOIN _TACSlipRem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.RemSeq = 2059 AND B.RemValSeq = A.LendSeq ) 
                 JOIN _TACSlipRem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.RemSeq = 2042 AND C.SlipSeq = B.SlipSeq AND C.RemValSeq = 4025002 ) 
      LEFT OUTER JOIN _TACSlipRow AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = C.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.SlipMstSeq = D.SlipMstSeq ) 
     WHERE D.AccDate <= @PivotDate 
       AND E.IsSet = '1'
     GROUP BY A.LendSeq
    
    SELECT LendSeq, MAX(RepayAmt) AS RepayAmt, MAX(LendBalanceAmt) AS LendBalanceAmt, MAX(TotIntAmt) AS TotIntAmt, MAX(IntPlanAmt) AS IntPlanAmt, MAX(PayIntAmt) AS PayIntAmt
      INTO #AMT_Result
      FROM #AMT 
     GROUP BY LendSeq
    
    SELECT A.LendSeq, 
           A.SMLendType, -- 대여구분코드
           C.MinorName AS SMLendTypeName, -- 대여구분 
           A.LendNo, 
           A.CustSeq, 
           D.CustName, 
           A.EmpSeq, 
           E.EmpName, 
           A.AccSeq, -- 계정과목코드
           F.AccName, -- 계정과목 
           A.LendDate, -- 대여일 
           A.ExpireDate, -- 만기일 
           A.Amt, -- 대여금액 
           A.Remark, 
           A.UMLendKind, -- 대여금종류코드
           G.MinorName AS UMLendKindName, -- 대여금종류
           H.RepayAmt, -- 상환금액
           H.LendBalanceAmt, -- 대여금잔액 
           H.TotIntAmt, -- 총이자금액
           H.IntPlanAmt, -- 이자예정금액 
           H.PayIntAmt -- 납입이자금액 
      FROM _TACLend AS A 
      LEFT OUTER JOIN _TDASMinor   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMLendType ) 
      LEFT OUTER JOIN _TDACust     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAAccount  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor   AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMLendKind ) 
      LEFT OUTER JOIN #AMT_Result  AS H              ON ( H.LendSeq = A.LendSeq )  
      
     WHERE A.CompanySeq = @CompanySeq
       AND (A.LendDate BETWEEN @LendDateFr AND @LendDateTo)
       AND (@UMLendKind = 0 OR A.UMLendKind = @UMLendKind ) 
       AND (A.ExpireDate BETWEEN @ExpireDateFr AND @ExpireDateTo)
       AND (@SMLendType = 0 OR A.SMLendType = @SMLendType ) 
       AND (@LendNo = '' OR A.LendNo LIKE @LendNo + '%')
    
    RETURN
GO
exec _SACLendListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <LendDateFr>20140101</LendDateFr>
    <LendDateTo />
    <SMLendType />
    <LendNo />
    <UMLendKind />
    <ExpireDateFr>20140101</ExpireDateFr>
    <ExpireDateTo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9674,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11497


--select * from _TDACust where CompanySeq = 1 and CustSeq = 38177  

--select * from _TDAEmp where CompanySeq = 1 and EmpSeq 