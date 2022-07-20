IF OBJECT_ID('mnpt_SPJTUnionPaySum') IS NOT NULL 
    DROP PROC mnpt_SPJTUnionPaySum
GO 

 -- 2018.01.16
/************************************************************
 설  명		- 노조노임정산 집계테이블 생성.
 작성일		- 2017년 10월 16일  
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
 CREATE PROC mnpt_SPJTUnionPaySum  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS

    
    DECLARE 
            --@GangAccSeq         INT,            -- 노조
            --@UDDAccSeq          INT,            -- 노조일용
            @RetireAccSeq		INT,			--퇴충금계정과목코드	
			@ModernAccSeq		INT,			--현대화계정과목코드
			@TraingAccSeq		INT,			--교육훈련계정과목코드
			@WelfareAccSeq		INT,			--복리후생계정과목코드	
			@MedicalAccSeq		INT,			--의료보험계정과목코드	
			@NationalAccSeq		INT,			--국민연금계정과목코드	
			@SafetyAccSeq		INT,			--안전기금계정과목코드	
			@SocietyAccSeq		INT,			--협회비계정과목코드	
			@MealAccSeq			INT,			--식대계정과목코드
            @GangOppAccSeq      INT,   
            @UDDOppAccSeq       INT,
            @RetireOppAccSeq    INT,
            @ModernOppAccSeq    INT,
            @TraingOppAccSeq    INT,
            @WelfareOppAccSeq   INT,
            @MedicalOppAccSeq   INT,
            @NationalOppAccSeq  INT,
            @SafetyOppAccSeq    INT,
            @SocietyOppAccSeq   INT,
            @MealOppAccSeq      INT, 
            @GangCustSeq        INT, 
            @UDDCustSeq         INT, 
            @RetireCustSeq      INT, 
            @ModernCustSeq      INT, 
            @TraingCustSeq      INT, 
            @WelfareCustSeq     INT, 
            @MedicalCustSeq     INT, 
            @NationalCustSeq    INT, 
            @SafetyCustSeq      INT, 
            @SocietyCustSeq     INT, 
            @MealCustSeq        INT, 
            @GangText           NVARCHAR(200), 
            @UDDText            NVARCHAR(200), 
            @RetireText         NVARCHAR(200), 
            @ModernText         NVARCHAR(200), 
            @TraingText         NVARCHAR(200), 
            @WelfareText        NVARCHAR(200), 
            @MedicalText        NVARCHAR(200), 
            @NationalText       NVARCHAR(200), 
            @SafetyText         NVARCHAR(200), 
            @SocietyText        NVARCHAR(200), 
            @MealText           NVARCHAR(200), 
            @Dummy1AccSeq       INT, 
            @Dummy2AccSeq       INT, 
            @Dummy1OppAccSeq    INT, 
            @Dummy2OppAccSeq    INT, 
            @Dummy1CustSeq      INT, 
            @Dummy2CustSeq      INT, 
            @Dummy1Text         NVARCHAR(200), 
            @Dummy2Text         NVARCHAR(200), 
            @DeptSeq            INT 

             

    --SELECT @GangAccSeq	        = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942001 AND Serl = 1000005)
    --SELECT @UDDAccSeq		    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942011 AND Serl = 1000005)
	SELECT @RetireAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942002 AND Serl = 1000005)
	SELECT @ModernAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942003 AND Serl = 1000005)
	SELECT @TraingAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942004 AND Serl = 1000005)
	SELECT @WelfareAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942005 AND Serl = 1000005)
	SELECT @MedicalAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942006 AND Serl = 1000005)
	SELECT @NationalAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942007 AND Serl = 1000005)
	SELECT @SafetyAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942008 AND Serl = 1000005)
	SELECT @SocietyAccSeq	    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942009 AND Serl = 1000005)
	SELECT @MealAccSeq		    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942010 AND Serl = 1000005)

    SELECT @GangOppAccSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942001 AND Serl = 1000006)
    SELECT @UDDOppAccSeq        = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942011 AND Serl = 1000006)
	SELECT @RetireOppAccSeq     = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942002 AND Serl = 1000006)
	SELECT @ModernOppAccSeq     = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942003 AND Serl = 1000006)
	SELECT @TraingOppAccSeq     = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942004 AND Serl = 1000006)
	SELECT @WelfareOppAccSeq    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942005 AND Serl = 1000006)
	SELECT @MedicalOppAccSeq    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942006 AND Serl = 1000006)
	SELECT @NationalOppAccSeq   = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942007 AND Serl = 1000006)
	SELECT @SafetyOppAccSeq     = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942008 AND Serl = 1000006)
	SELECT @SocietyOppAccSeq    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942009 AND Serl = 1000006)
	SELECT @MealOppAccSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942010 AND Serl = 1000006)

    SELECT @GangCustSeq         = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942001 AND Serl = 1000007)
    SELECT @UDDCustSeq          = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942011 AND Serl = 1000007)
	SELECT @RetireCustSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942002 AND Serl = 1000007)
	SELECT @ModernCustSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942003 AND Serl = 1000007)
	SELECT @TraingCustSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942004 AND Serl = 1000007)
	SELECT @WelfareCustSeq      = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942005 AND Serl = 1000007)
	SELECT @MedicalCustSeq      = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942006 AND Serl = 1000007)
	SELECT @NationalCustSeq     = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942007 AND Serl = 1000007)
	SELECT @SafetyCustSeq       = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942008 AND Serl = 1000007)
	SELECT @SocietyCustSeq      = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942009 AND Serl = 1000007)
	SELECT @MealCustSeq         = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942010 AND Serl = 1000007)


    SELECT @GangText         = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942001 )
    SELECT @UDDText          = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942011 )
    SELECT @RetireText       = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942002 )
    SELECT @ModernText       = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942003 )
    SELECT @TraingText       = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942004 )
    SELECT @WelfareText      = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942005 )
    SELECT @MedicalText      = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942006 )
    SELECT @NationalText     = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942007 )
    SELECT @SafetyText       = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942008 )
    SELECT @SocietyText      = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942009 )
    SELECT @MealText         = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942010 )
    
    SELECT @Dummy1AccSeq        = 0 
    SELECT @Dummy2AccSeq        = 0 
    SELECT @Dummy1OppAccSeq     = 0 
    SELECT @Dummy2OppAccSeq     = 0 
    SELECT @Dummy1CustSeq       = 0 
    SELECT @Dummy2CustSeq       = 0 
    SELECT @Dummy1Text          = ''
    SELECT @Dummy2Text          = ''



    SELECT @DeptSeq = B.DeptSeq 
      FROM _TCAUser AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.UserSeq = @UserSeq 




	DECLARE @MessageType		INT,
			@Status				INT,
			@Results			NVARCHAR(250),
			@TableColumns		NVARCHAR(MAX)
			
	--삭제대상, 프로젝트별 모선항차별, 하역방식 담기
	CREATE TABLE #tmpItem (
		PJTSeq		INT,
		ShipSeq		INT,
		ShipSerl	INT,
		UMLoadType	INT,
		ItemName	NVARCHAR(100)
	)
	INSERT INTO #tmpItem (
		PJTSeq,		ShipSeq,		ShipSerl,	UMLoadType, ItemName
	)
	SELECT 
		PJTSeq,		ShipSeq,		ShipSerl,	UMLoadType, ''
	  FROM #BIZ_OUT_DataBlock1
     WHERE Status	= 0
	UNION 
	SELECT 
		PJTSeq,		ShipSeq,		ShipSerl,	UMLoadType, ''
	  FROM #BIZ_OUT_DataBlock2
     WHERE Status	= 0

	--집계테이블 삭제
	DELETE mnpt_TPJTUnionPaySum
	  FROM mnpt_TPJTUnionPaySum AS A
		   INNER JOIN #tmpItem AS B
				   ON B.PJTSeq		= A.PJTSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSerl	= A.ShipSerl
				  AND B.UMLoadtype	= A.UMLoadType
				  AND B.ItemName	= A.ItemName
	  WHERE A.SlipSeq = 0
	

	INSERT INTO mnpt_TPJTUnionPaySum (
		CompanySeq,			PJTSeq,				ShipSeq,			ShipSerl,			BizUnit,			AccUnit,	
		OutDate,			PJTTypeSeq,			ItemName,			Qty,				MTQty,				GangAmt,
		GangExtraAmt,		GangSumAmt,			UtilityAmt,			UDDSumAmt,			SumAmt,				RetireAmt,
		ModernAmt,			TraingAmt,			WelfareAmt,			MedicalAmt,			NationalAmt,		SafetyAmt,
		SocietyAmt,			Dummy1,				Dummy2,				SlipSeq,			FirstUserSeq,		FirstDateTime,
		LastUserSeq,		LastDateTime,		PgmSeq,				UMLoadType,			IsUpdate,			MealAmt,
		IsRetro,			RetroDate, 

        GangAccSeq, UDDAccSeq, RetireAccSeq, ModernAccSeq, TraingAccSeq, 
        WelfareAccSeq, MedicalAccSeq, NationalAccSeq, SafetyAccSeq, SocietyAccSeq, 
        MealAccSeq, Dummy1AccSeq, Dummy2AccSeq, GangOppAccSeq, UDDOppAccSeq, 
        RetireOppAccSeq, ModernOppAccSeq, TraingOppAccSeq, WelfareOppAccSeq, MedicalOppAccSeq, 
        NationalOppAccSeq, SafetyOppAccSeq, SocietyOppAccSeq, MealOppAccSeq, Dummy1OppAccSeq,
        Dummy2OppAccSeq, GangCustSeq, UDDCustSeq, RetireCustSeq, ModernCustSeq, 
        TraingCustSeq, WelfareCustSeq ,MedicalCustSeq, NationalCustSeq, SafetyCustSeq, 
        SocietyCustSeq, MealCustSeq, Dummy1CustSeq, Dummy2CustSeq, GangText, 
        UDDText, RetireText, ModernText, TraingText, WelfareText, 
        MedicalText, NationalText, SafetyText, SocietyText, MealText, 
        Dummy1Text, Dummy2Text, UMCostType, DeptSeq, CCtrSeq
	)
	SELECT
		A.CompanySeq,		A.PJTSeq,			A.ShipSeq,			A.ShipSerl,			A.BizUnit,			C.AccUnit,
		A.OutDate,			A.PJTTypeSeq,		'',					0,					0,					0,
		0,					0,					0,					0,					0,					0,
		0,					0,					0,					0,					0,					0,
		0,					0,					0,					0,					@UserSeq,			GETDATE(),
		@UserSeq,			GETDATE(),			@PgmSeq,			A.UMLoadType,		'0',				0,
		'0',				'', 

        J.ValueSeq, J.ValueSeq, @RetireAccSeq, @ModernAccSeq, @TraingAccSeq, 
        @WelfareAccSeq, @MedicalAccSeq, @NationalAccSeq, @SafetyAccSeq, @SocietyAccSeq,
        @MealAccSeq, @Dummy1AccSeq, @Dummy2AccSeq, @GangOppAccSeq, @UDDOppAccSeq,
        @RetireOppAccSeq, @ModernOppAccSeq, @TraingOppAccSeq, @WelfareOppAccSeq, @MedicalOppAccSeq, 
        @NationalOppAccSeq, @SafetyOppAccSeq, @SocietyOppAccSeq, @MealOppAccSeq, @Dummy1OppAccSeq,
        @Dummy2OppAccSeq, @GangCustSeq, @UDDCustSeq, @RetireCustSeq, @ModernCustSeq, 
        @TraingCustSeq, @WelfareCustSeq, @MedicalCustSeq, @NationalCustSeq, @SafetyCustSeq, 
        @SocietyCustSeq, @MealCustSeq, @Dummy1CustSeq, @Dummy2CustSeq, @GangText, 
        @UDDText, @RetireText, @ModernText, @TraingText, @WelfareText, 
        @MedicalText, @NationalText, @SafetyText, @SocietyText, @MealText, 
        @Dummy1Text, @Dummy2Text, D.UMCostType, @DeptSeq, D.CCtrSeq 

	  FROM mnpt_TPJTUnionPayDaily AS A WITH(NOLOCK)
		   INNER JOIN #tmpItem AS B 
				   ON B.PJTSeq		= A.PJTSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSErl	= A.ShipSerl
				  AND B.UMLoadtype	= A.UMLoadType
				  AND B.ItemName	= ''
		   LEFT  JOIN _TDABizUnit AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  ANd C.BizUnit		= A.BizUnit
          LEFT JOIN _TPJTProject    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq )
          LEFT JOIN _TDACCtr        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = E.CCtrSeq )
		  LEFT  JOIN _TDAUMinorValue AS I WITH(NOLOCK) ON I.CompanySeq	= A.CompanySeq
			                                          AND I.ValueSeq	= A.PJTTypeSeq
				                                      AND I.Serl		= 1000001
				                                      AND I.MajorSeq	= 1016046
          LEFT  JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON J.CompanySeq	= I.CompanySeq
				                                      AND J.MinorSeq	= I.MinorSeq
				                                      AND J.Serl		= 1000002
				                                      AND J.MajorSeq	= 1016046 
	  WHERE A.CompanySeq	= @CompanySeq
	 GROUP BY 
		A.CompanySeq,		A.PJTSeq,			A.ShipSeq,			A.ShipSerl,			A.BizUnit,			C.AccUnit,
		A.OutDate,			A.PJTTypeSeq,		A.UMLoadType,       D.UMCostType,       D.CCtrSeq,          J.ValueSeq 

	INSERT INTO mnpt_TPJTUnionPaySum (
		CompanySeq,			PJTSeq,				ShipSeq,			ShipSerl,			BizUnit,			AccUnit,	
		OutDate,			PJTTypeSeq,			ItemName,			Qty,				MTQty,				GangAmt,
		GangExtraAmt,		GangSumAmt,			UtilityAmt,			UDDSumAmt,			SumAmt,				RetireAmt,
		ModernAmt,			TraingAmt,			WelfareAmt,			MedicalAmt,			NationalAmt,		SafetyAmt,
		SocietyAmt,			Dummy1,				Dummy2,				SlipSeq,			FirstUserSeq,		FirstDateTime,
		LastUserSeq,		LastDateTime,		PgmSeq,				UMLoadType,			IsUpdate,			MealAmt,
		IsRetro,			RetroDate, 

        GangAccSeq, UDDAccSeq, RetireAccSeq, ModernAccSeq, TraingAccSeq, 
        WelfareAccSeq, MedicalAccSeq, NationalAccSeq, SafetyAccSeq, SocietyAccSeq, 
        MealAccSeq, Dummy1AccSeq, Dummy2AccSeq, GangOppAccSeq, UDDOppAccSeq, 
        RetireOppAccSeq, ModernOppAccSeq, TraingOppAccSeq, WelfareOppAccSeq, MedicalOppAccSeq, 
        NationalOppAccSeq, SafetyOppAccSeq, SocietyOppAccSeq, MealOppAccSeq, Dummy1OppAccSeq,
        Dummy2OppAccSeq, GangCustSeq, UDDCustSeq, RetireCustSeq, ModernCustSeq, 
        TraingCustSeq, WelfareCustSeq ,MedicalCustSeq, NationalCustSeq, SafetyCustSeq, 
        SocietyCustSeq, MealCustSeq, Dummy1CustSeq, Dummy2CustSeq, GangText, 
        UDDText, RetireText, ModernText, TraingText, WelfareText, 
        MedicalText, NationalText, SafetyText, SocietyText, MealText, 
        Dummy1Text, Dummy2Text, UMCostType, DeptSeq, CCtrSeq
	)
	SELECT
		A.CompanySeq,		A.PJTSeq,			A.ShipSeq,			A.ShipSerl,			A.BizUnit,			C.AccUnit,
		A.OutDate,			A.PJTTypeSeq,		'',					0,					0,					0,
		0,					0,					0,					0,					0,					0,
		0,					0,					0,					0,					0,					0,
		0,					0,					0,					0,					@UserSeq,			GETDATE(),
		@UserSeq,			GETDATE(),			@PgmSeq,			A.UMLoadType,		'0',				0,
		'0',				'', 

        J.ValueSeq, J.ValueSeq, @RetireAccSeq, @ModernAccSeq, @TraingAccSeq, 
        @WelfareAccSeq, @MedicalAccSeq, @NationalAccSeq, @SafetyAccSeq, @SocietyAccSeq,
        @MealAccSeq, @Dummy1AccSeq, @Dummy2AccSeq, @GangOppAccSeq, @UDDOppAccSeq,
        @RetireOppAccSeq, @ModernOppAccSeq, @TraingOppAccSeq, @WelfareOppAccSeq, @MedicalOppAccSeq, 
        @NationalOppAccSeq, @SafetyOppAccSeq, @SocietyOppAccSeq, @MealOppAccSeq, @Dummy1OppAccSeq,
        @Dummy2OppAccSeq, @GangCustSeq, @UDDCustSeq, @RetireCustSeq, @ModernCustSeq, 
        @TraingCustSeq, @WelfareCustSeq, @MedicalCustSeq, @NationalCustSeq, @SafetyCustSeq, 
        @SocietyCustSeq, @MealCustSeq, @Dummy1CustSeq, @Dummy2CustSeq, @GangText, 
        @UDDText, @RetireText, @ModernText, @TraingText, @WelfareText, 
        @MedicalText, @NationalText, @SafetyText, @SocietyText, @MealText, 
        @Dummy1Text, @Dummy2Text, D.UMCostType, @DeptSeq, D.CCtrSeq 

	  FROM mnpt_TPJTUnionPayDaily2 AS A WITH(NOLOCK)
		   INNER JOIN #tmpItem AS B 
				   ON B.PJTSeq		= A.PJTSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSErl	= A.ShipSerl
				  AND B.UMLoadtype	= A.UMLoadType
				  AND B.ItemName	= ''
		  LEFT  JOIN _TDABizUnit AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  ANd C.BizUnit		= A.BizUnit
          LEFT JOIN _TPJTProject    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq )
          LEFT JOIN _TDACCtr        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = E.CCtrSeq )
		  LEFT  JOIN _TDAUMinorValue AS I WITH(NOLOCK) ON I.CompanySeq	= A.CompanySeq
			                                          AND I.ValueSeq	= A.PJTTypeSeq
				                                      AND I.Serl		= 1000001
				                                      AND I.MajorSeq	= 1016046
          LEFT  JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON J.CompanySeq	= I.CompanySeq
				                                      AND J.MinorSeq	= I.MinorSeq
				                                      AND J.Serl		= 1000002
				                                      AND J.MajorSeq	= 1016046 

	  WHERE A.CompanySeq	= @CompanySeq
	    AND NOT EXISTS (
						SELECT 1
						  FROM mnpt_TPJTUnionPaySum
						 WHERE CompanySeq	= A.CompanySeq
						   AND PJTSeq		= A.PJTSeq
						   AND ShipSeq		= A.ShipSeq
						   AND ShipSerl		= A.ShipSerl
						   AND UMLoadType	= A.UMLoadType
					)
	 GROUP BY 
		A.CompanySeq,		A.PJTSeq,			A.ShipSeq,			A.ShipSerl,			A.BizUnit,			C.AccUnit,
		A.OutDate,			A.PJTTypeSeq,		A.UMLoadType,       D.UMCostType,       D.CCtrSeq,          J.ValueSeq 
	  

	UPDATE mnpt_TPJTUnionPaySum
	   SET Qty			= ISNULL(B.Qty, 0),
		   MTQty		= ISNULL(B.MTQty, 0),
		   GangAmt		= ROUND(ISNULL(B.GangAmt, 0), 0),
		   GangExtraAmt	= ROUND(ISNULL(B.GangExtraAmt, 0), 0),
		   GangSumAmt	= ROUND(ISNULL(B.GangSumAmt, 0), 0)
	  FROM mnpt_TPJTUnionPaySum AS A
		   INNER  JOIN (
						SELECT SUM(Z.UpTodayQty)				AS Qty,		--조정된수량
							   SUM(Z.UpTodayMTWeight)			AS MTQty,	--조정된 MT수량
							   ROUND(SUM(Z.Amt), 0)				AS GangAmt,
							   ROUND(SUM(Z.ExtraAmt), 0)		AS GangExtraAmt,
							   ROUND(SUM(Z.SumAmt), 0)			AS GangSumAmt,
							   Z.PJTSeq,
							   Z.ShipSeq,
							   Z.ShipSerl,
							   Z.UMLoadType
						  FROM mnpt_TPJTUnionPayDaily AS Z
							   INNER JOIN #tmpItem AS Y 
									   ON Y.PJTSeq		= Z.PJTSeq
									  AND Y.ShipSeq		= Z.ShipSeq
									  AND Y.ShipSErl	= Z.ShipSerl
									  AND Y.UMLoadType	= Z.UMLoadType
						 WHERE Z.CompanySeq	= @CompanySeq
						 GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.UMLoadType
					) AS B
				   ON B.PJTSeq		= A.PJTSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSerl	= A.ShipSerl
				  AND B.UMLoadType	= A.UMLoadType

	UPDATE mnpt_TPJTUnionPaySum
	   SET UDDSumAmt	= ROUND(ISNULL(C.UDDSumAmt, 0), 0),
		   MealAmt		= ROUND(ISNULL(C.MealAmt, 0), 0)
	  FROM mnpt_TPJTUnionPaySum AS A
		   INNER  JOIN (
						SELECT ROUND(SUM(X.SumAmt), 0)				AS UDDSumAmt,
							   ROUND(SUM(X.MealAmt), 0)				AS MealAmt,
							   X.PJTSeq,
							   X.ShipSeq,
							   X.ShipSerl,
							   X.UMLoadType
						  FROM mnpt_TPJTUnionPayDaily2 AS X
							   INNER JOIN #tmpItem AS W 
									   ON W.PJTSeq		= X.PJTSeq
									  AND W.ShipSeq		= X.ShipSeq
									  AND W.ShipSErl	= X.ShipSerl
									  AND W.UMLoadType	= X.UMLoadType
						 WHERE X.CompanySeq	= @CompanySeq
						 GROUP BY X.PJTSeq, X.ShipSeq, X.ShipSerl, X.UMLoadType
					) AS C
				   ON C.PJTSeq		= A.PJTSeq
				  AND C.ShipSeq		= A.ShipSeq
				  AND C.ShipSerl	= A.ShipSerl
				  AND C.UMLoadType	= A.UMLoadType
	
	--노조노임의 식대비도 노조노임집계테이블에서 노조일용계로 금액 update
	--2017.11.11
	UPDATE mnpt_TPJTUnionPaySum
	   SET MealAmt	= ROUND(ISNULL(A.MealAmt, 0) + ISNULL(C.MealAmt, 0), 0)
	  FROM mnpt_TPJTUnionPaySum AS A
		   INNER  JOIN (
						SELECT ROUND(SUM(X.MealAmt), 0)	AS MealAmt,
							   X.PJTSeq,
							   X.ShipSeq,
							   X.ShipSerl,
							   X.UMLoadType
						  FROM mnpt_TPJTUnionPayDaily AS X
							   INNER JOIN #tmpItem AS W 
									   ON W.PJTSeq		= X.PJTSeq
									  AND W.ShipSeq		= X.ShipSeq
									  AND W.ShipSErl	= X.ShipSerl
									  AND W.UMLoadType	= X.UMLoadType
						 WHERE X.CompanySeq	= @CompanySeq
						 GROUP BY X.PJTSeq, X.ShipSeq, X.ShipSerl, X.UMLoadType
					) AS C
				   ON C.PJTSeq		= A.PJTSeq
				  AND C.ShipSeq		= A.ShipSeq
				  AND C.ShipSerl	= A.ShipSerl
				  AND C.UMLoadType	= A.UMLoadType

	--노조노임 공과금계산..
	CREATE TABLE #tmpUtilityPrice (
		PJTTypeSeq		INT,
		UMLoadType		INT,
		TitleSeq		INT,
		StratDate		NCHAR(8),
		EndDate			NCHAR(8),
		Price			DECIMAL(19, 5)
	)
	INSERT INTO #tmpUtilityPrice (
		PJTTypeSeq,	UMLoadType,		TitleSeq,
		StratDate,	EndDate,		Price
	)
	SELECT 
		PJTTypeSeq,	UMLoadWaySeq,	C.TitleSeq,
		A.StdDate,	'',				C.Value
	  FROM mnpt_TPJTUnionWagePrice AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTUnionWagePriceItem AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND b.StdSeq		= A.StdSeq
		   INNER JOIN mnpt_TPJTUnionWagePriceValue AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.StdSeq		= B.StdSeq
				  AND C.StdSerl		= B.StdSerl
	  WHERE A.CompanySeq	= @CompanySeq
	
	--시작, 종료일 재구성
	UPDATE #tmpUtilityPrice
	   SET EndDate  = ( SELECT ISNULL(CONVERT(NCHAR(8), DATEADD(d, -1, MIN(StratDate)), 112), '99991231')
						  FROM #tmpUtilityPrice
						 WHERE PJTTypeSeq	= A.PJTTypeSeq
						   AND UMLoadType	= A.UMLoadType
						   AND StratDate       > A.StratDate   )
	  FROM #tmpUtilityPrice AS A
	 
	UPDATE mnpt_TPJTUnionPaySum
	   SET RetireAmt	= ROUND(A.MTQty * ISNULL(B.Price, 0), 0),
		   ModernAmt	= ROUND(A.MTQty * ISNULL(C.Price, 0), 0),
		   TraingAmt	= ROUND(A.MTQty * ISNULL(D.Price, 0), 0),
		   WelfareAmt	= ROUND(A.MTQty * ISNULL(E.Price, 0), 0),
		   MedicalAmt	= ROUND(A.GangSumAmt * (ISNULL(F.Price, 0)/100), 0),
		   NationalAmt	= ROUND(A.GangSumAmt * (ISNULL(G.Price, 0)/100), 0),
		   SafetyAmt	= ROUND(A.MTQty * ISNULL(H.Price, 0), 0),
		   SocietyAmt	= ROUND(A.MTQty * ISNULL(I.Price, 0), 0)
	  FROM mnpt_TPJTUnionPaySum AS A
		   LEFT  JOIN #tmpUtilityPrice AS B
				   ON B.PJTTypeSeq	= A.PJTTypeSeq
				  AND B.UMLoadType	= A.UMLoadType
				  AND B.TitleSeq	= 1015942002		--퇴충금
				  AND A.OutDate		BETWEEN B.StratDate AND B.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS C
				   ON C.PJTTypeSeq	= A.PJTTypeSeq
				  AND C.UMLoadType	= A.UMLoadType
				  AND C.TitleSeq	= 1015942003		--현대화
				  AND A.OutDate		BETWEEN C.StratDate AND C.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS D
				   ON D.PJTTypeSeq	= A.PJTTypeSeq
				  AND D.UMLoadType	= A.UMLoadType
				  AND D.TitleSeq	= 1015942004		--교육훈련
				  AND A.OutDate		BETWEEN D.StratDate AND D.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS E
				   ON E.PJTTypeSeq	= A.PJTTypeSeq
				  AND E.UMLoadType	= A.UMLoadType
				  AND E.TitleSeq	= 1015942005		--복리후생
				  AND A.OutDate		BETWEEN E.StratDate AND E.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS F
				   ON F.PJTTypeSeq	= A.PJTTypeSeq
				  AND F.UMLoadType	= A.UMLoadType
				  AND F.TitleSeq	= 1015942006		--의료보험
				  AND A.OutDate		BETWEEN F.StratDate AND F.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS G
				   ON G.PJTTypeSeq	= A.PJTTypeSeq
				  AND G.UMLoadType	= A.UMLoadType
				  AND G.TitleSeq	= 1015942007		--국민연금
				  AND A.OutDate		BETWEEN G.StratDate AND G.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS H
				   ON H.PJTTypeSeq	= A.PJTTypeSeq
				  AND H.UMLoadType	= A.UMLoadType
				  AND H.TitleSeq	= 1015942008		--안전기금
				  AND A.OutDate		BETWEEN H.StratDate AND H.EndDate
		   LEFT  JOIN #tmpUtilityPrice AS I
				   ON I.PJTTypeSeq	= A.PJTTypeSeq
				  AND I.UMLoadType	= A.UMLoadType
				  AND I.TitleSeq	= 1015942009		--협회비
				  AND A.OutDate		BETWEEN I.StratDate AND I.EndDate
	 WHERE EXISTS (
					SELECT 1
					  FROM #tmpItem
					 WHERE PJTSeq		= A.PJTSeq
					   AND ShipSeq		= A.ShipSeq
					   AND ShipSerl		= A.ShipSerl
					   AND UMLoadType	= A.UMLoadType
				)
	--공과금 Sum
	UPDATE mnpt_TPJTUnionPaySum
	   SET UtilityAmt	= ROUND(RetireAmt, 0)	+
						  ROUND(ModernAmt, 0)	+
						  ROUND(TraingAmt, 0)	+ 
						  ROUND(WelfareAmt, 0)	+
						  ROUND(MedicalAmt, 0)	+ 
						  ROUND(NationalAmt, 0) + 
						  ROUND(SafetyAmt, 0)	+ 
						  ROUND(SocietyAmt, 0)	
	  FROM mnpt_TPJTUnionPaySum AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM #tmpItem
					 WHERE PJTSeq		= A.PJTSeq
					   AND ShipSeq		= A.ShipSeq
					   AND ShipSerl		= A.ShipSerl
					   AND UMLoadType	= A.UMLoadType
				)
	--전체합계금액 Sum
	UPDATE mnpt_TPJTUnionPaySum
	   SET SumAmt	= ROUND(GangSumAmt + UDDSumAmt + UtilityAmt, 0)
	  FROM mnpt_TPJTUnionPaySum AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM #tmpItem
					 WHERE PJTSeq		= A.PJTSeq
					   AND ShipSeq		= A.ShipSeq
					   AND ShipSerl		= A.ShipSerl
					   AND UMLoadType	= A.UMLoadType
				)
