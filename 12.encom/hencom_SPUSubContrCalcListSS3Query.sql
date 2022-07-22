IF OBJECT_ID('hencom_SPUSubContrCalcListSS3Query') IS NOT NULL 
    DROP PROC hencom_SPUSubContrCalcListSS3Query
GO 

-- v2017.04.26 

/************************************************************
 설  명 - 데이터-도급운반비정산_hencom : 조회
 작성일 - 20151008
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SPUSubContrCalcListSS3Query                
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
            @SubContrCalcRegSeq            INT ,
			@WorkDateFr    NCHAR(8),
            @WorkDateTo    NCHAR(8),
            @DeptSeq       INT ,
            @CustSeq       INT,
            @SubContrCarSeq    INT,
			@UMSCCalcType  int, 
            @UMCarClass        INT, 
            @IsSlip            NCHAR(1)

	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @SubContrCalcRegSeq           = isnull(SubContrCalcRegSeq,0),
	        @WorkDateFr  = isnull(WorkDateFr,''),
	        @WorkDateTo  = isnull(WorkDateTo,''),
			@DeptSeq = isnull(DeptSeq,0),       
			@CustSeq = isnull(CustSeq,0),       
			@SubContrCarSeq = isnull(SubContrCarSeq,0),      
			@UMSCCalcType = isnull(UMSCCalcType,0)      
           ,@UMCarClass          =   ISNULL(UMCarClass,0)
           ,@IsSlip              =   ISNULL(IsSlip,'0')
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)

	  WITH (SubContrCalcRegSeq             INT,
	        WorkDateFr             nvarchar(8),
	        WorkDateTo             nvarchar(8),
			DeptSeq             INT,
			CustSeq             INT,
			SubContrCarSeq             INT,
			UMSCCalcType int
           ,UMCarClass     INT
           ,IsSlip         NCHAR(1)
	        )

	select *
	  into #car
	  from hencom_VPUContrCarInfo
	  where CompanySeq = @CompanySeq
	    and DeptSeq = @DeptSeq





	 select m.CompanySeq,        
			m.WorkDate,       
			m.DeptSeq,  
			
			(select CustName from _TDACust where CompanySeq = @CompanySeq and custseq = a.DeliCustSeq) as DeliCustName,
			(select BizNo from _TDACust where CompanySeq = @CompanySeq and custseq = a.DeliCustSeq) as BizNo,
			a.UMSCCalcType,
			(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMSCCalcType) as UMSCCalcTypeNm     , 
			a.UMCarClass,     
			(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMCarClass) as UMCarClassName , 
			a.UMDistanceDegree,     
			(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMDistanceDegree) as UMDistanceDegreeNm ,
			a.Price,
			a.Amt,
			m.CustSeq,
			m.CustName,            
			m.UMOutType,       
			m.Rotation,   
			m.PJTSeq, 
			m.MesKey,            
			m.SubContrCarSeq,   
			m.ProdQty,    
			m.OutQty,       
			m.InvCreDateTime,
			m.GoodItemSeq,
            car.carno as SubContrCarSeqNm   , 
			car.MinPresLoadCapa,
			car.IsPreserve,
			car.IsGpsApply,
			m.RealDistance as GPSRealDistance,
			( select  ShuttleDistance   from hencom_TPJTProjectAdd  where CompanySeq = @CompanySeq and PJTSeq = m.PJTSeq ) as ShuttleDistance,
			m.MesNo,
			(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = m.UMOutType) as UMOutTypeNm        , 
			(select PJTName from _TPJTProject where CompanySeq = @CompanySeq and pjtseq = m.pjtseq) as PJTName, 
			(select ItemName from _tdaitem where CompanySeq = @CompanySeq and itemseq = m.GoodItemSeq) as GoodItemName ,
            (select deptname from _tdadept where CompanySeq = @CompanySeq and deptseq = m.DeptSeq) as DetpNm              
		from hencom_TPUSubContrCalc as a
		join hencom_TPUSubContrCalcLentDet as d on d.CompanySeq = a.CompanySeq
											   and d.SubContrCalcRegSeq = a.SubContrCalcRegSeq
	left outer	join hencom_TIFProdWorkReportclose as m on m.CompanySeq =  a.CompanySeq 
		                                       and m.MesKey = d.MesKey
left outer join  #car as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate
		where  a.companyseq = @CompanySeq
		  AND  A.WorkDate between @WorkDateFr and @WorkDateTo
	      AND  (@DeptSeq = 0 or A.DeptSeq = @DeptSeq  )    
	      AND  (@CustSeq = 0 or A.DeliCustSeq = @CustSeq  )    
	      AND  (@SubContrCarSeq = 0 or A.SubContrCarSeq = @SubContrCarSeq  )    
		  and  (@SubContrCalcRegSeq = 0 or a.SubContrCalcRegSeq = @SubContrCalcRegSeq  )
		  and  (@UMSCCalcType = 0 or a.UMSCCalcType = @UMSCCalcType  )
          AND  (@UMCarClass = 0 or A.UMCarClass = @UMCarClass)
          and  (@IsSlip = '0' OR (@IsSlip = '1' AND CASE WHEN ISNULL(A.SlipSeq,0) = 0 THEN '0' ELSE '1' END = '1'))
order by DeliCustName,
BizNo,
UMCarClass,
UMCarClassName,
SubContrCarSeq,
SubContrCarSeqNm,
UMSCCalcTypeNm,
workdate,
Price,
Amt
	
	
		
RETURN
