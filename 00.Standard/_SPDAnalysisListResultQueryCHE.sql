
IF OBJECT_ID('_SPDAnalysisListResultQueryCHE') IS NOT NULL 
    DROP PROC _SPDAnalysisListResultQueryCHE
GO 

/************************************************************        
 설  명 - 데이터-공정분석자료관리 : 공정분석결과조회    
 작성일 - 20110331        
 작성자 - 신용식    
************************************************************/       
CREATE PROC dbo._SPDAnalysisListResultQueryCHE    
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT             = 0,        
    @ServiceSeq     INT             = 0,        
    @WorkingTag     NVARCHAR(10)    = '',        
    @CompanySeq     INT             = 1,        
    @LanguageSeq    INT             = 1,        
    @UserSeq        INT             = 0,        
    @PgmSeq         INT             = 0        
AS        
              
    DECLARE @docHandle       INT,      
            @FactUnit        INT,      
            @FactUnitName  NVARCHAR(20),    
            @SectionSeq      INT,      
            @SectionName  NVARCHAR(30),    
            @SampleLocSeq    INT,      
            @ItemCode        INT,      
            @SpecYN          INT,      
            @AnalysisDateFr  NVARCHAR(8),      
            @AnalysisDateTo  NVARCHAR(8),      
            @AnalysisTimeFr  NVARCHAR(4),      
            @AnalysisTimeTo  NVARCHAR(4),      
            @MatDiv          INT      
      
          
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
          
    SELECT  @FactUnit        = ISNULL(FactUnit, 0)      ,      
   @FactUnitName  = ISNULL(FactUnitName, '') ,    
            @SectionSeq      = ISNULL(SectionSeq, 0)     ,      
            @SectionName  = ISNULL(SectionName, '') ,    
            @SampleLocSeq    = ISNULL(SampleLocSeq, 0)   ,      
            @ItemCode        = ISNULL(ItemCode, 0)       ,      
            @SpecYN          = ISNULL(SpecYN, 0)         ,      
            @AnalysisDateFr  = CASE WHEN ISNULL(RTRIM(AnalysisDateFr),'') = '' then '19000101' else  AnalysisDateFr end,      
            @AnalysisDateTo  = CASE WHEN ISNULL(RTRIM(AnalysisDateTo),'') = '' then '99991231' else  AnalysisDateTo end,      
            @AnalysisTimeFr  = ISNULL(RTRIM(AnalysisTimeFr),'0'),      
            @AnalysisTimeTo  = ISNULL(RTRIM(AnalysisTimeTo),'24'),      
            @MatDiv          = ISNULL(MatDiv,0)    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)          
      WITH  (FactUnit        INT,      
    FactUnitName  NVARCHAR(20),    
             SectionSeq      INT,      
             SectionName  NVARCHAR(30),    
             SampleLocSeq    INT,      
             ItemCode        INT,      
             SpecYN          INT,      
             AnalysisDateFr  NVARCHAR(8),      
             AnalysisDateTo  NVARCHAR(8),      
             AnalysisTimeFr  NVARCHAR(4),      
             AnalysisTimeTo  NVARCHAR(4),      
             MatDiv          INT )          
        
    --SELECT @AnalysisTimeFr, @AnalysisTimeTo    
        
    SELECT @AnalysisTimeFr = RIGHT('0' + RTRIM(CAST(@AnalysisTimeFr AS CHAR(2))),2) + '00',    
  @AnalysisTimeTo = RIGHT('0' + RTRIM(CAST(@AnalysisTimeTo AS CHAR(2))),2) + '00'    
              
    --SELECT @AnalysisTimeFr, @AnalysisTimeTo    
              
    SELECT  A1.AnalysisDate ,    
   @AnalysisDateFr AS AnalysisDateFr,    
   @AnalysisDateTo AS AnalysisDateTo,    
   @AnalysisTimeFr AS AnalysisTimeFr,    
   @AnalysisTimeTo AS AnalysisTimeTo,    
   @FactUnitName AS FactUnitNameQ,    
   @SectionName AS SectionNameQ,    
            SUBSTRING(A1.AnalysisTime,1,2) AS AnalysisTime,          
            A1.AnalysisTime AS  AnalysisTime4,          
            C.FactUnit                  ,          
            G.FactUnitName    ,    
            C.SectionSeq                ,          
            C.SectionCode               ,          
            C.SectionName               ,          
            A.SampleLocSeq              ,          
            B.SampleLoc                 ,          
            A.AnalysisItemSeq           ,          
            A.ItemCode                  ,          
            D.MinorName AS ItemCodeName ,        
              D.Remark    AS Method       ,    
            A.Unit                      ,        
            E.MinorName AS UnitName     ,          
            A.StandVal                  ,          
              A.MaxVal                    ,          
            A.MinVal                    ,          
            A.ItemType                  ,          
            F.MinorName AS ItemTypeName ,         
            F.Remark                    ,     
            A1.AnalysisListSeq          ,         
            A.Spec                      ,     
            A1.ResultVal                ,          
            A1.SpecYN                   ,        
            H.MinorName AS SpecName     ,        
            A1.WorkType                 ,          
            A1.ManageDate               ,          
            A1.Serl                     ,           
            A1.Remark                      
      FROM  _TPDAnalysisItem         AS A WITH (NOLOCK)          
            JOIN _TPDAnalysisList    AS A1 WITH (NOLOCK) ON A.CompanySeq     = A1.CompanySeq          
                                                             AND A.AnalysisItemSeq= A1.AnalysisItemSeq          
            JOIN _TPDSampleLoc       AS B WITH (NOLOCK) ON A.CompanySeq     = B.CompanySeq          
                                                            AND A.SampleLocSeq   = B.SampleLocSeq          
            JOIN _TPDSectionCode     AS C WITH (NOLOCK) ON B.CompanySeq     = C.CompanySeq          
                                                            AND B.SectionSeq     = C.SectionSeq          
            LEFT OUTER JOIN _TDAUMinor    AS D WITH (NOLOCK) ON A.CompanySeq     = D.CompanySeq          
                                                            AND A.ItemCode       = D.MinorSeq          
            LEFT OUTER JOIN _TDAUMinor    AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySeq          
                                                            AND A.Unit       = E.MinorSeq                     
            LEFT OUTER JOIN _TDAUMinor    AS F WITH (NOLOCK) ON A.CompanySeq    = F.CompanySeq          
                                                            AND A.ItemType      = F.MinorSeq          
            LEFT OUTER JOIN _TDAFactUnit  AS G WITH (NOLOCK) ON C.CompanySeq    = G.CompanySeq          
                                                            AND C.FactUnit      = G.FactUnit               
            LEFT OUTER JOIN _TDAUMinor    AS H WITH (NOLOCK) ON A1.CompanySeq    = H.CompanySeq          
                                                            AND A1.SpecYN        = H.MinorSeq          
     WHERE  A1.CompanySeq     = @CompanySeq       
       AND  (B.FactUnit       = @FactUnit OR @FactUnit = 0)      
       AND  (B.SectionSeq     = @SectionSeq OR @SectionSeq = 0)      
       AND  (A1.SampleLocSeq  = @SampleLocSeq OR @SampleLocSeq = 0)      
       AND  (A.ItemCode       = @ItemCode OR @ItemCode = 0)      
       AND  (A1.SpecYN        = @SpecYN OR @SpecYN = 0)      
       AND  ((@MatDiv = '1000731004' AND B.MatDiv IN ('1000731001', '1000731003'))  -- 제품,반제품을 같이 조회하는 소분류 추가하고 변경 By ZOO 2012.03.14    
       OR  (B.MatDiv = @MatDiv  OR @MatDiv = 0))    
       --AND  (B.MatDiv = @MatDiv  OR @MatDiv = 0)  -- 제품,반제품을 같이 조회하는 소분류 추가하고 변경 By ZOO 2012.03.14    
       --AND  A1.AnalysisDate BETWEEN @AnalysisDateFr AND @AnalysisDateTo         
       --AND  A1.AnalysisTime BETWEEN @AnalysisTimeFr AND @AnalysisTimeTo         
       AND  A1.AnalysisDate + A1.AnalysisTime BETWEEN @AnalysisDateFr + @AnalysisTimeFr AND @AnalysisDateTo + @AnalysisTimeTo     
     ORDER BY A1.AnalysisDate ,A1.AnalysisTime , C.FactUnit, C.Serl,C.SectionCode ,B.Serl,B.SampleLoc,A1.Serl,A.Serl, A.ItemCode,A.AnalysisItemSeq     
               
        
    RETURN        