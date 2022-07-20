IF OBJECT_ID('mnpt_SSLEEJejuInvoiceExcelUnionSave') IS NOT NULL 
    DROP PROC mnpt_SSLEEJejuInvoiceExcelUnionSave
GO 

-- 2018.01.16
  /************************************************************
 설  명		- 제주연안 엑셀Upload 노조노임공과금 저장
 작성일		- 2017년 11월 23일  
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
 CREATE PROC mnpt_SSLEEJejuInvoiceExcelUnionSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
    
    DECLARE @GangAccSeq         INT,            -- 노조
            @UDDAccSeq          INT,            -- 노조일용
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

    SELECT @GangAccSeq	        = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942001 AND Serl = 1000005)
    SELECT @UDDAccSeq		    = (SELECT ValueSeq FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015942011 AND Serl = 1000005)
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

	-- Insert  
    IF EXISTS (SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0   )
    BEGIN
		INSERT INTO mnpt_TPJTUnionPaySum (
			CompanySeq,			PJTSeq,				ShipSeq,			ShipSerl,			IsUpdate,
			UMLoadType,			ItemName,			BizUnit,			AccUnit,			OutDate,
			PJTTypeSeq,			Qty,				MTQty,				GangAmt,			GangExtraAmt,
			GangSumAmt,			UtilityAmt,			UDDSumAmt,			SumAmt,				RetireAmt,
			ModernAmt,			TraingAmt,			WelfareAmt,			MedicalAmt,			NationalAmt,
			SafetyAmt,			SocietyAmt,			Dummy1,				Dummy2,				SlipSeq,
			FirstUserSeq,		FirstDateTime,		LastUserSeq,		LastDateTime,		PgmSeq,
			MealAmt, 

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
			@CompanySeq,        A.PJTSeq,				A.ShipSeq,			    A.ShipSerl,			    '0',
			A.UMLoadType,		A.ItemName2,			A.BizUnit,			    A.AccUnit,			    A.OutDate,
			A.PJTTypeSeq,		A.Qty,				    A.MTQty,				A.GangSumAmt,			0,
			A.GangSumAmt,		A.UtilityAmt,			A.UDDSumAmt,			A.SumAmt,				A.RetireAmt,
			A.ModernAmt,		A.TraingAmt,			A.WelfareAmt,			A.MedicalAmt,			A.NationalAmt,
			A.SafetyAmt,		A.SocietyAmt,			0,						0,				        0,
			@UserSeq,			GETDATE(),			    @UserSeq,			    GETDATE(),			    @PgmSeq,
			A.MealAmt, 

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

		  FROM #BIZ_OUT_DataBlock2  AS A 
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
         WHERE A.Status = 0
           AND A.WorkingTag = 'A'
		IF @@ERROR <> 0 RETURN  
	END
