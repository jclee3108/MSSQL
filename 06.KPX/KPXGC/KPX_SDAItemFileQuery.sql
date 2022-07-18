
IF OBJECT_ID('KPX_SDAItemFileQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemFileQuery
GO 

-- v2014.11.04 

-- 품목첨부파일 조회 by이재천


/*************************************************************************************************          
 설  명 - 품목첨부파일 조회      
 작성일 - 2008.10.  : CREATED BY JMKIM      
*************************************************************************************************/          
CREATE PROCEDURE KPX_SDAItemFileQuery     
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10)= '',      
      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS             
    DECLARE   @docHandle      INT,        
              @ItemSeq        INT    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument            
    
    SELECT  @ItemSeq     = ISNULL(ItemSeq, '')    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH ( ItemSeq  INT)            
    
    SELECT @ItemSeq  = ISNULL(LTRIM(RTRIM(@ItemSeq)),   0)    
    
    SELECT A.ItemSeq AS ItemSeq,    
           A.FileSeq AS FileSeq     
    FROM KPX_TDAItemFile A WITH (NOLOCK)    
    WHERE (A.CompanySeq  = @CompanySeq)    
      AND (A.ItemSeq     = @ItemSeq)    
    
RETURN        
  