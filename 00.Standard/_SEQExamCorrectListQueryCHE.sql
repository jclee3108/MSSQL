
IF OBJECT_ID('_SEQExamCorrectListQueryCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectListQueryCHE
GO 

-- v2015.01.27 
/************************************************************  
  설  명 - 데이터-설비검교정정보 : 현황조회  
  작성일 - 20110329  
  작성자 - 신용식  
 ************************************************************/  
 CREATE PROC dbo._SEQExamCorrectListQueryCHE  
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
             @ToolSeq          INT ,  
             @CorrectCycleSeq  INT ,  
             @Grade            INT ,  
             @CorrectPlaceSeq  INT ,  
             @RefDateFr        NCHAR(8) ,  
             @RefDateTo        NCHAR(8)   
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
   
     SELECT  @ToolSeq          = ISNULL(ToolSeq,0)           ,  
             @CorrectCycleSeq  = ISNULL(CorrectCycleSeq,0)   ,  
             @Grade            = ISNULL(Grade,0)             ,  
             @CorrectPlaceSeq  = ISNULL(CorrectPlaceSeq,0)   ,  
             @RefDateFr        = ISNULL(RefDateFr,'')         ,  
             @RefDateTo        = ISNULL(RefDateTo,'')           
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
       WITH  (ToolSeq           INT ,  
             CorrectCycleSeq   INT ,  
             Grade             INT ,  
             CorrectPlaceSeq   INT ,  
             RefDateFr         NCHAR(8) ,  
             RefDateTo         NCHAR(8) )  
    
     SELECT  A.ToolSeq          ,  
             A.AllowableError   ,  
             A.RefDate,  
             A.CorrectCycleSeq  ,  
             A.InstallPlace     ,  
             A.CorrectPlaceSeq  ,  
             A.Remark           ,  
             A.ToolName         , 
             A.ToolNo           , 
             A.FactUnit         ,
             A.FactUnitName ,
             A.ManuCompnay      ,   
             A.CorrectCycleName ,  
             A.CorrectPlaceName ,
             A.LastCorrectDate  ,
             LEFT(CONVERT(CHAR(8),CASE WHEN CorrectCycleSeq = 20026001 THEN DATEADD(m,6,A.LastCorrectDate)
                                       WHEN CorrectCycleSeq = 20026002 THEN DATEADD(m,12,A.LastCorrectDate)
                                       WHEN CorrectCycleSeq = 20026003 THEN DATEADD(m,24,A.LastCorrectDate)
                                       WHEN CorrectCycleSeq = 20026004 THEN DATEADD(m,36,A.LastCorrectDate)
                                       WHEN CorrectCycleSeq = 20026005 THEN DATEADD(m,48,A.LastCorrectDate)
                                       WHEN CorrectCycleSeq = 20026006 THEN DATEADD(m,60,A.LastCorrectDate)
                                  END,112),6) + '01' AS NextStartDate ,
              CONVERT(CHAR(8),DATEADD(d,-1,CONVERT(CHAR(6),CASE WHEN CorrectCycleSeq = 20026001 THEN DATEADD(m,13,A.LastCorrectDate)
                                                                WHEN CorrectCycleSeq = 20026002 THEN DATEADD(m,25,A.LastCorrectDate)
                                                                WHEN CorrectCycleSeq = 20026003 THEN DATEADD(m,49,A.LastCorrectDate)
                                                                WHEN CorrectCycleSeq = 20026004 THEN DATEADD(m,73,A.LastCorrectDate)
                                                                WHEN CorrectCycleSeq = 20026005 THEN DATEADD(m,97,A.LastCorrectDate)
                                                                WHEN CorrectCycleSeq = 20026006 THEN DATEADD(m,121,A.LastCorrectDate)
                                                            END,112)+ '01'),112) AS NextEndDate   
       FROM  (SELECT A.ToolSeq          ,  
                     A.AllowableError   ,  
                     CASE WHEN ISNULL(C.Remark,'') = '' THEN A.RefDate ELSE CONVERT(NCHAR(8),DATEADD(Month,CONVERT(INT,C.Remark),A.RefDate),112) END AS RefDate, 
                     A.CorrectCycleSeq  ,  
                     A.InstallPlace     ,  
                     A.CorrectPlaceSeq  ,  
                     A.Remark           ,  
                     B.ToolName         ,  
                     B.ToolNo           ,
                     B.FactUnit         ,
                     ISNULL(F.FactUnitName,'') AS FactUnitName ,
                     B.ManuCompnay      ,   
                     C.MinorName AS CorrectCycleName ,  
                     E.MinorName AS CorrectPlaceName ,
                     ISNULL(A1.CorrectDate,A.RefDate) AS LastCorrectDate 
                     
               FROM  _TEQExamCorrectCHE AS A WITH (NOLOCK)  
                     JOIN _TPDTool  AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                      AND A.ToolSeq    = B.ToolSeq  
                     LEFT OUTER JOIN _TDAUMinor AS C WITH (NOLOCK)ON A.CompanySeq       = C.CompanySeq   
                                                                 AND A.CorrectCycleSeq  = C.MinorSeq     
                     LEFT OUTER JOIN _TDAUMinor AS E WITH (NOLOCK)ON A.CompanySeq      = E.CompanySeq   
                                                                 AND A.CorrectPlaceSeq = E.MinorSeq 
                     LEFT OUTER JOIN _TDAFactUnit AS F WITH (NOLOCK) ON B.CompanySeq = F.CompanySeq 
                                                                    AND B.FactUnit   = F.FactUnit    -- 생산사업장 
                     LEFT OUTER JOIN (SELECT  S.CompanySeq, S.ToolSeq, MAX(S.CorrectDate) AS CorrectDate
                                        FROM  _TEQExamCorrectEditCHE AS S 
                                       GROUP BY S.CompanySeq, S.ToolSeq) AS A1 ON A.CompanySeq = A1.CompanySeq
                                                                              AND A.ToolSeq    = A1.ToolSeq                                                                                                                         
              WHERE  A.CompanySeq = @CompanySeq  
                AND  (A.ToolSeq           = @ToolSeq OR @ToolSeq = 0)  
                AND  (A.CorrectCycleSeq   = @CorrectCycleSeq OR @CorrectCycleSeq = 0)  
                AND  (A.CorrectPlaceSeq   = @CorrectPlaceSeq OR @CorrectPlaceSeq = 0 )  
                AND  CASE WHEN ISNULL(C.Remark,'') = '' THEN A.RefDate ELSE CONVERT(NCHAR(8),DATEADD(Month,CONVERT(INT,C.Remark),A.RefDate),112) END BETWEEN @RefDateFr AND @RefDateTo 
              ) AS A
   
          
   
     RETURN