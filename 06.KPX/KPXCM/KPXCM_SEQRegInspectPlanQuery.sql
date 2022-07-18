  
IF OBJECT_ID('KPXCM_SEQRegInspectPlanQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectPlanQuery  
GO  
  
-- v2015.07.01  
  
-- 정기검사계획조회-조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectPlanQuery  
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
            @FactUnit       INT,  
            @ToolSeq        INT, 
            @QCPlanDateFr   NCHAR(8), 
            @QCPlanDateTo   NCHAR(8), 
            @UMQCCompany    INT, 
            @UMLicense      INT, 
            @UMQCSeq        INT, 
            @UMQCCycle      INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FactUnit      = ISNULL( FactUnit     , 0 ),  
           @ToolSeq       = ISNULL( ToolSeq      , 0 ),  
           @QCPlanDateFr  = ISNULL( QCPlanDateFr , '' ),  
           @QCPlanDateTo  = ISNULL( QCPlanDateTo , '' ),  
           @UMQCCompany   = ISNULL( UMQCCompany  , 0 ),  
           @UMLicense     = ISNULL( UMLicense    , 0 ),  
           @UMQCSeq       = ISNULL( UMQCSeq      , 0 ), 
           @UMQCCycle     = ISNULL( UMQCCycle   , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            ToolSeq        INT,       
            QCPlanDateFr   NCHAR(8),      
            QCPlanDateTo   NCHAR(8),      
            UMQCCompany    INT,       
            UMLicense      INT,       
            UMQCSeq        INT, 
            UMQCCycle      INT 
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
           ISNULL(K.QCDate,A.LastQCDate) AS LastQCDate, 
           A.Spec, 
           A.QCNo, 
           A.RegInspectSeq, 
           
           CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) AS QCPlanDate, 
           J.ReplaceDate, 
           J.Remark 
           
      FROM KPXCM_TEQRegInspect      AS A  
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAEmp       AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TPDTool      AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit  AS I ON ( I.CompanySeq = @CompanySeq AND I.FactUnit = H.FactUnit ) 
      OUTER APPLY (
                    SELECT MAX(QCResultDate) AS QCDate 
                      FROM KPXCM_TEQRegInspectRst AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.RegInspectSeq = A.RegInspectSeq 
                     GROUP BY Z.RegInspectSeq
                  ) K 
      LEFT OUTER JOIN KPXCM_TEQRegInspectChg AS J ON ( J.CompanySeq = @CompanySeq AND J.RegInspectSeq = A.RegInspectSeq AND J.QCPlanDate = CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR H.FactUnit = @FactUnit )
       AND ( @ToolSeq = 0 OR A.ToolSeq = @ToolSeq ) 
       AND ( CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) BETWEEN @QCPlanDateFr AND @QCPlanDateTo ) 
       AND ( @UMQCCompany = 0 OR A.UMQCCompany = @UMQCCompany ) 
       AND ( @UMLicense = 0 OR A.UMLicense = @UMLicense ) 
       AND ( @UMQCSeq = 0 OR A.UMQCSeq = @UMQCSeq ) 
       AND ( @UMQCCycle = 0 OR A.UMQCCycle = @UMQCCycle ) 
       
    RETURN  
GO
exec KPXCM_SEQRegInspectPlanQuery @xmlDocument=N'<ROOT>
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
    <QCPlanDateFr>20150701</QCPlanDateFr>
    <QCPlanDateTo>20150731</QCPlanDateTo>
    <UMQCCycle />
    <UMQCSeq />
    <UMQCCompany />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030627,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025549