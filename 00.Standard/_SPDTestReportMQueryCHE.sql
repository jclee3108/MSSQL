
IF OBJECT_ID('_SPDTestReportMQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportMQueryCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시험성적서등록- 조회  
    작성일 : 2011.04.28 전경만  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportMQueryCHE
    @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달  
    @xmlFlags    INT = 0         ,    -- 해당 XML문서의 TYPE  
    @ServiceSeq  INT = 0         ,    -- 서비스 번호  
    @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그  
    @CompanySeq  INT = 1         ,    -- 회사 번호  
    @LanguageSeq INT = 1         ,    -- 언어 번호  
    @UserSeq     INT = 0         ,    -- 사용자 번호  
    @PgmSeq      INT = 0              -- 프로그램 번호  
  
AS  
    
    DECLARE @docHandle  INT,  
            @ItemSeq  INT,  
            @TestReportSeq INT  
  
  
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- 생성된 XML문서를 @docHandle로 핸들한다.  
  
    -- XML문서의 DataBlock1으로부터 값을 가져와 변수에 저장한다.  
    SELECT  @ItemSeq  = ISNULL(ItemSeq    ,  0),  
   @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML문서의 DataBlock1으로부터  
      WITH (ItemSeq   INT,  
            TestReportSeq INT)  
      
      
 SELECT A.ItemTakeDate,  
     A.ItemSeq,  
     I.ItemName,  
     A.CustSeq,  
     C.CustName,  
     A.NoticDate,  
     A.AnalysisDate,  
     A.TestReportSeq,  
     U.EmpSeq,  
     ISNULL(E.SignImg, '')     AS SealPhoto,  
     ISNULL(LEN(E.SignImg), 0) AS LenSealPhoto  
   FROM _TPDTestReport AS A  
     LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq  
              AND I.ItemSeq = A.ItemSeq  
     LEFT OUTER JOIN _TDACust AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq  
              AND C.CustSeq = A.CustSeq  
           LEFT OUTER JOIN _TCOMGroupWare AS G WITH(NOLOCK) ON G.CompanySeq = @CompanySeq  
                                                           AND G.WorkKind   = 'TestReport' -- 시험성적서  
                                                           AND A.TestReportSeq = CONVERT(INT, G.TblKey)  
           -- 시험성적서 출력물에서 전자결재 최종 결재자의 사인이미지를 출력하기 위해 최종결재자의 사용자코드를 가져온다. 110905 추가 by 천경민  
           LEFT OUTER JOIN (SELECT A.DocNo, A.ApprovalSeq, A.UserNo AS FinUserSeq  
                              FROM KSystemCommon.._TWFApprovalRoute AS A  
                                   JOIN (SELECT DocNo, MAX(ApprovalSeq) AS ApprovalSeq  
                                           FROM KSystemCommon.._TWFApprovalRoute  
                                          GROUP BY DocNo) AS B ON A.DocNo = B.DocNo  
                                                              AND A.ApprovalSeq = B.ApprovalSeq) AS D ON CONVERT(INT, ISNULL(G.DocID, 0)) = D.DocNo  
           LEFT OUTER JOIN _TCAUser AS U WITH(NOLOCK) ON U.CompanySeq = @CompanySeq  
                                                     AND D.FinUserSeq = U.UserSeq  
           LEFT OUTER JOIN _THREmpEtcInfo AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq  
                                                                AND U.EmpSeq     = E.EmpSeq  
  WHERE A.CompanySeq = @CompanySeq  
    AND (@TestReportSeq = A.TestReportSeq)  
RETURN  