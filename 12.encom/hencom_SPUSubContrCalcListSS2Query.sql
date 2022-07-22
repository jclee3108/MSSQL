IF OBJECT_ID('hencom_SPUSubContrCalcListSS2Query') IS NOT NULL 
    DROP PROC hencom_SPUSubContrCalcListSS2Query
GO 

-- v2017.04.26 

/************************************************************
 설  명 - 데이터-도급운반비정산현황SS2조회_hencom
 작성일 - 2015.11.11
 작성자 - kth
 수정자 -
************************************************************/
CREATE PROC hencom_SPUSubContrCalcListSS2Query              
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle          INT
            ,@DeptSeq           INT 
            ,@CustSeq           INT
            ,@SubContrCarSeq    INT
            ,@UMCarClass        INT
			,@WorkDateFr        nchar(8)
			,@WorkDateTo        nchar(8)
			,@UMDistanceDegree  int
			,@UMSCCalcType      int
            ,@IsSlip            NCHAR(1)
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    SELECT   @DeptSeq             =   ISNULL(DeptSeq     ,0) 
            ,@CustSeq             =   ISNULL(CustSeq     ,0) 
            ,@SubContrCarSeq      =   ISNULL(SubContrCarSeq     ,0) 
            ,@UMCarClass          =   ISNULL(UMCarClass     ,0) 
			,@WorkDateFr          =   isnull(WorkDateFr, '')
			,@WorkDateTo          =   isnull(WorkDateTo , '')
			,@UMDistanceDegree      =   isnull(UMDistanceDegree , 0)
			,@UMSCCalcType          =   isnull(UMSCCalcType , 0)
		    ,@IsSlip              =   ISNULL(IsSlip,'0')

      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH  (DeptSeq        INT
            ,CustSeq        INT
            ,SubContrCarSeq INT
            ,UMCarClass     INT
			,WorkDateFr     nchar(8)
			,WorkDateTo     nchar(8)
			,UMDistanceDegree int
			,UMSCCalcType int
            ,IsSlip         NCHAR(1))



	select *
	  into #car
	  from hencom_VPUContrCarInfo
	  where CompanySeq = @CompanySeq
	    and DeptSeq = @DeptSeq
	
			SELECT  SubContrCalcRegSeq , UMDistanceDegree   , UMSCCalcType       , a.UMCarClass         , a.SubContrCarSeq     , 
					a.MinPresLoadCapa    , a.IsPreserve         , OutQty             , ApplyQty           , Rotation           , 
					RealDistance       , UMOutType          , Price              , Amt                , UMOTType           , 
					OTAmt              , UMAddPayType       , AddPayAmt          , UMDeductionType    , DeductionAmt       , 
					CostSeq            , A.SlipSeq            , a.Remark             , a.LastUserSeq        , a.LastDateTime       , 
					MesKey             , WorkDate           , a.DeptSeq , IsRotation, IsQty, IsLentSumData,    a.PJTSeq, GoodItemSeq,InvCreDateTime,
					 H.SlipID     AS SlipID ,    
					 P.PJTName,
					 P.PJTNo,
					 ProdQty,
			         c.CarNo as SubContrCarSeqNm,
					 PA.ShuttleDistance,
					 c.IsGpsApply,
					 case a.isLentSumData when '1' then 0 else
					 ( select  RealDistance  from hencom_TIFProdWorkReportClose where CompanySeq = @CompanySeq and MesKey = a.MesKey) end  as GPSRealDistance,
					 Amt + OTAmt + AddPayAmt - DeductionAmt as TotalAmt,
					(select CustName from _TDACust where CompanySeq = @CompanySeq and custseq = p.CustSeq) as CustName     , 
					(select CustName from _TDACust where CompanySeq = @CompanySeq and custseq = a.DeliCustSeq) as DeliCustName,
					(select BizNo from _TDACust where CompanySeq = @CompanySeq and custseq = a.DeliCustSeq) as BizNo,
					a.DeliCustSeq, 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMSCCalcType) as UMSCCalcTypeNm     , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMCarClass) as UMCarClassName       , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMOutType) as UMOutTypeNm        , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMOTType) as UMOTTypeNm         , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMAddPayType) as UMAddPayTypeNm     , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMDeductionType) as UMDeductionTypeNm  , 
					(select deptname  from _tdadept where CompanySeq = @CompanySeq and deptseq = A.DeptSeq) as DetpNm             , 
					(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMDistanceDegree) as UMDistanceDegreeNm ,
					(select ItemName from _tdaitem where CompanySeq = @CompanySeq and itemseq = A.GoodItemSeq) as GoodItemName ,
					(select MesNo from hencom_TIFProdWorkReportclose where CompanySeq = @CompanySeq and MesKey = a.meskey ) as MesNo 
			  FROM  hencom_TPUSubContrCalc AS A WITH (NOLOCK) 
     LEFT OUTER JOIN  _TACSlipRow AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq 
                                                             AND A.SlipSeq = H.SlipSeq 
               left outer join  _TPJTProject as P on P.CompanySeq = A.CompanySeq
                                                 and P.PJTSeq = a.PJTSeq 
               left outer join  hencom_TPJTProjectAdd as PA on PA.CompanySeq = A.CompanySeq
                                                 and PA.PJTSeq = a.PJTSeq 
               left outer join  #car as c on c.CompanySeq = a.CompanySeq
                                                          and c.SubContrCarSeq = a.SubContrCarSeq
														  and a.workdate between c.StartDate and c.EndDate
	         WHERE A.CompanySeq = @CompanySeq
               AND A.DeptSeq = @DeptSeq
               AND (@SubContrCarSeq = 0 or A.SubContrCarSeq = @SubContrCarSeq)
               AND (@UMCarClass = 0 or A.UMCarClass = @UMCarClass)
               AND (@UMDistanceDegree = 0 or A.UMDistanceDegree = @UMDistanceDegree)
               AND (@UMSCCalcType = 0 or A.UMSCCalcType = @UMSCCalcType)
               AND (@CustSeq = 0 or A.DeliCustSeq = @CustSeq)
			   and a.WorkDate between @WorkDateFr and @WorkDateTo
               and (@IsSlip = '0' OR (@IsSlip = '1' AND CASE WHEN ISNULL(A.SlipSeq,0) = 0 THEN '0' ELSE '1' END = '1'))
               
	order by UMCarClass,
DeliCustName,
BizNo,
UMCarClassName,
SubContrCarSeq,
SubContrCarSeqNm,
UMDistanceDegreeNm,
UMSCCalcTypeNm					
		
		
RETURN