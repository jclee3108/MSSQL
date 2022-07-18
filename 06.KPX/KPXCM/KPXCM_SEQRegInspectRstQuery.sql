  
IF OBJECT_ID('KPXCM_SEQRegInspectRstQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectRstQuery  
GO  
  
-- v2015.07.03  
  
-- 정기검사내역등록-조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectRstQuery  
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
            @QCDateFr       NCHAR(8), 
            @QCDateTo       NCHAR(8), 
            @UMQCCompany    INT, 
            @UMLicense      INT, 
            @UMQCSeq        INT, 
            @UMQCCycle      INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FactUnit      = ISNULL( FactUnit     , 0 ),  
           @ToolSeq       = ISNULL( ToolSeq      , 0 ),  
           @QCDateFr      = ISNULL( QCDateFr , '' ),  
           @QCDateTo      = ISNULL( QCDateTo , '' ),  
           @UMQCCompany   = ISNULL( UMQCCompany  , 0 ),  
           @UMLicense     = ISNULL( UMLicense    , 0 ),  
           @UMQCSeq       = ISNULL( UMQCSeq      , 0 ), 
           @UMQCCycle     = ISNULL( UMQCCycle   , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            ToolSeq        INT,       
            QCDateFr       NCHAR(8),      
            QCDateTo       NCHAR(8),      
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
           A.LastQCDate, 
           A.Spec, 
           A.RegInspectSeq, 
           
           M.QCDate, 
           M.QCResultDate AS QCResultDateOld, 
           M.QCResultDate,
           M.Remark 
    
      FROM KPXCM_TEQRegInspectRst           AS M 
      LEFT OUTER JOIN KPXCM_TEQRegInspect   AS A ON ( A.CompanySeq = @CompanySeq AND A.RegInspectSeq = M.RegInspectSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCCompany ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLicense ) 
      LEFT OUTER JOIN _TDAEmp               AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle ) 
      LEFT OUTER JOIN _TPDTool              AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit          AS I ON ( I.CompanySeq = @CompanySeq AND I.FactUnit = H.FactUnit ) 
      
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR H.FactUnit = @FactUnit )
       AND ( @ToolSeq = 0 OR A.ToolSeq = @ToolSeq ) 
       AND ( M.QCDate BETWEEN @QCDateFr AND @QCDateTo ) 
       AND ( @UMQCCompany = 0 OR A.UMQCCompany = @UMQCCompany ) 
       AND ( @UMLicense = 0 OR A.UMLicense = @UMLicense ) 
       AND ( @UMQCSeq = 0 OR A.UMQCSeq = @UMQCSeq ) 
       AND ( @UMQCCycle = 0 OR A.UMQCCycle = @UMQCCycle ) 
    
    RETURN  
go
exec KPXCM_SEQRegInspectRstQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ToolSeq>7</ToolSeq>
    <FactUnit />
    <UMQCCycle>1011264002</UMQCCycle>
    <UMQCSeq>1011261002</UMQCSeq>
    <UMQCCompany>1011262002</UMQCCompany>
    <QCDateFr>20150701</QCDateFr>
    <QCDateTo>20150731</QCDateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030662,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025556