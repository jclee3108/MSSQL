
IF OBJECT_ID('_SPDTestReportQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportQueryCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - 시트조회  
    작성일 : 2011.04.28 전경만  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportQueryCHE    
    @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달  
    @xmlFlags    INT = 0         ,    -- 해당 XML문서의 TYPE  
    @ServiceSeq  INT = 0         ,    -- 서비스 번호  
    @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그  
    @CompanySeq  INT = 1         ,    -- 회사 번호  
    @LanguageSeq INT = 1         ,    -- 언어 번호  
    @UserSeq     INT = 0         ,    -- 사용자 번호  
    @PgmSeq      INT = 0              -- 프로그램 번호  
  
AS  
  
    DECLARE @docHandle  INT     ,  
            @ItemSeq INT  ,  
            @TestReportSeq INT   
  
  
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- 생성된 XML문서를 @docHandle로 핸들한다.  
  
    -- XML문서의 DataBlock1으로부터 값을 가져와 변수에 저장한다.  
    SELECT  @ItemSeq     = ISNULL(ItemSeq    ,  0),  
            @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)    -- XML문서의 DataBlock1으로부터  
      WITH (ItemSeq  INT     ,  
            TestReportSeq INT)  
   
    SELECT D.TestReportSeq,  
           D.TestReportSerl,  
           D.ItemCode,  
           IC.MinorName AS ItemCodeName,  
           --IC.Remark    AS Method,  
           (SELECT B.Method  
              FROM _TPDTestReportItem AS A  
                   LEFT OUTER JOIN _TPDTestReportItemDetail AS B ON A.CompanySeq = B.CompanySeq  
                                                                     AND A.Seq        = B.Seq  
             WHERE A.CompanySeq = @CompanySeq  
               AND A.ItemSeq    = J.ItemSeq  
               AND A.ItemCode   = D.ItemCode  
               AND J.NoticDate  BETWEEN B.ApplyFrDate AND B.ApplyToDate)    AS Method,    
           D.FactUnit,  
           P.FactUnitName,  
           D.SectionSeq,  
           S.SectionCode,  
           S.SectionName,  
           D.SampleLocSeq,  
           L.SampleLoc,  
           D.Unit,  
           U.MinorName AS UnitName,  
           D.ResultVal,  
           I.Spec,  
           J.ItemSeq  
      FROM _TPDTestReportD AS D   
      LEFT OUTER JOIN _TDAUMinor            AS U WITH(NOLOCK) ON U.CompanySeq = D.CompanySeq  
                            AND U.MinorSeq   = D.Unit  
      LEFT OUTER JOIN _TPDSectionCode  AS S WITH(NOLOCK) ON S.CompanySeq = D.CompanySeq  
                    AND S.SectionSeq = D.SectionSeq  
      LEFT OUTER JOIN _TDAFactUnit          AS P WITH(NOLOCK) ON P.CompanySeq = D.CompanySeq  
                            AND P.FactUnit   = D.FactUnit  
      LEFT OUTER JOIN _TPDSampleLoc    AS L WITH(NOLOCK) ON L.CompanySeq = D.CompanySeq  
                            AND L.SampleLocSeq = D.SampleLocSeq  
      LEFT OUTER JOIN _TDAUMinor            AS IC WITH(NOLOCK) ON IC.CompanySeq = D.CompanySeq  
                           AND IC.MinorSeq = D.ItemCode  
      LEFT OUTER JOIN _TPDAnalysisItem AS I WITH(NOLOCK) ON I.CompanySeq = D.CompanySeq  
                   AND I.SampleLocSeq = D.SampleLocSeq  
                   AND I.ItemCode = D.ItemCode  
      LEFT OUTER JOIN _TPDTestReport AS J WITH(NOLOCK) ON D.CompanySeq = J.CompanySeq  
                 AND D.TestReportSeq = J.TestReportSeq        
                    
     WHERE D.CompanySeq = @CompanySeq  
       AND (@TestReportSeq = 0 OR D.TestReportSeq = @TestReportSeq)  
     ORDER BY D.TestReportSerl  
    
    RETURN  