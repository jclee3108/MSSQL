IF OBJECT_ID('hencom_SCACodeHelpToolItem') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpToolItem
GO 

-- v2017.02.22 

-- 부외재고관리설비 by이재천
CREATE PROCEDURE hencom_SCACodeHelpToolItem
    @WorkingTag     NVARCHAR(1)      ,
    @LanguageSeq    INT              ,
    @CodeHelpSeq    INT              ,
    @DefQueryOption INT              ,    -- 2: direct search
    @CodeHelpType   TINYINT          ,
    @PageCount      INT = 20         ,
    @CompanySeq     INT = 1          ,
    @Keyword        NVARCHAR(50) = '',
    @Param1         NVARCHAR(50) = '',    
    @Param2         NVARCHAR(50) = '',   
    @Param3         NVARCHAR(50) = '',
    @Param4         NVARCHAR(50) = ''
AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT A.ItemSeq, A.ItemName, A.ItemNo, A.Spec, A.UnitSeq, B.UnitName
      FROM _TDAItem                     AS A 
      LEFT OUTER JOIN _TDAUnit          AS B ON ( B.CompanySeq = @CompanySeq AND B.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.MngSerl = 1000001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AssetSeq = 28 -- 설비(소모품) 
       AND (C.MngValText = 'True' OR C.MngValText = '1') -- 추가정보 부외재고관리유무
       AND (@Keyword = '' OR A.ItemName LIKE @Keyword+'%') 

    SET ROWCOUNT 0                  
              
    RETURN