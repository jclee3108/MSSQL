IF OBJECT_ID('hencom_SACSlipOnCustAgeIsSetQuery') IS NOT NULL 
    DROP PROC hencom_SACSlipOnCustAgeIsSetQuery
GO 

-- v2017.04.03

/************************************************************
 설  명 - 건별반제 거래처별 연령분석 조회(승인된전표)
 작성일 - 2016.04.14
 작성자 - 박수영
  수정: 2017.03.31 by박수영 기준년, 기준월 조건 추가.
 ************************************************************/
 CREATE PROCEDURE hencom_SACSlipOnCustAgeIsSetQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10) = '',
     @CompanySeq     INT = 0,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
 
     -- 변수선언 부분
    DECLARE @docHandle      INT,
            @AccSeq         INT,
            @AccDate        NCHAR(8),
            @AccDateYM        NCHAR(6),
            @IsSet          NCHAR(1),
            @Date00         NVARCHAR(06),
            @Date01         NVARCHAR(06),
            @Date02         NVARCHAR(06),
            @Date03         NVARCHAR(06),
            @Date04         NVARCHAR(06),
            @Date05         NVARCHAR(06),
            @Date06         NVARCHAR(06),
            @Date07         NVARCHAR(06),
            @Date08         NVARCHAR(06),
            @Date09         NVARCHAR(06),
            @Date10         NVARCHAR(06),
            @Date11         NVARCHAR(06),
            @Date12         NVARCHAR(06),
            @Date13         NVARCHAR(06),
            @Date14         NVARCHAR(06),
            @Date15         NVARCHAR(06),
            @Date16         NVARCHAR(06),
            @Date17         NVARCHAR(06),
            @Date18         NVARCHAR(06),
            @Date19         NVARCHAR(06),
            @Date20         NVARCHAR(06),
            @Date21         NVARCHAR(06),
            @Date22         NVARCHAR(06),
            @Date23         NVARCHAR(06),
            @Date24         NVARCHAR(06),
            @Date25         NVARCHAR(06),
            @Date26         NVARCHAR(06),
            @Date27         NVARCHAR(06),
            @Date28         NVARCHAR(06),
            @Date29         NVARCHAR(06),
            @Date30         NVARCHAR(06),
            @Date31         NVARCHAR(06),
            @Date32         NVARCHAR(06),
            @Date33         NVARCHAR(06),
            @Date34         NVARCHAR(06),
            @Date35         NVARCHAR(06),
            @Date36         NVARCHAR(06),
             @DeptSeq   INT,
             @CustSeq        INT,
             @Date1Year NCHAR(8) ,
             @Date2Year NCHAR(8) ,
             @Date3Year NCHAR(8) ,
             @Date4Year NCHAR(8),
             @AccDateLast NCHAR(8),
             @EnvValue          NVARCHAR(500),
             @EnvValue2         NVARCHAR(500) ,
			 @SlipUnit        INT  ,
			 @IsMonth			NCHAR(1)
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      
      SELECT
            @DeptSeq     = ISNULL(DeptSeq, 0),
            @CustSeq         = ISNULL(CustSeq,0),
            @AccDateYM = ISNULL(AccDateYM,''),
			@SlipUnit   = isnull(SlipUnit,0),
			@IsMonth = IsMonth
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (
             DeptSeq            INT,
             CustSeq			INT,
             AccDateYM		NCHAR(6),
			 SlipUnit		INT,
			 IsMonth		NCHAR(1))
             
    SET @IsSet = '1'
    SET @AccDate = CONVERT(NCHAR(8),DATEADD(d,-1,CONVERT(NCHAR(8),DATEADD(M,1,@AccDateYM+'01'),112)),112)
    SET @AccDateLast = LEFT(@AccDateYM,4)+'1231'
    
  
      SELECT @Date00 = SUBSTRING(@AccDate, 1, 6),                                  --  this        2xxx06
            @Date01 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -1, @AccDate), 112), 1, 6),     --  -01         
            @Date02 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -2, @AccDate), 112), 1, 6),     --  -02         
            @Date03 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -3, @AccDate), 112), 1, 6),     --  -03         
            @Date04 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -4, @AccDate), 112), 1, 6),     --  -04         
            @Date05 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -5, @AccDate), 112), 1, 6),     --  -05         
            @Date06 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -6, @AccDate), 112), 1, 6),     --  -06         
            @Date07 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -7, @AccDate), 112), 1, 6),     --  -07         
            @Date08 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -8, @AccDate), 112), 1, 6),     --  -08         
            @Date09 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -9, @AccDate), 112), 1, 6),     --  -09         
            @Date10 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -10, @AccDate), 112), 1, 6),     --  -10         
            @Date11 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -11, @AccDate), 112), 1, 6),     --  -11      
            @Date12 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -12, @AccDate), 112), 1, 6),     --  -12    
            ------------^^^^^^당해  
            @Date1Year  = SUBSTRING(CONVERT(CHAR(8), DATEADD(YEAR, -1, @AccDateLast), 112), 1, 8),     --  -13    
--            @Date13 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -13, @AccDate), 112), 1, 6),     --  -13         
--            @Date14 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -14, @AccDate), 112), 1, 6),     --  -14         
--            @Date15 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -15, @AccDate), 112), 1, 6),     --  -15         
--            @Date16 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -16, @AccDate), 112), 1, 6),     --  -16         
--            @Date17 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -17, @AccDate), 112), 1, 6),     --  -17         
--            @Date18 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -18, @AccDate), 112), 1, 6),     --  -18         
--            @Date19 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -19, @AccDate), 112), 1, 6),     --  -19         
--            @Date20 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -20, @AccDate), 112), 1, 6),     --  -20         
--            @Date21 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -21, @AccDate), 112), 1, 6),     --  -21         
--            @Date22 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -22, @AccDate), 112), 1, 6),     --  -22         
--            @Date23 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -23, @AccDate), 112), 1, 6),     --  -23      
--            @Date24 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -24, @AccDate), 112), 1, 6),     --  -24
            --------------^^^^^^^^^^1년전      
            @Date2Year  = CONVERT(CHAR(8), DATEADD(YEAR, -2, @AccDateLast), 112),     --  -13     
--            @Date25 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -25, @AccDate), 112), 1, 6),     --  -25         
--            @Date26 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -26, @AccDate), 112), 1, 6),     --  -26         
--            @Date27 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -27, @AccDate), 112), 1, 6),     --  -27         
--            @Date28 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -28, @AccDate), 112), 1, 6),     --  -28         
--            @Date29 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -29, @AccDate), 112), 1, 6),     --  -29         
--            @Date30 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -30, @AccDate), 112), 1, 6),     --  -30         
--            @Date31 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -31, @AccDate), 112), 1, 6),     --  -31         
--            @Date32 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -32, @AccDate), 112), 1, 6),     --  -32         
--            @Date33 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -33, @AccDate), 112), 1, 6),     --  -33         
--            @Date34 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -34, @AccDate), 112), 1, 6),     --  -34         
--            @Date35 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -35, @AccDate), 112), 1, 6),     --  -35         
--            @Date36 = SUBSTRING(CONVERT(CHAR(6), DATEADD(MONTH, -36, @AccDate), 112), 1, 6),     --  -36         
            --------------^^^^^^^^^^^^2년전 
            @Date3Year =  CONVERT(CHAR(8), DATEADD(YEAR, -3, @AccDateLast), 112),     
            --------------^^^^^^^^^^^^^3년전 
            @Date4Year = CONVERT(CHAR(8), DATEADD(YEAR, -4, @AccDateLast), 112)     
            --------------^^^^^^^^^^^^^4년전
  
--  select @Date1Year,@Date2Year,@Date3Year,@Date4Year return
     CREATE TABLE #OffAccSeq (AccSeq INT)
         -- 계정 전체를 조회할 경우 건별반제 계정 전부를 담는다.
         INSERT INTO #OffAccSeq (AccSeq)
         SELECT AccSeq FROM _TDAAccount WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND OffRemSeq > 0 and AccSeq = 18 -- 외상매출금계정만 20160527


       SELECT O.SlipSeq,
               MAX(R.AccSeq)            AS AccSeq,
               MAX(R.AccDate)           AS AccDate,
               MAX(O.OnAmt)             AS OnAmt,
               ISNULL(SUM(SlipOff.OffAmt), 0)       AS OffAmt,
               MAX(rem.RemValSeq)       AS CustSeq,
			   ISNULL(R.SlipUnit,0) AS SlipUnit,
			   999999999999999.99999       AS BalanceAmt
          INTO #tmpSlipOn  
          FROM _TACSlipOn AS O WITH (NOLOCK)
               LEFT OUTER JOIN _TACSlipRem        AS rem WITH(NOLOCK) ON O.CompanySeq = rem.CompanySeq
                                                 AND O.SlipSeq    = rem.SlipSeq
                                                           AND O.RemSeq     = rem.RemSeq
														   AND O.RemSeq     = 1017      -- CustSeq
               LEFT OUTER  JOIN _TACSlipRow AS R WITH (NOLOCK)
                       ON R.CompanySeq  = @CompanySeq
                      AND R.SlipSeq     = O.SlipSeq
               JOIN #OffAccSeq  AS accseq WITH(NOLOCK)      
                       ON R.AccSeq      = accseq.AccSeq
               LEFT OUTER JOIN (SELECT A.CompanySeq,  A.OnSlipSeq, A.OffAmt
                            FROM _TACSlipOff AS A WITH(NOLOCK)
                                     JOIN _TACSlipRow AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                       AND A.SlipSeq     = B.SlipSeq
                                                                       AND (@AccDate     = '' OR B.AccDate <= @AccDate)
                                                                       AND B.IsSet IN ('1', '2')
                                                                       AND A.CompanySeq  = @CompanySeq
									JOIN _TACSlip AS C WITH(NOLOCK)ON C.CompanySEq =@companySEq AND B.SlipMstSeq = C.SlipMstSeq 
                          ) AS SlipOff 
                      ON SlipOff.CompanySeq = O.CompanySeq
                     AND SlipOff.OnSlipSeq  = O.SlipSeq 
         WHERE O.CompanySeq = @CompanySeq
		   AND R.AccDate     <= @AccDate 
           AND R.IsSet IN ('1','2')
           AND (@CustSeq = 0 OR rem.RemValSeq = @CustSeq)  
		   AND (@SlipUnit = 0 OR R.SlipUnit = @SlipUnit)
         GROUP BY R.SlipUnit,O.SlipSeq
        HAVING (MAX(O.OnAmt) <> ISNULL(SUM(SlipOff.OffAmt), 0) AND MAX(O.OnAmt) <> 0)

      UPDATE #tmpSlipOn
        SET BalanceAmt = ISNULL(OnAmt, 0) - ISNULL(OffAmt, 0)
  
     -- 연령별 금액 담을 임시 테이블 생성
     CREATE TABLE #tmpAgingTable
     (
        CustSeq             INT,
        CostDeptSeq         INT, 
        Over4Year           DECIMAL(19,5),
        Over3Year           DECIMAL(19,5),
        Over2Year           DECIMAL(19,5),
        Over1Year           DECIMAL(19,5),
        thisMonth           DECIMAL(19,5),
        Over1Month          DECIMAL(19,5),
        Over2Month          DECIMAL(19,5),
        Over3Month          DECIMAL(19,5),
        Over4Under6Month    DECIMAL(19,5),
        Over7Under9Month    DECIMAL(19,5),
        Over10Under12Month  DECIMAL(19,5),
        YearTotAmt          DECIMAL(19,5),
        TotAmt              DECIMAL(19,5),
		OverLapAmt			DECIMAL(19,5)
     )
	IF @IsMonth = '1' --월별집계선택시
---------------------------------------------------------
	BEGIN 
		INSERT #tmpAgingTable
		( 
			CustSeq           ,  
			CostDeptSeq        , 
			Over4Year           ,
			Over3Year           ,
			Over2Year           ,
			Over1Year           ,
			thisMonth           ,
			Over1Month          ,
			Over2Month          ,
			Over3Month          ,
			Over4Under6Month    ,
			Over7Under9Month    ,
			Over10Under12Month  ,
			OverLapAmt 
		)
	  SELECT   CustSeq ,  
			SlipUnit        ,
			SUM(CASE WHEN AccDate <= @Date4Year THEN BalanceAmt ELSE 0 END) AS Over4Year ,
			SUM(CASE WHEN @Date4Year < AccDate AND AccDate <= @Date3Year THEN BalanceAmt ELSE 0 END) AS Over3Year,
			SUM(CASE WHEN @Date3Year < AccDate AND AccDate <= @Date2Year THEN BalanceAmt ELSE 0 END) AS Over2Year,
			SUM(CASE WHEN @Date2Year < AccDate AND AccDate <= @Date1Year THEN BalanceAmt ELSE 0 END) AS Over1Year,
			SUM(CASE WHEN  LEFT(AccDate,6) = @Date00 THEN BalanceAmt ELSE 0 END) AS thisMonth ,
			SUM(CASE WHEN  LEFT(AccDate,6) = @Date01 THEN BalanceAmt ELSE 0 END) AS Over1Month ,
			SUM(CASE WHEN  LEFT(AccDate,6) = @Date02 THEN BalanceAmt ELSE 0 END) AS Over2Month ,
			SUM(CASE WHEN  LEFT(AccDate,6) = @Date03 THEN BalanceAmt ELSE 0 END) AS Over3Month,
			SUM(CASE WHEN  LEFT(AccDate,6) <= @Date04 AND LEFT(AccDate,6) >= @Date06 THEN BalanceAmt ELSE 0 END) AS Over4Under6Month,
			SUM(CASE WHEN  LEFT(AccDate,6) <= @Date07 AND LEFT(AccDate,6) >= @Date09 THEN BalanceAmt ELSE 0 END) AS Over7Under9Month,
			SUM(CASE WHEN  LEFT(AccDate,6) <= @Date10 AND LEFT(AccDate,6) >= @Date11 THEN BalanceAmt ELSE 0 END) AS Over10Under12Month,
			-- 중복되는 금액: 중복되는 기간을 1년을 넘지 못한다.
			SUM(CASE WHEN LEFT(AccDate,4) = LEFT(@Date1Year,4) AND LEFT(AccDate,6) BETWEEN @Date11 AND @Date00  THEN A.BalanceAmt END) 
		FROM #tmpSlipOn AS A
		GROUP BY A.SlipUnit,A.CustSeq
    
		 UPDATE #tmpAgingTable
			SET     Over4Year       = ISNULL(Over4Year,0)       ,
					Over3Year       = ISNULL(Over3Year,0)       ,
					Over2Year       = ISNULL(Over2Year,0)       ,
					--Over1Year       = ISNULL(Over1Year,0)       ,
					Over1Year       = ISNULL(Over1Year,0)  -  ISNULL(OverLapAmt,0)   , --겹치는 금액 처리.
					thisMonth       = ISNULL(thisMonth,0)       ,
					Over1Month      = ISNULL(Over1Month,0)      ,
					Over2Month      = ISNULL(Over2Month,0)      ,
					Over3Month      = ISNULL(Over3Month,0)       ,
					Over4Under6Month    = ISNULL(Over4Under6Month,0),
					Over7Under9Month    = ISNULL(Over7Under9Month,0),
					Over10Under12Month  = ISNULL(Over10Under12Month,0) ,
					OverLapAmt = ISNULL( OverLapAmt,0)
		--총합계
		UPDATE #tmpAgingTable
		SET YearTotAmt = thisMonth + Over1Month + Over2Month + Over3Month + Over4Under6Month + Over7Under9Month + Over10Under12Month ,
			TotAmt  = Over4Year + Over3Year + Over2Year + Over1Year + thisMonth + Over1Month + Over2Month + Over3Month + Over4Under6Month + Over7Under9Month + Over10Under12Month
			--- OverLapAmt
	END
	ELSE
	BEGIN
		INSERT #tmpAgingTable
		( 
			CustSeq           ,  
			CostDeptSeq        , 
			Over4Year           ,
			Over3Year           ,
			Over2Year           ,
			Over1Year           ,
			thisMonth           ,
			Over1Month          ,
			Over2Month          ,
			Over3Month          ,
			Over4Under6Month    ,
			Over7Under9Month    ,
			Over10Under12Month  
		)
		SELECT   CustSeq           ,  
			SlipUnit        ,
			SUM(CASE WHEN AccDate <= @Date4Year THEN BalanceAmt ELSE 0 END) AS Over4Year ,
			SUM(CASE WHEN  @Date4Year < AccDate AND AccDate <= @Date3Year THEN BalanceAmt ELSE 0 END) AS Over3Year,
			SUM(CASE WHEN @Date3Year < AccDate AND AccDate <= @Date2Year THEN BalanceAmt ELSE 0 END) AS Over2Year,
			SUM(CASE WHEN @Date2Year < AccDate AND AccDate <= @Date1Year THEN BalanceAmt ELSE 0 END) AS Over1Year,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) = @Date00 THEN BalanceAmt ELSE 0 END) AS thisMonth ,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) = @Date01 THEN BalanceAmt ELSE 0 END) AS Over1Month ,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) = @Date02 THEN BalanceAmt ELSE 0 END) AS Over2Month ,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) = @Date03 THEN BalanceAmt ELSE 0 END) AS Over3Month,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) <= @Date04 AND LEFT(AccDate,6) >= @Date06 THEN BalanceAmt ELSE 0 END) AS Over4Under6Month,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) <= @Date07 AND LEFT(AccDate,6) >= @Date09 THEN BalanceAmt ELSE 0 END) AS Over7Under9Month,
			SUM(CASE WHEN LEFT(@AccDateYM,4) = LEFT(AccDate,4) AND LEFT(AccDate,6) <= @Date10 AND LEFT(AccDate,6) >= @Date11 THEN BalanceAmt ELSE 0 END) AS Over10Under12Month
		FROM #tmpSlipOn AS A
		GROUP BY A.SlipUnit,A.CustSeq
    
		 UPDATE #tmpAgingTable
			SET     Over4Year       = ISNULL(Over4Year,0)       ,
					Over3Year       = ISNULL(Over3Year,0)       ,
					Over2Year       = ISNULL(Over2Year,0)       ,
					Over1Year       = ISNULL(Over1Year,0)       ,
					thisMonth       = ISNULL(thisMonth,0)       ,
					Over1Month      = ISNULL(Over1Month,0)      ,
					Over2Month      = ISNULL(Over2Month,0)      ,
					Over3Month      = ISNULL(Over3Month,0)       ,
					Over4Under6Month    = ISNULL(Over4Under6Month,0),
					Over7Under9Month    = ISNULL(Over7Under9Month,0),
					Over10Under12Month  = ISNULL(Over10Under12Month,0) 
		--총합계
		UPDATE #tmpAgingTable
		SET YearTotAmt = thisMonth + Over1Month + Over2Month + Over3Month + Over4Under6Month + Over7Under9Month + Over10Under12Month ,
			TotAmt  = Over4Year + Over3Year + Over2Year + Over1Year + thisMonth + Over1Month + Over2Month + Over3Month + Over4Under6Month + Over7Under9Month + Over10Under12Month
        
	END 
----------------------------------------------------------------
      CREATE TABLE #tmpCustBankAcc
     (
         CustSeq     INT,
         BankAccNo   NVARCHAR(100),
         BankHQName  NVARCHAR(100)
     )
    -- 환경설정에 따른 사업자번호형식을 담는다.        
    SELECT @EnvValue = ISNULL(EnvValue, '') 
    FROM _TCOMEnv          
    WHERE CompanySeq = @CompanySeq AND EnvSeq = 17        
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue, '') = ''        
    BEGIN        
        SELECT @EnvValue = '999-99-99999'        
    END     
    
  -- 환경설정에 따른 주민등록번호형식 담는다.        
    SELECT @EnvValue2 = ISNULL(EnvValue, '') 
    FROM _TCOMEnv          
    WHERE CompanySeq = @CompanySeq AND EnvSeq = 16        
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue2, '') = ''        
    BEGIN        
        SELECT @EnvValue2 = '999999-9999999'        
    END    
    
      SELECT 
        ISNULL(C.CustName , '')      AS CustName,   --거래처
        CASE WHEN ISNULL(C.BizNo, '') = '' THEN dbo._FCOMMaskConv(@EnvValue2,dbo._fnResidMask(dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq)))       
                ELSE dbo._FCOMMaskConv(@EnvValue,C.BizNo) END      AS BizNo, --사업자번호  
        ISNULL((SELECT slipunitname FROM _TACSlipUnit WHERE SlipUnit = A.CostDeptSeq AND CompanySeq = @CompanySeq), '')     AS DeptName,   --사업소
        A.*,
        LEFT(@Date4Year,4) AS Date4Year ,
        LEFT(@Date3Year,4) AS Date3Year ,
        LEFT(@Date2Year,4) AS Date2Year ,
        LEFT(@Date1Year,4) AS Date1Year , 
        @AccDateYM AS AccDateYM
           
    FROM #tmpAgingTable AS A
    LEFT OUTER JOIN _TDACust    AS C WITH(NOLOCK) ON C.CompanySeq  = @CompanySeq AND C.CustSeq = A.CustSeq
    ORDER BY DeptName, C.CustName
     
     RETURN
 go
 exec hencom_SACSlipOnCustAgeIsSetQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <AccDateYM>201701</AccDateYM>
    <SlipUnit />
    <CustSeq />
    <IsMonth>0</IsMonth>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036474,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029905