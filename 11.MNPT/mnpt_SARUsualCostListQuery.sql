IF OBJECT_ID('mnpt_SARUsualCostListQuery') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostListQuery
GO 

-- v2018.01.08
/*********************************************************************************************************************    
    화면명 : 일반비용신청서현황 - 조회
    SP Name: _SARUsualCostListQuery    
    작성일 : 2010.04.22 : CREATEd by 송경애        
    수정일 : 
********************************************************************************************************************/    
CREATE PROCEDURE mnpt_SARUsualCostListQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle      INT    
          , @RegDateFr      NCHAR(8)    -- 작성일 Fr
          , @RegDateTo      NCHAR(8)    -- 작성일 To
          , @RegEmpSeq      INT         -- 작성자
          , @RegDeptSeq     INT         -- 작성부서
          , @UsualCostNo    NVARCHAR(50)-- 신청서No
          , @ApprDateFr     NCHAR(8)    -- 신청일Fr
          , @ApprDateTo     NCHAR(8)    -- 신청일To
          , @EmpSeq         INT         -- 신청자
          , @DeptSeq        INT         -- 신청부서
          , @CCtrSeq        INT         -- 활동센터
          , @IsProg         NVARCHAR(1) -- 진행여부
          , @IsEnd          NVARCHAR(1) -- 완료여부
          , @IsAttachFile   NVARCHAR(1) -- 첨부파일여부
          , @SetIsUse       NCHAR(1)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @RegDateFr   = ISNULL(RegDateFr, '')  -- 작성일 Fr
        , @RegDateTo  	= ISNULL(RegDateTo  , '')
        , @RegEmpSeq  	= ISNULL(RegEmpSeq  , 0)
        , @RegDeptSeq 	= ISNULL(RegDeptSeq , 0)
        , @UsualCostNo	= ISNULL(UsualCostNo, '')
        , @ApprDateFr 	= ISNULL(ApprDateFr , '')
        , @ApprDateTo 	= ISNULL(ApprDateTo , '')
        , @EmpSeq     	= ISNULL(EmpSeq     , 0)
        , @DeptSeq    	= ISNULL(DeptSeq    , 0)
        , @CCtrSeq    	= ISNULL(CCtrSeq    , 0)
        , @IsProg       = ISNULL(IsProg         , '0')
        , @IsEnd        = ISNULL(IsEnd          , '0')
        , @IsAttachFile = ISNULL(IsAttachFile   , '0')
           
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (RegDateFr      NCHAR(8)    -- 작성일 Fr
        , RegDateTo      NCHAR(8)    -- 작성일 To
        , RegEmpSeq      INT         -- 작성자
        , RegDeptSeq     INT         -- 작성부서
        , UsualCostNo    NVARCHAR(50)-- 신청서No
        , ApprDateFr     NCHAR(8)    -- 신청일Fr
        , ApprDateTo     NCHAR(8)    -- 신청일To
        , EmpSeq         INT         -- 신청자
        , DeptSeq        INT         -- 신청부서
        , CCtrSeq        INT         -- 활동센터
        , IsProg         NCHAR(1)    -- 진행여부
        , IsEnd          NCHAR(1)    -- 완료여부
        , IsAttachFile   NCHAR(1)    -- 첨부파일여부
         )      
    
    SELECT @RegDateFr   = ISNULL(@RegDateFr, '') 
        , @RegDateTo  	= ISNULL(@RegDateTo  , '')
        , @RegEmpSeq  	= ISNULL(@RegEmpSeq  , 0)
        , @RegDeptSeq 	= ISNULL(@RegDeptSeq , 0)
        , @UsualCostNo	= ISNULL(@UsualCostNo, '')
        , @ApprDateFr 	= ISNULL(@ApprDateFr , '')
        , @ApprDateTo 	= ISNULL(@ApprDateTo , '')
        , @EmpSeq     	= ISNULL(@EmpSeq     , 0)
        , @DeptSeq    	= ISNULL(@DeptSeq    , 0)
        , @CCtrSeq    	= ISNULL(@CCtrSeq    , 0)
        , @IsProg       = ISNULL(@IsProg        , '0')
        , @IsEnd        = ISNULL(@IsEnd         , '0')
        , @IsAttachFile = ISNULL(@IsAttachFile  , '0')
    --=================================================================================================================================
    -- 전자결재를 사용안함으로 체크하면 [진행여부], [완료여부], [첨부파일여부] 컨트롤이 없어짐
    SELECT @SetIsUse = ISNULL(IsUse, '') FROM _TCOMEnvGroupWare WHERE CompanySeq = @CompanySeq AND WorkKind = 'mnpt_UsualCost'
    IF @@ROWCOUNT = 0 OR ISNULL(@SetIsUse, '') = '' SELECT @SetIsUse = '0'
    IF @SetIsUse = '0'
    BEGIN
        SELECT  @IsProg         = '0',
                @IsEnd          = '0',
                @IsAttachFile   = '0'
    END
    --=================================================================================================================================
    
    IF @RegDateFr = '' SET @RegDateFr = '00000000'
    IF @RegDateTo = '' SET @RegDateTo = '99999999'
    IF @ApprDateFr = '' SET @ApprDateFr = '00000000'
    IF @ApprDateTo = '' SET @ApprDateTo = '99999999'
/***********************************************************************************************************************************************/  
    SELECT	B.UsualCostSeq, SUM(B.Amt) AS AmtSum, SUM(B.SupplyAmt) AS SupplyAmtSum , SUM(B.VatAmt) AS VatAmtSum, 
			MIN(B.UsualCostSerl) AS UsualCostSerl	-- 디테일의 가장 최소값을 대상으로 아래에서 조회하기 위해 추가 2015.07.29. by shpark [일반비용조회(ESS)] 에서 사용함
      INTO #TARUsualCostAmt
      FROM _TARUsualCostAmt AS B
        JOIN _TARUsualCost AS A ON B.CompanySeq = A.CompanySeq AND B.UsualCostSeq = A.UsualCostSeq
    WHERE B.CompanySeq = @CompanySeq
        AND (A.RegDate BETWEEN @RegDateFr AND @RegDateTo)
        AND (@RegEmpSeq = 0 OR A.RegEmpSeq = @RegEmpSeq)
        AND (@RegDeptSeq = 0 OR A.RegDeptSeq = @RegDeptSeq)
        AND (@UsualCostNo = '' OR A.UsualCostNo LIKE @UsualCostNo + '%')
        AND (A.ApprDate BETWEEN @ApprDateFr AND @ApprDateTo)
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
        AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
        AND (@CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq)
    GROUP BY B.UsualCostSeq
  
    SELECT A.UsualCostSeq	AS UsualCostSeq		-- 내부코드				      		
        , A.UsualCostNo		AS UsualCostNo		-- 일반비용신청서No				    
        , A.RegDate			AS RegDate			-- 작성일				          
        , A.RegEmpSeq		AS RegEmpSeq		-- 작성자코드				          
        , A.RegDeptSeq		AS RegDeptSeq		-- 작성부서코드
        , A.ApprDate        AS ApprDate         -- 신청일
        , A.EmpSeq          AS EmpSeq           -- 신청자코드
        , A.DeptSeq         AS DeptSeq          -- 신청부서코드
        , A.CCtrSeq		    AS CCtrSeq		    -- 활동센터코드			      		
        , A.Contents        AS Contents         -- 지출내역
        , A.SlipSeq         AS SlipSeq          -- 전표내부코드
        , B.EmpName         AS RegEmpName       -- 작성자
        , C.DeptName        AS RegDeptName      -- 작성부서
        , D.EmpName         AS EmpName          -- 신청자
        , E.DeptName        AS DeptName         -- 신청부서
        , F.CCtrName        AS CCtrName         -- 활동센터
        , H.SlipID          AS SlipID           -- 전표번호
        , A.UsualCostSeq	AS UsualCostSeq2		-- 내부코드2		
        , ISNULL(I.IsProg       , '')   AS IsProg       -- 진행여부
        , ISNULL(I.IsEnd        , '')   AS IsEnd        -- 완료여부
        , CASE ISNULL(I.IsAttachFile, 0) WHEN 0 THEN '0' 
												ELSE '1' END  AS IsAttachFile	-- 첨부파일여부
        , ISNULL(I.IsAttachFile,0)		AS AttachFileCnt	 -- 첨부파일갯수
        , G.AmtSum          AS AmtSum           -- 금액
        , G.SupplyAmtSum    AS SupplyAmtSum     -- 공급가액
        , G.VatAmtSum       AS VatAmtSum,        -- 부가세
		-- 화면에 컬럼만 추가 되어 있고 조회되지 않던 항목에 대해 추가함 : 2015.07.29. by shpark
		-- 해당 마스터-디테일 구조의 디테일의 가장 위에 등록 된 것을 대상으로 조회되도록 함 [일반비용조회(ESS)] 화면에서 사용
		cost.CostName					AS CostName,		-- 비용항목
		cost.CostSeq					AS CostSeq,			-- 비용항목내부코드
		cserl.RemValueName				AS RemValName,	-- 관리세부항목
		cserl.RemValueSerl				AS RemValSeq,	-- 관리세부항목내부코드
		CASE WHEN G1.CustSeq = 0 THEN G1.CustText ELSE ISNULL(cust.CustName, '') END AS CustName,	-- 거래처
		G1.CustSeq 						AS CustSeq,			-- 거래처내부코드
		G1.Remark						AS Remark,			-- 적요
		G1.CostCashDate					AS CostCashDate		-- 출납예정일
		----------------------------------------------------------
      FROM _TARUsualCost AS A WITH(NOLOCK)
        LEFT OUTER JOIN _TDAEmp     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.RegEmpSeq = B.EmpSeq
        LEFT OUTER JOIN _TDADept    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RegDeptSeq = C.DeptSeq
        LEFT OUTER JOIN _TDAEmp     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq
        LEFT OUTER JOIN _TDADept    AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.DeptSeq = E.DeptSeq
        LEFT OUTER JOIN _TDACCtr    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.CCtrSeq = F.CCtrSeq
        LEFT OUTER JOIN #TARUsualCostAmt    AS G ON A.UsualCostSeq = G.UsualCostSeq
        LEFT OUTER JOIN _TACSlipRow    AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.SlipSeq = H.SlipSeq
        LEFT OUTER JOIN _TCOMGroupWare AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.UsualCostSeq = I.TblKey AND I.WorkKind = 'mnpt_UsualCost'
		-- 조인항목 추가 2015.07.29 by shpark
		LEFT OUTER JOIN _TARUsualCostAmt AS G1 WITH(NOLOCK) ON A.CompanySeq = G1.CompanySeq AND A.UsualCostSeq = G1.UsualCostSeq AND G1.UsualCostSerl = G.UsualCostSerl
        LEFT OUTER JOIN _TARCostAcc		 AS cost WITH(NOLOCK) ON A.CompanySeq = cost.CompanySeq AND G1.CostSeq = cost.CostSeq  
        LEFT OUTER JOIN _TDAAccountRemValue AS cserl WITH(NOLOCK) ON A.CompanySeq = cserl.CompanySeq AND cost.RemSeq = cserl.RemSeq AND G1.RemValSeq = cserl.RemValueSerl  
		LEFT OUTER JOIN _TDACust		AS cust WITH(NOLOCK) ON A.CompanySeq = cust.CompanySeq AND G1.CustSeq = cust.CustSeq
     WHERE A.CompanySeq = @CompanySeq
        AND (A.RegDate BETWEEN @RegDateFr AND @RegDateTo)
        AND (@RegEmpSeq = 0 OR A.RegEmpSeq = @RegEmpSeq)
        AND (@RegDeptSeq = 0 OR A.RegDeptSeq = @RegDeptSeq)
        AND (@UsualCostNo = '' OR A.UsualCostNo LIKE @UsualCostNo + '%')
        AND (A.ApprDate BETWEEN @ApprDateFr AND @ApprDateTo)
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
        AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
        AND (@CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq)
        AND (@IsProg        = '0' OR I.IsProg       = @IsProg       )
        AND (@IsEnd         = '0' OR I.IsEnd        = @IsEnd        )
--        AND (@IsAttachFile  = '0' OR I.IsAttachFile = @IsAttachFile )
      AND (@IsAttachFile = '0' OR I.IsAttachFile > 0)

    RETURN
go
exec mnpt_SARUsualCostListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegDateFr>20180101</RegDateFr>
    <RegDateTo />
    <ApprDateFr>20180101</ApprDateFr>
    <ApprDateTo />
    <UsualCostNo />
    <RegEmpSeq />
    <EmpSeq />
    <CCtrSeq />
    <RegDeptSeq />
    <DeptSeq />
    <SlipProc />
    <IsProg>0</IsProg>
    <IsEnd>0</IsEnd>
    <IsAttachFile>0</IsAttachFile>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820118,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=13820110