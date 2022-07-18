
IF OBJECT_ID('KPX_SEQYearRepairReceiptRegListCHEQuery') IS NOT NULL 
    DROP PROC KPX_SEQYearRepairReceiptRegListCHEQuery
GO

-- v2014.12.11 

-- 작업접수조회(연차보수) by이재천
 CREATE PROC KPX_SEQYearRepairReceiptRegListCHEQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle         INT,
            @RepairYear        NCHAR(4),
            @Amd               INT,
            @FactUnit          INT,
            @WorkOperSeq       INT,
            @ProgType          INT,
            @DeptSeq           INT,
            @EmpSeq            INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    
    SELECT  @RepairYear        = ISNULL(RepairYear  , ''), 
            @Amd               = ISNULL(Amd         , 0), 
            @FactUnit          = ISNULL(FactUnit    , 0), 
            @WorkOperSeq       = ISNULL(WorkOperSeq , 0), 
            @ProgType          = ISNULL(ProgType    , 0), 
            @DeptSeq           = ISNULL(DeptSeq     , 0), 
            @EmpSeq            = ISNULL(EmpSeq      , 0) 
    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (
                RepairYear        NCHAR(4), 
                Amd               INT,
                FactUnit          INT,
                WorkOperSeq       INT,
                ProgType          INT,
                DeptSeq           INT,
                EmpSeq            INT 
            )
    
     SELECT A.ReqSeq          AS ReqSeq,
            A.RepairYear      AS RepairYear,
            A.Amd             AS Amd,
            A.ReqDate         AS ReqDate,
            B.FactUnitName    AS FactUnitName,
            
            A.FactUnit        AS FactUnit,
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
    
      FROM _TEQYearRepairMngCHE     AS A  
      LEFT OUTER JOIN _TDAFactUnit  AS B ON ( B.CompanySeq = @CompanySeq AND A.FactUnit = B.FactUnit ) 
      LEFT OUTER JOIN _TPDTool      AS D ON ( D.CompanySeq = @CompanySeq AND A.ToolSeq = D.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS E1 ON ( E1.CompanySeq = @CompanySeq AND A.WorkOperSeq = E1.MinorSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS E2 ON ( E2.CompanySeq = @CompanySeq AND A.WorkGubn = E2.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS E3 ON ( E3.CompanySeq = @CompanySeq AND A.ProgType = E3.MinorSeq ) 
      LEFT OUTER JOIN _TDADept      AS F ON ( F.CompanySeq = @CompanySeq AND A.DeptSeq = F.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS G ON ( G.CompanySeq = @CompanySeq AND A.EmpSeq = G.EmpSeq ) 
     WHERE (A.CompanySeq    = @CompanySeq )
       AND (A.RepairYear    = @RepairYear )
       AND (A.Amd           = @Amd  OR  @Amd = 0 )  
       AND (A.FactUnit      = @FactUnit   OR @FactUnit   = 0 )
       AND (@WorkOperSeq = 0 OR A.WorkOperSeq = @WorkOperSeq)
       AND (@ProgType = 0 OR A.ProgType = @ProgType)
       AND (A.DeptSeq       = @DeptSeq   OR @DeptSeq=0 )
       AND (A.EmpSeq        = @EmpSeq    OR @EmpSeq=0 )       
    
    RETURN
    
 GO 
 exec KPX_SEQYearRepairReceiptRegListCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RepairYear>2014</RepairYear>
    <Amd />
    <FactUnit />
    <EmpSeq />
    <DeptSeq />
    <WorkOperSeq />
    <ProgType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026682,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021371