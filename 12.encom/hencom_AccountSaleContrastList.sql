IF OBJECT_ID('hencom_AccountSaleContrastList') IS NOT NULL 
    DROP PROC hencom_AccountSaleContrastList
GO 

-- v2017.03.29 
/************************************************************
 설  명 - 데이터-회계/영업 잔액비교_hencom : 부서별 조회
 작성일 - 20161120
 작성자 - 이종민
************************************************************/
CREATE PROC dbo.hencom_AccountSaleContrastList
	@xmlDocument    NVARCHAR(MAX) ,  
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	DECLARE @docHandle    INT,
		    @CustSeq      INT ,
            @BasicYM      NCHAR(6) ,
            @SlipUnit     INT,
			@DeptSeq      INT,
            @SQL          NVARCHAR(MAX), 
            @IsBalance    NCHAR(1) 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @CustSeq      = ISNULL(CustSeq,0),
            @BasicYM      = ISNULL(BasicYM,''),
            @SlipUnit     = ISNULL(SlipUnit,0), 
            @IsBalance    = ISNULL(IsBalance,'0')
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            CustSeq       INT ,
            BasicYM       NCHAR(6) ,
            SlipUnit      INT, 
            IsBalance     NCHAR(1) 
           )
	
	-- 전표관리단위의 사업소를 Select
	SELECT	M.DeptSeq,M.DeptName ,A.DispSeq, M.SlipUnit, C.SlipUnitName
	INTO	#TMPMst
	FROM	_TDADept AS M                        
		LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq                     
															 AND A.DeptSeq = M.DeptSeq
		JOIN _TACSlipUnit AS C WITH(NOLOCK) ON M.SlipUnit = C.SlipUnit
	Where	(@SlipUnit = 0 or M.SlipUnit = @SlipUnit)
	AND		IsNull(A.UMTotalDiv,0) <> 0
    
	-- 영업 가계정
    CREATE TABLE #TempMAINResult(SlipUnit INT, SlipUnitName NVARCHAR(200), CustSeq INT, CustName NVARCHAR(200),
                                TempSLRemainAmt DECIMAL(19,5), TempSLChangeAmt DECIMAL(19,5), TempPastSLChangeAmt DECIMAL(19,5), TempSLPreSaleAmt DECIMAL(19,5),
						    	TempSLAmt DECIMAL(19,5), TempACAmt DECIMAL(19,5),TempDiffAmt DECIMAL(19,5) )

	-- 영업채권 외상매출금(계산서기준) - 총채권현황(FrmSLSaleBondTermTotal_hencom)
	CREATE TABLE #BondSLAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, DeptName NVARCHAR(40), ReceiptAmt DECIMAL(19,5), NoReceiptAmt DECIMAL(19,5), MiNoteAmt DECIMAL(19,5),
	                        PrevCreditAmt DECIMAL(19,5), SalesAmt DECIMAL(19,5), PrevBillAmt DECIMAL(19,5), PrevNotBillAmt DECIMAL(19,5),
							TotSalesAmt DECIMAL(19,5), TotBillAmt DECIMAL(19,5), TotBillAmtMiNote DECIMAL(19,5) )
	-- 영업 매출액
	CREATE TABLE #SaleSLAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, SaleAmt DECIMAL(19,5))
    
	-- 외상매출금(회계) 계정별 잔액조회_K-GAAP_hencom(FrmACAccBalanceList_GAAP_hencom)
	CREATE TABLE #BondACReceive(SlipUnitName NVARCHAR(100), SlipUnit INT, AccName NVARCHAR(100), AccSeq INT, CurrSeq INT, CurrName NVARCHAR(100), 
	                            ForwardForAmt DECIMAL(19,5), DrForAmt DECIMAL(19,5), CrForAmt DECIMAL(19,5), RemainForAmt DECIMAL(19,5), 
								ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
								UMCostType INT, AccNameOrg NVARCHAR(100), UMCostTypeName NVARCHAR(100), AccNo NVARCHAR(100), RemSeq INT, RemName NVARCHAR(100))
	-- 매출채권선수금(회계) 계정별 잔액조회_K-GAAP_hencom(FrmACAccBalanceList_GAAP_hencom)
	CREATE TABLE #BondACPre(SlipUnitName NVARCHAR(100), SlipUnit INT, AccName NVARCHAR(100), AccSeq INT, CurrSeq INT, CurrName NVARCHAR(100), 
	                        ForwardForAmt DECIMAL(19,5), DrForAmt DECIMAL(19,5), CrForAmt DECIMAL(19,5), RemainForAmt DECIMAL(19,5), 
							ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
							UMCostType INT, AccNameOrg NVARCHAR(100), UMCostTypeName NVARCHAR(100), AccNo NVARCHAR(100), RemSeq INT, RemName NVARCHAR(100))
	-- 매출채권선수금(회계) 계정별 잔액조회_K-GAAP_hencom(FrmACAccBalanceList_GAAP_hencom)
	CREATE TABLE #SaleACAmt(SlipUnitName NVARCHAR(100), SlipUnit INT, AccName NVARCHAR(100), AccSeq INT, CurrSeq INT, CurrName NVARCHAR(100), 
	                        ForwardForAmt DECIMAL(19,5), DrForAmt DECIMAL(19,5), CrForAmt DECIMAL(19,5), RemainForAmt DECIMAL(19,5), 
							ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
							UMCostType INT, AccNameOrg NVARCHAR(100), UMCostTypeName NVARCHAR(100), AccNo NVARCHAR(100), RemSeq INT, RemName NVARCHAR(100))
    
    -- insert #TempResult 문은 Proc안에 있음
    exec hencom_AccountSaleContrastListCalcNew @CompanySeq=1,@CustSeq = @CustSeq, @SlipUnit = @SlipUnit, @BasicYM = @BasicYM

    /*
	--SELECT @DeptSeq = MIN(DeptSeq) FROM #TMPMst
	SET @SQL = '<ROOT>
		<DataBlock1>
			<WorkingTag>A</WorkingTag>
			<IDX_NO>1</IDX_NO>
			<Status>0</Status>
			<DataSeq>1</DataSeq>
			<Selected>1</Selected>
			<TABLE_NAME>DataBlock1</TABLE_NAME>
			<IsChangedMst>1</IsChangedMst>
			<StdYM>' + @BasicYM + '</StdYM>
			<StdSaleType>1011915002</StdSaleType>
			<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
			<CustSeq>0</CustSeq>
			<BizUnit>1</BizUnit>
			</DataBlock1>
		</ROOT>'
    
	INSERT INTO #BondSLAmt(SlipUnit, SlipUnitName, ReceiptAmt, NoReceiptAmt, MiNoteAmt, PrevCreditAmt, SalesAmt, PrevBillAmt, PrevNotBillAmt, TotSalesAmt, TotBillAmt, TotBillAmtMiNote)
	exec hencom_SSLSaleBondTermTotalSlipUnit @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972
    */

    -- 영업 외상매출금
	IF @SlipUnit = 0
	BEGIN
		SET @SQL = '<ROOT>
			<DataBlock1>
				<WorkingTag>A</WorkingTag>
				<IDX_NO>1</IDX_NO>
				<Status>0</Status>
				<DataSeq>1</DataSeq>
				<Selected>1</Selected>
				<TABLE_NAME>DataBlock1</TABLE_NAME>
				<IsChangedMst>1</IsChangedMst>
				<StdYM>' + @BasicYM + '</StdYM>
				<StdSaleType>1011915002</StdSaleType>
				<DeptSeq />
				<CustSeq>' + CONVERT(NCHAR, @CustSeq) + '</CustSeq>
				<BizUnit>1</BizUnit>
				</DataBlock1>
			</ROOT>'
	END
	ELSE
	BEGIN
		SELECT @DeptSeq = MIN(DeptSeq) FROM #TMPMst
		SET @SQL = '<ROOT>
			<DataBlock1>
				<WorkingTag>A</WorkingTag>
				<IDX_NO>1</IDX_NO>
				<Status>0</Status>
				<DataSeq>1</DataSeq>
				<Selected>1</Selected>
				<TABLE_NAME>DataBlock1</TABLE_NAME>
				<IsChangedMst>1</IsChangedMst>
				<StdYM>' + @BasicYM + '</StdYM>
				<StdSaleType>1011915002</StdSaleType>
				<DeptSeq>' + CONVERT(NCHAR, @DeptSeq) + '</DeptSeq>
				<CustSeq></CustSeq>
				<BizUnit>1</BizUnit>
				</DataBlock1>
			</ROOT>'
	END
	INSERT INTO #BondSLAmt(DeptSeq, DeptName, ReceiptAmt, NoReceiptAmt, MiNoteAmt, PrevCreditAmt, SalesAmt, PrevBillAmt, PrevNotBillAmt, TotSalesAmt, TotBillAmt, TotBillAmtMiNote)
	exec hencom_SSLSaleBondTermTotalQuery @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	IF @DEPTSEQ = 35 -- 송악일경우 아스콘도 넣어줌
	BEGIN
		SET @SQL = '<ROOT>
			<DataBlock1>
				<WorkingTag>A</WorkingTag>
				<IDX_NO>1</IDX_NO>
				<Status>0</Status>
				<DataSeq>1</DataSeq>
				<Selected>1</Selected>
				<TABLE_NAME>DataBlock1</TABLE_NAME>
				<IsChangedMst>1</IsChangedMst>
				<StdYM>' + @BasicYM + '</StdYM>
				<StdSaleType>1011915002</StdSaleType>
				<DeptSeq>' + CONVERT(NCHAR, 53) + '</DeptSeq>
				<CustSeq>' + CONVERT(NCHAR, @CustSeq) + '</CustSeq>
				<BizUnit>1</BizUnit>
				</DataBlock1>
			</ROOT>'

			INSERT INTO #BondSLAmt(DeptSeq, DeptName, ReceiptAmt, NoReceiptAmt, MiNoteAmt, PrevCreditAmt, SalesAmt, PrevBillAmt, PrevNotBillAmt, TotSalesAmt, TotBillAmt, TotBillAmtMiNote)
			exec hencom_SSLSaleBondTermTotalQuery @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972
	END

	UPDATE  a
	SET     a.SlipUnit = b.SlipUnit
	,		a.SlipUnitName = b.SlipUnitName
	FROM    #BondSLAmt as a
	    JOIN #TMPMst as b on a.deptseq = b.deptseq
    
	-- 회계 외상매출금 INSERT
	SET @SQL = '<ROOT>
	  <DataBlock1>
		<WorkingTag>A</WorkingTag>
		<IDX_NO>1</IDX_NO>
		<Status>0</Status>
		<DataSeq>1</DataSeq>
		<Selected>1</Selected>
		<TABLE_NAME>DataBlock1</TABLE_NAME>
		<IsChangedMst>0</IsChangedMst>
		<FSDomainSeq />
		<AccUnit>1</AccUnit>
		<AccDate>' + @BasicYM + '01' + '</AccDate>
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeqFr>18</AccSeqFr>
		<AccSeqTo>18</AccSeqTo>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	insert into #BondACReceive
	EXEC hencom_SACLedgerQueryAccBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1035830,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029516

	-- 회계 매출채권선수금 INSERT
	SET @SQL = '<ROOT>
	  <DataBlock1>
		<WorkingTag>A</WorkingTag>
		<IDX_NO>1</IDX_NO>
		<Status>0</Status>
		<DataSeq>1</DataSeq>
		<Selected>1</Selected>
		<TABLE_NAME>DataBlock1</TABLE_NAME>
		<IsChangedMst>0</IsChangedMst>
		<FSDomainSeq />		<AccUnit>1</AccUnit>
		<AccDate>' + @BasicYM + '01' + '</AccDate>
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeqFr>113</AccSeqFr>
		<AccSeqTo>113</AccSeqTo>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	insert into #BondACPre
	EXEC hencom_SACLedgerQueryAccBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1035830,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029516
	
	-- 영업 매출액
	INSERT INTO #SaleSLAmt ( SlipUnit, SlipUnitName, DeptSeq, SaleAmt )
	SELECT	b.SlipUnit, b.SlipUnitName, a.DeptSeq, sum(a.CurAmt)
	FROM	hencom_VInvoiceReplaceItem as a
		JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	WHERE	a.WorkDate <> '20160101'
	AND		a.WorkDate BETWEEN LEFT(@BasicYM, 4) + '0101' AND @BasicYM + '31'
	AND		a.IsPreSales = 0
	GROUP BY b.SlipUnit, b.SlipUnitName, a.DeptSeq

	--UNION ALL

	--SELECT	b.SlipUnit, b.SlipUnitName, a.DeptSeq, sum(a.CurAmt)
	--FROM	hencom_TSLSalesCreditBasicData as a
	--	JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	--WHERE	a.WorkDate <> '20160101'
	--AND		a.WorkDate BETWEEN LEFT(@BasicYM, 4) + '0101' AND @BasicYM + '31'
	--GROUP BY b.SlipUnit, b.SlipUnitName, a.DeptSeq

	-- 회계 매출액 Insert
	SET @SQL = '<ROOT>
	  <DataBlock1>
		<WorkingTag>A</WorkingTag>
		<IDX_NO>1</IDX_NO>
		<Status>0</Status>
		<DataSeq>1</DataSeq>
		<Selected>1</Selected>
		<TABLE_NAME>DataBlock1</TABLE_NAME>
		<IsChangedMst>1</IsChangedMst>
		<FSDomainSeq />
		<AccUnit>1</AccUnit>
		<AccDate>' + @BasicYM + '01' + '</AccDate>
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeqFr>181</AccSeqFr>
		<AccSeqTo>738</AccSeqTo>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'
	INSERT INTO #SaleACAmt
	exec hencom_SACLedgerQueryAccBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972
    

    -- 영업매출 회계반영(이전년도)
    SELECT A.WorkDate, D.SlipUnit, D.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, A.ReplaceRegSeq, A.InvoiceSeq, A.InvoiceSerl, SUM(A.CurAmt) AS CurAmt 
      INTO #hencom_VInvoiceReplaceItem 
      FROM hencom_VInvoiceReplaceItem  AS A 
      JOIN #TMPMst                     AS D ON ( D.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkDate <> '20160101' 
       AND A.IsPreSales = 0
       AND A.ReplaceRegSeq IS NOT NULL
     GROUP BY A.WorkDate, D.SlipUnit, D.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, A.ReplaceRegSeq, A.InvoiceSeq, A.InvoiceSerl

    SELECT A.ReplaceRegSeq, A.SlipSeq, SUM(A.AdjAmt) AS AdjAmt
      INTO #hencom_TAcAdjTempAccount
      FROM hencom_TAcAdjTempAccount AS A 
     GROUP BY A.ReplaceRegSeq, A.SlipSeq

	CREATE TABLE #SaleSLPastAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, CustSeq INT, CustName NVARCHAR(200), SalesSLPastAmt DECIMAL(19,5))
    INSERT INTO #SaleSLPastAmt ( SlipUnit, SlipUnitName, DeptSeq, CustSeq, CustName, SalesSLPastAmt )
    SELECT A.SlipUnit, A.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, B.AdjAmt
      FROM #hencom_VInvoiceReplaceItem   AS A 
      JOIN #hencom_TAcAdjTempAccount    AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
      JOIN _TACSlipRow                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
      JOIN _TSLInvoiceItem              AS E ON ( E.CompanySeq = @CompanySeq and E.InvoiceSeq = A.InvoiceSeq AND E.InvoiceSerl = A.InvoiceSerl ) 
     WHERE C.AccDate BETWEEN LEFT(@BasicYM,4) + '0101' AND CONVERT(NCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,1,LEFT(@BasicYM,6) + '01')),112)
       AND LEFT(A.WorkDate,4) < LEFT(C.AccDate,4) 



	 --select * from #TempMAINResult
	 --select * from #BondSLAmt
	 --select * from #BondACReceive
	 --select * from #BondACPre
	 --select * from #SaleACAmt
    



	SELECT	a.BasicYm
	,		a.SlipUnit
	,		a.SlipUnitName
	,		SUM(a.TempSLAmt) as TempSLAmt
	,		SUM(a.TempACAmt) as TempACAmt
	,		SUM(a.TempDiffAmt) as TempDiffAmt
	,		SUM(a.TotBillAmt) as BondSLAmt
	,		SUM(a.BondACReceiveAmt) - SUM(a.BondACPreAmt) as BondACAmt
	,		SUM(a.TotBillAmt) - (SUM(a.BondACReceiveAmt) - SUM(a.BondACPreAmt)) as BondDiffAmt
	,		SUM(a.SaleSLAmt) as SaleSLAmt
	,		SUM(a.SaleACAmt) as SaleACAmt
	,		SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) as SaleDiffAmt
	,		SUM(a.TempSLChangeAmt) as TempSLChangeAmt
    ,		SUM(a.TempPastSLChangeAmt) as TempPastSLChangeAmt 
    ,       SUM(a.SalesSLPastAmt) as SalesSLPastAmt
	,		SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) - SUM(a.TempSLChangeAmt) - SUM(a.TempPastSLChangeAmt) - SUM(A.SalesSLPastAmt) as TempDiffAmt2
	FROM	(
		SELECT	@BasicYM as BasicYM
		,		a.SlipUnit
		,		a.SlipUnitName
		,		sum(a.TempSLAmt) as TempSLAmt
		,		sum(a.TempACAmt) as TempACAmt
		,		sum(a.TempDiffAmt) as TempDiffAmt
		,		0 as TotBillAmt
		,		0 as BondACReceiveAmt
		,		0 as BondACPreAmt
		,		0 as SaleSLAmt
		,		0 as SaleACAmt
		,		SUM(a.TempSLChangeAmt) as TempSLChangeAmt
        ,		SUM(a.TempPastSLChangeAmt) as TempPastSLChangeAmt
        ,       0 AS SalesSLPastAmt
		FROM	#TempMAINResult AS A
		GROUP BY a.SlipUnit, a.SlipUnitName

		UNION ALL

		SELECT	@BasicYM as BasicYM
		,		b.SlipUnit
		,		b.SlipUnitName
		,		0, 0, 0
		,		sum(b.TotBillAmt) as TotBillAmt
		,		0, 0, 0, 0, 0, 0, 0 
		FROM	#BondSLAmt as b
		GROUP BY b.SlipUnit, b.SlipUnitName

		UNION ALL

		SELECT	@BasicYM as BasicYM
		,		c.SlipUnit
		,		c.SlipUnitName
		,		0, 0, 0, 0
		,		c.RemainAmt
		,		0, 0, 0, 0, 0, 0 
		From	#BondACReceive as c

		UNION ALL

		SELECT	@BasicYM as BasicYM
		,		d.SlipUnit
		,		d.SlipUnitName
		,		0, 0, 0, 0, 0
		,		d.RemainAmt
		,		0, 0, 0, 0, 0 
		From	#BondACPre as d
		
		UNION ALL

		SELECT	@BasicYM as BasicYM
		,		e.SlipUnit
		,		e.SlipUnitName
		,		0, 0, 0, 0, 0, 0
		,		SUM(e.SaleAmt) as SaleSLAmt
		,		0, 0, 0, 0
		FROM	#SaleSLAmt e
		GROUP BY e.SlipUnit
		,		e.SlipUnitName

		UNION ALL
		
		SELECT	@BasicYM as BasicYM
		,		f.SlipUnit
		,		f.SlipUnitName
		,		0, 0, 0, 0, 0, 0, 0
		,		sum(f.RemainAmt) as SaleACAmt
		,		0, 0, 0  
		FROM	#SaleACAmt as f
		GROUP BY f.SlipUnit
		,		f.SlipUnitName
        
        UNION ALL 

        SELECT  @BasicYM as BasicYM
		       ,g.SlipUnit
		       ,g.SlipUnitName
		       ,0 ,0, 0, 0, 0 
		       ,0 ,0, 0, 0, 0 
               , SUM(SalesSLPastAmt)
		FROM	#SaleSLPastAmt as g
		GROUP BY g.SlipUnit
		,		 g.SlipUnitName
	) AS A
    
	group by a.BasicYm, a.SlipUnit, a.SlipUnitName
    HAVING @IsBalance = '0' 
        OR ( @IsBalance = '1' AND ( SUM(a.TempDiffAmt) <> 0 
                                 OR SUM(a.TotBillAmt) - (SUM(a.BondACReceiveAmt) - SUM(a.BondACPreAmt)) <> 0 
                                 OR SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) - SUM(a.TempSLChangeAmt) - SUM(a.TempPastSLChangeAmt) - SUM(A.SalesSLPastAmt) <> 0 
                                  ) 
           ) 
     
RETURN

go 
exec hencom_AccountSaleContrastList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BasicYM>201612</BasicYM>
    <IsBalance>0</IsBalance>
    <SlipUnit>0</SlipUnit>
    <CustSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510308,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032119

