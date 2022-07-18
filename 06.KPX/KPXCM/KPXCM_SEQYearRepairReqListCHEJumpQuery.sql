  
IF OBJECT_ID('KPXCM_SEQYearRepairReqListCHEJumpQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqListCHEJumpQuery  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청조회-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqListCHEJumpQuery  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairReqRegCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReqRegCHE'   
    IF @@ERROR <> 0 RETURN    
    

    
    IF EXISTS (SELECT 1 
                 FROM #KPXCM_TEQYearRepairReqRegCHE AS A 
                 JOIN KPXCM_TEQYearRepairReceiptRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
              )
    BEGIN
        SELECT '이미 진행된 데이터가 존재합니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
    END 
    ELSE 
    BEGIN 
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
               --B.ProgType, 
               --G.MinorName AS ProgTypeName, 
               A.EmpSeq, 
               H.EmpName, 
               A.DeptSeq, 
               I.DeptName, 
               C.FactUnit, 
               J.FactUnitName, 
               B.WONo, 
               0 AS Status 
        
          FROM #KPXCM_TEQYearRepairReqRegCHE                AS M 
                     JOIN KPXCM_TEQYearRepairReqRegCHE      AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = M.ReqSeq ) 
                     JOIN KPXCM_TEQYearRepairReqRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = M.ReqSeq AND B.ReqSerl = M.ReqSerl ) 
          LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.RepairSeq = A.RepairSeq ) 
          LEFT OUTER JOIN _TPDTool                          AS D ON ( D.CompanySeq = @CompanySeq AND D.ToolSeq = B.ToolSeq ) 
          LEFT OUTER JOIN _TDAUMinor                        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = B.WorkOperSeq ) 
          LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.WorkGubn ) 
          LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.ProgType ) 
          LEFT OUTER JOIN _TDAEmp                           AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                          AS I ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDAFactUnit                      AS J ON ( J.CompanySeq = @CompanySeq AND J.FactUnit = C.FactUnit ) 
    END 
    
    RETURN  
GO
exec KPXCM_SEQYearRepairReqListCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqSeq>10</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqSeq>10</ReqSeq>
    <ReqSerl>2</ReqSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030849,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025734