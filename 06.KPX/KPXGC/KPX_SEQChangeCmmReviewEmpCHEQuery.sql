  
IF OBJECT_ID('KPX_SEQChangeCmmReviewEmpCHEQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeCmmReviewEmpCHEQuery  
GO  
  
-- v2015.01.22  
  
-- 변경위원회회의록등록-조회 by이재천
CREATE PROC KPX_SEQChangeCmmReviewEmpCHEQuery  
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
            @ReviewSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReviewSeq   = ISNULL( ReviewSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ReviewSeq   INT)    
    
    
    
    SELECT B.ChangeRequestSeq, 
           B.Title AS ChangeTitle, 
           B.Remark AS ReqRemark, 
           B.Purpose,
           B.Effect, 
           B.UMChangeType, 
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName, 
           C.DeptName, 
           A.UMResult, 
           D.MinorName AS UMResultName, 
           
           A.Contents1, 
           A.DeptName1, 
           A.Date1, 
           A.Contents2, 
           A.DeptName2, 
           A.Date2, 
           A.Contents3, 
           A.DeptName3, 
           A.Date3, 
           A.Contents4, 
           A.DeptName4, 
           A.Date4, 
           A.Contents6, 
           A.DeptName6, 
           A.Date6, 
           A.Contents7, 
           A.DeptName7, 
           A.Date7, 
           A.Contents8, 
           A.DeptName8, 
           A.Date8, 
           A.IsProcDept, 
           A.IsProdDept, 
           A.IsStdDept, 
           A.IsSafeDept, 
           A.DeptEtc, 
           A.IsAct, 
           A.IsAdd, 
           A.IsNot, 
           A.TotEtc
          
      FROM KPX_TEQChangeCmmReviewCHE AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE           AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDADept                          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMResult ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.ReviewSeq = @ReviewSeq )   

    -- 참석자 
    SELECT A.ReviewSeq, 
           A.EmpSeq, 
           B.EmpName, 
           A.DeptSeq, 
           C.DeptName
      FROM KPX_TEQChangeCmmReviewEmpCHE AS A 
      LEFT OUTER JOIN _TDAEmp           AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.ReviewSeq = @ReviewSeq )   
    
    RETURN  
GO 
exec KPX_SEQChangeCmmReviewEmpCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReviewSeq>5</ReviewSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026713,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021388