  
IF OBJECT_ID('KPXCM_SEQRegInspectQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectQuerySub  
GO  
  
-- v2015.07.01  
  
-- 정기검사설비등록-Sub조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectQuerySub  
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
            @RegInspectSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @RegInspectSeq = ISNULL( RegInspectSeq, 0 )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( RegInspectSeq   INT )    
      
    -- 최종조회   
    SELECT C.ToolName, 
           C.ToolNo, 
           A.ToolSeq, 
           D.FactUnitName, 
           A.UMQCSeq, 
           E.MinorName AS UMQCName, 
           A.UMQCCompany, 
           F.MinorName AS UMQCCompanyName, 
           A.UMLicense, 
           G.MinorName AS UMLicenseName, 
           A.UMQCCycle, 
           H.MinorName AS UMQCCycleName, 
           A.EmpSeq, 
           I.EmpName, 
           A.Spec, 
           A.QCNo, 
           B.QCDate, 
           B.Remark AS QCRemark, 
           J.LastQCDate, 
           A.RegInspectSeq
    
      FROM KPXCM_TEQRegInspect                  AS A 
                 JOIN KPXCM_TEQRegInspectRst    AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq ) 
      LEFT OUTER JOIN _TPDTool                  AS C ON ( C.CompanySeq = @CompanySeq AND C.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit              AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = C.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor                AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAUMinor                AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TDAEmp                   AS I ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = A.EmpSeq ) 
      OUTER APPLY (
                    SELECT MAX(Z.QCDate) AS LastQCDate 
                      FROM KPXCM_TEQRegInspectRst AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.RegInspectSeq = A.RegInspectSeq 
                     GROUP BY Z.RegInspectSeq
                  ) AS J 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.RegInspectSeq = @RegInspectSeq ) 
    
    RETURN  
GO 

exec KPXCM_SEQRegInspectQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <RegInspectSeq>6</RegInspectSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030603,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025532