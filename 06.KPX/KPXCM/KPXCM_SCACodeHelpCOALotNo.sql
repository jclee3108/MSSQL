IF OBJECT_ID('KPXCM_SCACodeHelpCOALotNo') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpCOALotNo
GO 

-- v2016.05.09 

 /*************************************************************************************************    
 PROCEDURE    - KPXCM_SCACodeHelpCOALotNo    
 DESCRIPTION - CodeHellp 정보를 _TLGLotMaster 에서 조회한다.    
 작  성  일 - 2009년 3월    
 수  정  일 -    
 *************************************************************************************************/    
 CREATE PROC KPXCM_SCACodeHelpCOALotNo
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
  
  DECLARE @WHSeq   INT,    
             @StdDate NCHAR(8)    
      
  
    -- SELECT  
    --A.LotNo        AS LotNo,    
    --         B.ItemName     AS ItemName,    
    --         B.ItemNo       AS ItemNo,    
    --         -- 재고 수량을 보여 주고 있어서 기준단위로 변경 함 2011.07.15 by kskwon    
    --           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq), '') AS UnitName,    
    --         A.CreateDate   AS CreateDate,    
    --         A.CreateTime   AS CreateTime,    
    --         A.SourceLotNo  AS SourceLotNo,    
    --           A.OriLotNo     AS OriLotNo,    
    --         A.ValiDate,    
    --         A.ValidTime,    
    --         A.RegDate,    
    --         ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = X.WHSeq), '') AS WHName,    
    --         ISNULL(X.StockQty,0) AS StockQty,    
    --         C.LotSeq AS LotSeq,    
    --         A.Remark AS Remark,    
    --         A.ItemSeq       AS ItemSeq,    
    --         B.UnitSeq       AS UnitSeq,    
    --         ISNULL(X.WHSeq, 0) AS WHSeq,    
    --         B.Spec,      -- 규격    
    --         A.Dummy1    AS Dummy1,    
    --         A.Dummy2    AS Dummy2,    
    --         A.Dummy3    AS Dummy3,    
    --         A.Dummy4    AS Dummy4,    
    --         A.Dummy5    AS Dummy5,    
    --         A.Dummy6    AS Dummy6,    
    --         A.Dummy7    AS Dummy7,    
    --         M.CustName AS Manufacture       -- 제조처    
    --   INTO  #TempLot    
    --   FROM  _TLGLotMaster AS A WITH (NOLOCK)     
    --         LEFT OUTER JOIN (SELECT LotNo, ItemSeq, WHSeq, SUM(ISNULL(STDStockQty,0)) AS StockQty    
    --                            FROM #GetInOutLotStock    
    --                           GROUP BY LotNo, ItemSeq, WHSeq) AS X ON A.CompanySeq = @CompanySeq    
    --                                                               AND X.LotNo      = A.LotNo    
    --                                                               AND X.ItemSeq    = A.ItemSeq    
    --                                                               AND (@Param2 = '' OR @Param2 = '0' OR X.WHSeq  = @Param2)    
    --         LEFT OUTER JOIN _TDAItem     AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq    
    --                                                        AND A.ItemSeq    = B.ItemSeq    
    --         LEFT OUTER JOIN _TLGLotSeq     AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq    
    --                                                        AND A.ItemSeq    = C.ItemSeq    
    --                                                        AND A.LotNo    = C.LotNo    
    --         LEFT OUTER JOIN _TDACust        AS M WITH (NOLOCK) ON M.CompanySeq = A.CompanySeq    
    --                                                           AND M.CustSeq = A.CustSeq  
    ----JOIN KPX_TQCTestResult   AS Z WITH(NOLOCK) ON A.CompanySeq = Z.CompanySeq
    ----             AND A.ItemSeq    = Z.ItemSeq
    ----             AND A.LotNo    = Z.LotNo
    ----             AND
    --   WHERE A.CompanySeq = @CompanySeq    
    --    AND A.LotNo LIKE @Keyword + '%'    
    --    AND A.LotNo IN (SELECT LotNo 
    --                     FROM KPX_TQCTestResult AS R
    --                         JOIN KPX_TQCTestResultItem AS I WITH(NOLOCK) ON I.CompanySeq = R.CompanySeq
    --                                                                     AND I.QCSeq = R.QCSeq
    --                     WHERE R.CompanySeq=@CompanySeq 
    --                     AND (ISNULL(@Param3,0)=0 OR R.ItemSeq = @Param3)
    --                     AND (ISNULL(@Param4,0)=0 OR (CASE WHEN ISNULL(R.QCType,0) = 0 THEN I.QCType
    --                                                      ELSE R.QCType END) =@Param4))
    --AND ( ISNULL(@Param3,0)=0 OR A.ItemSeq = @Param3)
      -- ORDER BY A.ValiDate, A.LotNo      -- 2013-01-15 이성덕 수정 : 유효일자, LotNo 순으로 올림차순으로 수정      
            
    
    
    
     SET ROWCOUNT @PageCount      
     
      CREATE TABLE #temp 
     (
         LotNo       nvarchar(100), 
         ItemName    nvarchar(100), 
         ItemNo      nvarchar(100), 
         UnitName    nvarchar(100), 
         ItemSeq     int, 
         LotSeq      nvarchar(100)
     ) 
     
     
     IF NOT EXISTS (  
     
     SELECT 1 
       FROM KPX_TQCTestResult AS A 
       JOIN KPX_TQCTestResultItem AS B ON ( b.companyseq = a.companyseq and b.qcseq = a.qcseq ) 
      WHERE a.companyseq = @CompanySeq
        AND a.lotno LIKE  @Keyword + '%' 
        --AND A.SMTestResult NOT IN (1010418002)  
        --and a.workcenterseq = 1 
        AND (ISNULL(@Param1,0)=0 OR A.ItemSeq = @Param1)
        AND ISNULL(NULLIF(b.qctype,0), A.QCType) in (SELECT DISTINCT QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySEq and IsCOA = '1' ) 
        AND b.SMTestResult <> '0'
        AND ISSpecial = 0  
      GROUP BY ISNULL(NULLIF(b.qctype,0), A.QCType), b.testItemSeq, B.QAAnalysisType, B.QCUnit
      HAVING MIN(b.SMTestResult) = '6035004'
        ) 
     BEGIN
         
         INSERT INTO #temp ( LotNo, ItemName, ItemNo, UnitName, ItemSeq, LotSeq ) 
         SELECT DISTINCT 
                R.LotNo,  
                M.ItemName,  
                M.ItemNo,  
                U.UnitName,  
                M.ItemSeq,  
                R.LotNo      AS LotSeq
           FROM KPX_TQCTestResult AS R  
                JOIN KPX_TQCTestResultItem AS I WITH(NOLOCK) ON I.CompanySeq = R.CompanySeq  
                                                            AND I.QCSeq = R.QCSeq  
                LEFT OUTER JOIN _TDAItem AS M WITH(NOLOCK) ON M.CompanySeq = R.CompanySeq  
                                                          AND M.ItemSeq = R.ItemSeq  
                LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = M.CompanySeq  
                                                          AND U.UnitSeq = M.UnitSeq  
          WHERE R.CompanySeq= @CompanySeq   
            AND R.LotNo LIKE  @Keyword + '%' 
            -- AND R.SMTestResult NOT IN (1010418002)  
            
            AND (ISNULL(@Param2,0)=0 OR (CASE WHEN ISNULL(R.QCType,0) = 0 THEN I.QCType  
                                         ELSE R.QCType END) =@Param2)   
          AND (ISNULL(@Param1,0)=0 OR R.ItemSeq = @Param1)
          AND ISNULL(NULLIF(I.QCType,0), R.QCType) in (SELECT DISTINCT QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq and IsCOA = '1' ) 
          AND I.SMTestResult <> '6035004'   AND I.SMTestResult <> 0      
          AND R.LotNo NOT IN  ( SELECT LotNo       
                                  FROM KPX_TQCTestResult AS A       
                                  JOIN KPX_TQCTestResultItem AS B ON ( b.companyseq = a.companyseq and b.qcseq = a.qcseq )       
                                 WHERE a.companyseq = @CompanySeq
                                   AND (ISNULL(@Param1,0)=0 OR A.ItemSeq = @Param1)
                                   AND ISNULL(NULLIF(b.qctype,0), A.QCType) in (SELECT DISTINCT QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySEq and IsCOA = '1' ) 
                                   AND b.SMTestResult <> '0'      
                                   AND ISSpecial = 0  
                                 GROUP BY  ISNULL(NULLIF(B.QCType,0), A.QCType), b.testItemSeq, B.QAAnalysisType, B.QCUnit  , LotNo   
                                HAVING MIN(b.SMTestResult) = '6035004' )  
         
         SELECT * FROM #temp 
      END 
     ELSE
     BEGIN
         SELECT * FROM #temp 
     END 
     

     
     
    /* 원본 
     
     --SELECT DISTINCT 
     --       R.LotNo,
     --       M.ItemName,
     --       M.ItemNo,
     --       U.UnitName,
     --       M.ItemSeq,
     --       R.LotNo      AS LotSeq
     --  FROM KPX_TQCTestResult AS R
     --       JOIN KPX_TQCTestResultItem AS I WITH(NOLOCK) ON I.CompanySeq = R.CompanySeq
     --                                                   AND I.QCSeq = R.QCSeq
     --       LEFT OUTER JOIN _TDAItem AS M WITH(NOLOCK) ON M.CompanySeq = R.CompanySeq
     --                                                 AND M.ItemSeq = R.ItemSeq
     --       LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = M.CompanySeq
     --                                                 AND U.UnitSeq = M.UnitSeq
     -- WHERE R.CompanySeq=@CompanySeq 
     --   AND R.LotNo LIKE @Keyword + '%'  
     --   AND R.SMTestResult NOT IN (1010418002)
     ---- 합격건이 존재할 경우 조회되도록 수정 150729
     --AND  EXISTS (SELECT 1 FROM KPX_TQCTestResultItem 
     --                  WHERE CompanySeq = @CompanySeq AND QCSeq = R.QCSeq AND SMTestResult = '6035003' AND ISSpecial = 0 AND QCType IN (7, 8)) 
     --   AND (ISNULL(@Param1,0)=0 OR R.ItemSeq = @Param1)
     --   AND (ISNULL(@Param2,0)=0 OR (CASE WHEN ISNULL(R.QCType,0) = 0 THEN I.QCType
     --                                 ELSE R.QCType END) =@Param2) 
     
     
     */
      /***************하부조건 반영***************/      
  --     DECLARE @SQL NVARCHAR(MAX)      
       
 --     IF ISNULL(@SubConditionSql, '') = ''      
 --     BEGIN      
 --        SELECT @SQL = 'SELECT *      
 --                   FROM #TempLot      
 --                  ORDER BY ValiDate, LotNo'      
 --     END      
 --     ELSE      
 --     BEGIN              
 --        SELECT @SQL = 'SELECT *      
 --                   FROM #TempLot      
 --                  WHERE '+ LTRIM(RTRIM(@SubConditionSql)) +      
 --                ' ORDER BY ValiDate, LotNo'      
 --     END      
 ----select @Sql
 --     EXEC sp_executesql @SQL      
            
      /******************************************/ -- 20130205 박성호 추가      
     
     SET ROWCOUNT 0    
      
 RETURN    