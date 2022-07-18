
IF OBJECT_ID('KPX_SDAItemClassQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemClassQuery
GO 

-- 2014.11.04 

-- 품목분류 조회 by이재천
/*************************************************************************************************          
 설  명 - 품목분류 조회      
 작성일 - 2008.6.  : CREATED BY JMKIM      
*************************************************************************************************/          
CREATE PROCEDURE KPX_SDAItemClassQuery    
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
    WITH ( ItemSeq  INT )            
    
    SELECT @ItemSeq  = ISNULL(LTRIM(RTRIM(@ItemSeq)),   0)    
    
    SELECT   ISNULL(C.MajorName,'') AS UMItemClassName -- 품목분류구분    
            ,ISNULL(A.UMajorItemClass,0) AS UMajorItemClass -- 품목분류구분코드    
            ,ISNULL(D.MinorName,'') AS ItemClassName -- 품목분류세목    
            ,ISNULL(B.UMItemClass,0) AS UMItemClass  -- 품목분류세목코드    
            ,ISNULL(A.IsItem,'0') AS IsItem    
     FROM _TDADefineItemClass A With(Nolock) LEFT OUTER JOIN KPX_TDAItemClass B With(Nolock)    
                                               ON A.CompanySeq = B.CompanySeq    
                                              AND A.UMajorItemClass = B.UMajorItemClass    
                                              AND B.ItemSeq = @ItemSeq    
                                             LEFT OUTER JOIN _TDAUMajor C With(Nolock)    
                                               ON A.CompanySeq = C.CompanySeq    
                                              AND A.UMajorItemClass = C.MajorSeq    
                                             LEFT OUTER JOIN _TDAUMinor D With(Nolock)    
                                               ON B.CompanySeq = D.CompanySeq    
                                              AND B.UMItemClass = D.MinorSeq    
    
    WHERE 1 = 1      
      AND (A.CompanySeq = @CompanySeq)    
      AND (A.IsItem = '1')    
    Order by A.Priority    
    
RETURN        
  
  