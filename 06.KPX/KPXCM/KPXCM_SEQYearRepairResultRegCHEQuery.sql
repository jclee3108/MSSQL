  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHEQuery  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHEQuery  
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
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ResultSeq   INT)    
    
    -- 최종조회   
    SELECT A.ResultDate, 
           A.EmpSeq, 
           A.DeptSeq, 
           B.EmpName, 
           C.DeptName, 
           A.ResultSeq 
      FROM KPXCM_TEQYearRepairResultRegCHE  AS A 
      LEFT OUTER JOIN _TDAEmp               AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept              AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.ResultSeq = @ResultSeq )   
      
    RETURN  
GO 
exec KPXCM_SEQYearRepairResultRegCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ResultSeq>1</ResultSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'RltQuery',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775