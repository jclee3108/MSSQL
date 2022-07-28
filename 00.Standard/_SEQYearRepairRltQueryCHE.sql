IF OBJECT_ID('_SEQYearRepairRltQueryCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairRltQueryCHE
GO

-- v2015.07.01   
/************************************************************      
  설  명 - 데이터-연차보수작업 관리 : 조회      
  작성일 - 20110704      
  작성자 - 박헌기      
 ************************************************************/      
 CREATE PROC dbo._SEQYearRepairRltQueryCHE    
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT             = 0,      
     @ServiceSeq     INT             = 0,      
     @WorkingTag     NVARCHAR(10)    = '',      
     @CompanySeq     INT             = 1,      
     @LanguageSeq    INT             = 1,      
     @UserSeq        INT             = 0,      
     @PgmSeq         INT             = 0      
 AS        
     DECLARE @docHandle         INT,      
             @RepairYear        NCHAR(4),      
             @Amd               INT,      
             @ReqDate           NCHAR(8),      
             @FactUnit          INT,      
             @SectionSeq        INT,      
             @WorkOperSeq       INT,      
             @ProgType          INT,      
             @DeptSeq           INT,      
             @EmpSeq            INT,      
             @ReqFrDate         NCHAR(8),      
             @ReqToDate         NCHAR(8),      
             @WorkGubn          INT      
                 
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
         
     SELECT  @RepairYear      = RepairYear                 ,      
             @Amd             = ISNULL(Amd, 0)             ,           
             @ReqDate         = ReqDate                    ,           
             @FactUnit        = ISNULL(FactUnit,0)         ,           
             @SectionSeq      = ISNULL(SectionSeq,0)       ,      
             @WorkOperSeq     = ISNULL(WorkOperSeq,0)      ,      
             @ProgType        = ISNULL(ProgType,0)         ,      
             @DeptSeq         = ISNULL(DeptSeq,0)          ,      
             @EmpSeq          = ISNULL(EmpSeq,0)           ,      
             @ReqFrDate       = CASE WHEN ISNULL(ReqFrDate,'') ='' THEN  @RepairYear + '0101'  ELSE @ReqFrDate END    ,      
             @ReqToDate       = CASE WHEN ISNULL(ReqToDate,'') ='' THEN  @RepairYear + '1231'  ELSE @ReqToDate END    ,      
             @WorkGubn        = ISNULL(WorkGubn, 0)      
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
       WITH  (RepairYear         NCHAR(4),       
              Amd                INT,      
              ReqDate            NCHAR(8),      
              FactUnit           INT,      
              SectionSeq         INT,      
              WorkOperSeq        INT,      
              ProgType           INT,      
              DeptSeq            INT,      
              EmpSeq             INT,      
              ReqFrDate          NCHAR(8),      
              ReqToDate          NCHAR(8),      
              WorkGubn   INT)      
      SELECT  A.ReqSeq          AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
             A.FactUnit        AS FactUnit,      
             C.SectionCode     AS SectionCode,      
             A.SectionSeq      AS SectionSeq,      
             D.ToolName        AS ToolName,      
             D.ToolNo          AS ToolNo,      
                   
             A.ToolSeq         AS ToolSeq,      
             E1.MinorName      AS WorkOperName,      
             A.WorkOperSeq     AS WorkOperSeq,      
             E2.MinorName      AS WorkGubnName,      
             A.WorkGubn        AS WorkGubn,      
                   
             A.WorkContents    AS WorkContents,      
             E3.MinorName      AS ProgTypeName,      
             A.ProgType        AS ProgType,      
             A.RtnReason       AS RtnReason,      
             A.WONo            AS WONo,      
             F.DeptName        AS DeptName,      
                   
             A.DeptSeq         AS DeptSeq,      
               G.EmpName         AS EmpName,      
             A.EmpSeq          AS EmpSeq,   
             A.UMKeepKind,   
             H.MinorName AS UMKeepKindName,   
             I.MngValText AS LevelName  
      FROM _TEQYearRepairMngCHE     AS A WITH (NOLOCK)      
            LEFT OUTER JOIN _TDAFactUnit           AS B WITH (NOLOCK) ON 1 = 1      
                                                         AND A.CompanySeq   = B.CompanySeq      
                                                         AND A.FactUnit     = B.FactUnit      
            LEFT OUTER JOIN _TPDSectionCodeCHE  AS C WITH (NOLOCK) ON 1 = 1      
                                                         AND A.CompanySeq   = C.CompanySeq      
                                                         AND A.SectionSeq   = C.SectionSeq      
            LEFT OUTER JOIN _TPDTool   AS D WITH (NOLOCK) ON 1 = 1      
                                                         AND A.CompanySeq   = D.CompanySeq      
                                                         AND A.ToolSeq      = D.ToolSeq            
            LEFT OUTER JOIN _TDAUMinor            AS E1 WITH (NOLOCK)ON 1 = 1      
                                                         AND A.CompanySeq   = E1.CompanySeq      
                                                         AND A.WorkOperSeq  = E1.MinorSeq      
            LEFT OUTER JOIN _TDASMinor            AS E2 WITH (NOLOCK)ON 1 = 1      
                                                         AND A.CompanySeq   = E2.CompanySeq      
                                                         AND A.WorkGubn     = E2.MinorSeq      
            LEFT OUTER JOIN _TDAUMinor AS E3 WITH (NOLOCK)ON 1 = 1      
                                                         AND A.CompanySeq   = E3.CompanySeq      
                                                         AND A.ProgType     = E3.MinorSeq      
            LEFT OUTER JOIN _TDADept   AS F WITH (NOLOCK)ON 1 = 1      
                                                         AND A.CompanySeq   = F.CompanySeq      
                                                         AND A.DeptSeq      = F.DeptSeq       
            LEFT OUTER JOIN _TDAEmp    AS G WITH (NOLOCK)ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
            LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMKeepKind )   
            LEFT OUTER JOIN _TPDToolUserDefine AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.ToolSeq = D.ToolSeq AND I.MngSerl = 1000001)   
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
        AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd         OR @Amd = 0        )    
        AND (A.ReqDate       BETWEEN @ReqFrDate AND @ReqToDate )    
        AND (A.FactUnit      = @FactUnit    OR @FactUnit    = 0)    
        AND (A.SectionSeq    = @SectionSeq  OR @SectionSeq  = 0)    
        AND (A.WorkOperSeq   = @WorkOperSeq OR @WorkOperSeq = 0)    
        AND (A.ProgType      = @ProgType    OR @ProgType    = 0)    
        AND (A.DeptSeq       = @DeptSeq     OR @DeptSeq     = 0)    
        AND (A.EmpSeq        = @EmpSeq      OR @EmpSeq      = 0)    
        AND (A.WorkGubn      = @WorkGubn    OR @WorkGubn    = 0)    
        AND  A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- 접수,실적,완료요청,완료            
            
 RETURN    
   