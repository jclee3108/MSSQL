
IF OBJECT_ID('yw_SPJTProjectResultJump') IS NOT NULL 
    DROP PROC yw_SPJTProjectResultJump
GO 

-- v2014.07.07 

-- 프로젝트등록_yw(프로젝트실적입력점프) by이재천 
CREATE PROC dbo.yw_SPJTProjectResultJump                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 

AS        
    
    DECLARE @docHandle  INT,
            @PJTSeq     INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @PJTSeq = ISNULL(PJTSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
      WITH ( PJTSeq INT )
    
    SELECT A.PJTName, 
           A.PJTNo, 
           A.PJTSeq, 
           A.BegDate, 
           A.EndDate, 
           A.WbsLevelSeq, 
           A.UMStep AS UMStepSeq, 
           A.UMPJTKind, 
           B.MinorName AS UMPJTKindName, 
           C.MinorName AS UMStepName, 
           D.WBSLevelname
           --UMPJTKindName , EndDate       , PJTSeq        , BegDate       , PJTName       , 
    --        UMPJTKind     , UMStep        , UMStepName    , WBSLevelSeq   , PJTNo         , 
    --        WBSLevelName  
      FROM yw_TPJTProject           AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TDAUMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPJTKind ) 
      LEFT OUTER JOIN _TDAUMinor    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMStep ) 
      OUTER APPLY (SELECT TOP 1 WBSLevelName 
                     FROM YW_TPJTWBS AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WBSLevelSeq = A.WBSLevelSeq 
                  ) AS D 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PJTSeq = @PJTSeq        
    
    RETURN
GO
exec yw_SPJTProjectResultJump @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PJTSeq>16</PJTSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023434,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019669