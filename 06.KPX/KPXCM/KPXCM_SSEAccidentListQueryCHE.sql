
IF OBJECT_ID('KPXCM_SSEAccidentListQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentListQueryCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 복사 by이재천 
/************************************************************
   설  명 - 데이터-사고관리 : 조회
   작성일 - 20110324
   작성자 - 천경민
  ************************************************************/
  CREATE PROC dbo.KPXCM_SSEAccidentListQueryCHE
      @xmlDocument    NVARCHAR(MAX),
      @xmlFlags       INT             = 0,
      @ServiceSeq     INT             = 0,
      @WorkingTag     NVARCHAR(10)    = '',
      @CompanySeq     INT             = 1,
      @LanguageSeq    INT             = 1,
      @UserSeq        INT             = 0,
      @PgmSeq         INT             = 0
  AS
      
      DECLARE @docHandle      INT,
              @AccidentSerl   NCHAR(1),
              @DeptSeq        INT,
              @EmpSeq         INT,
              @AccidentNo     NVARCHAR(20),
              @AccidentClass  INT,
              @AccidentType   INT,
              @AccidentDate   NCHAR(8),
              @AccidentDateTo NCHAR(8),
              @ReportDate     NCHAR(8),
              @ReportDateTo   NCHAR(8),
              @ReporterSeq    INT, 
              @ReportProgType INT, 
              @AccidentGrade  INT, 
              @FactUnit       INT 
  
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
  
     SELECT @AccidentSerl   = ISNULL(AccidentSerl, ''),
             @DeptSeq        = ISNULL(DeptSeq, 0),
             @EmpSeq         = ISNULL(EmpSeq, 0),  
             @AccidentNo     = ISNULL(AccidentNo, ''),
             @AccidentClass  = ISNULL(AccidentClass, 0),
             @AccidentType   = ISNULL(AccidentType, 0),
             @AccidentDate   = ISNULL(AccidentDate, ''),
             @AccidentDateTo = ISNULL(AccidentDateTo, ''),
             @ReportDate     = ISNULL(ReportDate, ''),
             @ReportDateTo   = ISNULL(ReportDateTo, ''),
             @ReporterSeq    = ISNULL(ReporterSeq, 0), 
             @ReportProgType = ISNULL(ReportProgType,0), 
             @AccidentGrade  = ISNULL(AccidentGrade,0), 
             @FactUnit       = ISNULL(FactUnit,0) 
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
        WITH (AccidentSerl   NCHAR(1),
              DeptSeq        INT,
              EmpSeq         INT,
              AccidentNo     NVARCHAR(20),
              AccidentClass  INT,
              AccidentType   INT,
              AccidentDate   NCHAR(8),
              AccidentDateTo NCHAR(8),
              ReportDate     NCHAR(8),
              ReportDateTo   NCHAR(8),
              ReporterSeq    INT, 
              ReportProgType INT, 
              AccidentGrade  INT, 
              FactUnit       INT )
  
  
    SELECT @AccidentDateTo = '99991231' WHERE @AccidentDateTo = ''
    SELECT @ReportDateTo   = '99991231' WHERE @ReportDateTo   = ''
  
  
     SELECT A.AccidentSeq        ,
             A.AccidentSerl       ,
             A.AccidentNo         ,
             D.MinorName      AS AccidentClassName ,
             A.AccidentClass      ,
             B.DeptName           ,
             A.DeptSeq            ,
             C.EmpName            ,
             A.EmpSeq             ,
             E.MinorName      AS AccidentTypeName  ,
             A.AccidentType       ,
             F.MinorName      AS AccidentGradeName ,
             A.AccidentGrade      ,
             A.AccidentArea       ,
             G.MinorName      AS AreaClassName     ,
             A.AreaClass          ,
             A.AccidentName       ,
             A.AccidentDate       ,
             A.AccidentTime       ,
             A.ReportDate         ,
             J.EmpName        AS ReporterName      ,
             A.ReporterSeq        ,
             CASE WHEN A.InvestFrDate <> '' OR A.InvestToDate <> '' THEN LEFT(A.InvestFrDate, 4) + '-' + SUBSTRING(A.InvestFrDate, 5, 2) + '-' + SUBSTRING(A.InvestFrDate, 7, 2) + ' ~ ' + LEFT(A.InvestToDate, 4) + '-' + SUBSTRING(A.InvestToDate, 5, 2) + '-' + SUBSTRING(A.InvestToDate, 7, 2) END AS InvestDate ,
             A.InvestFrDate       ,
             A.InvestToDate       ,
             H.MinorName      AS WeatherName       ,
             A.Weather            ,
             I.MinorName      AS DOWName           ,
             A.DOW                ,
             A.WV                 ,
             A.LeakMatName        ,
             A.LeakMatQty         ,
             A.AccidentEqName     ,
             A.AccidentOutline    ,
             A.AccidentCause      ,

             A.MngRemark          ,
             A.AccidentInjury     ,
             A.PreventMeasure     ,
             A.FirstReporter      ,
             A.FileSeq            ,
             ISNULL((SELECT '1' FROM KPXCM_TSEAccidentCHE 
                               WHERE CompanySeq   = @CompanySeq 
                                 AND AccidentSeq  = A.AccidentSeq 
                                 AND AccidentSerl = '2'), '0') AS IsSurvey, -- 사고조사등록 여부
			 K.EmpName	AS WriteEmpName,
			 L.DeptName AS WriteDeptName,
			 CASE WHEN ISNULL(A1.CfmCode,0) = 0 AND ISNULL(GW.IsProg,0) = 0 THEN 1010655001   
                WHEN ISNULL(A1.CfmCode,0) = 5	AND ISNULL(GW.IsProg,0) = 1 THEN 1010655002   
                WHEN ISNULL(A1.CfmCode,0) = 1	THEN 1010655003   
                ELSE 0 END AS ReportProgType,   
           (SELECT TOP 1 MinorName   
              FROM _TDAUMinor   
             WHERE CompanySeq = @CompanySeq   
               AND MinorSeq = (CASE WHEN ISNULL(A1.CfmCode,0) = 0 AND ISNULL(GW.IsProg,0) = 0 THEN 1010655001   
                                    WHEN ISNULL(A1.CfmCode,0) = 5 AND ISNULL(GW.IsProg,0) = 1 THEN 1010655002   
                                    WHEN ISNULL(A1.CfmCode,0) = 1 THEN 1010655003   
                                    ELSE 0 END  
                              )   
           ) AS ReportProgTypeName , 
           A.FactUnit, 
           M.FactUnitName 

        FROM KPXCM_TSEAccidentCHE AS A WITH(NOLOCK)
             LEFT OUTER JOIN _TDADept   AS B WITH(NOLOCK) ON A.CompanySeq    = B.CompanySeq
                                                         AND A.DeptSeq       = B.DeptSeq
             LEFT OUTER JOIN _TDAEmp    AS C WITH(NOLOCK) ON A.CompanySeq    = C.CompanySeq
                                                         AND A.EmpSeq        = C.EmpSeq
             LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq
                                                         AND A.AccidentClass = D.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS E WITH(NOLOCK) ON A.CompanySeq    = E.CompanySeq
                                                         AND A.AccidentType  = E.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS F WITH(NOLOCK) ON A.CompanySeq    = F.CompanySeq
                                                         AND A.AccidentGrade = F.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS G WITH(NOLOCK) ON A.CompanySeq    = G.CompanySeq
                                                         AND A.AreaClass     = G.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK) ON A.CompanySeq    = H.CompanySeq
                                                         AND A.Weather       = H.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS I WITH(NOLOCK) ON A.CompanySeq    = I.CompanySeq
                                                         AND A.DOW           = I.MinorSeq
             LEFT OUTER JOIN _TDAEmp    AS J WITH(NOLOCK) ON A.CompanySeq    = J.CompanySeq
                                                         AND A.ReporterSeq   = J.EmpSeq
			 LEFT OUTER JOIN _TDAEmp	AS K WITH(NOLOCK) ON K.CompanySeq	 = @CompanySeq
														 AND K.EmpSeq		 = A.WriteEmpSeq
			 LEFT OUTER JOIN _TDADept	AS L WITH(NOLOCK) ON L.CompanySeq	 = @CompanySeq
														 AND L.DeptSeq		 = A.WriteDeptSeq
			 LEFT OUTER JOIN _TComGroupWare	AS GW WITH(NOLOCK) ON GW.CompanySeq = @CompanySeq
															  AND LEFT(TblKey,CHARINDEX(',',GW.TblKey) - 1) = AccidentSeq	
															  AND REPLACE(SUBSTRING(TblKey,CHARINDEX(',',GW.TblKey) + 1,100),',','') = AccidentSerl 
															  AND GW.WorkKind	= CASE WHEN @PgmSeq = 1025156 THEN 'AccidentSurvey_CM' ELSE 'AccidentReport_CM' END 
			 LEFT OUTER JOIN KPXCM_TSEAccidentCHE_Confirm AS A1 ON A1.CompanySeq =	@CompanySeq
															   AND A1.CfmSeq	 =	AccidentSeq
															   AND A1.CfmSerl	 =	AccidentSerl 
             LEFT OUTER JOIN _TDAFactUnit   AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.FactUnit = A.FactUnit ) 
       WHERE A.CompanySeq   = @CompanySeq
         AND (@AccidentSerl = '' or   A.AccidentSerl = @AccidentSerl )-- ('1' : 사고발생보고등록, '2' : 사고조사등록)
         AND (@DeptSeq       = 0  OR A.DeptSeq       = @DeptSeq)
         AND (@EmpSeq        = 0  OR A.EmpSeq        = @EmpSeq)
         AND (@AccidentClass = 0  OR A.AccidentClass = @AccidentClass)
         AND (@AccidentType  = 0  OR A.AccidentType  = @AccidentType)
         AND (@AccidentNo    = '' OR A.AccidentNo LIKE @AccidentNo + '%')
         AND (@ReporterSeq   = 0  OR A.ReporterSeq   = @ReporterSeq)
         AND (A.AccidentDate BETWEEN @AccidentDate AND @AccidentDateTo)
         AND (A.ReportDate   BETWEEN @ReportDate   AND @ReportDateTo)
         AND (@AccidentGrade = 0 OR A.AccidentGrade = @AccidentGrade)
         AND (@ReportProgType = 0 OR @ReportProgType = CASE WHEN ISNULL(A1.CfmCode,0) = 0 AND ISNULL(GW.IsProg,0) = 0 THEN 1010655001   
                                                            WHEN ISNULL(A1.CfmCode,0) = 5	AND ISNULL(GW.IsProg,0) = 1 THEN 1010655002   
                                                            WHEN ISNULL(A1.CfmCode,0) = 1	THEN 1010655003   
                                                            ELSE 0 END 
             )
        AND (@FactUnit = 0 OR A.FactUnit = @FactUnit) 
       ORDER BY A.AccidentSeq, A.AccidentSerl
  
 RETURN

 go

exec KPXCM_SSEAccidentQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReportProgType />
    <AccidentGrade />
    <AccidentNo />
    <AccidentDate />
    <AccidentDateTo />
    <AccidentClass />
    <AccidentType />
    <DeptSeq />
    <EmpSeq />
    <ReportDate />
    <ReportDateTo />
    <ReporterSeq />
    <AccidentSerl>2</AccidentSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030103,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025156