IF OBJECT_ID('hencom_SACPJTPayListQuery') IS NOT NULL 
    DROP PROC hencom_SACPJTPayListQuery
GO 

-- v2017.05.10 
/************************************************************
 설  명 - 데이터-현장별임금대장_hencom : 조회
 작성일 - 20160119
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SACPJTPayListQuery                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
    
	DECLARE @docHandle      INT,
		    @SubcCustSeq    INT ,
            @PayYM          NCHAR(6) ,
            @PayYMFr        NCHAR(6) ,
            @PJTCustName    NVARCHAR(200) ,
            @EmpCustSeq     INT ,
            @PJTName        NVARCHAR(200) ,
            @PayYMTo        NCHAR(6) ,
			@Remark         nvarchar(1000), 
            @DeptSeq        INT 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @SubcCustSeq    = ISNULL(SubcCustSeq  ,0),
            @PayYM          = ISNULL(PayYM        ,''),
            @PayYMFr        = ISNULL(PayYMFr      ,''),
            @PJTCustName    = ISNULL(PJTCustName  ,''),
            @EmpCustSeq     = ISNULL(EmpCustSeq   ,0),
            @PJTName        = ISNULL(PJTName      ,''),
            @PayYMTo        = ISNULL(PayYMTo      ,''),
			@Remark         = ISNULL(Remark       ,''), 
            @DeptSeq        = ISNULL(DeptSeq      ,0)
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            SubcCustSeq     INT ,
            PayYM           NCHAR(6) ,
            PayYMFr         NCHAR(6) ,
            PJTCustName     NVARCHAR(200) ,
            EmpCustSeq      INT ,
            PJTName         NVARCHAR(200) ,
            PayYMTo         NCHAR(6),
			Remark          nvarchar(1000), 
            DeptSeq         INT
           )
	
    SELECT  A.PJTPayRegSeq,
            A.PayYM,
            A.PJTSeq,
            p.PJTName,
            A.DeptSeq,
            ( select deptname from _tdadept where companyseq = @CompanySeq and deptseq = a.DeptSeq ) as DeptName,
            A.EmpCustSeq,
            C.CustName as EmpCustName,
            A.SlipSeq,
            S.SlipID,
            A.WorkingDay,
            A.Price,
            A.TotalPay,
            A.IncomTax,
            A.ResidenceTax,
            A.IncomTax + A.ResidenceTax as TaxSum,
            A.HealthIns,
            A.NationalPension,
            A.HealthIns + A.NationalPension as InsSum,
            A.IncomTax + A.ResidenceTax + A.HealthIns + A.NationalPension as DepSum,
            A.UnemployIns,
            A.IncomTax + A.ResidenceTax + A.HealthIns + A.NationalPension + A.UnemployIns as DeductionAmt,
            A.TotalPay - (A.IncomTax + A.ResidenceTax + A.HealthIns + A.NationalPension + A.UnemployIns) as RealAmt,
            A.ContributionAmt,
            A.UMBankHQ,
            A.BankAccNo,
            A.Owner,
            A.SubcCustSeq,
            ( select CustName from _tdacust where CompanySeq = @CompanySeq and custseq = a.SubcCustSeq ) as SubcCustName,
            A.SubsAccSeq,
            ( select AccName from _TDAAccount where CompanySeq = @CompanySeq and AccSeq = A.SubsAccSeq ) as SubsAccName,
            A.CalcAccSeq,
            ( select AccName from _TDAAccount where CompanySeq = @CompanySeq and AccSeq = A.CalcAccSeq ) as CalcAccName,
            A.PrepaidExpenseAccSeq,
            ( select AccName from _TDAAccount where CompanySeq = @CompanySeq and AccSeq = A.PrepaidExpenseAccSeq ) as PrepaidExpenseAccName,
            A.PayAccSeq,
            ( select AccName from _TDAAccount where CompanySeq = @CompanySeq and AccSeq = A.PayAccSeq ) as PayAccName,
            A.Calc2AccSeq,
            ( select AccName from _TDAAccount where CompanySeq = @CompanySeq and AccSeq = A.Calc2AccSeq ) as Calc2AccName,
            A.Remark,
            ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
            C.TelNo, 
            ISNULL(F.KorAddr1, '') + ' ' + ISNULL(F.KorAddr2, '') + ' ' + ISNULL(F.KorAddr3, '') AS Addr, 
            A.CashDate
      FROM hencom_TACPJTPayList     AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPJTProject  AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDACust      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.EmpCustSeq ) 
      LEFT OUTER JOIN _TDACustAdd   AS F WITH(NOLOCK) ON ( F.Companyseq = @CompanySeq AND F.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TACSlipRow   AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.slipseq = A.SlipSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PayYM between @PayYMFr and @PayYMTo            
       AND (@SubcCustSeq = 0 or A.SubcCustSeq = @SubcCustSeq)           
       AND (@EmpCustSeq = 0  or A.EmpCustSeq = @EmpCustSeq)    
       and A.remark   like @Remark + '%'
       and P.PJTName like @PJTName + '%'
       and B.CustName like @PJTCustName + '%' 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
		
    RETURN
go
begin tran 
exec hencom_SACPJTPayListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PayYMFr>201601</PayYMFr>
    <PayYMTo>201705</PayYMTo>
    <SubcCustSeq />
    <EmpCustSeq />
    <PJTName />
    <DeptSeq />
    <PJTCustName />
    <Remark />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034419,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028494
rollback 