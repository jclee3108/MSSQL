
IF OBJECT_ID('yw_SPJTProjectToolJump') IS NOT NULL 
    DROP PROC yw_SPJTProjectToolJump
GO 

-- v2014.07.07 

-- 프로젝트등록_yw(금형테스트이력점프) by이재천 
CREATE PROC yw_SPJTProjectToolJump                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS 
    
    DECLARE @docHandle      INT,
            @ToolSeqOld     INT ,
            @PJTSeq         INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ToolSeqOld  = ISNULL(ToolSeqOld,0), 
           @PJTSeq      = ISNULL(PJTSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ToolSeqOld  INT ,
            PJTSeq      INT )
    
    SELECT A.PJTName        , 
           A.PJTNo          ,
           A.UMPJTKind      , 
           E.ToolSeq        , 
           A.WBSLevelSeq    , 
           E.ToolName       , 
           C.WBSLevelName   , 
           A.PJTSeq         , 
           E.ToolNo         , 
           B.MinorName AS UMPJTKindName 
      FROM yw_TPJTProject           AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPJTKind ) 
      OUTER APPLY (SELECT TOP 1 WBSLevelName 
                     FROM YW_TPJTWBS AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WBSLevelSeq = A.WBSLevelSeq
                  ) AS C  
      OUTER APPLY (SELECT Y.ToolName, Y.ToolNo, Z.ToolSeq 
                     FROM YW_TPJTProjectTool    AS Z 
                     LEFT OUTER JOIN _TPDTool   AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.ToolSeq = Z.ToolSeq ) 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.PJTSeq = A.PJTSeq 
                      AND Z.ToolSeq = @ToolSeqOld 
                  ) AS E
      
     WHERE A.CompanySeq = @CompanySeq
       AND A.PJTSeq = @PJTSeq        

    RETURN
GO

exec yw_SPJTProjectToolJump @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolSeqOld>909</ToolSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PJTSeq>16</PJTSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023434,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019669