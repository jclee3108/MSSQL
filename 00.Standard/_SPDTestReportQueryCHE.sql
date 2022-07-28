
IF OBJECT_ID('_SPDTestReportQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportQueryCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - ��Ʈ��ȸ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportQueryCHE    
    @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML������ ����  
    @xmlFlags    INT = 0         ,    -- �ش� XML������ TYPE  
    @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
    @WorkingTag  NVARCHAR(10)= '',    -- ��ŷ �±�  
    @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
    @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
    @UserSeq     INT = 0         ,    -- ����� ��ȣ  
    @PgmSeq      INT = 0              -- ���α׷� ��ȣ  
  
AS  
  
    DECLARE @docHandle  INT     ,  
            @ItemSeq INT  ,  
            @TestReportSeq INT   
  
  
    -- XML����  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- ������ XML������ @docHandle�� �ڵ��Ѵ�.  
  
    -- XML������ DataBlock1���κ��� ���� ������ ������ �����Ѵ�.  
    SELECT  @ItemSeq     = ISNULL(ItemSeq    ,  0),  
            @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)    -- XML������ DataBlock1���κ���  
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