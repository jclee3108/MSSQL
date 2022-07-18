  
IF OBJECT_ID('KPXCM_SEQRegInspectQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectQuery  
GO  
  
-- v2015.07.01  
  
-- 정기검사설비등록-조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectQuery  
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
            @FactUnit   INT, 
            @ToolSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit = ISNULL( FactUnit, 0 ), 
           @ToolSeq  = ISNULL( ToolSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit    INT, 
            ToolSeq     INT 
           )    
    
    -- 최종조회   
    SELECT A.ToolSeq, 
           H.ToolName, 
           H.ToolNo, 
           I.FactUnitName, 
           A.UMQCSeq, 
           B.MinorName AS UMQCName, 
           A.UMQCCompany, 
           C.MinorName AS UMQCCompanyName, 
           A.UMLicense, 
           D.MinorName AS UMLicenseName, 
           A.EmpSeq, 
           E.EmpName, 
           A.UMQCCycle, 
           F.MinorName AS UMQCCycleName, 
           A.LastQCDate, 
           A.Spec, 
           A.QCNo, 
           A.RegInspectSeq 
      FROM KPXCM_TEQRegInspect      AS A  
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAEmp       AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TPDTool      AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit  AS I ON ( I.CompanySeq = @CompanySeq AND I.FactUnit = H.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR H.FactUnit = @FactUnit )
       AND ( @ToolSeq = 0 OR A.ToolSeq = @ToolSeq ) 
      
    RETURN  
GO
exec KPXCM_SEQRegInspectQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit />
    <ToolSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030603,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025532