
IF OBJECT_ID('KPX_SDAItemSalesQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemSalesQuery
GO 

-- v2014.11.04 

-- 품목영업정보 조회 by이재천
/*************************************************************************************************        
 설  명 - 품목영업정보 조회    
 작성일 - 2008.6.  : CREATED BY JMKIM    
*************************************************************************************************/        
CREATE PROCEDURE KPX_SDAItemSalesQuery      
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
      
    -- 마스타 등록 생성    
    CREATE TABLE #KPX_TDAItemSales (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemSales'    
  
    SELECT  A.ItemSeq   AS ItemSeq,  
            A.IsVat     AS IsVat, -- 부가세포함여부  
            A.SMVatKind AS SMVatKind, -- 부가세구분  
            A.SMVatType AS SMVatType, -- 부가세종류  
            A.IsOption  AS IsOption, -- 옵션여부  
            A.IsSet     AS IsSet, -- Set품목여부  
            ISNULL(A.Guaranty,0) AS Guaranty,  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMVatKind),'') AS VatKindName,  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMVatType),'') AS VatTypeName,  
            ISNULL(A.HSCode, '') AS HSCode,  
            B.IDX_NO AS IDX_NO  
    FROM KPX_TDAItemSales A WITH(NOLOCK)  
         JOIN #KPX_TDAItemSales AS B ON A.CompanySeq = @CompanySeq  
                                AND A.ItemSeq = B.ItemSeq  
    WHERE 1=1    
      AND (A.CompanySeq  = @CompanySeq)  
  
RETURN      
  