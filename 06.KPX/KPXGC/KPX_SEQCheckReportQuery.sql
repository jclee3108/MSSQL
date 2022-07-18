  
IF OBJECT_ID('KPX_SEQCheckReportQuery') IS NOT NULL   
    DROP PROC KPX_SEQCheckReportQuery  
GO  
  
-- v2014.10.31  
  
-- 점검내역등록-조회 by 이재천   
CREATE PROC KPX_SEQCheckReportQuery  
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
    
    -- 최종조회   
    SELECT B.ToolName, 
           B.ToolNo, 
           A.ToolSeq, 
           A.CheckDate, 
           A.UMCheckTerm, 
           C.MinorName AS UMCheckTermName, 
           A.CheckReport, 
           A.Remark, 
           A.Files1, 
           A.Files2, 
           A.Files3, 
           D.FactUnitName, 
           E.CheckKind, 
           E.CheckItem, 
           A.CheckDate AS CheckDateOld 
           
           
      FROM KPX_TEQCheckReport           AS A 
      LEFT OUTER JOIN _TPDTool          AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMCheckTerm ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = B.FactUnit ) 
      LEFT OUTER JOIN KPX_TEQCheckItem  AS E ON ( E.CompanySeq = @CompanySeq AND E.ToolSeq = A.ToolSeq AND E.UMCheckTerm = A.UMCheckTerm ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (@CheckDate = '' OR @CheckDate = A.CheckDate) 
       AND (@FactUnit = 0 OR ISNULL(B.FactUnit,0) = @FactUnit) 
       AND (@UMCheckTerm = 0 OR A.UMCheckTerm = @UMCheckTerm)
      
    RETURN  
    