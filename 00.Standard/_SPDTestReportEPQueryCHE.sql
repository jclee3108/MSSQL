
IF OBJECT_ID('_SPDTestReportEPQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportEPQueryCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서조회 : 전자결제  
 작성일 - 20110621  
 작성자 - 박헌기  
************************************************************/  
CREATE PROC dbo._SPDTestReportEPQueryCHE
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT             = 0,  
    @ServiceSeq     INT             = 0,  
    @WorkingTag     NVARCHAR(10)    = '',  
    @CompanySeq     INT             = 1,  
    @LanguageSeq    INT             = 1,  
    @UserSeq        INT             = 0,  
    @PgmSeq         INT             = 0  
AS  
      
    DECLARE @docHandle     INT,  
            @TestReportSeq INT   
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @TestReportSeq = TestReportSeq    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH  (TestReportSeq  INT )  
      
    SELECT CompanySeq   ,  
           TestReportSeq,  
           MAX(CASE WHEN UMSpec = 1000723001 THEN UMSpecValue ELSE '' END) Commodity,  
           MAX(CASE WHEN UMSpec = 1000723002 THEN UMSpecValue ELSE '' END) Quantity,  
           MAX(CASE WHEN UMSpec = 1000723003 THEN UMSpecValue ELSE '' END) Destnation,  
           MAX(CASE WHEN UMSpec = 1000723004 THEN UMSpecValue ELSE '' END) Shipper,  
           MAX(CASE WHEN UMSpec = 1000723005 THEN UMSpecValue ELSE '' END) Buyer,  
           MAX(CASE WHEN UMSpec = 1000723006 THEN UMSpecValue ELSE '' END) Maker,  
           MAX(CASE WHEN UMSpec = 1000723007 THEN UMSpecValue ELSE '' END) Date,  
           MAX(CASE WHEN UMSpec = 1000723008 THEN UMSpecValue ELSE '' END) Lotno,  
           MAX(CASE WHEN UMSpec = 1000723009 THEN UMSpecValue ELSE '' END) Plant  
      INTO #TPDTestReportUMSpec  
      FROM _TPDTestReportUMSpec  
     WHERE CompanySeq = @CompanySeq  
     GROUP BY CompanySeq, TestReportSeq          
      
    SELECT  A.TestReportSeq ,   
            A.Commodity     ,   
            A.Quantity      ,   
            A.Destnation    ,   
            A.Shipper       ,   
            A.Buyer         ,   
            A.Maker         ,   
            A.Date          ,   
            A.Lotno         ,   
            A.Plant         ,   
            B.NoticDate     ,   
            B.AnalysisDate  ,   
            B.ItemTakeDate  ,   
            D.CustName      ,   
            B.CustSeq       ,   
            B.ItemSeq       ,   
            E.ItemName      ,   
            E.ItemNo        ,  
            C.FactUnit      ,  
            F.FactUnitName  ,  
            C.ItemCode      ,  
            G.MinorName AS ItemCodeName  ,  
            C.Unit          ,  
            H.MinorName AS UnitName      ,  
            C.ResultVal     ,  
            I.Spec AS Spec,  
            CASE WHEN B.ItemSeq IN (2,3,4,279) THEN G.Remark ELSE ''  END AS Method  
      FROM  #TPDTestReportUMSpec            AS A WITH (NOLOCK)  
            JOIN _TPDTestReport              AS B WITH (NOLOCK) ON A.CompanySeq    = B.CompanySeq  
                                                                    AND A.TestReportSeq = B.TestReportSeq  
            JOIN _TPDTestReportD             AS C WITH (NOLOCK) ON A.CompanySeq    = C.CompanySeq  
                                                                    AND A.TestReportSeq = C.TestReportSeq  
            LEFT OUTER JOIN _TDACust              AS D WITH (NOLOCK) ON B.CompanySeq    = D.CompanySeq  
                                                                    AND B.CustSeq       = D.CustSeq  
            LEFT OUTER JOIN _TDAItem              AS E WITH (NOLOCK) ON B.AnalysisDate  = E.CompanySeq  
                                                                    AND B.ItemSeq       = E.ItemSeq  
            LEFT OUTER JOIN _TDAFactUnit          AS F WITH (NOLOCK) ON C.CompanySeq  = F.CompanySeq  
                                                                    AND C.FactUnit    = F.FactUnit  
            LEFT OUTER JOIN _TDAUMinor            AS G WITH (NOLOCK) ON C.CompanySeq  = G.CompanySeq  
                                          AND C.ItemCode    = G.MinorSeq  
            LEFT OUTER JOIN _TDAUMinor            AS H WITH (NOLOCK) ON C.CompanySeq  = H.CompanySeq  
                                                                    AND C.Unit        = H.MinorSeq  
            LEFT OUTER JOIN _TPDAnalysisItem AS I WITH (NOLOCK) ON C.CompanySeq   = I.CompanySeq  
                                                                    AND C.SampleLocSeq = I.SampleLocSeq  
                                                                    AND C.ItemCode     = I.ItemCode  
     WHERE  A.CompanySeq     = @CompanySeq  
       AND  A.TestReportSeq  = @TestReportSeq  
  
    RETURN  