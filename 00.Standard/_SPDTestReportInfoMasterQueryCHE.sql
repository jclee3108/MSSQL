
IF OBJECT_ID('_SPDTestReportInfoMasterQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportInfoMasterQueryCHE
GO

/************************************************************  
 설  명 - 데이터-시험성적서조회 : 조회  
 작성일 - 20110621  
 작성자 - 박헌기  
************************************************************/  
CREATE PROC dbo._SPDTestReportInfoMasterQueryCHE 
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT             = 0,  
    @ServiceSeq     INT             = 0,  
    @WorkingTag     NVARCHAR(10)    = '',  
    @CompanySeq     INT             = 1,  
    @LanguageSeq    INT             = 1,  
    @UserSeq        INT             = 0,  
    @PgmSeq         INT             = 0  
AS  
      
    DECLARE @docHandle      INT,  
            @Commodity     NVARCHAR(200) ,  
            @Quantity      NVARCHAR(200) ,  
            @Destnation    NVARCHAR(200) ,  
            @Shipper       NVARCHAR(200) ,  
            @Buyer         NVARCHAR(200) ,  
            @Maker         NVARCHAR(200) ,  
            @Date          NVARCHAR(200) ,  
            @Lotno         NVARCHAR(200) ,  
            @Plant         NVARCHAR(200) ,  
            @CustSeq       INT ,  
            @ItemSeq       INT ,  
            @NoticDateFr   NCHAR(8) ,  
            @NoticDateTo   NCHAR(8) ,  
            @TestDateFr    NCHAR(8) ,  
            @TestDateTo    NCHAR(8)   
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @Commodity     = Commodity      ,  
            @Quantity      = Quantity       ,  
            @Destnation    = Destnation     ,  
            @Shipper       = Shipper        ,  
            @Buyer         = Buyer          ,  
            @Maker         = Maker          ,  
            @Date          = Date           ,  
            @Lotno         = Lotno          ,  
            @Plant         = Plant          ,  
            @CustSeq       = CustSeq        ,  
            @ItemSeq       = ItemSeq        ,  
            @NoticDateFr   = NoticDateFr    ,  
            @NoticDateTo   = NoticDateTo    ,  
            @TestDateFr    = TestDateFr     ,  
            @TestDateTo    = TestDateTo       
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH  (Commodity      NVARCHAR(200) ,  
             Quantity       NVARCHAR(200) ,  
             Destnation     NVARCHAR(200) ,  
             Shipper        NVARCHAR(200) ,  
             Buyer          NVARCHAR(200) ,  
             Maker          NVARCHAR(200) ,  
             Date           NVARCHAR(200) ,  
             Lotno          NVARCHAR(200) ,  
             Plant          NVARCHAR(200) ,  
             CustSeq        INT ,  
             ItemSeq        INT ,  
             NoticDateFr    NCHAR(8) ,  
             NoticDateTo    NCHAR(8) ,  
             TestDateFr     NCHAR(8) ,  
             TestDateTo     NCHAR(8) )  
      
      
 IF @NoticDateFr = ''   
  SELECT @NoticDateFr = '19000101'  
 IF @NoticDateTo = ''  
  SELECT @NoticDateTo = '99991231'  
 IF @TestDateFr = ''  
  SELECT @TestDateFr = '19000101'  
 IF @TestDAteTo = ''  
  SELECT @TestDAteTo = '99991231'      
      
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
            E.ItemNo  
      FROM  #TPDTestReportUMSpec AS A WITH (NOLOCK)  
            JOIN _TPDTestReport   AS B WITH (NOLOCK) ON A.CompanySeq    = B.CompanySeq  
                                                         AND A.TestReportSeq = B.TestReportSeq  
            LEFT OUTER JOIN _TDACust   AS D WITH (NOLOCK) ON B.CompanySeq    = D.CompanySeq  
                                                         AND B.CustSeq       = D.CustSeq  
            LEFT OUTER JOIN _TDAItem   AS E WITH (NOLOCK) ON B.CompanySeq    = E.CompanySeq  
                                                         AND B.ItemSeq       = E.ItemSeq  
     WHERE  A.CompanySeq = @CompanySeq  
       AND  A.Commodity      LIKE '%'+@Commodity  +'%'     
       AND  A.Quantity       LIKE '%'+@Quantity   +'%'     
       AND  A.Destnation     LIKE '%'+@Destnation +'%'     
       AND  A.Shipper        LIKE '%'+@Shipper    +'%'     
       AND  A.Buyer          LIKE '%'+@Buyer      +'%'     
       AND  A.Maker          LIKE '%'+@Maker      +'%'     
       AND  A.Date           LIKE '%'+@Date       +'%'     
       AND  A.Lotno          LIKE '%'+@Lotno      +'%'     
       AND  A.Plant          LIKE '%'+@Plant      +'%'     
    AND (B.NoticDate BETWEEN @NoticDateFr AND @NoticDateTo)  
    AND (B.AnalysisDate BETWEEN @TestDateFr AND @TestDAteTo)  
    AND (@ItemSeq = 0 OR B.ItemSeq = @ItemSeq)  
    AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)  
     ORDER BY B.NoticDate DESC    ,B.AnalysisDate DESC ,B.ItemTakeDate DESC , D.CustName  
         
  
    RETURN  
      