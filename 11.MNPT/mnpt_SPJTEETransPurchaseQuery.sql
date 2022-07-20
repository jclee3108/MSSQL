IF OBJECT_ID('mnpt_SPJTEETransPurchaseQuery') IS NOT NULL 
    DROP PROC mnpt_SPJTEETransPurchaseQuery
GO 


/************************************************************
 설  명		- 운송매입입력_mnpt 조회
 작성일		- 2017년 11월 30일  
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
 CREATE PROC mnpt_SPJTEETransPurchaseQuery  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
	DECLARE @PurCustSeq		INT,
			@EmpSeq			INT,
			@DeptSeq		INT,
			@PJTSeq			INT,
			@PJTName		NVARCHAR(100),
			@CustSeq		INT,
			@PurDateFr		NCHAR(8),
			@PurDateTo		NCHAR(8),
			@ExpenseItemSeq	INT,
			@PJTNo			NVARCHAR(100),
			@ItemName		NVARCHAR(100),
			@InputEquipment	NVARCHAR(100),
			@TransPlace		NVARCHAR(100),
			@SMSlipKind		INT

	SELECT @PurCustSeq	= ISNULL(PurCustSeq, 0),
		   @EmpSeq		= ISNULL(EmpSeq, 0),
		   @DeptSeq		= ISNULL(DeptSeq, 0),
		   @PJTSeq		= ISNULL(PJTSeq, 0),
		   @PJTName		= ISNULL(PJTName, ''),
		   @CustSeq		= ISNULL(CustSeq, 0),
		   @PurDateFr	= ISNULL(PurDateFr, 0),
		   @PurDateTo		= ISNULL(PurDateTo, 0),
		   @ExpenseItemSeq		= ISNULL(ExpenseItemSeq, 0),
		   @PJTNo				= ISNULL(PJTNo, ''),
		   @ItemName			= ISNULL(ItemName, ''),	
		   @InputEquipment		= ISNULL(InputEquipment, ''),
		   @TransPlace			= ISNULL(TransPlace, ''),
		   @SMSlipKind			= ISNULL(SMSlipKind, 0)
	  FROM #BIZ_IN_DataBlock1

    -- 자동전표환경설정 계정과목가져오기 
    SELECT DISTINCT 
           C.AccSeq,
           D.AccName,
           C.RowSort, 
           C.IsAnti, 
           D.SMAccType
      INTO #Acc
      FROM _TACSlipKind             AS A 
      JOIN _TACSlipAutoEnv          AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipKindNo = A.SlipKindNo ) 
      JOIN _TACSlipAutoEnvRow       AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipAutoEnvSeq = B.SlipAutoEnvSeq ) 
      JOIN _TDAAccount              AS D ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = C.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PgmSeq     = @PgmSeq
     ORDER BY C.RowSort

	SELECT B.BizUnitName,
		   B.BizUnit,
		   A.PurDate,
		   C.CustName		AS PurCustName,
		   A.PurCustSeq,
		   D.EmpName,
		   A.EmpSeq,
		   E.DeptName,
		   A.DeptSeq,
		   F.PJTName,
		   F.PJTNo,
		   A.PJTSeq,
		   G.CCtrName,
		   G.CCtrSeq,
		   H.CustName,
		   A.CustSeq,
		   A.ItemName,
		   A.TransPlace,
		   I.ExpenseItemName,
		   A.ExpenseItemSeq,
		   J.EvidName,
		   A.EvidSeq,
		   A.InputEquipment,
		   A.Qty,
		   A.Price,
		   K.UnitName,
		   A.UnitSeq,
		   A.CurAmt,
		   A.IsVat,
		   A.CurVat,
		   A.CurAmt + A.CurVat AS SumCurAmt,
		   A.Remark,
		   A.Dummy1,
		   A.Dummy2,
		   A.Dummy3,
		   A.Dummy4,
		   A.Dummy5,
		   Q.AccName,
		   Q.AccSeq,
		   --L.AccName,
		   --L.AccSeq,
		   CASE WHEN A.IsVAt = '1' THEN M.AccName		
				ELSE ''
				END			AS VatAccName,
		   CASE WHEN A.IsVat = '1' THEN M.AccSeq
			    ELSE 0
				END			AS VatAccSeq,
		   N.AccName		AS OppAccName,
		   --N.AccSeq			AS OppAccSeq,
           CONVERT(INT,A.Dummy5) AS OppAccSeq, 
		   A.TransPurSeq,
		   A.SlipSeq,
		   O.MinorName		AS UMCostTypeName,
		   E.UMCosttype		AS UMCostType,
		   P.SlipID			AS SlipNo
	  FROM mnpt_TPJTEETransPurchase AS A WITH(NOLOCK)
		   LEFT  JOIN _TDABizUnit AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.BizUnit		= A.BizUnit
		   LEFT  JOIN _TDACust AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  ANd C.CustSeq		= A.PurCustSeq
		   LEFT  JOIN _TDAEmp AS D WITH(NOLOCK)
				   ON D.CompanySeq	= A.CompanySeq
				  AND D.EmpSeq		= A.EmpSeq
		   LEFT  JOIN _TDADept AS E WITH(NOLOCK)
				   ON E.CompanySeq	= A.CompanySeq
				  ANd E.DeptSeq		= A.DeptSeq
		   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
				   ON F.CompanySeq	= A.CompanySeq
				  AND F.PJTSeq		= A.PJTSeq
		   LEFt  JOIN _TDACCtr AS G WITH(NOLOCK)
				   ON G.CompanySeq	= F.CompanySeq
				  AND G.CCtrSeq		= F.CCtrSeq
		   LEFT  JOIN _TDACust AS H WITH(NOLOCK)
				   ON H.CompanySeq	= A.CompanySeq
				  AND H.CustSeq		= A.CustSeq
		   LEFT  JOIN _TPJTBaseTypeExpenseItem AS I WITH(NOLOCK)
				   ON I.CompanySeq		= A.CompanySeq
				  AND I.ExpenseItemSeq	= A.ExpenseItemSeq
		   LEFT  JOIN _TDAEvid AS J WITH(NOLOCK)
				   ON J.CompanySeq	= A.CompanySeq
				  AND J.EvidSeq		= A.EvidSeq
		   LEFT  JOIN _TDAUnit AS K WITH(NOLOCK)
				   ON K.CompanySeq	= A.CompanySeq
				  AND K.UnitSeq		= A.UnitSeq
		   LEFT  JOIN ( -- 정산
		   					SELECT TOP 1 AccSeq, AccName
		   					  FROM #Acc AS Z 
		   					 WHERE IsAnti = '0'
							   AND SMAcctype <> 4002009
		   					ORDER BY RowSort
		   				  ) AS L ON ( 1 = 1 ) 
		   LEFT  JOIN ( -- 부가세계정
		   					SELECT TOP 1 AccSeq, AccName
		   					  FROM #Acc AS Z 
		   					 WHERE IsAnti = '0'
		   					   AND SMAccType = 4002009
		   					ORDER BY RowSort
		   				  ) AS M ON ( 1 = 1 ) 
		   --LEFT  JOIN ( -- 상대계정
		   --					SELECT TOP 1 AccSeq, AccName
		   --					  FROM #Acc AS Z 
		   --					 WHERE IsAnti = '1'
		   --					ORDER BY RowSort
		   --				  ) AS N ON ( 1 = 1 ) 
           LEFT  JOIN _TDAAccount AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.AccSeq = CONVERT(INT,A.Dummy5) ) 
		   LEFT  JOIN _TDAUMinor AS O WITH(NOLOCK)
				   ON O.CompanySeq	= E.CompanySeq
				  AND O.MinorSeq	= E.UMCostType
		   LEFT  JOIN _TACSlipRow AS P WITH(NOLOCK)
				   ON P.CompanySeq	= A.companySeq
				  AND P.SlipSeq		= A.SlipSeq
		   LEFT  JOIn _TDAAccount AS Q WITH(NOLOCK)
				   ON Q.CompanySeq	= I.CompanySeq
				  AND Q.AccSeq		= I.AccSeq
				 
	WHERE A.CompanySeq	= @CompanySeq
	  AND A.PurDate		BETWEEN @PurDateFr AND @PurDateTo
	  AND (@PurCustSeq	= 0 OR A.PurCustSeq	= @PurCustSeq)
	  AND (@CustSeq		= 0 OR A.CustSeq	= @CustSeq)
	  AND (@PJTName		= '' OR F.PJTName LIKE @PJTName + '%')
	  AND (@EmpSeq		= 0 OR A.EmpSeq		= @EmpSeq)
	  AND (@DeptSeq		= 0 OR A.DeptSeq	= @DeptSeq)
	  AND (@ExpenseItemSeq	= 0 OR A.ExpenseItemSeq = @ExpenseItemSeq)
	  AND (@PJTNo		= '' OR F.PJTNo LIKE @PJTNo + '%')
	  AND (@ItemName	= '' OR A.ItemName LIKE @ItemName + '%')
	  AND (@InputEquipment	= '' OR A.InputEquipment LIKE @InputEquipment + '%')
	  AND (@TransPlace	= '' OR A.TransPlace	LIKE @TransPlace)
	  AND (@SMSlipKind	= 0 OR (@SMSlipKind = 20231001 AND A.SlipSeq = 0)
						    OR (@SMSlipKind	= 20231002 AND A.SlipSeq <> 0)
								)
	ORDER BY A.BizUnit, A.PurDate
