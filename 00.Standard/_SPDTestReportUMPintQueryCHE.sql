
IF OBJECT_ID('_SPDTestReportUMPintQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportUMPintQueryCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - �׸������ȸ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportUMPintQueryCHE 
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
            @ItemSeq  INT  ,  
            @TestReportSeq INT  
  
  
    -- XML����  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- ������ XML������ @docHandle�� �ڵ��Ѵ�.  
  
    -- XML������ DataBlock1���κ��� ���� ������ ������ �����Ѵ�.  
    SELECT  @ItemSeq  = ISNULL(ItemSeq    ,  0),  
            @TestReportSeq = ISNULL(TestReportSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)    -- XML������ DataBlock1���κ���  
      WITH (ItemSeq   INT     ,  
            TestReportSeq INT)  
  
  
 SELECT A.MinorName AS UMSpecName,  
     A.MinorSeq AS UMSpec,  
     CASE WHEN A.MinorSeq = 1000723006 THEN ':  CORPORATION'  
            ELSE ':  '+B.UMSpecValue END AS UMSpecValue  
   FROM _TDAUMinor AS A  
     JOIN _TPDTestReportUMSpec AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq  
                   AND B.UMSpec = A.MinorSeq  
                   AND (B.TestReportSeq = @TestReportSeq)  
  WHERE A.CompanySeq = @CompanySeq  
    AND A.MajorSeq = 1000723  
    AND LEN(B.UMSpecValue) > 0  
  ORDER BY A.MinorSeq  
  
  
  
RETURN  
  