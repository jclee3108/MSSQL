
IF OBJECT_ID('_SPDTestExpReportInfoQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportInfoQueryCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서조회(영업) : 조회  
 작성일 - 20110922  
 작성자 - 마스터  
************************************************************/  
  
CREATE PROC dbo._SPDTestExpReportInfoQueryCHE
    @xmlDocument    NVARCHAR(MAX) ,  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
  
AS  
  
    DECLARE @docHandle       INT,  
            @RgstEmpSeq      INT ,  
            @Commodity       NVARCHAR(300) ,  
            @Buyer           NVARCHAR(300) ,  
            @Quantity        NVARCHAR(300) ,  
            @PortOfLoading   NVARCHAR(300) ,  
            @PortOfDischarge NVARCHAR(300) ,  
            @ShipmentDate    NVARCHAR(300) ,  
            @Vessel          NVARCHAR(300) ,  
            @Manufacturer    NVARCHAR(300) ,  
            @RgstDateFr      NCHAR(8)      ,  
            @RgstDateTo      NCHAR(8)      ,  
            @AnalysisDateFr  NCHAR(8)      ,  
            @AnalysisDateTo  NCHAR(8)        
  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @RgstEmpSeq      = ISNULL(RgstEmpSeq     , 0)  ,  
            @Commodity       = ISNULL(Commodity      ,'')  ,  
            @Buyer           = ISNULL(Buyer          ,'')  ,  
            @Quantity        = ISNULL(Quantity       ,'')  ,  
            @PortOfLoading   = ISNULL(PortOfLoading  ,'')  ,  
            @PortOfDischarge = ISNULL(PortOfDischarge,'')  ,  
            @ShipmentDate    = ISNULL(ShipmentDate   ,'')  ,  
            @Vessel          = ISNULL(Vessel         ,'')  ,  
            @Manufacturer    = ISNULL(Manufacturer   ,'')  ,  
            @RgstDateFr      = ISNULL(RgstDateFr     ,'')  ,  
            @RgstDateTo      = ISNULL(RgstDateTo     ,'')  ,  
            @AnalysisDateFr  = ISNULL(AnalysisDateFr ,'')  ,  
            @AnalysisDateTo  = ISNULL(AnalysisDateTo ,'')    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (RgstDate         NCHAR(8) ,  
            RgstEmpSeq       INT ,  
            AnalysisDate     NCHAR(8) ,  
            Commodity        NVARCHAR(300) ,  
            Buyer            NVARCHAR(300) ,  
            Quantity         NVARCHAR(300) ,  
            PortOfLoading    NVARCHAR(300) ,  
            PortOfDischarge  NVARCHAR(300) ,  
            ShipmentDate     NVARCHAR(300) ,  
            Vessel           NVARCHAR(300) ,  
            Manufacturer     NVARCHAR(300) ,  
            RgstDateFr       NCHAR(8)      ,  
            RgstDateTo       NCHAR(8)      ,  
            AnalysisDateFr   NCHAR(8)      ,  
            AnalysisDateTo   NCHAR(8)      )  
              
              
    SELECT  A.TestReportSeq   ,   
            A.RgstDate        ,   
            A.RgstEmpSeq      ,   
            A.RgstEmpName     ,  
            A.AnalysisDate    ,   
            A.Commodity       ,   
            A.Buyer           ,   
            A.Quantity        ,   
            A.PortOfLoading   ,   
            A.PortOfDischarge ,  
            A.ShipmentDate    ,   
            A.Vessel          ,    
            A.Manufacturer  
      FROM (SELECT  A.TestReportSeq   ,   
                    A.RgstDate        ,   
                    A.RgstEmpSeq      ,   
                    B.EmpName AS RgstEmpName,  
                    A.AnalysisDate    ,   
                    MAX(CASE WHEN A.UMSpec = 1000950001 THEN A.UMSpecValue ELSE '' END) AS Commodity       ,   
                    MAX(CASE WHEN A.UMSpec = 1000950002 THEN A.UMSpecValue ELSE '' END) AS Buyer           ,   
                    MAX(CASE WHEN A.UMSpec = 1000950003 THEN A.UMSpecValue ELSE '' END) AS Quantity        ,   
                    MAX(CASE WHEN A.UMSpec = 1000950004 THEN A.UMSpecValue ELSE '' END) AS PortOfLoading   ,   
                    MAX(CASE WHEN A.UMSpec = 1000950005 THEN A.UMSpecValue ELSE '' END) AS PortOfDischarge ,  
               MAX(CASE WHEN A.UMSpec = 1000950006 THEN A.UMSpecValue ELSE '' END) AS ShipmentDate    ,   
                    MAX(CASE WHEN A.UMSpec = 1000950007 THEN A.UMSpecValue ELSE '' END) AS Vessel          ,    
                    MAX(CASE WHEN A.UMSpec = 1000950008 THEN A.UMSpecValue ELSE '' END) AS Manufacturer  
              FROM  _TPDTestExpReport AS A WITH (NOLOCK)  
                    LEFT OUTER JOIN _TDAEmp           AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                        AND A.RgstEmpSeq = B.EmpSeq  
             WHERE  1=1  
               AND  A.CompanySeq = @CompanySeq  
               AND  (@RgstEmpSeq = 0 OR A.RgstEmpSeq       = @RgstEmpSeq)  
               AND  (@RgstDateFr ='' OR A.RgstDate >= @RgstDateFr)  
               AND  (@RgstDateTo ='' OR A.RgstDate <= @RgstDateTo)         
               AND  (@AnalysisDateFr='' OR A.AnalysisDate >= @AnalysisDateFr)  
               AND  (@AnalysisDateTo='' OR A.AnalysisDate <= @AnalysisDateTo)  
             GROUP BY A.TestReportSeq, A.RgstDate    , A.RgstEmpSeq,   
                      B.EmpName      , A.AnalysisDate ) AS A  
     WHERE (@Commodity       = '' OR A.Commodity       LIKE '%'+@Commodity      +'%'  )  
       AND (@Buyer           = '' OR A.Buyer           LIKE '%'+@Buyer          +'%'  )  
       AND (@Quantity        = '' OR A.Quantity        LIKE '%'+@Quantity       +'%'  )  
       AND (@PortOfLoading   = '' OR A.PortOfLoading   LIKE '%'+@PortOfLoading  +'%'  )  
       AND (@PortOfDischarge = '' OR A.PortOfDischarge LIKE '%'+@PortOfDischarge+'%'  )  
       AND (@ShipmentDate    = '' OR A.ShipmentDate    LIKE '%'+@ShipmentDate   +'%'  )  
       AND (@Vessel          = '' OR A.Vessel          LIKE '%'+@Vessel         +'%'  )  
       AND (@Manufacturer    = '' OR A.Manufacturer    LIKE '%'+@Manufacturer   +'%'  )  
     ORDER BY A.RgstDate DESC, AnalysisDate DESC, A.RgstEmpName   
RETURN  
  
  