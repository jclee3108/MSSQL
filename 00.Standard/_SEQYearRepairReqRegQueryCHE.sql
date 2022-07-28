IF OBJECT_ID('_SEQYearRepairReqRegQueryCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairReqRegQueryCHE
GO 

-- v2015.07.01 
/************************************************************  
   설  명 - 데이터-연차보수작업요청 : 조회  
   작성일 - 20110623  
   작성자 - 김수용  
  ************************************************************/  
  CREATE PROC [dbo].[_SEQYearRepairReqRegQueryCHE]  
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
              @WorkGubn     INT,  
              @ProgType          INT,  
              @DeptSeq           INT,  
              @EmpSeq            INT,  
              @ReqFrDate         NCHAR(8),  
              @ReqToDate         NCHAR(8)   
       EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
       SELECT    
              @RepairYear     = RepairYear      ,  
              @Amd            = Amd             ,       
              @ReqDate        = ReqDate         ,       
              @FactUnit       = FactUnit        ,       
              @SectionSeq     = SectionSeq      ,  
              @WorkOperSeq    = ISNULL(WorkOperSeq,0)     ,  
              @WorkGubn  = ISNULL(WorkGubn, 0),  
              @ProgType       = ProgType        ,  
              @DeptSeq        = DeptSeq         ,  
              @EmpSeq         = EmpSeq          ,  
              @ReqFrDate      = CASE WHEN ISNULL(ReqFrDate,'') ='' THEN  @RepairYear + '0101'  ELSE @ReqFrDate END    ,  
              @ReqToDate      = CASE WHEN ISNULL(ReqToDate,'') ='' THEN  @RepairYear + '1231'  ELSE @ReqToDate END       
        FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
        WITH  (RepairYear         NCHAR(4),   
               Amd                INT,  
               ReqDate            NCHAR(8),  
               FactUnit           INT,  
               SectionSeq         INT,  
               WorkOperSeq        INT,  
               WorkGubn   INT,  
               ProgType           INT,  
               DeptSeq            INT,  
               EmpSeq             INT,  
               ReqFrDate          NCHAR(8),  
               ReqToDate          NCHAR(8))  
                 
     
      
     
   IF  @WorkingTag ='LIST'   
   BEGIN  
          GOTO LIST_QUERY          
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
       --       C.MinorName       AS SectionCode,  
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
                A.WONo            AS WONo,  
              F.DeptName        AS DeptName,  
                
  A.DeptSeq         AS DeptSeq,  
              G.EmpName         AS EmpName,  
              A.EmpSeq       AS EmpSeq  
  
        FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  JOIN _TDAFactUnit AS B WITH (NOLOCK)  
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
         AND (A.Amd           = @Amd        )        
         AND (@ReqDate     ='' OR A.ReqDate     = @ReqDate)  
         AND (A.FactUnit      = @FactUnit   )  
         AND (A.SectionSeq    = @SectionSeq )  
         AND (@WorkOperSeq = 0 OR A.WorkOperSeq = @WorkOperSeq)  
         AND (@WorkGubn    = 0 OR A.WorkGubn    = @WorkGubn)  
            
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
              A.WONo            AS WONo,  
              F.DeptName        AS DeptName,  
                
              A.DeptSeq         AS DeptSeq,  
              G.EmpName         AS EmpName,  
              A.EmpSeq          AS EmpSeq  
         FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)  JOIN _TDAFactUnit AS B WITH (NOLOCK)  
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
         AND (A.Amd           = @Amd OR @Amd = 0)        
         AND (A.ReqDate       BETWEEN @ReqFrDate AND @ReqToDate)  
         AND (A.FactUnit      = @FactUnit OR @FactUnit=''  )  
         AND (A.SectionSeq    = @SectionSeq OR @SectionSeq = 0)  
         AND (@WorkOperSeq = 0 OR A.WorkOperSeq = @WorkOperSeq)  
         AND (@WorkGubn    = 0 OR A.WorkGubn    = @WorkGubn)  
         AND (A.ProgType      = @ProgType  OR @ProgType='' )  
         AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq='' )  
         AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq='' )  
   ORDER BY A.Amd, A.ReqDate  
     
           
            
     RETURN  
  END  
    