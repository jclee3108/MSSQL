  
IF OBJECT_ID('KPXCM_SEQYearRepairReqListCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqListCHEQuery  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청조회-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqListCHEQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @FactUnit       INT,  
            @EmpSeq         INT,  
            @WorkOperSeq    INT,  
            @WorkGubn       INT,  
            @DeptSeq        INT,  
            @ProgType       INT,  
            @RepairYear     INT,  
            @Amd            INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit       = ISNULL( FactUnit      , 0 ), 
           @EmpSeq         = ISNULL( EmpSeq        , 0 ), 
           @WorkOperSeq    = ISNULL( WorkOperSeq   , 0 ), 
           @WorkGubn       = ISNULL( WorkGubn      , 0 ), 
           @DeptSeq        = ISNULL( DeptSeq       , 0 ), 
           @ProgType       = ISNULL( ProgType      , 0 ), 
           @RepairYear     = ISNULL( RepairYear    , 0 ), 
           @Amd            = ISNULL( Amd           , 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,
            EmpSeq         INT,
            WorkOperSeq    INT,
            WorkGubn       INT,
            DeptSeq        INT,
            ProgType       INT,
            RepairYear     INT,
            Amd            INT
           )    
    
    -- 최종조회   
    SELECT A.ReqSeq, 
           B.ReqSerl, 
           C.RepairYear, 
           C.Amd, 
           A.ReqDate, 
           C.ReceiptFrDate, 
           C.ReceiptToDate,
           C.RepairFrDate, 
           C.RepairToDate, 
           B.ToolSeq, 
           D.ToolName, 
           D.ToolNo, 
           B.WorkOperSeq, 
           E.MinorName AS WorkOperName, 
           B.WorkGubn, 
           F.MinorName AS WorkGubnName, 
           B.WorkContents, 
           B.ProgType, 
           G.MinorName AS ProgTypeName, 
           A.EmpSeq, 
           H.EmpName, 
           A.DeptSeq, 
           I.DeptName, 
           C.FactUnit, 
           J.FactUnitName, 
           B.WONo
           
           
      FROM KPXCM_TEQYearRepairReqRegCHE                 AS A 
                 JOIN KPXCM_TEQYearRepairReqRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.RepairSeq = A.RepairSeq ) 
      LEFT OUTER JOIN _TPDTool                          AS D ON ( D.CompanySeq = @CompanySeq AND D.ToolSeq = B.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = B.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.WorkGubn ) 
      LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.ProgType ) 
      LEFT OUTER JOIN _TDAEmp                           AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                          AS I ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                      AS J ON ( J.CompanySeq = @CompanySeq AND J.FactUnit = C.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR C.FactUnit = @FactUnit ) 
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq ) 
       AND ( @DeptSEq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @WorkOperSeq = 0 OR B.WorkOperSeq = @WorkOperSeq ) 
       AND ( @WorkGubn = 0 OR B.WorkGubn = @WorkGubn ) 
       AND ( @ProgType = 0 OR B.ProgType = @ProgType ) 
       AND ( @RepairYear = 0 OR C.RepairYear = @RepairYear ) 
       AND ( @Amd = 0 OR C.Amd = @Amd ) 
    
    RETURN  