
IF OBJECT_ID('_SPDTestReportJumpInUMQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportJumpInUMQueryCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - 점프인항목조회  
    작성일 : 2011.06.02 전경만  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportJumpInUMQueryCHE  
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
            @ItemSeq  INT  ,  
            @TestReportSeq INT  
  
  
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- 생성된 XML문서를 @docHandle로 핸들한다.  
  
    -- XML문서의 DataBlock1으로부터 값을 가져와 변수에 저장한다.  
    SELECT  @ItemSeq  = ISNULL(ItemSeq    ,  0),  
   @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)    -- XML문서의 DataBlock1으로부터  
      WITH (ItemSeq   INT     ,  
   TestReportSeq INT)  
  
  
 --IF @TestReportSeq = 0 OR @TestReportSeq IS NULL  
 --BEGIN  
 SELECT A.MinorName AS UMSpecName,  
     A.MinorSeq AS UMSpec,  
     CASE --WHEN A.MinorSeq = 1000723001 THEN I.ItemEngName  
    WHEN A.MinorSeq = 1000723006 THEN 'CORPORATION'  
            ELSE '' END AS UMSpecValue  
   FROM _TDAUMinor AS A  
     LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq  
              AND (@ItemSeq = 0 OR @ItemSeq = I.ItemSeq)  
  WHERE A.CompanySeq = @CompanySeq  
    AND A.MajorSeq = 1000723  
  ORDER BY A.MinorSeq  
 --END  
 --ELSE BEGIN  
 --SELECT A.MinorName AS UMSpecName,  
 --    A.MinorSeq AS UMSpec,  
 --    CASE WHEN A.MinorSeq = 1000723006 THEN 'CORPORATION'  
 --           ELSE B.UMSpecValue END AS UMSpecValue  
 --  FROM _TDAUMinor AS A  
 --    LEFT OUTER JOIN _TPDTestReportUMSpec AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq  
 --                  AND B.UMSpec = A.MinorSeq  
 --                  AND (B.TestReportSeq = @TestReportSeq)  
 -- WHERE A.CompanySeq = @CompanySeq  
 --   AND A.MajorSeq = 1000723  
 -- ORDER BY A.MinorSeq  
 --END  
  
  
RETURN  