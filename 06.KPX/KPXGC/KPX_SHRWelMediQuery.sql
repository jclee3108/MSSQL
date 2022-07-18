  
IF OBJECT_ID('KPX_SHRWelMediQuery') IS NOT NULL   
    DROP PROC KPX_SHRWelMediQuery  
GO  
  
-- v2014.12.02  
  
-- 의료비신청-조회 by 이재천   
CREATE PROC KPX_SHRWelMediQuery  
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
            @WelMediSeq     INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WelMediSeq   = ISNULL( WelMediSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WelMediSeq   INT)    
      
    -- 최종조회   
    SELECT A.YY, 
           A.RegSeq, 
           E.RegName, 
           A.BaseDate, 
           A.EmpSeq, 
           B.EmpName, 
           C.EmpID, 
           D.DeptName, 
           F.YearLimite, 
           G.SumComAmt, 
           A.ComAmt, 
           E.EmpAmt, 
           CASE WHEN ISNULL(F.YearLimite,0) - ISNULL(G.SumComAmt,0) > 0 THEN ISNULL(F.YearLimite,0) - ISNULL(G.SumComAmt,0) ELSE 0 END AS SurportAmt, 
           F.SMRegType, 
           H.CfmCode AS IsCfm 
           
           
      FROM KPX_THRWelMedi                       AS A 
      LEFT OUTER JOIN _TDAEmp                   AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq )  
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN KPX_THRWelCodeYearItem    AS E ON ( E.CompanySeq = @CompanySeq AND E.RegSeq = A.RegSeq ) 
      LEFT OUTER JOIN KPX_THRWelCode            AS F ON ( F.CompanySeq = @CompanySeq AND F.WelCodeSeq = E.WelCodeSeq ) 
      OUTER APPLY ( SELECT SUM(Z.ComAmt) AS SumComAmt
                      FROM KPX_THRWelMedi AS Z 
                      LEFT OUTER JOIN KPX_THRWelCodeYearItem    AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.RegSeq = Z.RegSeq ) 
                      LEFT OUTER JOIN KPX_THRWelCode            AS X ON ( X.CompanySeq = @CompanySeq AND X.WelCodeSeq = Y.WelCodeSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.EmpSeq = A.EmpSeq 
                       AND Z.YY = A.YY 
                       AND X.WelCodeSeq = F.WelCodeSeq
                  ) AS G  
      LEFT OUTER JOIN KPX_THRWelMedi_Confirm    AS H ON ( H.CompanySeq = @COmpanySeq AND H.CfmSeq = A.WelMediSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WelMediSeq = @WelMediSeq 
    
    
    SELECT A.WelMediSeq, 
           A.WelMediSerl, 
           A.FamilyName, 
           A.UMRelSeq, 
           B.MinorName AS UMRelName, 
           A.MedicalName, 
           A.BegDate, 
           A.EndDate, 
           A.MediAmt, 
           A.NonPayAmt, 
           ISNULL(A.MediAmt,0) - ISNULL(A.NonPayAmt,0) AS HEmpAmt
      FROM KPX_THRWelMediItem       AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMRelSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WelMediSeq = @WelMediSeq 
    
    RETURN  
GO 
exec KPX_SHRWelMediQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WelMediSeq>4</WelMediSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105