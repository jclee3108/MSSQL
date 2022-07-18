  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHEItemQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHEItemQuery  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-디테일조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHEItemQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ResultSeq  INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ResultSeq   = ISNULL( ResultSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ResultSeq   INT)    
    
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
           C.WONo 
           
           
      FROM KPXCM_TEQYearRepairResultRegItemCHE              AS Z 
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
     WHERE ( Z.CompanySeq = @CompanySeq ) 
       AND ( Z.ResultSeq = @ResultSeq )  
    
    
    RETURN  
GO 
exec KPXCM_SEQYearRepairResultRegCHEItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ResultSeq>1</ResultSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'RltQuery',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775
