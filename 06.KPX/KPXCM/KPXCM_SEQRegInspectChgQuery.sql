  
IF OBJECT_ID('KPXCM_SEQRegInspectChgQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectChgQuery  
GO  
  
-- v2015.07.01  
  
-- 정기검사계획조정등록-조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectChgQuery  
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
           A.RegInspectSeq, 
           M.QCPlanDate, 
           M.ReplaceDate, 
           M.Remark, 
           M.ReplaceDate AS ReplaceDateOld, 
           '1' AS IsExists 
      FROM KPXCM_TEQRegInspectChg           AS M  
      LEFT OUTER JOIN KPXCM_TEQRegInspect   AS A ON ( A.CompanySeq = @CompanySeq AND A.RegInspectSeq = M.RegInspectSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAEmp               AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TPDTool              AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit          AS I ON ( I.CompanySeq = @CompanySeq AND I.FactUnit = H.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
     
    RETURN  
GO
exec KPXCM_SEQRegInspectChgQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1030624,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025548