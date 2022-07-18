  
IF OBJECT_ID('KPX_SHRWorkEmpDailyQuery') IS NOT NULL   
    DROP PROC KPX_SHRWorkEmpDailyQuery  
GO  
  
-- v2014.12.23  
  
-- 지역별근무인원등록-조회 by 이재천   
CREATE PROC KPX_SHRWorkEmpDailyQuery  
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
    
    DECLARE @docHandle          INT,  
            -- 조회조건   
            @WorkDate           NCHAR(8), 
            @UMWorkCenterSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkDate        = ISNULL( WorkDate, '' ),  
           @UMWorkCenterSeq = ISNULL ( UMWorkCenterSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkDate           NCHAR(8), 
            UMWorkCenterSeq    INT
           )    
      
    -- 최종조회   
    SELECT A.Serl, 
           A.EmpSeq, 
           B.EmpName, 
           B.WkDeptName 
      FROM KPX_THRWorkEmpDaily AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkDate = @WorkDate 
       AND A.UMWorkCenterSeq =@UMWorkCenterSeq
    
    RETURN  