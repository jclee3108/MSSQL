  
IF OBJECT_ID('KPXCM_SEQYearRepairResultListCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultListCHEQuery  
GO  
  
-- v2015.07.18  
  
-- 연차보수실적조회-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultListCHEQuery  
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
            @DeptSeq        INT, 
            @ProtectKind    INT, 
            @FactUnit       INT, 
            @Amd            INT, 
            @RepairYear     NCHAR(4), 
            @ProtectLevel   INT, 
            @WorkReason     INT, 
            @PreProtect     INT, 
            @ProgType       INT, 
            @EmpSeq         INT, 
            @ResultDateFr   NCHAR(8), 
            @ResultDateTo   NCHAR(8), 
            @ToolKindName   NVARCHAR(100), 
            @ToolName       NVARCHAR(100), 
            @ToolNo         NVARCHAR(100), 
            @WONo           NVARCHAR(100), 
            @WorkGubn       INT, 
            @WorkOperSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DeptSeq          = ISNULL( DeptSeq     , 0 ),  
           @ProtectKind      = ISNULL( ProtectKind , 0 ),  
           @FactUnit         = ISNULL( FactUnit    , 0 ),  
           @Amd              = ISNULL( Amd         , 0 ),  
           @RepairYear       = ISNULL( RepairYear  , '' ),  
           @ProtectLevel     = ISNULL( ProtectLevel, 0 ),  
           @WorkReason       = ISNULL( WorkReason  , 0 ),  
           @PreProtect       = ISNULL( PreProtect  , 0 ),  
           @ProgType         = ISNULL( ProgType    , 0 ),  
           @EmpSeq           = ISNULL( EmpSeq      , 0 ),  
           @ResultDateFr     = ISNULL( ResultDateFr, '' ),  
           @ResultDateTo     = ISNULL( ResultDateTo, '' ),  
           @ToolKindName     = ISNULL( ToolKindName, '' ),  
           @ToolName         = ISNULL( ToolName    , '' ),  
           @ToolNo           = ISNULL( ToolNo      , '' ),  
           @WONo             = ISNULL( WONo        , '' ),  
           @WorkGubn         = ISNULL( WorkGubn    , 0 ),  
           @WorkOperSeq      = ISNULL( WorkOperSeq , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DeptSeq        INT, 
            ProtectKind    INT, 
            FactUnit       INT, 
            Amd            INT, 
            RepairYear     NCHAR(4), 
            ProtectLevel   INT, 
            WorkReason     INT, 
            PreProtect     INT, 
            ProgType       INT, 
            EmpSeq         INT, 
            ResultDateFr   NCHAR(8), 
            ResultDateTo   NCHAR(8), 
            ToolKindName   NVARCHAR(100),
            ToolName       NVARCHAR(100),
            ToolNo         NVARCHAR(100),
            WONo           NVARCHAR(100),
            WorkGubn       INT, 
            WorkOperSeq    INT 
           )    
    
    IF @ResultDateTo = '' SELECT @ResultDateTo = '99991231'
    
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
           A.ReceiptRegDate AS ReceiptDate, 
           A.EmpSeq AS ReceiptEmpSeq, 
           M.EmpName AS ReceiptEmpName, 
           A.DeptSeq AS ReceiptDeptSeq, 
           N.DeptName AS ReceiptDeptName, 
           C.ToolSeq, 
           F.ToolName, 
           F.ToolNo, 
           C.WorkOperSeq, 
           G.MinorName AS WorkOperName, 
           C.WorkGubn, 
           H.MinorName AS WorkGubnName, 
           C.WorkContents, 
           Z.ProgType, 
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
           O.MngValText AS ToolKindName, 
           P.MngValText AS ProtectLevelName, 
           Z.UMProtectKind AS ProtectKind, 
           Q.MinorName AS ProtectKindName, 
           Z.UMWorkReason AS WorkReason, 
           R.MinorName AS WorkReasonName, 
           Z.UMPreProtect AS PreProtect, 
           S.MinorName AS PreProtectName, 
           Z.Remark, 
           Z.FileSeq, 
           Z.ResultSeq, 
           Z.ResultSerl, 
           X.EmpSeq, 
           U.EmpName, 
           X.DeptSeq, 
           T.DeptName, 
           X.ResultDate, 
           C.WONo
           
           
           
      FROM KPXCM_TEQYearRepairResultRegItemCHE              AS Z 
                 JOIN KPXCM_TEQYearRepairResultRegCHE       AS X ON ( X.CompanySeq = @CompanySeq AND X.ResultSeq = Z.ResultSeq ) 
                 JOIN KPXCM_TEQYearRepairReceiptRegCHE      AS A ON ( A.CompanySeq = @CompanySeq AND A.ReceiptRegSeq = Z.ReceiptRegSeq ) 
                 JOIN KPXCM_TEQYearRepairReceiptRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = Z.ReceiptRegSeq AND B.ReceiptRegSerl = Z.ReceiptRegSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegItemCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegCHE          AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = C.ReqSeq ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE          AS E ON ( E.CompanySeq = @CompanySeq AND E.RepairSeq = D.RepairSeq ) 
      LEFT OUTER JOIN _TPDTool                              AS F ON ( F.CompanySeq = @CompanySeq AND F.ToolSeq = C.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAUMinor                            AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = C.WorkGubn ) 
      LEFT OUTER JOIN _TDAEmp                               AS I ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                              AS J ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = D.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                          AS K ON ( K.CompanySeq = @CompanySeq AND K.FactUnit = E.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor                            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = Z.ProgType ) 
      LEFT OUTER JOIN _TDAEmp                               AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                              AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TPDToolUserDefine                     AS O ON ( O.CompanySeq = @CompanySeq AND O.ToolSeq = F.ToolSeq AND O.MngSerl = 1000001 )
      LEFT OUTER JOIN _TPDToolUserDefine                     AS P ON ( P.CompanySeq = @CompanySeq AND P.ToolSeq = F.ToolSeq AND P.MngSerl = 1000002 )
      LEFT OUTER JOIN _TDAUMinor                            AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.UMProtectKind ) 
      LEFT OUTER JOIN _TDAUMinor                            AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = Z.UMWorkReason ) 
      LEFT OUTER JOIN _TDAUMinor                            AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = Z.UMPreProtect ) 
      LEFT OUTER JOIN _TDADept                              AS T ON ( T.CompanySeq = @CompanySeq AND T.DeptSeq = X.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp                               AS U ON ( U.CompanySeq = @CompanySeq AND U.EmpSeq = X.EmpSeq ) 
     WHERE ( Z.CompanySeq = @CompanySeq ) 
       AND ( @DeptSeq = 0 OR X.DeptSeq = @DeptSeq ) 
       AND ( @EmpSeq = 0 OR X.EmpSeq = @EmpSeq ) 
       AND ( @ProtectKind = 0 OR Z.UMProtectKind = @ProtectKind ) 
       AND ( @FactUnit = 0 OR E.FactUnit = @FactUnit ) 
       AND ( @Amd = 0 OR E.Amd = @Amd ) 
       AND ( @RepairYear = '' OR E.RepairYear = @RepairYear ) 
       AND ( @ProtectKind = 0 OR Z.UMProtectKind = @ProtectKind ) 
       AND ( @WorkReason = 0 OR Z.UMWorkReason = @WorkReason ) 
       AND ( @PreProtect = 0 OR Z.UMPreProtect = @PreProtect ) 
       AND ( @ProgType = 0 OR Z.ProgType = @ProgType ) 
       AND ( X.ResultDate BETWEEN @ResultDateFr AND @ResultDateTo ) 
       AND ( @ToolKindName = '' OR O.MngValText LIKE @ToolKindName + '%' ) 
       AND ( @ToolName = '' OR F.ToolName LIKE @ToolName + '%' ) 
       AND ( @ToolNo = '' OR F.ToolNo LIKE @ToolNo + '%' ) 
       --AND ( @WONo = '' OR O.MngValText LIKE @ToolKindName + '%' ) 
       AND ( @WorkGubn = 0 OR C.WorkGubn = @WorkGubn ) 
       AND ( @WorkOperSeq = 0 OR C.WorkOperSeq = @WorkOperSeq ) 
    
    RETURN  
GO
exec KPXCM_SEQYearRepairResultListCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd />
    <ResultDateFr />
    <ResultDateTo />
    <ProgType />
    <WorkOperSeq />
    <WorkGubn />
    <EmpSeq />
    <DeptSeq />
    <ToolName>가공3호기sssss</ToolName>
    <ToolNo />
    <WONo />
    <ProtectKind />
    <WorkReason />
    <PreProtect />
    <ToolKindName />
    <ProtectLevel />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030938,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025807
