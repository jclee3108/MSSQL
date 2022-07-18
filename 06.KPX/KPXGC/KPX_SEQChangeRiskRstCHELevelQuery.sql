  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHELevelQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHELevelQuery  
GO  
  
-- v2015.01.21  
  
-- 변경위험성평가등록-등급조회 by 이재천 
CREATE PROC KPX_SEQChangeRiskRstCHELevelQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @UMMaterialChange   INT,  
            @UMFlashPoint       INT, 
            @UMPPM              INT, 
            @UMMg               INT, 
            @UMHeat             INT, 
            @UMDriveUp          INT, 
            @UMDriveDown        INT, 
            @UMDrivePress       INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @UMMaterialChange = ISNULL( UMMaterialChange , 0 ), 
           @UMFlashPoint     = ISNULL( UMFlashPoint     , 0 ), 
           @UMPPM            = ISNULL( UMPPM            , 0 ), 
           @UMMg             = ISNULL( UMMg             , 0 ), 
           @UMHeat           = ISNULL( UMHeat           , 0 ), 
           @UMDriveUp        = ISNULL( UMDriveUp        , 0 ), 
           @UMDriveDown      = ISNULL( UMDriveDown      , 0 ), 
           @UMDrivePress     = ISNULL( UMDrivePress     , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            UMMaterialChange   INT,
            UMFlashPoint       INT,
            UMPPM              INT,
            UMMg               INT,
            UMHeat             INT,
            UMDriveUp          INT,
            UMDriveDown        INT,
            UMDrivePress       INT 
           )    
    
    
    DECLARE @SumFlt INT 
    
    /*************************************************************************************************************************************************** 
    사용자정의코드 
    물질증가량 + 인화점 + TWA-PPM + TWA-mg/m3 + 반응열 + 운전온도(영상) + 운전온도(영하) + 운전입력 (추가정보 1000001 값)
    ****************************************************************************************************************************************************/
    SELECT @SumFlt = ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMMaterialChange),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMFlashPoint    ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMPPM           ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMMg            ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMHeat          ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMDriveUp       ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMDriveDown     ),0) +
                     ISNULL((SELECT CONVERT(INT,ValueText) AS Flt FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND Serl = 1000001 AND MinorSeq = @UMDrivePress    ),0)
    
    -- 계산 된 값으로 등급 Setting
    SELECT CASE WHEN @SumFlt > 1 AND @SumFlt <= 6   THEN 1010470004
                WHEN @SumFlt > 6 AND @SumFlt <= 12  THEN 1010470003
                WHEN @SumFlt > 12 AND @SumFlt <= 18 THEN 1010470002
                WHEN @SumFlt > 18 AND @SumFlt <= 24 THEN 1010470001 
                ELSE 0 END AS UMChangeLevel, 
           CASE WHEN @SumFlt > 1 AND @SumFlt <= 6   THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010470004)
                WHEN @SumFlt > 6 AND @SumFlt <= 12  THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010470003)
                WHEN @SumFlt > 12 AND @SumFlt <= 18 THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010470002)
                WHEN @SumFlt > 18 AND @SumFlt <= 24 THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010470001) 
                ELSE '' END AS UMChangeLevelName 
    
    RETURN  
GO 
exec KPX_SEQChangeRiskRstCHELevelQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMMaterialChange>1010462002</UMMaterialChange>
    <UMFlashPoint />
    <UMPPM />
    <UMMg />
    <UMHeat />
    <UMDriveUp />
    <UMDriveDown />
    <UMDrivePress />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351