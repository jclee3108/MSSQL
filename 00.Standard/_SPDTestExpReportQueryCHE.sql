
IF OBJECT_ID('_SPDTestExpReportQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportQueryCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서등록(영업) : 조회  
 작성일 - 20110921  
 작성자 - 박헌기  
************************************************************/  
  
CREATE PROC dbo._SPDTestExpReportQueryCHE  
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
    IF @TestReportSeq = 0  
    BEGIN  
        SELECT 0           AS TestReportSeq,  
               CONVERT(NCHAR(8),GETDATE(),112) AS AnalysisDate ,  
               A.MinorSeq  AS UMSpec       ,  
               A.MinorName AS UMSpecName   ,  
               CASE WHEN A.MinorSeq = 1000950008 THEN 'CORPORATION'--+CHAR(10)+  
                                                      --'BEAKSANG BLDG. 197-28'+CHAR(10)+  
                                                      --'GWANHOON-DONG, JONGNO-GU, SEOUL, KOREA'  
                                                 ELSE '' END AS UMSpecValue  
          FROM _TDAUMinor  AS A WITH (NOLOCK)   
         WHERE A.CompanySeq = @CompanySeq  
           AND A.MajorSeq   = 1000950  
         ORDER BY A.MinorSort  
           
    END  
    ELSE   
    BEGIN  
        SELECT  A.TestReportSeq ,  
                A.AnalysisDate  ,  
                A.UMSpec        ,  
                B.MinorName AS UMSpecName    ,   
                A.UMSpecValue  
          FROM  _TPDTestExpReport AS A WITH (NOLOCK)  
                JOIN _TDAUMinor        AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq   
                                                         AND A.UMSpec     = B.MinorSeq  
         WHERE  A.CompanySeq     = @CompanySeq  
           AND  A.TestReportSeq  = @TestReportSeq  
         ORDER  BY B.MinorSort  
    END  
    --공정분석 항목정보  
    SELECT  A.TestReportSeq    ,  
            A.TestReportSerl   ,   
            A.FactUnit         ,   
            B.FactUnitName AS FactUnitName     ,   
            A.SectionSeq       ,   
            C.SectionCode  AS SectionCode      ,  
            C.SectionName  AS SectionName      ,   
            A.SampleLocSeq     ,   
            D.SampleLoc    AS SampleLoc        ,   
            A.AnalysisItemSeq  ,   
            A.ItemCodeName     ,  
            A.UnitName         ,   
            A.Spec             ,   
            A.ResultVal        ,   
            A.Method             
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