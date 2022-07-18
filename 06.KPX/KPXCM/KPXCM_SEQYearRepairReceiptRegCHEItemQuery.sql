  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEItemQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEItemQuery  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-디테일조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEItemQuery  
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
            @ReceiptRegSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReceiptRegSeq   = ISNULL( ReceiptRegSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ReceiptRegSeq   INT)    
    
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
           A.EmpSeq, 
           H.EmpName, 
           A.DeptSeq, 
           I.DeptName, 
           C.FactUnit, 
           M.ReceiptRegSeq, 
           M.ReceiptRegSerl, 
           M.ProgType, 
           K.MinorName AS ProgTypeName, 
           M.RtnReason, 
           ISNULL(L.ValueText,'0') AS IsRtnReason, 
           B.WONo
      FROM KPXCM_TEQYearRepairReceiptRegItemCHE         AS M 
                 JOIN KPXCM_TEQYearRepairReqRegCHE      AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = M.ReqSeq ) 
                 JOIN KPXCM_TEQYearRepairReqRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = M.ReqSeq AND B.ReqSerl = M.ReqSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.RepairSeq = A.RepairSeq ) 
      LEFT OUTER JOIN _TPDTool                          AS D ON ( D.CompanySeq = @CompanySeq AND D.ToolSeq = B.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = B.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.WorkGubn ) 
      LEFT OUTER JOIN _TDAEmp                           AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                          AS I ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                      AS J ON ( J.CompanySeq = @CompanySeq AND J.FactUnit = C.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor                        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = M.ProgType ) 
      LEFT OUTER JOIN _TDAUMinorValue                   AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.MinorSeq AND L.Serl = 1000007 ) 
     WHERE ( M.CompanySeq = @CompanySeq ) 
       AND ( M.ReceiptRegSeq = @ReceiptRegSeq ) 
    
    RETURN  
GO
exec KPXCM_SEQYearRepairReceiptRegCHEItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReceiptRegSeq>2</ReceiptRegSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743