  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptListCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptListCHEQuery  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수조회-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptListCHEQuery  
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
    
    DECLARE @docHandle          INT,  
            -- 조회조건   
            @FactUnit           INT,  
            @RepairYear         NCHAR(4), 
            @AmdSeq             INT, 
            @EmpSeq             INT, 
            @DeptSeq            INT, 
            @WorkGubn           INT, 
            @WorkOperSeq        INT, 
            @ProgType           INT, 
            @ReceiptRegDateFr   NCHAR(8), 
            @ReceiptRegDateTo   NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT  @FactUnit         = ISNULL( FactUnit        , 0 ),  
            @RepairYear       = ISNULL( RepairYear      , '' ),  
            @AmdSeq           = ISNULL( AmdSeq          , 0 ),  
            @EmpSeq           = ISNULL( EmpSeq          , 0 ),  
            @DeptSeq          = ISNULL( DeptSeq         , 0 ), 
            @WorkGubn         = ISNULL( WorkGubn        , 0 ),  
            @WorkOperSeq      = ISNULL( WorkOperSeq     , 0 ),  
            @ProgType         = ISNULL( ProgType        , 0 ),  
            @ReceiptRegDateFr = ISNULL( ReceiptRegDateFr, '' ),  
            @ReceiptRegDateTo = ISNULL( ReceiptRegDateTo, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit           INT,  
            RepairYear         NCHAR(4),       
            AmdSeq             INT,       
            EmpSeq             INT,       
            DeptSeq            INT, 
            WorkGubn           INT,       
            WorkOperSeq        INT,       
            ProgType           INT,       
            ReceiptRegDateFr   NCHAR(8),       
            ReceiptRegDateTo   NCHAR(8)      
           )
    
    IF @ReceiptRegDateTo = '' SELECT @ReceiptRegDateTo = '99991231' 
    
    
    -- 최종조회   
    SELECT E.FactUnit, 
           K.FactUnitName, 
           E.RepairYear, 
           E.Amd, 
           D.ReqDate, 
           E.ReceiptFrDate, 
           E.ReceiptToDate,
           E.RepairFrDate, 
           E.RepairToDate, 
           A.ReceiptRegDate, 
           A.EmpSeq, 
           M.EmpName, 
           A.DeptSeq, 
           N.DeptName, 
           C.ToolSeq, 
           F.ToolName, 
           F.ToolNo, 
           C.WorkOperSeq, 
           G.MinorName AS WorkOperName, 
           C.WorkGubn, 
           H.MinorName AS WorkGubnName, 
           C.WorkContents, 
           B.ProgType, 
           L.MinorName AS ProgTypeName, 
           B.RtnReason, 
           D.EmpSeq AS ReqEmpSeq, 
           I.EmpName AS ReqEmpName, 
           D.DeptSeq AS ReqDeptSeq, 
           J.DeptName AS ReqDeptName, 
           B.ReceiptRegSeq, 
           B.ReceiptRegSerl, 
           C.ReqSeq, 
           C.ReqSerl, 
           C.WONo
           
      FROM KPXCM_TEQYearRepairReceiptRegCHE                 AS A 
                 JOIN KPXCM_TEQYearRepairReceiptRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = A.ReceiptRegSeq ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegItemCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegCHE          AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = C.ReqSeq ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE          AS E ON ( E.CompanySeq = @CompanySeq AND E.RepairSeq = D.RepairSeq ) 
      LEFT OUTER JOIN _TPDTool                              AS F ON ( F.CompanySeq = @CompanySeq AND F.ToolSeq = C.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAUMinor                            AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = C.WorkGubn ) 
      LEFT OUTER JOIN _TDAEmp                               AS I ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                              AS J ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = D.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                          AS K ON ( K.CompanySeq = @CompanySeq AND K.FactUnit = E.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor                            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = B.ProgType ) 
      LEFT OUTER JOIN _TDAEmp                               AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                              AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = A.DeptSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( @FactUnit = 0 OR E.FactUnit = @FactUnit ) 
       AND ( @RepairYear = '' OR E.RepairYear = @RepairYear ) 
       AND ( @AmdSeq = 0 OR E.Amd = @AmdSeq ) 
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @WorkGubn = 0 OR C.WorkGubn = @WorkGubn ) 
       AND ( @ProgType = 0 OR B.ProgType = @ProgType ) 
       AND ( @WorkOperSeq = 0 OR C.WorkOperSeq = @WorkOperSeq ) 
       AND ( A.ReceiptRegDate BETWEEN @ReceiptRegDateFr AND @ReceiptRegDateTo ) 
      
    RETURN  
GO
exec KPXCM_SEQYearRepairReceiptListCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RepairYear>2015</RepairYear>
    <AmdSeq />
    <FactUnit>1</FactUnit>
    <WorkOperSeq />
    <ProgType />
    <DeptSeq />
    <EmpSeq />
    <WorkGubn />
    <ReceiptRegDateFr />
    <ReceiptRegDateTo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030880,@WorkingTag=N'LIST',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025766