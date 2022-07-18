  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHEQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHEQuery  
GO  
  
-- v2015.01.22  
  
-- 변경위험성평가등록-조회 by 이재천
CREATE PROC KPX_SEQChangeRiskRstCHEQuery  
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
            @RiskRstSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @RiskRstSeq   = ISNULL( RiskRstSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (RiskRstSeq   INT)    
    
    -- 최종조회   
    SELECT B.ChangeRequestSeq, 
           B.Title AS ChangeTitle, 
           B.Remark AS ReqRemark, 
           B.Purpose,
           B.Effect, 
           B.UMChangeType, 
           ISNULL(Q.MinorName  ,'') AS UMChangeTypeName, 
           A.RiskRstDate, 
           A.UMMaterialChange, 
           C.MinorName AS UMMaterialChangeName, 
           A.UMFlashPoint, 
           D.MinorName AS UMFlashPointName, 
           A.UMPPM, 
           E.MinorName AS UMPPMName, 
           A.UMMg, 
           F.MinorName AS UMMgName, 
           A.UMHeat, 
           G.MinorName AS UMHeatName, 
           A.UMDriveUp, 
           H.MinorName AS UMDriveUpName, 
           A.UMDriveDown, 
           I.MinorName AS UMDriveDownName, 
           A.UMDrivePress, 
           J.MinorName AS UMDrivePressName, 
           A.IsProdUp, 
           A.IsChangeProd, 
           A.IsFlare, 
           A.UMChangeLevel, 
           K.MinorName AS UMChangeLevelName, 
           A.Remark, 
           A.FileSeq
           
           
           
      FROM KPX_TEQChangeRiskRstCHE              AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE   AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = B.UMChangeType ) 
      LEFT OUTER JOIN _TDAUMinor                AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMMaterialChange ) 
      LEFT OUTER JOIN _TDAUMinor                AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMFlashPoint ) 
      LEFT OUTER JOIN _TDAUMinor                AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMPPM ) 
      LEFT OUTER JOIN _TDAUMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMMg ) 
      LEFT OUTER JOIN _TDAUMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMHeat ) 
      LEFT OUTER JOIN _TDAUMinor                AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMDriveUp ) 
      LEFT OUTER JOIN _TDAUMinor                AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMDriveDown ) 
      LEFT OUTER JOIN _TDAUMinor                AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMDrivePress ) 
      LEFT OUTER JOIN _TDAUMinor                AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = A.UMChangeLevel ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.RiskRstSeq = @RiskRstSeq )  
      
    RETURN  
GO 
exec KPX_SEQChangeRiskRstCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RiskRstSeq>6</RiskRstSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351

