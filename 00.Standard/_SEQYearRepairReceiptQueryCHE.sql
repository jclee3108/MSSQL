
IF OBJECT_ID('_SEQYearRepairReceiptQueryCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairReceiptQueryCHE
GO 

-- v2015.07.01 
  
/************************************************************      
  설  명 - 데이터-연차보수작업 관리 : 조회      
  작성일 - 20110704      
  작성자 - 김수용      
 ************************************************************/      
 CREATE PROC [dbo].[_SEQYearRepairReceiptQueryCHE]      
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
    @WorkGubn     INT      
        
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      SELECT        
             @RepairYear     = RepairYear      ,      
             @Amd            = ISNULL(Amd , 0)            ,           
             @ReqDate        = ReqDate         ,           
             @FactUnit       = ISNULL(FactUnit, 0)        ,           
             @SectionSeq     = ISNULL(SectionSeq, 0)      ,      
             @WorkOperSeq    = ISNULL(WorkOperSeq, 0)     ,      
             @ProgType       = ISNULL(ProgType, 0)        ,      
             @DeptSeq        = ISNULL(DeptSeq, 0)         ,      
             @EmpSeq         = ISNULL(EmpSeq, 0)          ,      
             @ReqFrDate      = CASE WHEN ISNULL(ReqFrDate,'') ='' THEN  @RepairYear + '0101'  ELSE @ReqFrDate END    ,      
             @ReqToDate      = CASE WHEN ISNULL(ReqToDate,'') ='' THEN  @RepairYear + '1231'  ELSE @ReqToDate END    ,      
             @WorkGubn  = ISNULL(WorkGubn, 0)      
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
                    
   IF  @WorkingTag ='LIST'                -- 리스트 조회      
  BEGIN      
         GOTO LIST_QUERY              
  END      
  ELSE IF @WorkingTag ='WOQuery'         -- W/O 생성 조회      
  BEGIN      
         GOTO WOCREATE_QUERY      
  END       
  ELSE IF @WorkingTag ='RltQuery'         -- 실적 조회      
  BEGIN      
         GOTO RESULT_QUERY      
  END       
  ELSE IF @WorkingTag ='PLAN_LIST'         -- 계획현황 조회      
  BEGIN      
         GOTO PLAN_LIST      
  END       
  ELSE      
  BEGIN      
         GOTO MAJOR_QUERY      
  END      
        
         
        
 /**************************************************************************************************************************/      
  -- 기본조회      
 /**************************************************************************************************************************/      
  MAJOR_QUERY:      
  BEGIN       
        
     SELECT      
             A.ReqSeq          AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
               A.FactUnit        AS FactUnit,       
             C.SectionCode     AS SectionCode,      
  --           C.MinorName       AS SectionCode,      
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
             A.EmpSeq          AS EmpSeq      
        
       FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  LEFT OUTER JOIN _TDAFactUnit AS B WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = B.CompanySeq      
                                                        AND A.FactUnit     = B.FactUnit      
                                            LEFT OUTER JOIN _TPDSectionCodeCHE AS C WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = C.CompanySeq      
                                                        AND A.SectionSeq   = C.SectionSeq      
                                                       --JOIN _TDAUMinor AS C WITH (NOLOCK)      
                                                       --  ON 1 =1       
                                                       -- AND A.CompanySeq   = C.CompanySeq      
                                                       -- AND A.SectionSeq   = C.MinorSeq      
                                      LEFT OUTER      JOIN _TPDTool AS D WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = D.CompanySeq      
                                                        AND A.ToolSeq      = D.ToolSeq            
                                          LEFT OUTER JOIN _TDAUMinor AS E1 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E1.CompanySeq      
                                                        AND A.WorkOperSeq  = E1.MinorSeq      
                                          LEFT OUTER  JOIN _TDASMinor AS E2 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E2.CompanySeq      
                                                        AND A.WorkGubn     = E2.MinorSeq      
                                          LEFT OUTER   JOIN _TDAUMinor AS E3 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E3.CompanySeq      
                                                        AND A.ProgType     = E3.MinorSeq      
                                          LEFT OUTER   JOIN _TDADept AS F WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = F.CompanySeq      
                                                        AND A.DeptSeq      = F.DeptSeq       
                                         LEFT OUTER    JOIN _TDAEmp AS G WITH (NOLOCK)      
                       ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
          AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd  OR  @Amd = 0     )        
        AND (A.FactUnit      = @FactUnit   OR @FactUnit   = 0 )      
        AND (A.SectionSeq    = @SectionSeq OR @SectionSeq = 0 )      
        AND (@WorkOperSeq = 0 OR A.WorkOperSeq = @WorkOperSeq)      
          AND (@WorkGubn = 0 OR A.WorkGubn = @WorkGubn)      
        AND (@ProgType = 0 OR A.ProgType = @ProgType)      
        AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq=0 )      
        AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq=0 )             
               
    RETURN      
  END      
 /**************************************************************************************************************************/      
 -- 현황조회      
 /**************************************************************************************************************************/      
 LIST_QUERY:      
 BEGIN      
      SELECT      
             A.ReqSeq          AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
             A.FactUnit        AS FactUnit,      
             C.SectionCode     AS SectionCode,      
 --            C.MinorName       AS SectionCode,      
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
             A.EmpSeq          AS EmpSeq      
        
       FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  LEFT OUTER JOIN _TDAFactUnit AS B WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = B.CompanySeq      
                                                        AND A.FactUnit     = B.FactUnit      
                                         LEFT OUTER JOIN _TPDSectionCodeCHE AS C WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = C.CompanySeq      
                                                        AND A.SectionSeq   = C.SectionSeq      
                                                       --JOIN _TDAUMinor AS C WITH (NOLOCK)      
                                                       --  ON 1 =1       
                                                       -- AND A.CompanySeq   = C.CompanySeq      
                                                       -- AND A.SectionSeq   = C.MinorSeq      
                                      LEFT OUTER      JOIN _TPDTool AS D WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = D.CompanySeq      
                                                        AND A.ToolSeq      = D.ToolSeq            
                                          LEFT OUTER JOIN _TDAUMinor AS E1 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E1.CompanySeq      
                                                        AND A.WorkOperSeq  = E1.MinorSeq      
                                                       JOIN _TDASMinor AS E2 WITH (NOLOCK)      
                                                  ON 1 = 1      
                                                        AND A.CompanySeq   = E2.CompanySeq      
                                                        AND A.WorkGubn     = E2.MinorSeq      
                                          LEFT OUTER   JOIN _TDAUMinor AS E3 WITH (NOLOCK)      
                                                         ON 1 = 1      
   AND A.CompanySeq   = E3.CompanySeq      
                                                        AND A.ProgType     = E3.MinorSeq      
                                          LEFT OUTER   JOIN _TDADept AS F WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = F.CompanySeq      
                                                        AND A.DeptSeq      = F.DeptSeq       
                                       LEFT OUTER    JOIN _TDAEmp AS G WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
        AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd        )            
        AND (A.ReqDate       BETWEEN @ReqFrDate AND @ReqToDate   )      
        AND (A.FactUnit      = @FactUnit OR @FactUnit=0  )      
        AND (A.SectionSeq    = @SectionSeq )      
        AND (A.WorkOperSeq   = @WorkOperSeq )      
        AND (A.ProgType      = @ProgType  OR @ProgType=0 )      
        AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq=0 )      
        AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq=0 )      
         
              
               
    RETURN      
 END      
 /**************************************************************************************************************************/      
  -- W/O 생성 조회      
 /**************************************************************************************************************************/      
  WOCREATE_QUERY:      
  BEGIN       
        
     SELECT      
             A.ReqSeq          AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
             A.FactUnit        AS FactUnit,      
             C.SectionCode     AS SectionCode,      
  --           C.MinorName       AS SectionCode,      
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
A.EmpSeq          AS EmpSeq      
        
       FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  LEFT OUTER JOIN _TDAFactUnit AS B WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = B.CompanySeq      
                                                        AND A.FactUnit     = B.FactUnit      
                                           LEFT OUTER JOIN _TPDSectionCodeCHE AS C WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = C.CompanySeq      
                                                        AND A.SectionSeq   = C.SectionSeq      
                                                       --JOIN _TDAUMinor AS C WITH (NOLOCK)      
                                                       --  ON 1 =1       
                                                       -- AND A.CompanySeq   = C.CompanySeq      
                                                       -- AND A.SectionSeq   = C.MinorSeq      
                                        LEFT OUTER      JOIN _TPDTool AS D WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = D.CompanySeq      
                                                        AND A.ToolSeq      = D.ToolSeq            
                                         LEFT OUTER JOIN _TDAUMinor AS E1 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E1.CompanySeq      
                                                        AND A.WorkOperSeq  = E1.MinorSeq      
                                         LEFT OUTER JOIN _TDASMinor AS E2 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E2.CompanySeq      
                                                        AND A.WorkGubn     = E2.MinorSeq      
                                          LEFT OUTER   JOIN _TDAUMinor AS E3 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E3.CompanySeq      
                                                        AND A.ProgType     = E3.MinorSeq      
                                          LEFT OUTER   JOIN _TDADept AS F WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = F.CompanySeq      
                                                        AND A.DeptSeq      = F.DeptSeq       
                                         LEFT OUTER    JOIN _TDAEmp AS G WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
        AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd        OR @Amd      = 0  )            
        AND (A.FactUnit      = @FactUnit   OR @FactUnit = 0  )      
        AND (A.SectionSeq    = @SectionSeq OR @SectionSeq = 0)      
               
    RETURN      
  END      
  /**************************************************************************************************************************/      
 -- 년차보수 계획현황 조회( PLAN_LIST )      
 /**************************************************************************************************************************/      
 PLAN_LIST:      
 BEGIN      
      SELECT      
               A.ReqSeq          AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
             A.FactUnit        AS FactUnit,      
             C.SectionCode     AS SectionCode,      
 --            C.MinorName       AS SectionCode,      
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
             A.EmpSeq          AS EmpSeq      
        
       FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  LEFT OUTER JOIN _TDAFactUnit AS B WITH (NOLOCK)      
                                                           ON 1 = 1      
                                                        AND A.CompanySeq   = B.CompanySeq      
                                                        AND A.FactUnit     = B.FactUnit      
                                            LEFT OUTER JOIN _TPDSectionCodeCHE AS C WITH (NOLOCK)      
                                                           ON 1 = 1      
                                                        AND A.CompanySeq   = C.CompanySeq      
                                                        AND A.SectionSeq   = C.SectionSeq      
                                                       --JOIN _TDAUMinor AS C WITH (NOLOCK)      
                                                       --  ON 1 =1       
                                                       -- AND A.CompanySeq   = C.CompanySeq      
                              -- AND A.SectionSeq   = C.MinorSeq      
                                      LEFT OUTER      JOIN _TPDTool AS D WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = D.CompanySeq      
                                                        AND A.ToolSeq      = D.ToolSeq            
                                                       JOIN _TDAUMinor AS E1 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E1.CompanySeq      
                                                        AND A.WorkOperSeq  = E1.MinorSeq      
                                           LEFT OUTER JOIN _TDASMinor AS E2 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E2.CompanySeq      
                                                        AND A.WorkGubn     = E2.MinorSeq      
                                          LEFT OUTER   JOIN _TDAUMinor AS E3 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E3.CompanySeq      
                                                        AND A.ProgType     = E3.MinorSeq      
                                          LEFT OUTER   JOIN _TDADept AS F WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                          AND A.CompanySeq   = F.CompanySeq      
                                                        AND A.DeptSeq      = F.DeptSeq       
                                         LEFT OUTER    JOIN _TDAEmp AS G WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
        AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd  OR  @Amd = 0     )       
        AND (A.ReqDate       BETWEEN @ReqFrDate AND @ReqToDate   )      
        AND (A.FactUnit      = @FactUnit OR @FactUnit=0  )      
        AND (A.SectionSeq    = @SectionSeq OR @SectionSeq =0)      
          AND (A.WorkOperSeq   = @WorkOperSeq OR @WorkOperSeq=0)      
        AND (A.WorkGubn      = @WorkGubn    OR @WorkGubn = 0)      
        AND (A.ProgType      = @ProgType  OR @ProgType = 0 )      
        AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq = 0 )      
        AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq = 0 )      
     ORDER BY E2.MinorName, C.SectionCode, A.WorkContents   -- 생산계획조회시 정렬 순서 추가 by ZOO 2012.3.22      
         
              
               
    RETURN      
 END      
        
        
        
  /**************************************************************************************************************************/      
  -- 실적조회      
 /**************************************************************************************************************************/      
  RESULT_QUERY:      
  BEGIN       
        
     SELECT      
               A.ReqSeq           AS ReqSeq,      
             A.RepairYear      AS RepairYear,      
             A.Amd             AS Amd,      
             A.ReqDate         AS ReqDate,      
             B.FactUnitName    AS FactUnitName,      
                   
             A.FactUnit        AS FactUnit,      
             C.SectionCode     AS SectionCode,      
  --           C.MinorName       AS SectionCode,      
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
             A.EmpSeq          AS EmpSeq      
        
       FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK) LEFT OUTER JOIN _TDAFactUnit AS B WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = B.CompanySeq      
                                                        AND A.FactUnit     = B.FactUnit      
                                            LEFT OUTER JOIN _TPDSectionCodeCHE AS C WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = C.CompanySeq      
                                                        AND A.SectionSeq   = C.SectionSeq      
                                                       --JOIN _TDAUMinor AS C WITH (NOLOCK)      
                                                       --  ON 1 =1       
                                                         --  AND A.CompanySeq   = C.CompanySeq      
                                                       -- AND A.SectionSeq   = C.MinorSeq      
                                      LEFT OUTER      JOIN _TPDTool AS D WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = D.CompanySeq      
                                                        AND A.ToolSeq      = D.ToolSeq            
                                          LEFT OUTER  JOIN _TDAUMinor AS E1 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E1.CompanySeq      
                                                        AND A.WorkOperSeq  = E1.MinorSeq      
                                          LEFT OUTER JOIN _TDASMinor AS E2 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                AND A.CompanySeq   = E2.CompanySeq      
                                                        AND A.WorkGubn     = E2.MinorSeq      
                                          LEFT OUTER   JOIN _TDAUMinor AS E3 WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = E3.CompanySeq      
                                                        AND A.ProgType     = E3.MinorSeq      
                                          LEFT OUTER   JOIN _TDADept AS F WITH (NOLOCK)      
                                                         ON 1 = 1      
                                                        AND A.CompanySeq   = F.CompanySeq      
                                                        AND A.DeptSeq      = F.DeptSeq       
                                         LEFT OUTER    JOIN _TDAEmp AS G WITH (NOLOCK)      
                                                ON 1 = 1      
                                                        AND A.CompanySeq   = G.CompanySeq      
                                                        AND A.EmpSeq       = G.EmpSeq      
      WHERE 1 = 1      
        AND (A.CompanySeq    = @CompanySeq )      
        AND (A.RepairYear    = @RepairYear )      
        AND (A.Amd           = @Amd  OR  @Amd = 0     )            
        AND (A.ReqDate       BETWEEN @ReqFrDate AND @ReqToDate   )      
        AND (A.FactUnit      = @FactUnit OR @FactUnit = 0  )      
        AND (A.SectionSeq    = @SectionSeq OR @SectionSeq = 0)      
        AND (A.WorkOperSeq   = @WorkOperSeq OR @WorkOperSeq = 0)      
        AND (A.ProgType      = @ProgType  OR @ProgType = 0 )      
        AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq = 0 )      
        AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq = 0 )      
        AND (A.WorkGubn      = @WorkGubn    OR @WorkGubn = 0)      
        AND  A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- 접수,실적,완료요청,완료      
    RETURN      
    END     