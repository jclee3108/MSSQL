
IF OBJECT_ID('KPXLS_SPNWeeklyPlanbyRstListPrintQuery') IS NOT NULL 
    DROP PROC KPXLS_SPNWeeklyPlanbyRstListPrintQuery
GO 

-- v2016.01.07 

-- 사업계획조회 출력물 by 이재천 
  
/************************************************************  
 설  명 - 데이터-사업계획조회 : 조회  
 작성일 - 20151127  
 작성자 - 박진희  
 수정자 -   
************************************************************/  
  
CREATE PROC KPXLS_SPNWeeklyPlanbyRstListPrintQuery                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    DECLARE @docHandle      INT,  
            @PlanYear       NCHAR(4),  
            @Amd            NVARCHAR(2),  
            @PlanMonth      INT,  
            @StdMonth       NCHAR(6),  
            @MM             NCHAR(2),  
            @BizUnit        INT,  
            @UMisNew        INT   
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @PlanYear     = ISNULL(PlanYear ,'' )  ,  
           @Amd          = ISNULL(Amd      ,'')  ,  
           @PlanMonth    = ISNULL(PlanMonth  ,0 ),  
           @BizUnit      = ISNULL(BizUnit,0),   
           @UMisNew      = ISNULL(UMIsNew,0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (  
             PlanYear        NCHAR(4),  
             Amd             NVARCHAR(2),  
             PlanMonth       INT         ,  
             BizUnit         INT,  
             UMIsNew         INT  
           )  
  
    
    --------------------------  
    -- 동적컬럼  
    --------------------------      
    CREATE TABLE #TCol  
    (  
        ColIDX        INT ,  
        TitleName     NVARCHAR(100),  
        TitleSeq      INT,  
        TitleSubName  NVARCHAR(100),  
        TitleSubSeq   INT,  
        TitleSubName2 NVARCHAR(100),  
        TitleSubSeq2  INT  
    )  
                 
    -- 기준월구하기  
    SELECT @StdMonth = @PlanYear + RIGHT('00' + CONVERT(NVARCHAR(2),@PlanMonth),2)  
    SELECT @MM = RIGHT('00' + CONVERT(NVARCHAR(2),@PlanMonth),2)  
  
    ----------------------------------  
    -- 기준주차구하기  
    /*  
        주차에 대한 시작 일자, 요일은? (KPX)추가개발 Mapping정보 설정에 정의된 시작요일로 표시  
        단, 해당하는 월에 해당하는 일자만 반영한다.  
        예)시작요일을 일요일로 지정한 경우  
          2015.11월 : 1주차 1 ~ 7, 2주차 8 ~ 14, 3주차 15 ~ 21, 4주차 22 ~ 28, 5주차 29 ~30  
          2015.12월 : 1주차 1 ~ 5, 2주차 6 ~ 12, 3주차 13 ~ 19, 4주차 20 ~ 26, 5주차 27 ~ 31  
          2016. 1월 : 1주차 1 ~ 2, 2주차 3 ~ 8 등  
    */  
    ----------------------------------  
    CREATE TABLE #TStdWk  
    (  
        WkSeq   INT,  
        WKDate  NCHAR(8)  
    )  
    create index idx_#TStdWk ON #TStdWk(WkSeq)  
      
    -- 일요일 기준으로 하드코딩함 추후 변경예정  
    DECLARE @StdWkDay INT,  
            @StdWkCnt INT,  
            @WkDay    INT  
    SELECT @StdWkDay = 1 -- 1~7 일요일~토요일  
  
    DECLARE @i INT,  
            @StdDate NCHAR(8)  
  
    SELECT @i=0, @StdWkCnt=1  
      
    WHILE (1=1)  
    BEGIN   
        SELECT @StdDate = CONVERT(NCHAR(8),DATEADD(DD,@i,@StdMonth + '01'),112)  
          
        IF @StdMonth <> LEFT(@StdDate,6) BREAK  
          
        SELECT @WkDay = DATEPART(dw, @StdDate)  
          
        IF (@WkDay = @StdWkDay AND @i <> 0)  
            SELECT @StdWkCnt = @StdWkCnt + 1   
          
        INSERT INTO #TStdWk   
        SELECT @StdWkCnt, @StdDate  
  
        SELECT @i = @i + 1          
    END   
      
    SELECT WkSeq,  MIN(WKDate) AS WKDateFr, MAX(WKDate) AS WKDateTo  
      INTO #TWeekDate  
      FROM #TStdWk  
     GROUP BY WkSeq  
      
    INSERT INTO #TCol(ColIDX, TitleSeq, TitleName, TitleSubName, TitleSubSeq, TitleSubName2, TitleSubSeq2 )  
    SELECT WKSeq - 1, WKSeq, CONVERT(NVARCHAR(2),WKSeq) + '주차 (' + CONVERT(NVARCHAR(2),@PlanMonth) + '.' + RIGHT(WKDateFr,2) + ' ~ ' + CONVERT(NVARCHAR(2),@PlanMonth) + '.' + RIGHT(WKDateTo,2) + ')',  
           TitleSubName, TitleSubSeq, TitleSubName2, TitleSubSeq2  
      From #TWeekDate AS A  
           CROSS JOIN (  
                          SELECT N'계획' AS TitleSubName , 1 AS TitleSubSeq UNION  
                        SELECT N'실적' AS TitleSubName , 2 AS TitleSubSeq   
                       ) AS X   
           CROSS JOIN (  
                        SELECT N'수량' AS TitleSubName2 , 1 AS TitleSubSeq2 UNION  
                        SELECT N'금액' AS TitleSubName2 , 2 AS TitleSubSeq2   
                       ) AS Z  
    ORDER BY A.WkSeq, X.TitleSubSeq, Z.TitleSubSeq2  
  
    --SELECT * FROM #TCol  
      
  
    -----------------------------------      
    -- 고정컬럼  
    -----------------------------------  
    -- 매출기준데이터가저오기  
    -----------------------------  
    SELECT B.ItemSeq, C.WkSeq AS Weekly, SUM(B.Qty) AS RstQty, SUM(B.DomAmt) AS RstAmt  
      INTO #TRstData  
      FROM _TSLSales AS A WITH(NOLOCK)  
           JOIN _TSLSalesItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq   
           JOIN #TStdWk       AS C              ON A.SalesDate  = C.WkDate       
     WHERE A.CompanySeq = @CompanySeq  
     GROUP BY B.ItemSeq, C.WkSeq  
  
    -----------------------------------  
    -- 품목순서  
    -----------------------------------        
    SELECT B.ValueSeq AS ItemSeq, A.MinorSort AS ItemSort  
      INTO #TItemSort  
      FROM _TDAUMinor AS A  
           JOIN _TDAUMinorValue AS B ON A.CompanySeq = B.CompanySeq AND A.MajorSeq = B.MajorSeq AND A.Minorseq = B.MinorSeq AND B.Serl = 1000001  
     WHERE A.MajorSeq = 1011999  
     ORDER BY ItemSort  
  
    -----------------------------------  
    -- 단가조회   
    -- 동일품목에 확정단가가 있으면 확정단가 기준  
    -----------------------------------        
    SELECT X.BizUnit, X.ItemSeq, X.CurrSeq, X.UMIsNew, MAX(X.PlanPrice) AS PlanPrice  
      INTO #TItemPrice  
      FROM KPXLS_TPNBisPlanItem AS X  
           JOIN (  
                    SELECT A.PlanSeq, A.Amd, A.ItemSeq, A.BizUnit,A.CurrSeq, A.UMIsNew, MAX(A.UMIsCfm) AS UMIsCfm  
                      FROM KPXLS_TPNBisPlan AS M   
                           JOIN KPXLS_TPNBisPlanItem  AS A WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq AND M.PlanSeq = A.PlanSeq AND M.Amd = A.Amd  
                     WHERE M.CompanySeq  = @CompanySeq  
                       AND M.PlanYear    = @PlanYear  
                       AND M.Amd         = @Amd  
                     GROUP BY A.PlanSeq, A.Amd, A.ItemSeq, A.BizUnit, A.CurrSeq, A.UMIsNew  
                ) AS Z ON X.PlanSeq = Z.PlanSeq AND X.Amd = Z.Amd AND X.ItemSeq = Z.ItemSeq AND X.CurrSeq = Z.CurrSeq AND X.UMIsCfm = Z.UMIsCfm AND X.BizUnit = Z.BizUnit AND X.UMIsNew = Z.UMIsNew  
     GROUP BY X.BizUnit, X.ItemSeq, X.CurrSeq, X.UMIsNew  
       
    CREATE TABLE #TRowData  
    (   
        IDX             INT,  
        PlanSeq         INT,  
        Amd             NCHAR(2),  
        ItemSeq         INT,  
        BizUnit         INT,  
        BizUnitName     NVARCHAR(200),  
        UMIsNew         INT,  
        UMIsNewName     NVARCHAR(100),  
        ItemName        NVARCHAR(100),  
        ItemNo          NVARCHAR(100),  
        UMUseTypeName   NVARCHAR(100),  
        CurrSeq         INT,  
        CurrName        NVARCHAR(100),  
        PlanPrice       DECIMAL(19,5),  
        SumPlanQty      DECIMAL(19,5),  
        SumPlanAmt      DECIMAL(19,5),  
        SumRstQty       DECIMAL(19,5),  
        SumRstAmt       DECIMAL(19,5),  
        ExRate          DECIMAL(19,5),  
        StdMonth        NCHAR(2),  
        ItemSorting     INT,  
        Sort            INT  
    )       
  
    -- 고정row조회 
    INSERT INTO #TRowData (  
                            IDX            ,  PlanSeq        ,  Amd            ,  ItemSeq        ,  
                            BizUnit        ,  BizUnitName    ,  UMIsNew        ,  UMIsNewName    ,  
                              ItemName       ,  ItemNo         ,  UMUseTypeName   ,  
                            CurrSeq        ,  CurrName       ,  PlanPrice      ,  
                            SumPlanQty     ,  SumPlanAmt     ,  SumRstQty      ,  SumRstAmt      ,  
                            ExRate         ,  StdMonth       ,    
                            ItemSorting    ,  Sort             
                          )  
    SELECT 1           ,  A.PlanSeq      ,  A.Amd       ,  A.ItemSeq ,    
           A.BizUnit   ,  B.BizUnitName  ,  A.UMIsNew   ,  E.MinorName AS UMIsNewName  ,    
           C.ItemName  ,  C.ItemNo       ,  J.MinorName AS UMUseTypeName,  
           A.CurrSeq   ,  D.CurrName, MAX(K.PlanPrice) AS PlanPrice,  
  
           (SELECT SUM(ISNULL(PlanQty,0)) FROM kpxls_TPNWeeklyPlanbyRst WHERE CompanySeq = @CompanySeq AND PlanSeq = A.PlanSeq AND Amd = A.Amd AND ItemSeq = A.ItemSeq AND BizUnit = A.BizUnit AND UMIsNew = A.UMIsNew AND CurrSeq = A.CurrSeq AND StdMonth = @MM ) / 1000 AS SumPlanQty,  
           (SELECT SUM(ISNULL(PlanAmt,0)) FROM kpxls_TPNWeeklyPlanbyRst WHERE CompanySeq = @CompanySeq AND PlanSeq = A.PlanSeq AND Amd = A.Amd AND ItemSeq = A.ItemSeq AND BizUnit = A.BizUnit AND UMIsNew = A.UMIsNew AND CurrSeq = A.CurrSeq AND StdMonth = @MM ) AS SumPlanAmt,  
           (SELECT SUM(ISNULL(RstQty,0))  FROM kpxls_TPNWeeklyPlanbyRst WHERE CompanySeq = @CompanySeq AND PlanSeq = A.PlanSeq AND Amd = A.Amd AND ItemSeq = A.ItemSeq AND BizUnit = A.BizUnit AND UMIsNew = A.UMIsNew AND CurrSeq = A.CurrSeq AND StdMonth = @MM ) / 1000 AS SumRstQty,  
           (SELECT SUM(ISNULL(RstAmt,0))  FROM kpxls_TPNWeeklyPlanbyRst WHERE CompanySeq = @CompanySeq AND PlanSeq = A.PlanSeq AND Amd = A.Amd AND ItemSeq = A.ItemSeq AND BizUnit = A.BizUnit AND UMIsNew = A.UMIsNew AND CurrSeq = A.CurrSeq AND StdMonth = @MM ) AS SumRstAmt,  
           ISNULL(H.ExRate,1) AS ExRate,  
           @MM AS StdMonth,  
           ISNULL(G.ItemSort,999999999) AS ItemSorting,  
           1 AS Sort   
      FROM KPXLS_TPNBisPlan AS M   
           JOIN KPXLS_TPNBisPlanItem          AS A WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq AND M.PlanSeq = A.PlanSeq AND M.Amd = A.Amd  
           LEFT OUTER JOIN _TDABizUnit        AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit  
           LEFT OUTER JOIN _TDAItem           AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.ItemSeq = C.ItemSeq  
           LEFT OUTER JOIN _TDACurr           AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.CurrSeq = D.CurrSeq  
           LEFT OUTER JOIN _TDAUMinor         AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.UMIsNew = E.MinorSeq  
           LEFT OUTER JOIN _TDAUMinor         AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.UMIsCfm = F.MinorSeq  
           LEFT OUTER JOIN #TItemSort         AS G              ON A.ItemSeq    = G.ItemSeq  
           LEFT OUTER JOIN KPXLS_TPNExRate    AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq   
                                                               AND A.CurrSeq    = H.CurrSeq    
                                                               AND B.AccUnit    = H.AccUnit    
                                                               AND H.PlanYM     = @StdMonth   
                                                               AND H.UMType     = 1011920001  
           LEFT OUTER JOIN _TDAItemUserDefine AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.ItemSeq = I.ItemSeq  AND MngSerl = 1000025  
           LEFT OUTER JOIN _TDAUMinor         AS J WITH(NOLOCK) ON I.CompanySeq = J.CompanySeq AND I.MngValSeq = J.MinorSeq   
           LEFT OUTER JOIN #TItemPrice        AS K              ON A.ItemSeq    = K.ItemSeq AND A.CurrSeq = K.CurrSeq AND A.BizUnit = K.BizUnit AND A.UMIsNew = K.UMIsNew   
     WHERE M.CompanySeq  = @CompanySeq  
       AND M.PlanYear    = @PlanYear  
       AND M.Amd         = @Amd  
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)  
       AND (@UMIsNew = 0 OR A.UMIsNew = @UMIsNew)  
     GROUP BY A.PlanSeq   ,  A.Amd       ,  A.BizUnit   ,  B.BizUnitName  ,     
              A.UMIsNew   ,  E.MinorName ,  A.ItemSeq    ,  C.ItemName  ,  C.ItemNo, J.MinorName,  
              A.CurrSeq   ,  D.CurrName  ,  G.ItemSort, H.ExRate  
     ORDER BY A.PlanSeq, A.BizUnit, A.UMIsNew DESC, ItemSorting , C.ItemName  
    
    
    INSERT INTO #TRowData   
    SELECT 2, PlanSeq, Amd, -3, BizUnit, BizUnitName + N' 총계', 0,N'',   
           N'',N'',N'',  
           0,N'',null,   
           SUM(SumPlanQty)  ,SUM(SumPlanAmt)  ,SUM(SumRstQty)  ,SUM(SumRstAmt),  
           NULL,StdMonth, 999999999, 3 AS Sort   
      FROM #TRowData  
     WHERE Sort = 1  
     GROUP BY PlanSeq, Amd, BizUnit, BizUnitName, StdMonth  
  
    --INSERT INTO #TRowData   
    --SELECT 3, PlanSeq, Amd, -4, 0,  N'총계', 0,N'',   
    --       N'',N'',N'',  
    --       0,N'',null,   
    --       SUM(SumPlanQty)  ,SUM(SumPlanAmt)  ,SUM(SumRstQty)  ,SUM(SumRstAmt),  
    --       NULL,StdMonth, 999999999, 4 AS Sort  
    --  FROM #TRowData  
    -- WHERE Sort = 1  
    -- GROUP BY PlanSeq, Amd, StdMonth  
    
    
    ------------------------------------  
    -- 값조회  
    ------------------------------------  
    CREATE TABLE #TData  
    (  
        PlanSeq  INT,   
        Amd      NCHAR(2),   
        ItemSeq  INT,   
        BizUnit  INT,  
        UMIsNew  INT,   
        CurrSeq  INT,  
        Weekly   INT,   
        PlanQty  DECIMAL(19,5),   
        PlanAmt  DECIMAL(19,5),   
        RstQty   DECIMAL(19,5),   
        RstAmt   DECIMAL(19,5),  
        DataType INT  
    )  
    
    INSERT INTO #TData  
    SELECT B.PlanSeq, B.Amd, B.ItemSeq, B.BizUnit, B.UMIsNew, B.CurrSeq , B.Weekly, B.PlanQty / 1000, B.PlanAmt , B.RstQty / 1000, B.RstAmt, 1 AS DataType  
      FROM KPXLS_TPNBisPlan AS M   
           JOIN kpxls_TPNWeeklyPlanbyRst  AS B WITH(NOLOCK) ON M.CompanySeq = B.CompanySeq AND M.PlanSeq = B.PlanSeq AND M.Amd = B.Amd AND B.StdMonth = @MM  
     WHERE M.CompanySeq  = @CompanySeq  
       AND M.PlanYear    = @PlanYear  
       AND M.Amd         = @Amd  
    
    -- 사업부문별소계    
    INSERT INTO #TData  
    SELECT  PlanSeq, Amd, -3, BizUnit, 0, 0, Weekly,   
            SUM(PlanQty), SUM(PlanAmt) , SUM(RstQty), SUM(RstAmt),   
            3  
      FROM #TData  
     WHERE DataType = 1  
     GROUP BY PlanSeq, Amd, BizUnit, Weekly  
  
    ---- 총계    
    --INSERT INTO #TData  
    --SELECT  PlanSeq, Amd, -4, 0, 0, 0, Weekly,   
    --        SUM(PlanQty), SUM(PlanAmt) , SUM(RstQty), SUM(RstAmt),   
    --        3  
    --  FROM #TData  
    -- WHERE DataType = 1  
    -- GROUP BY PlanSeq, Amd,  Weekly  
    
    --select * from #TRowData 
    --return 
    
    SELECT @PlanYear + '년 ' + CONVERT(NVARCHAR(10),CONVERT(INT,A.StdMonth)) + '월' AS Title, 
           A.IDX, 
           A.BizUnit, 
           A.BizUnitName, 
           A.UMUseTypeName, 
           A.UMIsNew, 
           A.ItemName + 
           CASE WHEN ISNULL(A.UMUseTypeName,'') = '' THEN '' ELSE NCHAR(13) + '( ' + A.UMUseTypeName + ' )' END AS ItemName, 
           
           A.SumPlanQty     ,  
           A.SumPlanAmt     ,  
           A.SumRstQty      ,  
           A.SumRstAmt      ,  
           
           B.PlanQty01, 
           B.PlanAmt01, 
           B.RstQty01, 
           B.RstAmt01, 
           C.PlanQty02, 
           C.PlanAmt02, 
           C.RstQty02, 
           C.RstAmt02, 
           D.PlanQty03, 
           D.PlanAmt03, 
           D.RstQty03, 
           D.RstAmt03, 
           E.PlanQty04, 
           E.PlanAmt04, 
           E.RstQty04, 
           E.RstAmt04, 
           F.PlanQty05, 
           F.PlanAmt05, 
           F.RstQty05, 
           F.RstAmt05, 
           G.PlanQty06, 
           G.PlanAmt06, 
           G.RstQty06, 
           G.RstAmt06
      FROM #TRowData AS A 
      OUTER APPLY ( SELECT PlanQty AS PlanQty01, PlanAmt AS PlanAmt01, RstQty AS RstQty01, RstAmt AS RstAmt01
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 1 
                  ) AS B 
      OUTER APPLY ( SELECT PlanQty AS PlanQty02, PlanAmt AS PlanAmt02, RstQty AS RstQty02, RstAmt AS RstAmt02
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 2 
                  ) AS C 
      OUTER APPLY ( SELECT PlanQty AS PlanQty03, PlanAmt AS PlanAmt03, RstQty AS RstQty03, RstAmt AS RstAmt03
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 3 
                  ) AS D 
      OUTER APPLY ( SELECT PlanQty AS PlanQty04, PlanAmt AS PlanAmt04, RstQty AS RstQty04, RstAmt AS RstAmt04
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 4 
                  ) AS E 
      OUTER APPLY ( SELECT PlanQty AS PlanQty05, PlanAmt AS PlanAmt05, RstQty AS RstQty05, RstAmt AS RstAmt05
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 5 
                  ) AS F 
      OUTER APPLY ( SELECT PlanQty AS PlanQty06, PlanAmt AS PlanAmt06, RstQty AS RstQty06, RstAmt AS RstAmt06
                      FROM #TData AS Z 
                     WHERE Z.ItemSeq = A.ItemSeq 
                       AND Z.BizUnit = A.BizUnit 
                       AND Z.UMIsNew = A.UMIsNew
                       AND Z.Weekly = 6 
                  ) AS G 
     ORDER BY BizUnit, IDX, UMIsNew DESC 
    
    RETURN  
  go 

exec KPXLS_SPNWeeklyPlanbyRstListPrintQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYear>2016</PlanYear>
    <Amd>07</Amd>
    <PlanMonth>1</PlanMonth>
    <IsExists>1</IsExists>
    <Weekly>0</Weekly>
    <BizUnit />
    <UMIsNew />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033947,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028115