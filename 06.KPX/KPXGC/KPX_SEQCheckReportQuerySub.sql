  
IF OBJECT_ID('KPX_SEQCheckReportQuerySub') IS NOT NULL   
    DROP PROC KPX_SEQCheckReportQuerySub  
GO  
  
-- v2014.10.31  
  
-- 점검내역등록-생성 by 이재천   
CREATE PROC KPX_SEQCheckReportQuerySub  
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
            @CheckDate      NCHAR(8),
            @UMCheckTerm    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit    = ISNULL( FactUnit,  0 ),  
           @CheckDate   = ISNULL( CheckDate, '' ), 
           @UMCheckTerm = ISNULL( UMCheckTerm, 0 ) 
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            CheckDate      NCHAR(8),  
            UMCheckTerm    INT  
           )    
    
    DECLARE @IsExists NCHAR(1) 
    
    
    IF NOT EXISTS (SELECT 1 
                     FROM KPX_TEQCheckReport            AS A 
                     LEFT OUTER JOIN _TPDTool           AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
                    WHERE A.CompanySeq = @CompanySeq 
                      AND (@CheckDate = '' OR A.CheckDate = @CheckDate) 
                      AND (@FactUnit = 0 OR ISNULL(B.FactUnit,0) = @FactUnit) 
                      AND (@UMCheckTerm = 0 OR A.UMCheckTerm = @UMCheckTerm)
                   ) 
    BEGIN 
        SELECT '0' AS IsExists, 
               B.ToolName, 
               B.ToolNo, 
               A.ToolSeq, 
               B.FactUnit, 
               C.FactUnitName, 
               A.CheckKind, 
               A.CheckItem, 
               A.UMCheckTerm, 
               D.MinorName AS UMCheckTermName, 
               A.SMInputType, 
               A.CodeHelpConst, 
               A.CodeHelpParams, 
               A.Mask, 
               E.MinorName AS SMInputTypeName
          FROM KPX_TEQCheckItem         AS A 
          LEFT OUTER JOIN _TPDTool      AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
          LEFT OUTER JOIN _TDAFactUnit  AS C ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = B.FactUnit ) 
          LEFT OUTER JOIN _TDAUMinor    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMCheckTerm ) 
          LEFT OUTER JOIN _TDASMinor    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMInputType ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND (@UMCheckTerm = 0 OR A.UMCheckTerm = @UMCheckTerm) 
           AND (@FactUnit = 0 OR IsNULL(B.FactUnit,0) = @FactUnit)
    END 
    ELSE
    BEGIN
        SELECT '1' AS IsExists, 
               B.ToolName, 
               B.ToolNo, 
               A.ToolSeq, 
               A.CheckDate, 
               A.UMCheckTerm, 
               C.MinorName AS UMCheckTermName, 
               A.CheckReport AS MngValText, 
               CONVERT(INT,CASE WHEN E.SMInputType IN ( 1027003, 1027005 ) THEN A.CheckReport ELSE 0 END) AS Seq, 
               A.Remark, 
               A.Files1, 
               A.Files2, 
               A.Files3, 
               D.FactUnitName, 
               E.CheckKind, 
               E.CheckItem, 
               A.CheckDate AS CheckDateOld, 
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
           AND (@CheckDate = '' OR @CheckDate = A.CheckDate) 
           AND (@FactUnit = 0 OR ISNULL(B.FactUnit,0) = @FactUnit) 
           AND (@UMCheckTerm = 0 OR A.UMCheckTerm = @UMCheckTerm) 
        
        EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#TEMP' 
        
        select IsExists, 
               ToolName, 
               ToolNo, 
               ToolSeq, 
               CheckDate, 
               UMCheckTerm, 
               UMCheckTermName, 
               CASE WHEN SMInputType IN ( 1027003, 1027005 ) THEN ValueName ELSE MngValText END AS CheckReport, 
               CASE WHEN SMInputType IN ( 1027003, 1027005 ) THEN Seq ELSE 0 END AS CheckReportSeq, 
               Remark, 
               Files1, 
               Files2, 
               Files3, 
               FactUnitName, 
               CheckKind, 
               CheckItem, 
               CheckDateOld, 
               SMInputType, 
               CodeHelpSeq AS CodeHelpConst, 
               CodeHelpParams, 
               Mask, 
               SMInputTypeName
          from #TEMP 
           
    END  
    
    RETURN 
GO 
exec KPX_SEQCheckReportQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit />
    <CheckDate>20141111</CheckDate>
    <UMCheckTerm />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025499,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021363