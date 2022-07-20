IF OBJECT_ID('mnpt_SAREEGWUsualCostQuery') IS NOT NULL 
    DROP PROC mnpt_SAREEGWUsualCostQuery
GO 

-- v2018.01.30 

CREATE PROC mnpt_SAREEGWUsualCostQuery
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10) = '',  
    @CompanySeq     INT = 0,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS
  
	DECLARE @docHandle      INT,  
            @UsualCostSeq   INT
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
  
    SELECT @UsualCostSeq      = UsualCostSeq 
		   --@ApproReqSerl     = ApproReqSerl                       
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH ( UsualCostSeq         INT)

	DECLARE	@StdYear	NCHAR(4),
		    @Deptseq	INT,
			@AccUnit	INT


	SELECT @StdYear	= LEFT(ApprDate, 4),
		   @DeptSeq	= ISNULL(A.DeptSeq, 0),
		   @AccUnit	= ISNULL(B.AccUnit, 0)
	  FROM _TARUsualCost AS A
		   LEFT  JOIN _TDADept AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.DeptSeq		= A.DeptSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND A.UsualCostSeq	= @UsualCostSeq


		SELECT IDENTITY(INT, 1, 1)					AS RowNo,
               ISNULL(B.UsualCostSeq        ,  0)   AS UsualCostSeq     , -- 일반비용내부코드  
               ISNULL(B.UsualCostNo         , '')   AS UsualCostNo      , -- 신청서No  
               ISNULL(B.RegDate             , '')   AS RegDate          , -- 작성일  
               ISNULL(REmp.EmpName          , '')   AS RegEmpName       , -- 작성자  
               ISNULL(REmp.DeptName         , '')   AS RegDeptName      , -- 작성부서  
               ISNULL(B.ApprDate            , '')   AS ApprDate         , -- 신청일  
               ISNULL(Emp.EmpName           , '')   AS EmpName          , -- 신청자  
               ISNULL(Dept.DeptName          , '')   AS DeptName         , -- 신청부서  
               ISNULL(CCtr.CCtrName         , '')   AS CCtrName         , -- 활동센터  
               ISNULL(B.Contents            , '')   AS RemarkM          , -- 지출내역  
               --ISNULL(@SumAmt               ,  0)   AS SumAmt           , -- 합계금액  
               --ISNULL(@SumSupplyAmt         ,  0)   AS SumSupplyAmt     , -- 합계공급가액  
               --ISNULL(@SumVatAmt            ,  0)   AS SumVatAmt        , -- 합계부가세 
               -- Detail
               ISNULL(A.UsualCostSerl       ,  0)   AS UsualCostSerl    , -- 일반비용순번  
			   ISNULL(CM.CostName           , '')   AS CostName         , -- 비용항목  
               ISNULL(Rem.RemName           , '')   AS RemName          , -- 관리항목종류  
               ISNULL(RemVal.RemValueName   , '')   AS RemValName       , -- 관리항목값 명칭  
               ISNULL(A.IsVat               , '')   AS IsVat            , -- 부가세여부  
               ISNULL(A.Amt                 ,  0)   AS Amt              , -- 금액  
               ISNULL(A.SupplyAmt           ,  0)   AS Price			, -- 단가  
               ISNULL(A.SupplyAmt           ,  0)   AS CurAmt			, -- 공급가액  
               ISNULL(A.VatAmt              ,  0)   AS VatAmt           , -- 부가세  
               ISNULL(Cust.CustName         , '')   AS CustName         , -- 거래처  
               ISNULL(A.CustText            , '')   AS CustText         , -- 거래처(Text)  
               ISNULL(Evid.EvidName         , '')   AS EvidName         , -- 증빙  
               ISNULL(A.Remark              , '')   AS RemarkD           , -- 비고  
               ISNULL(Acc1.AccName          , '')   AS AccName          , -- 계정과목  
               ISNULL(A.AccSeq              ,  0)   AS AccSeq,            -- 계정코드  
			   CONVERT(DECIMAL(19, 5), 0)			AS NotSlipAmt
		  INTO #tmpCost
          FROM _TARUsualCostAmt AS A WITH (NOLOCK) JOIN _TARUsualCost AS B WITH (NOLOCK)
                                                     ON A.CompanySeq    = B.CompanySeq
                                                    AND A.UsualCostSeq  = B.UsualCostSeq
                                                   LEFT OUTER JOIN _TARCostAcc AS CM WITH (NOLOCK)  
                                                     ON A.CompanySeq    = CM.CompanySeq  
                                                    AND A.CostSeq       = CM.CostSeq  
                                                   LEFT OUTER JOIN _TDAAccountRem AS Rem WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Rem.CompanySeq  
                                                    AND CM.RemSeq       = Rem.RemSeq  
                                                   LEFT OUTER JOIN _TDAAccountRemValue AS RemVal WITH (NOLOCK)  
                                                     ON A.CompanySeq    = RemVal.CompanySeq  
                                                    AND A.RemValSeq     = RemVal.RemValueSerl  
                                                   LEFT OUTER JOIN _TDACust AS Cust WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Cust.CompanySeq  
                                                    AND A.CustSeq       = Cust.CustSeq  
                                                   LEFT OUTER JOIN _TDAEvid AS Evid WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Evid.CompanySeq  
                                                    AND A.EvidSeq       = Evid.EvidSeq  
                                                   LEFT OUTER JOIN _TDAAccount AS Acc1 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc1.CompanySeq  
                                                    AND A.AccSeq        = Acc1.AccSeq  
												   LEFT OUTER JOIN _TDAAccount AS Acc2 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc2.CompanySeq  
                                                    AND A.VatAccSeq     = Acc2.AccSeq  
                                                   LEFT OUTER JOIN _TDAAccount AS Acc3 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc3.CompanySeq  
                                                    AND A.OppAccSeq     = Acc3.AccSeq  
                                                   LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'') AS REmp 
                                                     ON B.RegEmpSeq  = REmp.EmpSeq  
                                                   LEFT OUTER JOIN _TDAEmp AS Emp  
                                                     ON B.EmpSeq	= Emp.EmpSeq  
													AND B.CompanySeq	= Emp.CompanySeq
												   LEFT OUTER JOIN _TDADept AS Dept
												     ON B.DeptSeq	= Dept.DeptSeq
													AND B.CompanySeq	= Dept.CompanySeq
                                                   LEFT OUTER JOIN _TDACCtr AS CCtr WITH (NOLOCK)  
                                                     ON B.CompanySeq   = CCtr.CompanySeq  
                                                    AND B.CCtrSeq      = CCtr.CCtrSeq  
                                                   LEFT OUTER JOIN _TACSlipRow AS Slip WITH (NOLOCK)  
                                                     ON B.CompanySeq   = Slip.CompanySeq  
                                                    AND B.SlipSeq      = Slip.SlipSeq  
                                                   LEFT OUTER JOIN _TCAUser AS U WITH (NOLOCK)  
                                                     ON B.CompanySeq   = U.CompanySeq  
                                                    AND B.LastUserSeq  = U.UserSeq  
         WHERE A.CompanySeq     = @CompanySeq  
           AND A.UsualCostSeq   = @UsualCostSeq  
         ORDER BY A.UsualCostSerl  
    

	--select * from _fnAdmEmpOrd(1,'') where EmpNAme ='한라홀딩스'

	--ylw_helptext3 _fnAdmEmpOrd


	--비용승인완료, 전표처리 X
	SELECT SUM(A.SupplyAmt) AS NotSlipAmt,
		   A.AccSeq
	  INTO #TNotSlipAmt2
	  FROM _TARUsualCostAmt AS A WITH(NOLOCK)
		   INNER JOIN _TARUsualCost AS B WITH(NOLOCK)
				   ON B.CompanySeq		= A.CompanySeq
				  AND B.UsualCostSeq	= A.UsualCostSeq
		   LEFT  JOIN _TARUsualCost_Confirm AS C WITH(NOLOCK)
				   ON C.CompanySeq		= B.CompanySeq
				  AND C.CfmSeq			= B.UsualCostSeq
	 WHERE A.CompanySeq	= @CompanySeq
	   AND LEFT(B.ApprDate, 4)	= @StdYear
	   AND ISNULL(C.CfmCode, 0)			= 1	--비용승인완료
	   AND ISNULL(B.SlipSeq, 0)			= 0 --전표처리 X
       AND B.DeptSeq = @DeptSeq 
	 GROUP BY A.AccSeq

	--DECLARE @CurAmt	DECIMAL(19, 5),
	--	    @CurVat	DECIMAL(19, 5),
	--		@TotAmt	DECIMAL(19, 5)

	--SELECT @CurAmt	= SUM(SupplyAmt),
	--	   @CurVat	= SUM(VatAmt),
	--	   @TotAmt	= SUM(Amt)
	--  FROM _TARUsualCostAmt AS A
 --    WHERE A.CompanySeq		= @CompanySeq
	--   AND A.UsualCostSeq	= @UsualCostSeq



------------------------------------------------------------------------------
------------------------계정 - 예산과목 연결 START----------------------------
------------------------------------------------------------------------------
    DECLARE @IsSave         NCHAR(1),  
            @AccSeq         INT,  
            @RemSeq         INT,  
            @BgtSeq         INT,
            @AccNo          NVARCHAR(50),
            @SMBgtType      INT,
			@txtAccName		NVARCHAR(100),			-- 계정과목명 - 조회조건에 계정과목명, 예산과목명 추가 2015.07.08 By sryoun.
			@BgtName		NVARCHAR(100),			-- 예산과목명
			@RemName		NVARCHAR(100)			-- 관리항목명
    SELECT @IsSave      = '0',  
           @AccSeq      = 0,  
           @RemSeq      = 0,  
           @BgtSeq      = 0,
           @AccNo       = '',
           @SMBgtType   = 0,
		   @txtAccName	= '',
		   @BgtName		= '',
		   @RemName		= ''

    CREATE TABLE #BgtItemList (      
        AccSeq          INT,      
        RemSeq          INT,      
        RemValSeq       INT,      
        BgtSeq          INT,      
        --IsSave          NCHAR(1),  
        RemValName      NVARCHAR(100))      
            -- 2-1. 연결된 것 중 계정인것 (SMBgtType = 4005001)
            INSERT INTO #BgtItemList (AccSeq, RemSeq, RemValSeq, BgtSeq) --, IsSave)
                SELECT a.AccSeq, 0, 0, bgt.BgtSeq --, '1'
                  FROM _TDAAccount AS a WITH (NOLOCK) JOIN _TACBgtAcc AS bgt WITH (NOLOCK)
                                                        ON a.CompanySeq     = bgt.CompanySeq
                                                       AND a.AccSeq         = bgt.AccSeq
                                                       AND bgt.RemSeq       = 0
                                                       AND bgt.RemValSeq    = 0
                 WHERE a.CompanySeq     = @CompanySeq
                   AND a.IsSlip         = '1'                                   -- 기표
                   AND a.SMBgtType      = 4005001                               -- 예산유형 : 계정과목
                   AND (@AccSeq         = 0  OR a.AccSeq     = @AccSeq       )  -- 계정코드
                   AND (@BgtSeq         = 0  OR bgt.BgtSeq   = @BgtSeq       )  -- 예산과목
                   AND a.AccNo      LIKE @AccNo + '%'                           -- 계정번호
            INSERT INTO #BgtItemList (AccSeq, RemSeq, RemValSeq, BgtSeq, RemValName) -- IsSave, 
                -- 1) 사용자소분류 (19999)
                SELECT A.AccSeq, A.BgtRemSeq, D.RemValSeq, D.BgtSeq, C.MinorName  --'1', 
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)
                                                        ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- 코드도움인 것만.
                                                      JOIN _TDAUMinor AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq   AND C.MajorSeq       = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.MinorSeq       = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- 기표      
                   AND A.SMBgtType      = 4005002                               -- 예산유형 : 관리항목      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- 계정코드      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- 예산과목      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- 관리항목      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- 계정번호      
                   AND A.BgtRemSeq     <> 0                                     -- 예산관리항목이 코드가 있는것.   
                   AND B.CodeHelpSeq    = 19999                                 -- ***사용자소분류
                UNION
                -- 2) 시스템소분류 (19998)
                SELECT A.AccSeq, A.BgtRemSeq, D.RemValSeq, D.BgtSeq,C.MinorName -- '1', 
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)
                                                        ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- 코드도움인 것만.
                                                      JOIN _TDASMinor AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq
                                                       AND C.MajorSeq       = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.MinorSeq       = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- 기표      
                   AND A.SMBgtType      = 4005002                               -- 예산유형 : 관리항목      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- 계정코드      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- 예산과목      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- 관리항목      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- 계정번호      
                   AND A.BgtRemSeq     <> 0                                     -- 예산관리항목이 코드가 있는것. 
                   AND B.CodeHelpSeq    = 19998                                 -- ***시스템소분류
                UNION
                -- 3) 회계관리항목값 (40031)
                SELECT A.AccSeq, A.BgtRemSeq,  C.RemValueSerl, D.BgtSeq, C.RemValueName  --'1',			-- 등록된 부분에 대한 관리항목코드만 조회되어 데이터 입력 후 저장 시 저장되지 않아 수정함. 2015.09.24
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)                                               ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- 코드도움인 것만.
                                                      JOIN _TDAAccountRemValue AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq
                                                       AND C.RemSeq         = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.RemValueSerl   = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- 기표      
                   AND A.SMBgtType      = 4005002                               -- 예산유형 : 관리항목      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- 계정코드      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- 예산과목      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- 관리항목      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- 계정번호      
                   AND A.BgtRemSeq     <> 0                                     -- 예산관리항목이 코드가 있는것. 
                   AND B.CodeHelpSeq    = 40031                                 -- ***회계관리항목
				   


    SELECT ISNULL(acc.AccName           , '')   AS AccName          ,       
           ISNULL(bgt.BgtName           , '')   AS BgtName          ,      
           ISNULL(A.AccSeq              , 0)    AS AccSeq           ,      
           A.BgtSeq								AS BgtSeq
	  INTO #BgtAcc
      FROM #BgtItemList AS A LEFT OUTER JOIN _TDAAccount AS acc WITH (NOLOCK)      
                               ON acc.CompanySeq    = @CompanySeq      

                              AND A.AccSeq          = acc.AccSeq      
                             LEFT OUTER JOIN _TDAAccountRem AS rem WITH (NOLOCK)      
                               ON rem.CompanySeq    = @CompanySeq      
                              AND A.RemSeq          = rem.RemSeq      
                             LEFT OUTER JOIN _TACBgtItem AS bgt WITH (NOLOCK)      
                               ON bgt.CompanySeq    = @CompanySeq      
                              AND A.BgtSeq          = bgt.BgtSeq
	 WHERE (@txtAccName	= ''	OR acc.AccName	LIKE @txtAccName + N'%')			-- 계정과목명		-- 조회조건에 추가 2015.07.08 by sryoun.
	   AND (@BgtName	= ''	OR bgt.BgtName	LIKE @BgtName + N'%')				-- 예산과목명
	   AND (@RemName	= ''	OR rem.RemName	LIKE @RemName + N'%')				-- 관리항목명
	  GROUP BY A.AccSeq,acc.AccName,bgt.BgtName,A.BgtSeq


----------------------------------------------------------------------------
------------------------계정 - 예산과목 연결 END----------------------------
----------------------------------------------------------------------------

	SELECT B.BgtName,
		   SUM(A.BgtAmt) AS BgtAmt,
		   A.CompanySeq,
		   LEFT(A.BgtYM,4) AS BgtYM,
		   A.AccUnit,
		   A.DeptSeq,
		   A.CCtrSeq,
		   A.BgtSeq
	  INTO #TACBgtAdjItem
	  FROM _TACBgt AS A
	  LEFT OUTER JOIN _TACBgtItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
												   AND A.BgtSeq = B.BgtSeq
	 GROUP BY A.CompanySeq,		LEFT(A.BgtYM,4),
			  A.AccUnit,		A.DeptSeq,
			  A.CCtrSeq,		A.BgtSeq,
			  B.BgtName,		A.IniOrAmd
	HAVING A.CompanySeq = @CompanySeq
	   AND LEFT(A.BgtYM,4) = @StdYear
	   AND A.AccUnit = @AccUnit
	   AND A.DeptSeq = @DeptSeq
	   AND A.IniOrAmd = 1




--예산과목의 연간 실적+집행 금액(누계)
	 SELECT SUM((DrAmt - CrAmt)*SMDrOrCr) AS Sumtot,BgtSeq,BgtDeptSeq,AccUnit
	   INTO #TACSlipRow
	   FROM _TACSlipRow		
	  WHERE CompanySeq = @CompanySeq
	    AND LEFT(ISNULL(AccDate,''),4) = @StdYear
		AND AccUnit = @AccUnit
		AND BgtDeptSeq = @DeptSeq
	  GROUP BY BgtSeq,BgtDeptSeq,AccUnit


-- 계정과목 별 품의금액(금번)
    SELECT A.AccName, 
		   --SUM(CurAmt + CurVat) AS TotAmt,
		   SUM(A.CurAmt) AS TotAmt,
		   SUM(A.NotSlipAmt) AS NotSlipAmt,
		   A.AccSeq
	  INTO #TACBgtAdjAccCal
      FROM #tmpCost AS A
	  --LEFT OUTER JOIN #TNotSlipAmt2 AS B ON A.AccSeq = B.AccSeq2
     GROUP BY A.AccName,A.AccSeq

--계정x예산 과목에 품의금액 적용 임시테이블(계정과목기준)
	 SELECT A.*,B.TotAmt,C.NotSlipAmt
	   INTO #BgtAccTotAmt
	   FROM #BgtAcc AS A
	   LEFT OUTER JOIN #TACBgtAdjAccCal AS B ON A.AccSeq = B.AccSeq
	   LEFT OUTER JOIN #TNotSlipAmt2 AS C ON A.AccSeq = C.AccSeq

--계정x예산 과목에 품의금액 적용한 것을 예산과목별로 SUM
	SELECT SUM(TotAmt) AS TotAmt,
		   SUM(NotSlipAmt) AS NotSlipAmt,
	       BgtSeq
	  INTO #BgtAccTotAmt2
	  FROM #BgtAccTotAmt
	 GROUP BY BgtSeq


--사업계획포함여부 @IsPlanName : 품의품목 각각의 계정과목이 하나라도 예산으로 안잡혀있으면 "미포함" 아니면 "포함"
--#TACBgtAdjAccCal : 구매품의품목의 계정과목
--#BgtAcc : 계정과목 - 예산과목 연결
--#TACBgtAdjItem : 예산이 잡혀있는 예산과목
	DECLARE @IsPlanName NVARCHAR(100)

	IF EXISTS (SELECT A.AccSeq, B.AccSeq 
				 FROM #TACBgtAdjAccCal AS A
				 LEFT OUTER JOIN #BgtAcc AS B WITH(NOLOCK) ON A.AccSeq = B.AccSeq
				 LEFT OUTER JOIN #TACBgtAdjItem AS C WITH(NOLOCK) ON B.BgtSeq = C.BgtSeq
				WHERE C.BgtSeq IS NULL)

	BEGIN
		SELECT @IsPlanName = '미포함'
	END
	ELSE
	BEGIN
		SELECT @IsPlanName = '포함'
	END

-------------
--최종 출력--
-------------
	--예산과목 품의 계정과목에 해당하는 것만 나오기
	SELECT TOP 5
		   A.BgtName,
		   A.BgtAmt AS BgtAmt, 
		   ISNULL(C.TotAmt,0) AS Thistot, 
		   ISNULL(B.Sumtot,0) + ISNULL(C.NotSlipAmt,0) AS Sumtot, 
		   ISNULL(A.BgtAmt,0)-ISNULL(B.Sumtot,0) - ISNULL(C.TotAmt,0) - ISNULL(C.NotSlipAmt,0) AS BgtRest
	  INTO #TACBgtAdjItem2
	  FROM #TACBgtAdjItem AS A
	  LEFT OUTER JOIN #TACSlipRow AS B WITH(NOLOCK) ON A.BgtSeq = B.BgtSeq
	  JOIN #BgtAccTotAmt2 AS C ON A.BgtSeq = C.BgtSeq
	 WHERE A.BgtSeq IN (SELECT BgtSeq FROM #BgtAccTotAmt2 WHERE ISNULL(TotAmt,0) <> 0)


--전자결재 예산부분만 출력창에서 빈칸으로라도 5칸 유지
	WHILE (SELECT COUNT (1) FROM #TACBgtAdjItem2) < 5
	BEGIN
		INSERT INTO #TACBgtAdjItem2 VALUES ('',0,0,0,0)
	END


	SELECT * FROM #TACBgtAdjItem2 ORDER BY BgtName DESC

	SELECT LEFT(ApprDate,4) + '-' + SUBSTRING(ApprDate,5,2) +'-' + RIGHT(ApprDate,2) AS ApproReqDate,
		   UsualCostNo								AS ApproReqNo,
		   DeptName									AS DeptName,
		   EmpName									AS EmpName,
		   @IsPlanName								AS IsPlanName,
		   RemarkM									AS RemarkM,
		   AccName									AS AccName,
		   ''										AS ItemNo,
		   CostName									AS ItemName,
		   CustName									AS CustName,
		   ISNULL(CurAmt, 0)						AS CurAmt,
		   ISNULL(VatAmt, 0)						AS CurVat,
		   ISNULL(CurAmt, 0) + ISNULL(VatAmt, 0)	AS TotAmt,
		   RemarkD									AS RemarkD,
		   RowNo									AS RowNo
	  FROM #tmpCost

