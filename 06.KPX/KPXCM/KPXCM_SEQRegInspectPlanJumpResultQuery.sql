  
IF OBJECT_ID('KPXCM_SEQRegInspectPlanJumpResultQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectPlanJumpResultQuery  
GO  
  
-- v2015.07.03 
  
-- 정기검사계획조회-내역등록 점프 by 이재천   
CREATE PROC KPXCM_SEQRegInspectPlanJumpResultQuery  
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
    
    CREATE TABLE #KPXCM_TEQRegInspect( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspect'   
    IF @@ERROR <> 0 RETURN    
    
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
           ISNULL(L.QCDate,A.LastQCDate) AS LastQCDate, 
           A.Spec, 
           A.QCNo, 
           A.RegInspectSeq, 
           ISNULL(K.QCDate,ISNULL(J.ReplaceDate,CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(L.QCDate,A.LastQCDate)),112))) AS QCDate, 
           ISNULL(K.QCDate,ISNULL(J.ReplaceDate,CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(L.QCDate,A.LastQCDate)),112))) AS QCResultDate, 
           ISNULL(K.QCDate,ISNULL(J.ReplaceDate,CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(L.QCDate,A.LastQCDate)),112))) AS QCResultDateOld, 
           ISNULL(K.Remark,'') AS Remark,
           CASE WHEN K.RegInspectSeq IS NULL THEN '0' ELSE '1' END AS IsExists 
    
      FROM #KPXCM_TEQRegInspect                 AS M 
      LEFT OUTER JOIN KPXCM_TEQRegInspect       AS A ON ( A.CompanySeq = @CompanySeq AND A.RegInspectSeq = M.RegInspectSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor                AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TPDTool                  AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit              AS I ON ( I.CompanySeq = @CompanySeq AND I.FactUnit = H.FactUnit ) 
      
      OUTER APPLY (
                    SELECT MAX(QCDate) AS QCDate 
                      FROM KPXCM_TEQRegInspectRst AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.RegInspectSeq = A.RegInspectSeq 
                     GROUP BY Z.RegInspectSeq
                  ) L 
      LEFT OUTER JOIN KPXCM_TEQRegInspectChg    AS J ON ( J.CompanySeq = @CompanySeq 
                                                      AND J.RegInspectSeq = M.RegInspectSeq 
                                                      AND J.QCPlanDate = CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(L.QCDate,A.LastQCDate)),112) 
                                                        ) 
      LEFT OUTER JOIN KPXCM_TEQRegInspectRst    AS K ON ( K.CompanySeq = @CompanySeq 
                                                      AND K.RegInspectSeq = M.RegInspectSeq 
                                                      AND K.QCDate = ISNULL(J.ReplaceDate,CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(L.QCDate,A.LastQCDate)),112))
                                                        ) 
    
    RETURN  
GO
exec KPXCM_SEQRegInspectPlanJumpResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RegInspectSeq>6</RegInspectSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RegInspectSeq>7</RegInspectSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030627,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025549