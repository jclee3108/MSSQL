IF OBJECT_ID('KPXCM_SCACodeHelpCOAItemName') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpCOAItemName
GO 

-- 2016.05.30 

/*************************************************************************************************    
PROCEDURE   - KPXCM_SCACodeHelpCOAItemName    
작  성  일  - 2015.03.10
수  정  일  -    
*************************************************************************************************/    
CREATE PROC KPXCM_SCACodeHelpCOAItemName
    @WorkingTag         NVARCHAR(1),    
    @LanguageSeq        INT,    
    @CodeHelpSeq        INT,    
    @DefQueryOption     INT, -- 2: direct search    
    @CodeHelpType       TINYINT,    
    @PageCount          INT = 20,    
    @CompanySeq         INT = 1,    
    @Keyword            NVARCHAR(50) = '',    
    @Param1             NVARCHAR(50) = '',    
    @Param2             NVARCHAR(50) = '',    
    @Param3             NVARCHAR(50) = '',    
    @Param4             NVARCHAR(50) = '',      
    @SubConditionSql    NVARCHAR(500)= '' -- 20130205 박성호 추가     
AS    
	
	--DECLARE @WHSeq   INT,    
 --           @StdDate NCHAR(8)    
           
    SET ROWCOUNT @PageCount 
         
    --CREATE TABLE #CustItem
    --(
    --    CustSeq         INT NULL, 
    --    ItemSeq         INT,
    --    DVPlaceSeq      INT NULL,
    --    CustItemName    NVARCHAR(100) NULL,
    --    CustItemNo      NVARCHAR(100) NULL,
    --    CustItemSpce    NVARCHAR(100) NULL
    --)
    --INSERT INTO #CustItem
    SELECT DISTINCT 
           A.CustSeq,
           A.ItemSeq, 
           Z.DVPlaceSeq,
           --Z.CustItemName,
           --Z.CustItemNo,
           --Z.CustItemSpec,
           C.CustName,
           I.ItemName,
           I.ItemNo,
           I.Spec,
           D.DVPlaceName
      FROM (SELECT CompanySeq, CustSeq, ItemSeq--, DVPlaceSeq
              FROM KPX_TQCQAQualityAssuranceSpec 
             WHERE CompanySeq = @CompanySeq
             GROUP BY CompanySeq, CustSeq, ItemSeq) AS A
           LEFT OUTER JOIN KPX_TSLCustItem AS Z WITH(NOLOCK) ON Z.CompanySeq = A.CompanySeq
                                                            AND Z.CustSeq = A.CustSeq
                                                            AND Z.ItemSeq = A.ItemSeq
                                                            --AND Z.DVPlaceSeq = A.DVPlaceSeq
           LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                     AND I.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN _TDACust AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                     AND C.CustSeq = A.CustSeq
           LEFT OUTER JOIN _TSLDeliveryCust AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                             AND D.DVPlaceSeq = Z.DVPlaceSeq
     WHERE A.CompanySeq=@CompanySeq 
       AND (ISNULL(@Param1,0)=0 OR A.CustSeq = @Param1)
       AND (@Keyword = '' OR I.ItemName LIKE @Keyword + '%')
    
            
        --SELECT A.*,
        --       C.CustName,
        --       I.ItemName,
        --       I.ItemNo,
        --       I.Spec,
        --       D.DVPlaceName
        --  FROM #CustItem AS A
        --       LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
        --                                                 AND I.ItemSeq = A.ItemSeq
        --       LEFT OUTER JOIN _TDACust AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
        --                                                 AND C.CustSeq = A.CustSeq
        --       LEFT OUTER JOIN _TSLDeliveryCust AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
        --                                                         AND D.DVPlaceSeq = A.DVPlaceSeq
        --  WHERE I.ItemName LIKE @Keyword + '%'  

    SET ROWCOUNT 0    

    
RETURN   

GO


