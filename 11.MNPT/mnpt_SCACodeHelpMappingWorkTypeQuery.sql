IF OBJECT_ID('mnpt_SCACodeHelpMappingWorkTypeQuery') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpMappingWorkTypeQuery
GO 
-- v2017.11.22

-- 작업항목 코드도움 by이재천
CREATE PROCEDURE mnpt_SCACodeHelpMappingWorkTypeQuery
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
    
    /*
    SELECT DISTINCT 
           A.UMWorkType, 
           B.MinorName AS UMWorkTypeName, 
           B.MinorSort
      FROM mnpt_TPJTProjectMapping              AS A 
      LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMWorkType ) 
      LEFT OUTER JOIN _TDAItem                  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TPJTProjectDelivery      AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = A.PJTSeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN mnpt_TPJTProjectDelivery  AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = D.PJTSeq AND E.DelvSerl  = D.DelvSerl ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PJTSeq = @Param1
	   AND (@Keyword = '' OR B.MinorName LIKE @Keyword + '%')
     ORDER BY B.MinorSort
    */
    IF @Param2 = '1' -- 모든 작업항목나오기
    BEGIN 
        -- 화태(프로젝트유형)에 매출대상이 아니면 모두 나오도록 적용
        SELECT DISTINCT 
               A.MinorSeq AS UMWorkType, 
               A.MinorName AS UMWorkTypeName, 
               A.MinorSort 
          FROM _TDAUMinor AS A 
         WHERE A.CompanySeq = @CompanySeq
           AND (@Keyword = '' OR A.MinorName LIKE @Keyword)
           AND A.Majorseq = 1015816
         ORDER BY A.MinorSort

    END 
    ELSE 
    BEGIN 
        -- 화태(프로젝트유형)에 매출대상이 아니면 모두 나오도록 적용
        SELECT DISTINCT 
               A.MinorSeq AS UMWorkType, 
               A.MinorName AS UMWorkTypeName, 
               A.MinorSort 
          FROM _TDAUMinor                           AS A 
          LEFT OUTER JOIN mnpt_TPJTProjectMapping   AS B ON ( B.CompanySeq = @CompanySeq AND B.UMWorkType = A.MinorSeq AND B.PJTSeq = @Param1 ) 
          LEFT OUTER JOIN _TPJTProject              AS F ON ( F.CompanySeq = @CompanySeq AND F.PJTSeq = @Param1 ) 
          LEFT OUTER JOIN _TPJTType                 AS G ON ( G.CompanySeq = @CompanySeq AND G.PJTTypeSeq = F.PJTTypeSeq ) 
         WHERE A.CompanySeq = @CompanySeq
           AND (@Keyword = '' OR A.MinorName LIKE @Keyword)
           AND ( (CASE WHEN G.SMSalesRecognize = 7002005 THEN '1' ELSE '0' END = '1')
              OR (CASE WHEN G.SMSalesRecognize = 7002005 THEN '1' ELSE '0' END = '0' AND B.UMWorkType IS NOT NULL)
               ) -- 화태(프로젝트유형)에 매출대상이 아니면 모두 나오도록 적용
           AND A.Majorseq = 1015816
         ORDER BY A.MinorSort
    END 
    
    SET ROWCOUNT 0 
    
    RETURN 


