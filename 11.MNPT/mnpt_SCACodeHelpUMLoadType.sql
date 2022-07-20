     
IF OBJECT_ID('mnpt_SCACodeHelpUMLoadType') IS NOT NULL       
    DROP PROC mnpt_SCACodeHelpUMLoadType      
GO      
      
-- v2017.11.09
      
-- 하역방식(작업)-코드도움_mnpt by 이재천  
CREATE PROC mnpt_SCACodeHelpUMLoadType      
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SET ROWCOUNT @PageCount      
    
    DECLARE @UMLoadTypeC INT 

    SELECT @UMLoadTypeC = A.UMLoadType
      FROM mnpt_TPJTProject AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = CONVERT(INT,@Param1) 

    SELECT A.MinorName AS UMLoadTypeName, -- 하역방식(작업)
           A.MinorSeq AS UMLoadType
      FROM _TDAUMinor                   AS A   
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
	 WHERE A.CompanySeq	= @CompanySeq 
       AND A.MajorSeq = 1015935 
       AND B.ValueSeq = @UMLoadTypeC
       AND (@Keyword = '' OR A.MinorName LIKE @Keyword + '%')
    
    SET ROWCOUNT 0 

    RETURN 