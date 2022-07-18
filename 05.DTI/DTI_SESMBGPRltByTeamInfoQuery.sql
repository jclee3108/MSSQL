  
IF OBJECT_ID('DTI_SESMBGPRltByTeamInfoQuery') IS NOT NULL   
    DROP PROC DTI_SESMBGPRltByTeamInfoQuery  
GO  
  
-- v2014.03.17  
  
-- 전기대비손익조회(부문별)_DTI(조회) by이재천 
CREATE PROC DTI_SESMBGPRltByTeamInfoQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle  INT,    
            -- 조회조건     
            @CostYMBFr      NVARCHAR(6),   
            @CostYMBTo      NVARCHAR(6),   
            @CostYMNFr      NVARCHAR(6),   
            @CostYMNTo      NVARCHAR(6),   
            
            @AmtUnit        INT,  
            @IsAdj          NVARCHAR(1)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @CostYMBFr     = ISNULL( CostYMBFr, '' ),  
           @CostYMBTo     = ISNULL( CostYMBTo, '' ),  
           @CostYMNFr     = ISNULL( CostYMNFr, '' ),  
           @CostYMNTo     = ISNULL( CostYMNTo, '' ),  
             
           @AmtUnit       = ISNULL( AmtUnit  , 0 ),    
           @IsAdj         = ISNULL( IsAdj    , '0' )    
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (
            CostYMBFr      NVARCHAR(6),  
            CostYMBTo      NVARCHAR(6),  
            CostYMNFr      NVARCHAR(6),  
            CostYMNTo      NVARCHAR(6),  
              
            AmtUnit        INT,  
            IsAdj          NVARCHAR(1)  
           )   
    
    -- 금액단위가 0일 때, 1로 Update    
    IF @AmtUnit = 0 SELECT @AmtUnit = 1 
    
    -- 대표 활동센터 하위 활동센터만 대상 
    CREATE TABLE #TMP_CCtrSeq     
    (     
        IDX_NO      INT IDENTITY(1,1),  
        CostYM      NCHAR(6)   ,  
        CCtrSeq     INT     ,  
        UMDeptLevel INT     ,  
        OrgCd       NVARCHAR(20), 
        DataKind    INT 
    )   
   
    DECLARE @CostYM  NCHAR(6),  
            @MinorSort INT  
    
    SELECT @CostYM = @CostYMBFr    
    
    WHILE @CostYM <= @CostYMBTo  
    BEGIN   
        INSERT INTO #TMP_CCtrSeq (CostYM, CCtrSeq, UMDeptLevel, OrgCd, DataKind )    
        SELECT @CostYM, A.CCtrSeq, A.UMDeptLevel, A.OrgCd, 1 
          FROM DTI_fnOrgCCtr(@CompanySeq, @CostYM, 0)   AS A    
          JOIN _TDACCtr          AS B ON ( B.CompanySeq = @CompanySeq AND A.CCtrSeq = B.CCtrSeq )   
         WHERE A.IsGPEx = '0' -- 부서손익제외    
           AND (SELECT TOP 1 UMDeptLevel FROM DTI_TESMDOrgCCtr WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.UppCCtrSeq) = 3054002  
         ORDER BY A.OrgCd ASC     
        
        SELECT @CostYM = CONVERT(NCHAR(6),DATEADD (M, 1,@CostYM + '01'),112)    
    END   
    
    SELECT @CostYM = @CostYMNFr   
    
    WHILE @CostYM <= @CostYMNTo  
    BEGIN   
        INSERT INTO #TMP_CCtrSeq (CostYM, CCtrSeq, UMDeptLevel, OrgCd, DataKind )    
        SELECT @CostYM, A.CCtrSeq, A.UMDeptLevel, A.OrgCd, 2 
          FROM DTI_fnOrgCCtr(@CompanySeq, @CostYM, 0)   AS A    
          JOIN _TDACCtr          AS B ON ( B.CompanySeq = @CompanySeq AND A.CCtrSeq = B.CCtrSeq )   
         WHERE A.IsGPEx = '0' -- 부서손익제외    
           AND (SELECT TOP 1 UMDeptLevel FROM DTI_TESMDOrgCCtr WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.UppCCtrSeq) = 3054002  
         ORDER BY A.OrgCd ASC     
        
        SELECT @CostYM = CONVERT(NCHAR(6),DATEADD (M, 1,@CostYM + '01'),112)    
    END  
    
    CREATE TABLE #TEMP_CostKeySeq 
    (
        CostKeySeq      INT, 
        CostYM          NCHAR(6), 
        DataKind        INT
    )
    -- CostKeySeq 가져오기 (전기)
    INSERT INTO #TEMP_CostKeySeq (CostKeySeq, CostYM, DataKind)
    SELECT A.CostKeySeq, 
           A.CostYM, 
           1 AS DataKind   
      FROM _TESMDCostKey    AS A WITH(NOLOCK)   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.CostYM BETWEEN @CostYMBFr AND @CostYMBTo  
       AND A.SMCostMng = 5512001 -- 관리회계   
       
    -- CostKeySeq 가져오기 (당기)
    INSERT INTO #TEMP_CostKeySeq (CostKeySeq, CostYM, DataKind)
    SELECT A.CostKeySeq, 
           A.CostYM, 
           2 AS DataKind 
      FROM _TESMDCostKey    AS A WITH(NOLOCK)   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.CostYM BETWEEN @CostYMNFr AND @CostYMNTo 
       AND A.SMCostMng = 5512001 -- 관리회계   
    
    CREATE TABLE #TEMP_DTI_TESMCProfitResult
    (
        SMGPItem        INT, 
        CostName        NVARCHAR(100), 
        CCtrSeq         INT, 
        DataKind        INT, 
        Value           DECIMAL(19,5), 
        CostNameSort    INT, 
        PrtItemname     NVARCHAR(100), 
        BGColor         INT, 
        MinorSort       INT
    )
    
    -- 메인 데이터 가져오기(전기) - 부문
    INSERT INTO #TEMP_DTI_TESMCProfitResult
    SELECT A.*,   
           (CASE WHEN A.CostName = '' THEN D.ValueText ELSE ' '+A.CostName END) AS PrtItemName,  
           (CASE WHEN A.CostName = '' THEN C.ValueText ELSE 0 END) AS BGColor,  
           B.MinorSort  
    
      FROM (  
            SELECT A.SMGPItem,   
                   ISNULL(E.CostName,'')    AS CostName,  
                   A.CCtrSeq,  
                   B.DataKind,  
                   ROUND(SUM(A.Value)/@AmtUnit,0)   AS Value,   
                   MAX(ISNULL(E.CostNameSort,0))    AS CostNameSort  
                     
              FROM DTI_TESMCProfitResult        AS A WITH(NOLOCK) -- CompanySeq, CostKeySeq, CCtrSeq, SMGPItem, AccSeq   
              JOIN #TEMP_CostKeySeq             AS B              ON ( B.CostKeySeq = A.CostKeySeq AND B.DataKind = 1 )   
              LEFT OUTER JOIN DTI_TPNCostItem   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq    
                                                                   AND E.STDYear    = LEFT(B.CostYM,4)  
                                                                   AND E.AccSeq     = A.AccSeq    
                                                                   AND E.SMGPItem   = A.SMGPItem   
                                                                     )    
             WHERE A.CompanySeq = @CompanySeq   
               AND A.CCtrSeq IN (SELECT CCtrSeq FROM #TMP_CCtrSeq WHERE CostYM = B.CostYM AND DataKind = 1 AND UMDeptLevel = 3054003)   
               --and A.SMGPItem = 1000398017   
             GROUP BY A.SMGPItem, ISNULL(E.CostName,''), A.CCtrSeq, B.DataKind  
           ) AS A   
      JOIN _TDASMinor                   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMGPItem )  
      JOIN _TDASMinorValue              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMGPItem AND C.Serl = 1000004 )  
      JOIN _TDASMinorValue              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMGPItem AND D.Serl = 1000002 )     
    
    -- 메인 데이터 가져오기(당기) - 부문
    INSERT INTO #TEMP_DTI_TESMCProfitResult
    SELECT A.*,   
           (CASE WHEN A.CostName = '' THEN D.ValueText ELSE ' '+A.CostName END) AS PrtItemName,  
           (CASE WHEN A.CostName = '' THEN C.ValueText ELSE 0 END) AS BGColor,  
           B.MinorSort  
    
      FROM (  
            SELECT A.SMGPItem,   
                   ISNULL(E.CostName,'')    AS CostName,  
                   A.CCtrSeq,  
                   B.DataKind,  
                   ROUND(SUM(A.Value)/@AmtUnit,0)   AS Value,   
                   MAX(ISNULL(E.CostNameSort,0))    AS CostNameSort  
                     
              FROM DTI_TESMCProfitResult        AS A WITH(NOLOCK) -- CompanySeq, CostKeySeq, CCtrSeq, SMGPItem, AccSeq   
              JOIN #TEMP_CostKeySeq             AS B              ON ( B.CostKeySeq = A.CostKeySeq AND B.DataKind = 2 )   
              LEFT OUTER JOIN DTI_TPNCostItem   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq    
                                                                   AND E.STDYear    = LEFT(B.CostYM,4)  
                                                                   AND E.AccSeq     = A.AccSeq    
                                                                   AND E.SMGPItem   = A.SMGPItem   
                                                                     )    
             WHERE A.CompanySeq = @CompanySeq   
               AND A.CCtrSeq IN (SELECT CCtrSeq FROM #TMP_CCtrSeq WHERE CostYM = B.CostYM AND DataKind = 2 AND UMDeptLevel = 3054003) 
               --and A.SMGPItem = 1000398017   
             GROUP BY A.SMGPItem, ISNULL(E.CostName,''), A.CCtrSeq, B.DataKind  
           ) AS A   
      JOIN _TDASMinor                   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMGPItem )  
      JOIN _TDASMinorValue              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMGPItem AND C.Serl = 1000004 )  
      JOIN _TDASMinorValue              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMGPItem AND D.Serl = 1000002 )     
    
    -- 메인 데이터 가져오기(전기) - 기타
    INSERT INTO #TEMP_DTI_TESMCProfitResult
    SELECT A.*,   
           (CASE WHEN A.CostName = '' THEN D.ValueText ELSE ' '+A.CostName END) AS PrtItemName,  
           (CASE WHEN A.CostName = '' THEN C.ValueText ELSE 0 END) AS BGColor,  
           B.MinorSort  
    
      FROM (  
            SELECT A.SMGPItem,   
                   '기타'   AS CostName,  
                   888888888 AS CCtrSeq,  
                   B.DataKind,  
                   ROUND(SUM(A.Value)/@AmtUnit,0)   AS Value,   
                   MAX(ISNULL(E.CostNameSort,0))    AS CostNameSort  
                     
              FROM DTI_TESMCProfitResult        AS A WITH(NOLOCK) -- CompanySeq, CostKeySeq, CCtrSeq, SMGPItem, AccSeq   
              JOIN #TEMP_CostKeySeq             AS B              ON ( B.CostKeySeq = A.CostKeySeq AND B.DataKind = 1 )   
              LEFT OUTER JOIN DTI_TPNCostItem   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq    
                                                                   AND E.STDYear    = LEFT(B.CostYM,4)  
                                                                   AND E.AccSeq     = A.AccSeq    
                                                                   AND E.SMGPItem   = A.SMGPItem   
                                                                     )    
             WHERE A.CompanySeq = @CompanySeq   
               AND A.CCtrSeq IN (SELECT CCtrSeq FROM #TMP_CCtrSeq WHERE CostYM = B.CostYM AND DataKind = 1 AND UMDeptLevel <> 3054003)   
               --and A.SMGPItem = 1000398017   
             GROUP BY A.SMGPItem, B.DataKind  
           ) AS A   
      JOIN _TDASMinor                   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMGPItem )  
      JOIN _TDASMinorValue              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMGPItem AND C.Serl = 1000004 )  
      JOIN _TDASMinorValue              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMGPItem AND D.Serl = 1000002 )     
    
    -- 메인 데이터 가져오기(당기) - 기타 
    INSERT INTO #TEMP_DTI_TESMCProfitResult
    SELECT A.*,   
           (CASE WHEN A.CostName = '' THEN D.ValueText ELSE ' '+A.CostName END) AS PrtItemName,  
           (CASE WHEN A.CostName = '' THEN C.ValueText ELSE 0 END) AS BGColor,  
           B.MinorSort  
    
      FROM (  
            SELECT A.SMGPItem,   
                   '기타' AS CostName,  
                   888888888 AS CCtrSeq,  
                   B.DataKind,  
                   ROUND(SUM(A.Value)/@AmtUnit,0)   AS Value,   
                   MAX(ISNULL(E.CostNameSort,0))    AS CostNameSort  
                     
              FROM DTI_TESMCProfitResult        AS A WITH(NOLOCK) -- CompanySeq, CostKeySeq, CCtrSeq, SMGPItem, AccSeq   
              JOIN #TEMP_CostKeySeq             AS B              ON ( B.CostKeySeq = A.CostKeySeq AND B.DataKind = 2 )   
              LEFT OUTER JOIN DTI_TPNCostItem   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq    
                                                                   AND E.STDYear    = LEFT(B.CostYM,4)  
                                                                   AND E.AccSeq     = A.AccSeq    
                                                                   AND E.SMGPItem   = A.SMGPItem   
                                                                     )    
             WHERE A.CompanySeq = @CompanySeq   
               AND A.CCtrSeq IN (SELECT CCtrSeq FROM #TMP_CCtrSeq WHERE CostYM = B.CostYM AND DataKind = 2 AND UMDeptLevel <> 3054003) 
               --and A.SMGPItem = 1000398017   
             GROUP BY A.SMGPItem, B.DataKind  
           ) AS A   
      JOIN _TDASMinor                   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMGPItem )  
      JOIN _TDASMinorValue              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMGPItem AND C.Serl = 1000004 )  
      JOIN _TDASMinorValue              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMGPItem AND D.Serl = 1000002 )     
    
    -- 합계 계산하기    
    INSERT INTO #TEMP_DTI_TESMCProfitResult   
    (  
        SMGPItem, CostName, CCtrSeq, DataKind, Value,   
        CostNameSort, PrtItemName, BGColor, MinorSort   
    )  
    SELECT A.SMGPItem, A.CostName, -1, A.DataKind, SUM(ISNULL(A.Value,0)),   
           MAX(A.CostNameSort), MAX(A.PrtItemName), MAX(A.BGColor), MAX(A.MinorSort)   
             
      FROM #TEMP_DTI_TESMCProfitResult AS A   
     GROUP BY A.SMGPItem, A.CostName, A.DataKind 
    
    -- 증감률 계산하기   
    INSERT INTO #TEMP_DTI_TESMCProfitResult   
    (  
        SMGPItem, CostName, CCtrSeq, DataKind, Value,   
        CostNameSort, PrtItemName, BGColor, MinorSort   
    )  
    SELECT A.SMGPItem, A.CostName, A.CCtrSeq, 3,   
           ISNULL((SUM(CASE WHEN A.DataKind = 2 THEN ISNULL(A.Value,0) ELSE 0 END)  
           -SUM(CASE WHEN A.DataKind = 1 THEN ISNULL(A.Value,0) ELSE 0 END)  
           )/NULLIF(SUM(CASE WHEN A.DataKind = 1 THEN ISNULL(A.Value,0) ELSE 0 END),0),0)*100,   
             
           MAX(A.CostNameSort), MAX(A.PrtItemName), MAX(A.BGColor), MAX(A.MinorSort)  
             
      FROM #TEMP_DTI_TESMCProfitResult AS A   
     GROUP BY A.SMGPItem, A.CostName, A.CCtrSeq 
    

    
    -- Title
    CREATE TABLE #TMP_TItle ( ColIDX INT, Title NVARCHAR(100), TitleSeq INT, Title2 NVARCHAR(100), TitleSeq2 INT)  
    
    INSERT INTO #TMP_TItle  
    SELECT  (ROW_NUMBER() OVER(ORDER BY MAX(A.OrgCd) DESC)-1) * 3  
            ,B.CCtrName   AS Title  
            ,A.CCtrSeq   AS TitleSeq  
            ,N'전기'   AS Title2  
            ,1     AS TitleSeq2  
      FROM #TMP_CCtrSeq  AS A  
      JOIN _TDACCtr   AS B ON B.CompanySeq = @CompanySeq AND A.CCtrSeq = B.CCtrSeq  
     WHERE A.UMDeptLevel = 3054003   -- 부문활동센터만 title 정보에 담음 
     GROUP BY A.CCtrSeq, B.CCtrName  
    
    INSERT INTO #TMP_TItle  
    SELECT ISNULL((SELECT MAX(ColIDX) + 3 FROM #TMP_TItle),0)  
           ,N'기타' AS Title  
           ,888888888  AS TitleSeq  
           ,'전기'   AS Title2  
           ,1    AS TitleSeq2  
    
    INSERT INTO #TMP_TItle  
    SELECT ISNULL((SELECT MAX(ColIDX) + 3 FROM #TMP_TItle),0)  
           ,N'전사합계' AS Title  
           ,-1  AS TitleSeq  
           ,'전기'   AS Title2  
           ,1    AS TitleSeq2  
    
    INSERT INTO #TMP_TItle  
    SELECT ColIDX + 1,  
           Title,  
           TitleSeq,  
           N'당기',  
           2  
      FROM #TMP_TItle  
     WHERE TitleSeq2 = 1  
    
    INSERT INTO #TMP_TItle  
    SELECT ColIDX + 2,  
           Title,  
           TitleSeq,  
           N'증감률',  
           3  
      FROM #TMP_TItle  
    WHERE TitleSeq2 = 1   
    
    -- 고정부
    SELECT MAX(A.PrtItemName) AS PrtItemName,   
           A.SMGPItem,   
           MAX(A.BGColor) AS BGColor,   
           IDENTITY(INT,0,1) AS RowIDX 
      INTO #TEMP_DYM_HARD 
      FROM #TEMP_DTI_TESMCProfitResult AS A   
     GROUP BY A.SMGPItem, A.CostName   
     ORDER BY MAX(A.MinorSort), MAX(A.CostNameSort) DESC  

    -- 최종조회     
    SELECT * FROM #TMP_TItle ORDER BY ColIDX  
    
    SELECT PrtItemName, SMGPItem, BGColor, RowIDX   
    
      FROM #TEMP_DYM_HARD  
     ORDER BY RowIDX   
      
    SELECT C.RowIDX, B.ColIDX, A.Value   
             
      FROM #TEMP_DTI_TESMCProfitResult  AS A   
      JOIN #TMP_TItle              AS B ON ( B.TiTleSeq = A.CCtrSeq AND B.TitleSeq2 = A.DataKind )  
      JOIN #TEMP_DYM_HARD               AS C ON ( C.SMGPItem = A.SMGPItem AND C.PrtItemName = A.PrtItemName )  
     --where C.RowIDX = 0 --A.SMGPItem = 1000398001  
     --where A.Value = 5649516  
     ORDER BY C.RowIDX, B.ColIDX  
    
    RETURN  
GO
exec DTI_SESMBGPRltByTeamInfoQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CostYMBFr>201301</CostYMBFr>
    <CostYMBTo>201301</CostYMBTo>
    <CostYMNFr>201301</CostYMNFr>
    <CostYMNTo>201301</CostYMNTo>
    <AmtUnit>1000</AmtUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021713,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018154