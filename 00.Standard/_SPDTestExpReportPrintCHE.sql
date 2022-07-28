
IF OBJECT_ID('_SPDTestExpReportPrintCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportPrintCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서등록(영업) : 출력  
 작성일 - 20110921  
 작성자 - 박헌기  
************************************************************/  
  
CREATE PROC dbo._SPDTestExpReportPrintCHE
    @xmlDocument    NVARCHAR(MAX) ,  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
  
AS  
  
    DECLARE @docHandle      INT,  
            @TestReportSeq  INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @TestReportSeq = TestReportSeq  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (TestReportSeq  INT )  
    --마스터 , 수출/내수정보  
    
    SELECT  ISNULL(A.TestReportSeq,0)  AS TestReportSeq,  
            LEFT(ISNULL(A.AnalysisDate,''),4)+'-'+SUBSTRING(ISNULL(A.AnalysisDate,''),5,2)+'-'+SUBSTRING(ISNULL(A.AnalysisDate,''),7,2)  AS AnalysisDate ,  
            ISNULL(A.UMSpec      , 0)  AS UMSpec       ,  
            ISNULL(B.MinorName   ,'')  AS UMSpecName   ,   
            ISNULL(A.UMSpecValue ,'')  AS UMSpecValue  
      FROM  _TPDTestExpReport AS A WITH (NOLOCK)  
            JOIN _TDAUMinor        AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq   
                                                     AND A.UMSpec     = B.MinorSeq  
     WHERE  A.CompanySeq     = @CompanySeq  
       AND  A.TestReportSeq  = @TestReportSeq  
       AND  LEN(RTRIM(LTRIM(ISNULL(A.UMSpecValue,0))))>0  
     ORDER  BY B.MinorSort  
  
    --공정분석 항목정보  
    SELECT  ISNULL(A.TestReportSeq  , 0) AS TestReportSeq  ,  
            ISNULL(A.TestReportSerl , 0) AS TestReportSerl ,  
            ISNULL(A.FactUnit       , 0) AS FactUnit       ,  
            ISNULL(B.FactUnitName   ,'') AS FactUnitName   ,    
            ISNULL(A.SectionSeq     , 0) AS SectionSeq     ,  
            ISNULL(C.SectionCode    ,'') AS SectionCode    ,    
            ISNULL(C.SectionName    ,'') AS SectionName    ,    
            ISNULL(A.SampleLocSeq   , 0) AS SampleLocSeq   ,  
            ISNULL(D.SampleLoc      ,'') AS SampleLoc      ,    
            ISNULL(A.AnalysisItemSeq, 0) AS AnalysisItemSeq,  
            ISNULL(A.ItemCodeName   ,'') AS ItemCodeName   ,    
            ISNULL(A.UnitName       ,'') AS UnitName       ,    
            ISNULL(A.Spec           ,'') AS Spec           ,  
            ISNULL(A.ResultVal      ,'') AS ResultVal      ,  
            ISNULL(A.Method         ,'') AS Method          
      FROM  _TPDTestExpReportList            AS A WITH (NOLOCK)  
            LEFT OUTER JOIN _TDAFactUnit          AS B WITH (NOLOCK) ON A.CompanySeq      = B.CompanySeq  
                                                                    AND A.FactUnit        = B.FactUnit  
            LEFT OUTER JOIN _TPDSectionCode  AS C WITH (NOLOCK) ON A.CompanySeq      = C.CompanySeq   
                                                                    AND A.SectionSeq      = C.SectionSeq  
            LEFT OUTER JOIN _TPDSampleLoc    AS D WITH (NOLOCK) ON A.CompanySeq      = D.CompanySeq  
                                                                    AND A.SampleLocSeq    = D.SampleLocSeq  
            LEFT OUTER JOIN _TPDAnalysisItem AS E WITH (NOLOCK) ON A.CompanySeq      = E.CompanySeq  
                                                                    AND A.AnalysisItemSeq = E.AnalysisItemSeq                                                           
     WHERE  A.CompanySeq        = @CompanySeq  
       AND  A.TestReportSeq     = @TestReportSeq  
  
RETURN  