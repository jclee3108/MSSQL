IF OBJECT_ID('hencom_SPUSubContrCalcListSS1Query') IS NOT NULL 
    DROP PROC hencom_SPUSubContrCalcListSS1Query
GO 

-- v2017.04.26 

/************************************************************
 설  명 - 데이터-도급운반비정산현황SS1조회_hencom
 작성일 - 2015.11.11
 작성자 - kth
 수정자 -
************************************************************/
CREATE PROCEDURE hencom_SPUSubContrCalcListSS1Query
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS       
    DECLARE @docHandle          INT
            ,@WorkDateFr        NCHAR(8)
            ,@WorkDateTo        NCHAR(8)
            ,@DeptSeq           INT 
            ,@CustSeq           INT
            ,@SubContrCarSeq    INT
            ,@UMCarClass        INT 
            ,@IsSlip            NCHAR(1)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT   @WorkDateFr          =   ISNULL(WorkDateFr,''   )
            ,@WorkDateTo          =   ISNULL(WorkDateTo,''   )
            ,@DeptSeq             =   ISNULL(DeptSeq     ,0) 
            ,@CustSeq             =   ISNULL(CustSeq     ,0) 
            ,@SubContrCarSeq      =   ISNULL(SubContrCarSeq     ,0) 
            ,@UMCarClass          =   ISNULL(UMCarClass,0)
            ,@IsSlip              =   ISNULL(IsSlip,'0')
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (WorkDateFr     NCHAR(8)
            ,WorkDateTo     NCHAR(8)
            ,DeptSeq        INT
            ,CustSeq        INT
            ,SubContrCarSeq INT
            ,UMCarClass     INT
            ,IsSlip         NCHAR(1))

	select *
	  into #car
	  from hencom_VPUContrCarInfo
	  where CompanySeq = @CompanySeq
	    and DeptSeq = @DeptSeq

    SELECT   a.DeliCustSeq  as CustSeq
            ,A.UMCarClass
            ,A.SubContrCarSeq
            ,max(C.CarNo) as SubContrCarSeqNm
			,a.UMDistanceDegree
			,a.UMSCCalcType
			,max(a.SlipSeq) as SlipSeq
            ,SUM(A.Rotation) AS Rotation
			,sum(a.prodqty) as ProdQty
			,sum(a.OutQty) as OutQty
			,sum(a.RealDistance) as RealDistance
            ,SUM(  a.outqty - case a.UMOutType when 8020103 then A.outqty else 0 end    ) AS ApplyQty
            ,SUM(A.Amt) AS Amt
            ,SUM(A.OTAmt) AS OTAmt
            ,SUM(A.AddPayAmt) AS AddPayAmt
            ,SUM(A.DeductionAmt) AS DeductionAmt
            ,SUM(A.Amt + A.OTAmt + A.AddPayAmt - A.DeductionAmt) AS TotalAmt
            ,CASE WHEN max(ISNULL(A.SlipSeq,0)) = 0 THEN '0' ELSE '1' END AS IsSlip
	  into #tempresult
      FROM hencom_TPUSubContrCalc AS A WITH (NOLOCK) 
      LEFT OUTER JOIN  #car  as c on c.CompanySeq = a.CompanySeq
                                                 and c.SubContrCarSeq = a.SubContrCarSeq
                                                 and a.workdate between c.StartDate and c.EndDate
     WHERE A.CompanySeq   = @CompanySeq
       AND A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@CustSeq = 0 OR A.DeliCustSeq = @CustSeq) 
       AND (@SubContrCarSeq = 0 OR A.SubContrCarSeq = @SubContrCarSeq) 
       AND (@UMCarClass = 0 OR A.UMCarClass = @UMCarClass) 
     
     GROUP BY a.DeliCustSeq
            ,A.UMCarClass
            ,A.SubContrCarSeq
			,a.UMDistanceDegree
			,a.UMSCCalcType


	 
     SELECT   a.CustSeq  as CustSeq
            ,B.CustName
			,b.BizNo
            ,A.UMCarClass
            ,D.MinorName AS UMCarClassNm
            ,A.SubContrCarSeq
            ,SubContrCarSeqNm as SubContrCarSeqNm
			,a.UMDistanceDegree
			,(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMDistanceDegree) as UMDistanceDegreeNm
			,a.UMSCCalcType
			,(select MinorName from _tdauminor where CompanySeq = @CompanySeq and minorseq = A.UMSCCalcType) as UMSCCalcTypeNm 
			,H.SlipID     AS SlipID
            ,Rotation AS Rotation
			,ProdQty as ProdQty
			,OutQty as OutQty
			,RealDistance as RealDistance
            ,ApplyQty AS ApplyQty
            ,A.Amt AS Amt
            ,A.OTAmt AS OTAmt
            ,A.AddPayAmt AS AddPayAmt
            ,A.DeductionAmt AS DeductionAmt
            ,A.Amt + A.OTAmt + A.AddPayAmt - A.DeductionAmt AS TotalAmt
      FROM #tempresult AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
                                    AND B.CustSeq = a.CustSeq
      LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                  AND D.MinorSeq = A.UMCarClass
	  LEFT OUTER JOIN _TACSlipRow AS H WITH(NOLOCK) ON @CompanySeq = H.CompanySeq 
                                                   AND A.SlipSeq = H.SlipSeq 
     WHERE (@IsSlip = '0' OR (@IsSlip = '1' AND A.IsSlip = '1'))
      order by UMCarClass,B.CustName,BizNo,UMCarClassNm,SubContrCarSeq,SubContrCarSeqNm,UMDistanceDegreeNm,UMSCCalcTypeNm				
	 
	 								           
RETURN  
go
