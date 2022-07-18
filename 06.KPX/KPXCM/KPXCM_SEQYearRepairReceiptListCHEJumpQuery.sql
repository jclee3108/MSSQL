  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptListCHEJumpQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptListCHEJumpQuery  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수조회-점프조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptListCHEJumpQuery  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegItemCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReceiptRegItemCHE'   
    IF @@ERROR <> 0 RETURN     
    
    IF EXISTS (SELECT 1 
                 FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
                 JOIN KPXCM_TEQYearRepairResultRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = A.ReceiptRegSeq AND B.ReceiptRegSerl = A.ReceiptRegSerl ) 
              )
    BEGIN
        SELECT '이미 진행된 데이터가 존재합니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
    END 
    ELSE 
    BEGIN 
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
               O.MngValText AS ToolKindName, 
               P.MngValText AS ProtectLevelName, 
               C.WONo, 
               0 AS Status 
               
          FROM #KPXCM_TEQYearRepairReceiptRegItemCHE            AS Z 
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
          LEFT OUTER JOIN _TDAUMinor                            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = B.ProgType ) 
          LEFT OUTER JOIN _TDAEmp                               AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                              AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TPDToolUserDefine                     AS O ON ( O.CompanySeq = @CompanySeq AND O.ToolSeq = F.ToolSeq AND O.MngSerl = 1000001 )
          LEFT OUTER JOIN _TPDToolUserDefine                     AS P ON ( P.CompanySeq = @CompanySeq AND P.ToolSeq = F.ToolSeq AND P.MngSerl = 1000002 )
    END 
    
    RETURN  
GO

EXEC KPXCM_SEQYearRepairReceiptListCHEJumpQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReceiptRegSeq>2</ReceiptRegSeq>
    <ReceiptRegSerl>1</ReceiptRegSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReceiptRegSeq>2</ReceiptRegSeq>
    <ReceiptRegSerl>2</ReceiptRegSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReceiptRegSeq>2</ReceiptRegSeq>
    <ReceiptRegSerl>3</ReceiptRegSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReceiptRegSeq>2</ReceiptRegSeq>
    <ReceiptRegSerl>4</ReceiptRegSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReceiptRegSeq>2</ReceiptRegSeq>
    <ReceiptRegSerl>5</ReceiptRegSerl>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1030880, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1025766
