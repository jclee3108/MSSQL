
IF OBJECT_ID('KPXCM_SSEAccidentPrintCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentPrintCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천 

/************************************************************
  설  명 - 데이터-사고관리_capro : 사고발생보고서출력
  작성일 - 20110728
  작성자 - 신용식
 ************************************************************/
CREATE PROC dbo.KPXCM_SSEAccidentPrintCHE                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT  = 0,            
    @ServiceSeq     INT  = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT  = 1,            
    @LanguageSeq    INT  = 1,            
    @UserSeq        INT  = 0,            
    @PgmSeq         INT  = 0         
     
 AS        
  
    DECLARE @docHandle      INT,
            @AccidentSeq    INT ,
            @AccidentSerl   NCHAR(1)  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    SELECT @AccidentSeq       = ISNULL(AccidentSeq,0), 
           @AccidentSerl      = ISNULL(AccidentSerl,0) 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (
            AccidentSeq     INT ,
            AccidentSerl    NCHAR(1) 
         )
    
    SELECT A.AccidentClass     , 
           B.DeptName          , 
           A.DeptSeq           , 
           C.EmpName           , 
           A.EmpSeq            , 
           A.AccidentType      , 
           A.AccidentGrade     , 
           A.AccidentArea      , 
           A.AreaClass         , 
           A.AccidentName      , 
           A.AccidentDate      , 
           A.ReportDate        , 
           A.ReporterSeq       , 
           A.InvestFrDate      , 
           A.InvestToDate      , 
           A.Weather           , 
           REPLACE(A.AccidentOutline,CHAR(10),'') AS AccidentOutline, 
           A.AccidentCause     , 
           REPLACE(A.MngRemark,CHAR(10),'')       AS MngRemark      , 
           A.AccidentInjury    , 
           A.PreventMeasure    , 
           A.FirstReporter, 
           LEFT(A.AccidentTime,2)+':'+SUBSTRING(A.AccidentTime,3,2)AS AccidentTime , 
           A.AccidentNo        , 
           D.MinorName      AS AccidentClassName , 
           E.MinorName      AS AccidentTypeName  ,
           F.MinorName      AS AccidentGradeName ,
           G.MinorName      AS AreaClassName     , 
           ISNULL(CASE WHEN A.InvestFrDate <> '' OR A.InvestToDate <> '' THEN LEFT(A.InvestFrDate, 4) + '-' + SUBSTRING(A.InvestFrDate, 5, 2) + '-' + SUBSTRING(A.InvestFrDate, 7, 2) + ' ~ ' + LEFT(A.InvestToDate, 4) + '-' + SUBSTRING(A.InvestToDate, 5, 2) + '-' + SUBSTRING(A.InvestToDate, 7, 2) END,'') AS InvestDate , 
           H.MinorName      AS WeatherName       ,
           J.EmpName        AS ReporterName      ,
           I.MinorName      AS DOWName           ,  
           A.DOW                ,  
           A.WV                 ,
           A.AccidentEqName     ,
           A.LeakMatName        ,
           D.MinorName + ' 발생 보고서' AS FormName,
           SUBSTRING(A.ReportDate, 1, 4) + '.' + SUBSTRING(A.ReportDate, 5, 2) + '.' + SUBSTRING(A.ReportDate, 7, 2) AS ReportDateGW,
           SUBSTRING(A.AccidentDate, 1, 4) + '.' + SUBSTRING(A.AccidentDate, 5, 2) + '.' + SUBSTRING(A.AccidentDate, 7, 2) + ' ' + DATENAME(dw, A.AccidentDate) + ' ' + LEFT(A.AccidentTime,2)+':'+SUBSTRING(A.AccidentTime,3,2) AS AccidentDateGW,
           CASE WHEN A.AccidentClass <> 20036006 THEN '문서번호' END AS Title1GW,
           CASE WHEN A.AccidentClass <> 20036006 THEN '보관기간' END AS Title2GW,
           CASE WHEN A.AccidentClass <> 20036006 THEN '영 구'    END AS Value2GW,
           FirstReporter
      FROM  _TSEAccidentCHE AS A WITH (NOLOCK) 
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
     WHERE A.CompanySeq = @CompanySeq
       AND A.AccidentSeq = @AccidentSeq       
       AND A.AccidentSerl = @AccidentSerl      
    
    RETURN