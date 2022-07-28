
IF OBJECT_ID('_SPDTestReportMQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportMQueryCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���輺�������- ��ȸ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportMQueryCHE
    @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML������ ����  
    @xmlFlags    INT = 0         ,    -- �ش� XML������ TYPE  
    @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
    @WorkingTag  NVARCHAR(10)= '',    -- ��ŷ �±�  
    @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
    @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
    @UserSeq     INT = 0         ,    -- ����� ��ȣ  
    @PgmSeq      INT = 0              -- ���α׷� ��ȣ  
  
AS  
    
    DECLARE @docHandle  INT,  
            @ItemSeq  INT,  
            @TestReportSeq INT  
  
  
    -- XML����  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- ������ XML������ @docHandle�� �ڵ��Ѵ�.  
  
    -- XML������ DataBlock1���κ��� ���� ������ ������ �����Ѵ�.  
    SELECT  @ItemSeq  = ISNULL(ItemSeq    ,  0),  
   @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML������ DataBlock1���κ���  
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
                                                           AND G.WorkKind   = 'TestReport' -- ���輺����  
                                                           AND A.TestReportSeq = CONVERT(INT, G.TblKey)  
           -- ���輺���� ��¹����� ���ڰ��� ���� �������� �����̹����� ����ϱ� ���� ������������ ������ڵ带 �����´�. 110905 �߰� by õ���  
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