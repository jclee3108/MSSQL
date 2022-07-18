  
IF OBJECT_ID('KPX_SEQCheckItemQuery') IS NOT NULL   
    DROP PROC KPX_SEQCheckItemQuery  
GO  
  
-- v2014.10.30  
  
-- 점검설비등록-조회 by 이재천   
CREATE PROC KPX_SEQCheckItemQuery  
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
            @ToolSeq    INT,  
            @FactUnit   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ToolSeq = ISNULL( ToolSeq, 0 ), 
           @FactUnit = ISNULL( FactUnit, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ToolSeq     INT, 
            FactUnit    INT
           )    
    
    -- 최종조회   
    SELECT A.ToolSeq, 
           B.ToolName, 
           B.ToolNo, 
           A.UMCheckTerm, 
           C.MinorName AS UMCheckTermName, 
           A.SMInputType, 
           D.MinorName AS SMInputTypeName, 
           A.CheckKind, 
           A.CheckItem,  
           A.CodeHelpConst, 
           CONVERT(NVARCHAR(100),'') AS CodeHelpConstName, 
           A.CodeHelpParams, 
           A.Remark, 
           A.UMCheckTerm AS UMCheckTermOld, 
           B.FactUnit, 
           E.FactUnitName, 
           A.Mask
      INTO #TEMP 
      FROM KPX_TEQCheckItem         AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDTool      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMCheckTerm )
      LEFT OUTER JOIN _TDASMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMInputType ) 
      LEFT OUTER JOIN _TDAFactUnit  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.FactUnit = B.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @ToolSeq = 0 OR A.ToolSeq = @ToolSeq )   
       AND ( @FactUnit = 0 OR B.FactUnit = @FactUnit ) 
    
    -- UMajor(19999)
    UPDATE A
       SET CodeHelpConstName = B.MajorName
      FROM #TEMP        AS A 
      JOIN _TDAUMajor   AS B ON ( B.CompanySeq = @CompanySeq AND A.CodeHelpParams = B.MajorSeq ) 
     WHERE (1=1)
       AND A.CodeHelpConst = 19999
    
    -- UMajor(19998)
    UPDATE A
       SET CodeHelpConstName = B.MajorName
      FROM #TEMP        AS A 
      JOIN _TDASMajor   AS B ON ( B.CompanySeq = @CompanySeq AND A.CodeHelpParams = B.MajorSeq ) 
     WHERE (1=1)
       AND A.CodeHelpConst = 19998
    
    -- 그외
    UPDATE A
       SET CodeHelpConstName = B.CodeHelpTitle
      FROM #TEMP            AS A 
      JOIN _TCACodeHelpData AS B ON ( B.CompanySeq = 0 AND A.CodeHelpConst = B.CodeHelpSeq )
       AND A.CodeHelpConst > 0
       AND A.CodeHelpConst NOT IN ( 19998, 19999 )
    
    SELECT * FROM #TEMP 
    
    RETURN  
    
GO 
exec KPX_SEQCheckItemQuery @xmlDocument=N'<ROOT>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=1025469,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021362