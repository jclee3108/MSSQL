  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHEQuery  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청등록-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqRegCHEQuery  
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
            @ReqSeq     INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReqSeq   = ISNULL( ReqSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ReqSeq   INT)    
    
    -- 최종조회   
    SELECT B.FactUnit, 
           C.FactUnitName, 
           B.Amd, 
           B.Amd AS AmdSeq, 
           B.RepairYear, 
           B.RepairYear AS RepairYearSeq, 
           A.ReqDate, 
           A.EmpSeq, 
           D.EmpName, 
           A.DeptSeq, 
           E.DeptName, 
           B.RepairFrDate, 
           B.RepairToDate, 
           B.ReceiptFrDate, 
           B.ReceiptToDate, 
           A.ReqSeq, 
           A.RepairSeq
      FROM KPXCM_TEQYearRepairReqRegCHE             AS A 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.RepairSeq = A.RepairSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                  AS C ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = B.FactUnit ) 
      LEFT OUTER JOIN _TDAEmp                       AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                      AS E ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReqSeq = @ReqSeq 
      
    RETURN  
GO 
exec KPXCM_SEQYearRepairReqRegCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReqSeq>3</ReqSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722