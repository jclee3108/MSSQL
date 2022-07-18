
IF OBJECT_ID('KPX_SDAItemUnitQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitQuery
GO 

-- v2014.11.04 

-- 품목단위환산조회 by이재천
CREATE PROCEDURE KPX_SDAItemUnitQuery    
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
      
    SELECT  @ItemSeq = ItemSeq    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH (  ItemSeq     INT)         
    
    
    --================================================================================================================================      
    -- 업무기능    
    --================================================================================================================================      
    SELECT IDENTITY(INT, 0, 1)  AS ColIDX,          
           ISNULL( ISNULL( Z.Word, A.MinorName ), '' ) AS TitleName,          
           A.MinorSeq           AS TitleSeq        
      INTO #Temp_TDAItemUnitModule    
      FROM _TDAUMinor A WITH (NOLOCK)    
      LEFT OUTER JOIN _TCADictionary AS Z WITH(NOLOCK) ON ( Z.LanguageSeq = @LanguageSeq AND A.WordSeq = Z.WordSeq )    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.MajorSeq   = 1003     
     ORDER BY A.MinorSeq       
    
    SELECT A.TitleName            AS Title,      
           A.TitleSeq             AS TitleSeq      
      FROM #Temp_TDAItemUnitModule AS A      
    ORDER BY ColIDX      
    
    --================================================================================================================================      
    -- 품목단위    
    --================================================================================================================================      
    
    SELECT  IDENTITY(INT, 0, 1)   AS RowIDX,      
            ISNULL(B.UnitName,'') AS UnitName,    
            ISNULL(A.UnitSeq,0)   AS UnitSeq,    
            ISNULL(A.BarCode,'')  AS BarCode,    
            ISNULL(A.ConvNum,0)   AS ConvNum,    
            ISNULL(A.ConvDen,0)   AS ConvDen,    
            ISNULL(A.TransConvQty,0) AS TransConvQty,    
            ISNULL(A.UnitSeq,0)   AS UnitSeqOld    
     INTO #Temp_TDAItemUnit    
     FROM KPX_TDAItemUnit A With(Nolock)     
           LEFT OUTER JOIN _TDAUnit B With(Nolock) ON A.CompanySeq = B.CompanySeq      
                                                  AND A.UnitSeq    = B.UnitSeq      
    WHERE A.CompanySeq = @CompanySeq    
      AND A.ItemSeq = @ItemSeq     
    Order by A.UnitSeq      
    
    
    SELECT  ISNULL(UnitName,'')  AS UnitName,    
            ISNULL(UnitSeq,0)    AS UnitSeq,    
            ISNULL(BarCode,'')   AS BarCode,    
            ISNULL(ConvNum,0)    AS ConvNum,    
            ISNULL(ConvDen,0)    AS ConvDen,    
            ISNULL(TransConvQty,0) AS TransConvQty,    
            ISNULL(UnitSeqOld,0) AS UnitSeqOld    
     FROM #Temp_TDAItemUnit      
    ORDER BY RowIDX      
    
    --================================================================================================================================      
    -- 품목단위업무기능    
    --================================================================================================================================      
    SELECT C.RowIDX             AS RowIDX,      
           B.ColIDX             AS ColIDX,      
           ISNULL(A.IsUsed,'0') AS IsUsed    
      FROM KPX_TDAItemUnitModule AS A WITH (NOLOCK)     
           JOIN #Temp_TDAItemUnitModule AS B      ON A.UMModuleSeq = B.TitleSeq    
           JOIN #Temp_TDAItemUnit       AS C      ON A.UnitSeq     = C. UnitSeq    
     WHERE A.CompanySeq = @CompanySeq    
         AND A.ItemSeq    = @ItemSeq    
      
RETURN        