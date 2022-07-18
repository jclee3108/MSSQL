  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppItemQuery') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppItemQuery  
GO  
  
-- v2014.12.17  
  
-- OT일괄신청- 품목 조회 by 이재천   
CREATE PROC KPX_SPRWKEmpOTGroupAppItemQuery  
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
            @GroupAppSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @GroupAppSeq   = ISNULL( GroupAppSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (GroupAppSeq   INT)    
    
    -- 최종조회   
    SELECT A.GroupAppSeq, 
           ISNULL(D.CfmCode,'0') AS IsCfm, 
           E.EmpName, 
           E.EmpID, 
           A.EmpSeq, 
           E.DeptName, 
           E.DeptSeq, 
           B.AppDate, -- 신청일 
           B.AppSeq, 
           C.WkDate, -- 근무일자
           C.DTime, -- 신청시간 
           B.OTReason, -- 신청사유 
           C.Rem
      FROM KPX_TPRWKEmpOTGroupAppEmp AS A 
      LEFT OUTER JOIN _TPRWkEmpOTTimeApp            AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq AND B.AppSeq = A.AppSeq )  
      LEFT OUTER JOIN _TPRWkEmpOTTimeDtl            AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.EmpSeq AND C.AppSeq = B.AppSeq ) 
      LEFT OUTER JOIN _TPRWkEmpOTTimeApp_Confirm    AS D ON ( D.CompanySeq = @CompanySeq AND D.CfmSeq = B.EmpSeq AND D.CfmSerl = B.AppSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS E ON ( E.EmpSeq = A.EmpSeq )
     WHERE A.CompanySeq = @CompanySeq  
       AND A.GroupAppSeq = @GroupAppSeq 
      
    RETURN  
GO 
exec KPX_SPRWKEmpOTGroupAppItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <GroupAppSeq>1</GroupAppSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026866,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022469