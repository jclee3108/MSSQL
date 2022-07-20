IF OBJECT_ID('mnpt_SPJTEETransPurchaseSave') IS NOT NULL 
    DROP PROC mnpt_SPJTEETransPurchaseSave
GO 

/************************************************************
 설  명		- 운송매입입력_mnpt 저장
 작성일		- 2017년 11월 30일  
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
CREATE PROC mnpt_SPJTEETransPurchaseSave
	@ServiceSeq		INT			= 0,
    @WorkingTag		NCHAR(1)	= '',
    @CompanySeq		INT			= 1,
    @LanguageSeq	INT			= 1,
    @UserSeq		INT			= 0,
    @PgmSeq			INT			= 0,
    @IsTransaction	BIT			= 0
AS
	
	DECLARE @TableColumns		NVARCHAR(MAX)


	SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEETransPurchase')  
	EXEC dbo._SCOMLog	@CompanySeq,
						@UserSeq,
						'mnpt_TPJTEETransPurchase',
						'#BIZ_OUT_DataBlock1',
						'TransPurSeq',
						@TableColumns,
						 '',
						 @PgmSeq



	IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE Status	= 0 AND WorkingTag = 'D')
	BEGIN
		DELETE mnpt_TPJTEETransPurchase
		  FROM mnpt_TPJTEETransPurchase AS A
			   INNER JOIN #BIZ_OUT_DataBlock1 AS B
					   ON A.TransPurSeq		= B.TransPurSeq
		 WHERE A.CompanySeq	= @CompanySeq
		   AND B.Status		= 0 
		   AND B.WorkingTag	= 'D'

		IF @@ERROR	<> 0
		BEGIN
			RETURN
		END

	END

	IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE Status	= 0 AND WorkingTag = 'U')
	BEGIN
		UPDATE mnpt_TPJTEETransPurchase
		   SET BizUnit			= B.BizUnit,
			   PurDate			= B.PurDate,
			   PurCustSeq		= B.PurCustSeq,
			   EmpSeq			= B.EmpSeq,
			   DeptSeq			= B.DeptSeq,
			   PJTSeq			= B.PJTSeq,
			   CustSeq			= B.CustSeq,
			   ItemName			= B.ItemName,
			   TransPlace		= B.TransPlace,
			   ExpenseItemSeq	= B.ExpenseItemSeq,
			   InputEquipment	= B.InputEquipment,
			   Qty				= B.Qty,
			   UnitSeq			= B.UnitSeq,
			   Price			= B.Price,
			   CurAmt			= B.CurAmt,
			   IsVat			= B.IsVat,
			   CurVat			= B.CurVat,
			   Remark			= B.Remark,
			   EvidSeq			= B.EvidSeq,
			   Dummy1			= B.Dummy1,
			   Dummy2			= B.Dummy2,
			   Dummy3			= B.Dummy3,
			   Dummy4			= B.Dummy4,
			   Dummy5			= B.Dummy5,
			   LastUserSeq		= @UserSeq,
			   LastDateTime		= GETDATE(),
			   PgmSeq			= @PgmSeq
		  FROM mnpt_TPJTEETransPurchase AS A
			   INNER JOIN #BIZ_OUT_DataBlock1 AS B
					   ON A.TransPurSeq		= B.TransPurSeq
		 WHERE A.CompanySeq	= @CompanySeq
		   AND B.Status		= 0 
		   AND B.WorkingTag	= 'U'

		IF @@ERROR	<> 0
		BEGIN
			RETURN
		END


	END

	IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE Status	= 0 AND WorkingTag = 'A')
	BEGIN
		INSERT INTO mnpt_TPJTEETransPurchase (
			CompanySeq,			TransPurSeq,			BizUnit,			PurCustSeq,			EmpSeq,				DeptSeq,
			PJTSeq,				CustSeq,				ItemName,			TransPlace,			ExpenseItemSeq,		InputEquipment,
			Qty,				UnitSeq,				Price,				CurAmt,				IsVat,				CurVat,
			Remark,				SlipSeq,				Dummy1,				Dummy2,				Dummy3,				Dummy4,
			Dummy5,				FirstUserSeq,			FirstDateTime,		LastUserSeq,		LastDateTime,		PgmSeq,
			PurDate,			EvidSeq
		)
		SELECT
			@CompanySeq,		TransPurSeq,			BizUnit,			PurCustSeq,			EmpSeq,				DeptSeq,
			PJTSeq,				CustSeq,				ItemName,			TransPlace,			ExpenseItemSeq,		InputEquipment,
			Qty,				UnitSeq,				Price,				CurAmt,				IsVat,				CurVat,
			Remark,				SlipSeq,				Dummy1,				Dummy2,				Dummy3,				Dummy4,
			Dummy5,				@UserSeq,				GETDATE(),			@UserSeq,			GETDATE(),			@PgmSeq,
			PurDate,			EvidSeq
		  FROM #BIZ_OUT_DataBlock1 AS A
		 WHERE A.Status		= 0 
		   AND A.WorkingTag	= 'A'

		IF @@ERROR	<> 0
		BEGIN
			RETURN
		END
	END


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




	UPDATE #BIZ_OUT_DataBlock1
	   SET UMCostTypeName	= C.MinorName,
		   UMCostType		= C.MinorSeq
	  FROM #BIZ_OUT_DataBlock1 AS A
		   INNER JOIN _TDADept AS B
				   ON B.CompanySeq	= @CompanySeq
				  AND B.DeptSeq		= A.DeptSeq
		   INNER JOIN _TDAUMinor AS C 
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.MinorSeq	= B.UMCostType

	UPDATE #BIZ_OUT_DataBlock1
	   SET AccName		= Q.AccName,
		   AccSeq		= Q.AccSeq,
		   VatAccName	= CASE WHEN A.IsVat = '1' THEN C.AccName ELSE '' END,
		   VatAccSeq	= CASE WHEN A.IsVat = '1' THEN C.AccSeq ELSE 0 END
		   --OppAccName	= D.AccName,
		   --OppAccSeq	= D.AccSeq
	  FROM #BIZ_OUT_DataBlock1 AS A
      	LEFT  JOIN _TPJTBaseTypeExpenseItem AS I WITH(NOLOCK) ON I.CompanySeq		= @CompanySeq
				                                              AND I.ExpenseItemSeq	= A.ExpenseItemSeq
		   LEFT  JOIn _TDAAccount AS Q WITH(NOLOCK)
				   ON Q.CompanySeq	= I.CompanySeq
				  AND Q.AccSeq		= I.AccSeq
		   LEFT  JOIN ( -- 정산
		   					SELECT TOP 1 AccSeq, AccName
		   					  FROM #Acc AS Z 
		   					 WHERE IsAnti = '0'
							   AND SMAcctype <> 4002009
		   					ORDER BY RowSort
		   				  ) AS B ON ( 1 = 1 ) 
		   LEFT  JOIN ( -- 부가세계정
		   					SELECT TOP 1 AccSeq, AccName
		   					  FROM #Acc AS Z 
		   					 WHERE IsAnti = '0'
		   					   AND SMAccType = 4002009
		   					ORDER BY RowSort
		   				  ) AS C ON ( 1 = 1 ) 
		   --LEFT  JOIN ( -- 상대계정
		   --					SELECT TOP 1 AccSeq, AccName
		   --					  FROM #Acc AS Z 
		   --					 WHERE IsAnti = '1'
		   --					ORDER BY RowSort
		   --				  ) AS D ON ( 1 = 1 ) 