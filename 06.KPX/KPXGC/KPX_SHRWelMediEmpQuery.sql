  
IF OBJECT_ID('KPX_SHRWelMediEmpQuery') IS NOT NULL   
    DROP PROC KPX_SHRWelMediEmpQuery  
GO  
  
-- v2014.12.03  
  
-- 의료비내역등록-조회 by 이재천   
CREATE PROC KPX_SHRWelMediEmpQuery  
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
            @YY         NCHAR(4), 
            @EmpSeq     INT, 
            @DeptSeq    INT, 
            @RegSeq     INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YY   = ISNULL( YY, '' ), 
           @EmpSeq = ISNULl( EmpSeq, 0 ), 
           @DeptSeq = ISNULL( DeptSeq, 0 ), 
           @RegSeq = ISNULL ( RegSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            YY         NCHAR(4), 
            EmpSeq     INT, 
            DeptSeq    INT, 
            RegSeq     INT 
           )    
    
    -- 최종조회   
    SELECT A.WelMediEmpSeq, 
           A.EmpSeq, 
           B.EmpName, 
           B.EmpID, 
           B.DeptName, 
           B.PosName, 
           B.UMJpName, 
           A.YY, 
           A.BaseDate, 
           A.CompanyAmt, 
           A.ItemSeq, 
           C.ItemName, 
           A.PbSeq, 
           D.PbName, 
           A.PbYM, 
           A.WelMediSeq 
           
      FROM KPX_THRWelMediEmp AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRBasPayItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TPRBasPb         AS D ON ( D.CompanySeq = @CompanySeq AND D.PbSeq = A.PbSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @YY = '' OR A.YY = @YY ) 
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq ) 
       AND ( @DeptSeq = 0 OR B.DeptSeq = @DeptSeq ) 
       AND ( @RegSeq = 0 OR A.RegSeq = @RegSeq ) 
       
      
    RETURN  