
IF OBJECT_ID('KPX_SEQCheckReportJump') IS NOT NULL 
    DROP PROC KPX_SEQCheckReportJump
GO 
        
-- v2015.07.09      
        
-- 점검설비등록-조회 by 이삭    수정 by이재천
CREATE PROC KPX_SEQCheckReportJump    
        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS         
            
    CREATE TABLE #KPX_TEQCheckItem (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQCheckItem'         
    IF @@ERROR <> 0 RETURN       

    
    -- 최종조회         
    SELECT A.Seq,      
           A.ToolSeq,       
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
           A.Mask,       
           A.WorkOperSeq,       
           F.MinorName AS WorkOperName,      
           AA.CheckDate AS CheckDate      
      INTO #TEMP       
      FROM #KPX_TEQCheckItem AS AA    
                 JOIN KPX_TEQCheckItem  AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq 
                                                          AND AA.ToolSeq = A.ToolSeq 
                                                          AND A.UMCheckTerm = AA.UMCheckTerm 
                                                          AND AA.CheckItem = A.CheckItem 
                                                          AND AA.CheckKind = A.CheckKind 
                                                            ) 
      LEFT OUTER JOIN _TPDTool      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq )       
      LEFT OUTER JOIN _TDAUMinor    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMCheckTerm )      
      LEFT OUTER JOIN _TDASMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMInputType )       
      LEFT OUTER JOIN _TDAFactUnit  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.FactUnit = B.FactUnit )       
      LEFT OUTER JOIN _TDAUMinor    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.WorkOperSeq )             
          
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
begin tran 
exec KPX_SEQCheckReportJump @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolName>가열로</ToolName>
    <ToolNo>235600</ToolNo>
    <ToolSeq>1</ToolSeq>
    <FactUnit>0</FactUnit>
    <CheckDate>20150625</CheckDate>
    <UMCheckTerm>1010201001</UMCheckTerm>
    <Seq>1</Seq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolName>가공2호기</ToolName>
    <ToolNo>가공2호기</ToolNo>
    <ToolSeq>2</ToolSeq>
    <FactUnit>0</FactUnit>
    <CheckDate>20150625</CheckDate>
    <UMCheckTerm>1010201001</UMCheckTerm>
    <Seq>2</Seq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025469,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1024950

rollback 