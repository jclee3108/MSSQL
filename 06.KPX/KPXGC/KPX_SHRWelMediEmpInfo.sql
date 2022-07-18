  
IF OBJECT_ID('KPX_SHRWelMediEmpInfo') IS NOT NULL   
    DROP PROC KPX_SHRWelMediEmpInfo  
GO  
  
-- v2014.12.02  
  
-- 의료비신청-사원정보 by 이재천   
CREATE PROC KPX_SHRWelMediEmpInfo  
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
            @EmpSeq     INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @EmpSeq   = ISNULL( EmpSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (EmpSeq   INT)    
    
    SELECT A.EmpSeq, 
           A.EmpName, 
           A.EmpID, 
           B.DeptName 
      FROM _fnAdmEmpOrd(@CompanySeq, '') AS A 
      LEFT OUTER JOIN _TDADept           AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSEq ) 
     WHERE A.EmpSeq = @EmpSeq
    
    RETURN  
GO 


exec KPX_SHRWelMediEmpInfo @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105