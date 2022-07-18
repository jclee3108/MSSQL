  
IF OBJECT_ID('KPX_SEQCheckRptListQuery') IS NOT NULL   
    DROP PROC KPX_SEQCheckRptListQuery  
GO  
  
-- v2014.11.03  
  
-- 점검내역조회-조회 by 이재천   
CREATE PROC KPX_SEQCheckRptListQuery  
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
            @CheckDateFr    NCHAR(8), 
            @CheckDateTo    NCHAR(8), 
            @UMCheckTerm    INT, 
            @ToolName       NVARCHAR(100), 
            @ToolNo         NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit    = ISNULL( FactUnit, 0 ), 
           @CheckDateFr = ISNULL( CheckDateFr, '' ),
           @CheckDateTo = ISNULL( CheckDateTo, '' ), 
           @UMCheckTerm = ISNULL( UMCheckTerm, 0 ), 
           @ToolName    = ISNULL( ToolName, '' ), 
           @ToolNo      = ISNULL( ToolNo, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            CheckDateFr    NCHAR(8), 
            CheckDateTo    NCHAR(8), 
            UMCheckTerm    INT, 
            ToolName       NVARCHAR(100), 
            ToolNo         NVARCHAR(100) 
           )
    
    IF @CheckDateTo = '' SELECT @CheckDateTo = '99991231'
    
    -- 최종조회   
    
    SELECT B.ToolName, 
           B.ToolNo, 
           A.ToolSeq, 
           A.CheckDate, 
           A.UMCheckTerm, 
           C.MinorName AS UMCheckTermName, 
           A.CheckReport AS MngValText, 
           CONVERT(INT,CASE WHEN E.SMInputType IN ( 1027003, 1027005 ) THEN A.CheckReport ELSE 0 END) AS Seq, 
           A.Remark, 
           D.FactUnitName, 
           E.CheckKind, 
           E.CheckItem, 
           E.SMInputType, 
           E.CodeHelpConst AS CodeHelpSeq, 
           E.CodeHelpParams, 
           E.Mask, 
           F.MinorName AS SMInputTypeName 
      INTO #TEMP 
      FROM KPX_TEQCheckReport           AS A 
      LEFT OUTER JOIN _TPDTool          AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMCheckTerm ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = B.FactUnit ) 
      LEFT OUTER JOIN KPX_TEQCheckItem  AS E ON ( E.CompanySeq = @CompanySeq AND E.ToolSeq = A.ToolSeq AND E.UMCheckTerm = A.UMCheckTerm ) 
      LEFT OUTER JOIN _TDASMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.SMInputType ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR B.FactUnit = @FactUnit )  
       AND ( A.CheckDate BETWEEN @CheckDateFr AND @CheckDateTo ) 
       AND ( @UMCheckTerm = 0 OR A.UMCheckTerm = @UMCheckTerm ) 
       AND ( @ToolName = '' OR B.ToolName LIKE @ToolName + '%' )
       AND ( @ToolNo = '' OR B.ToolNo LIKE @ToolNo + '%' ) 
    
    EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#TEMP' 
    
    SELECT ToolName, 
           ToolNo, 
           ToolSeq, 
           CheckDate, 
           UMCheckTerm, 
           UMCheckTermName, 
           CASE WHEN SMInputType IN ( 1027003, 1027005 ) THEN ValueName ELSE MngValText END AS CheckReport, 
           CASE WHEN SMInputType IN ( 1027003, 1027005 ) THEN Seq ELSE 0 END AS CheckReportSeq, 
           Remark, 
           FactUnitName, 
           CheckKind, 
           CheckItem, 
           SMInputType, 
           CodeHelpSeq AS CodeHelpConst, 
           CodeHelpParams, 
           Mask, 
           SMInputTypeName
      FROM #TEMP 
    
    RETURN  
GO
exec KPX_SEQCheckRptListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit />
    <CheckDateFr>20141102</CheckDateFr>
    <CheckDateTo>20141111</CheckDateTo>
    <UMCheckTerm />
    <ToolName />
    <ToolNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025548,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021364