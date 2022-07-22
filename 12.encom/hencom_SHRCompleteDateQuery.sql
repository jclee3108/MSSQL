 
IF OBJECT_ID('hencom_SHRCompleteDateQuery') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateQuery  
GO  

-- v2017.07.27
  
-- 완료일관리-조회 by 이재천   
CREATE PROC hencom_SHRCompleteDateQuery  
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
            @CompleteSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CompleteSeq   = ISNULL( CompleteSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (CompleteSeq   INT)    
    
    -- 최종조회   
    SELECT A.UMCompleteType, 
           B.MinorName AS UMCompleteTypeName, 
           A.DeptSeq, 
           C.DeptName, 
           A.ManagementAmt, 
           A.AlarmDay, 
           A.SrtDate, 
           A.EndDate, 
           A.Remark 
      FROM hencom_THRCompleteDate   AS A
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMCompleteType ) 
      LEFT OUTER JOIN _TDADept      AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @CompleteSeq = 0 OR A.CompleteSeq = @CompleteSeq )   


    -- 최종조회   
    SELECT A.CompleteSeq, 
           A.ShareSerl, 
           A.EmpDeptSeq AS ShareDeptSeq,
           B.DeptName AS ShareDeptName 
      FROM hencom_THRCompleteDateShare  AS A
      LEFT OUTER JOIN _TDADept          AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.EmpDeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @CompleteSeq = 0 OR A.CompleteSeq = @CompleteSeq )   
       AND A.EmpDeptType = 2 


    -- 최종조회   
    SELECT A.CompleteSeq, 
           A.ShareSerl, 
           A.EmpDeptSeq AS ShareEmpSeq,
           B.EmpName AS ShareEmpName 
      FROM hencom_THRCompleteDateShare  AS A
      LEFT OUTER JOIN _TDAEmp           AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpDeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @CompleteSeq = 0 OR A.CompleteSeq = @CompleteSeq )   
       AND A.EmpDeptType = 1 
    
    RETURN  

    GO
    exec hencom_SHRCompleteDateQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CompleteSeq>8</CompleteSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512703,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033993