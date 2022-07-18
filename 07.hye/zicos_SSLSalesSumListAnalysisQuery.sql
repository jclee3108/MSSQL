IF OBJECT_ID('zicos_SSLSalesSumListAnalysisQuery') IS NOT NULL 
    DROP PROC zicos_SSLSalesSumListAnalysisQuery
GO 

-- v2016.07.25  
/**************************************************************************************************************
 설  명 - 판매실적조회(집계)
 작성일 - 20160712
 작성자 - 윤삼혁

 수정일 -  2016.07.22 
 수정자 -  이재천 
 수정내용 - Orderby추가 및 조회단위 추가 

 비  고 -
		  (1) 환산수량 추가 필요
		  (2) 거래명세서 거래처와 세금계산서 거래처가 다름
		      실적거래처로 담는 부분 검토 필요

**************************************************************************************************************/

CREATE PROC zicos_SSLSalesSumListAnalysisQuery
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle              INT  
            -- 조회조건   
           ,@BizUnit                INT         
           ,@StdFromDate            NCHAR(8)
           ,@DeptSeq                INT         
           ,@EmpSeq                 INT
           ,@ItemClassLSeq          INT
           ,@ItemClassMSeq          INT
           ,@ItemClassSSeq          INT
           ,@StdToDate              NCHAR(8)       
           ,@CustSeq                INT         
           ,@UMDistribuSystem       INT     
           ,@UMArea                 INT
           ,@SMInvoORSalesSeq       INT
           ,@SMImpType              INT
           ,@ItemName               NVARCHAR(200)
           ,@ItemNo                 NVARCHAR(100) 
           ,@Spec                   NVARCHAR(100)
           ,@SUMBizUnit             NCHAR(1)          
           ,@SUMArea                NCHAR(1) 
           ,@SUMUMDistribuSystem    NCHAR(1)      
           ,@SUMItemClassLSeq       NCHAR(1)    
           ,@SUMItemClassMSeq       NCHAR(1)    
           ,@SUMItemClassSSeq       NCHAR(1)    
           ,@SUMCust                NCHAR(1)             
           ,@SUMDept                NCHAR(1)   
           ,@SUMEmp                 NCHAR(1)     
           ,@SUMItemSeq             NCHAR(1)     
           ,@LYStdFromDate          NCHAR(8)
           ,@LYStdToDate            NCHAR(8)
           ,@UMUnitSeq              INT   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    SELECT  @BizUnit                = ISNULL(BizUnit              , 0 )            
           ,@StdFromDate            = ISNULL(StdFromDate          , '')        
           ,@DeptSeq                = ISNULL(DeptSeq              , 0 )            
           ,@EmpSeq                 = ISNULL(EmpSeq               , 0 )                         
           ,@ItemClassLSeq          = ISNULL(ItemClassLSeq        , 0 )                  
           ,@ItemClassMSeq          = ISNULL(ItemClassMSeq        , 0 )                  
           ,@ItemClassSSeq          = ISNULL(ItemClassSSeq        , 0 )                  
           ,@StdToDate              = ISNULL(StdToDate            , '')                  
           ,@CustSeq                = ISNULL(CustSeq              , 0 )                        
           ,@UMDistribuSystem       = ISNULL(UMDistribuSystem     , 0 )                  
           ,@UMArea                 = ISNULL(UMArea               , 0 )                         
           ,@SMInvoORSalesSeq       = ISNULL(SMInvoORSalesSeq     , 0 )              
           ,@SMImpType              = ISNULL(SMImpType            , 0 )            
           ,@ItemName               = ISNULL(ItemName             , '')              
           ,@ItemNo                 = ISNULL(ItemNo               , '')            
           ,@Spec                   = ISNULL(Spec                 , '')              
           ,@SUMBizUnit             = ISNULL(SUMBizUnit           , '')            
           ,@SUMArea                = ISNULL(SUMArea              , '')              
           ,@SUMUMDistribuSystem    = ISNULL(SUMUMDistribuSystem  , '')            
           ,@SUMItemClassLSeq       = ISNULL(SUMItemClassLSeq     , '')              
           ,@SUMItemClassMSeq       = ISNULL(SUMItemClassMSeq     , '')            
           ,@SUMItemClassSSeq       = ISNULL(SUMItemClassSSeq     , '')              
           ,@SUMCust                = ISNULL(SUMCust              , '')              
           ,@SUMDept                = ISNULL(SUMDept              , '')            
           ,@SUMEmp                 = ISNULL(SUMEmp               , '')    
           ,@SUMItemSeq             = ISNULL(SUMItemSeq           , '')        
           ,@UMUnitSeq              = ISNULL(UMUnitSeq            , 0 ) 
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit                INT         
           ,StdFromDate            NCHAR(8)
           ,DeptSeq                INT         
           ,EmpSeq                 INT
           ,ItemClassLSeq          INT
           ,ItemClassMSeq          INT
           ,ItemClassSSeq          INT
           ,StdToDate              NCHAR(8)       
           ,CustSeq                INT         
           ,UMDistribuSystem       INT     
           ,UMArea                 INT
           ,SMInvoORSalesSeq       INT
           ,SMImpType              INT
           ,ItemName               NVARCHAR(200)
           ,ItemNo                 NVARCHAR(100) 
           ,Spec                   NVARCHAR(100)
           ,SUMBizUnit             NCHAR(1)          
           ,SUMArea                NCHAR(1) 
           ,SUMUMDistribuSystem    NCHAR(1)      
           ,SUMItemClassLSeq       NCHAR(1)    
           ,SUMItemClassMSeq       NCHAR(1)    
           ,SUMItemClassSSeq       NCHAR(1)    
           ,SUMCust                NCHAR(1)             
           ,SUMDept                NCHAR(1)   
           ,SUMEmp                 NCHAR(1)
           ,SUMItemSeq             NCHAR(1)          
           ,UMUnitSeq              INT
           )    
    SELECT @LYStdFromDate   = CONVERT(NCHAR(8),DATEADD(YY,-1,@StdFromDate),112)
          ,@LYStdToDate     = CONVERT(NCHAR(8),DATEADD(YY,-1,@StdToDate),112)
    CREATE TABLE #TMP_SalesGroupSUM( 
                                         BizUnit            INT
                                        ,CustSeq            INT
                                        ,DeptSeq            INT                   
                                        ,EmpSeq             INT   
                                        ,ItemSeq            INT                
                                        ,ItemClassLSeq      INT                   
                                        ,ItemClassMSeq      INT                   
                                        ,ItemClassSSeq      INT     
                                        ,UMDistribuSystem   INT      
                                        ,UMArea             INT
                                        ,SalesGoalsQty      DECIMAL(19,5)       --판매목표-수량
                                        ,TodaySalesQty      DECIMAL(19,5)       --당일판매-수량
                                        ,TodaySalesQtyTOT   DECIMAL(19,5)       --당일누계-수량
                                        ,AchieveQtyRate     DECIMAL(19,5)       --달성율(%)-수량
                                        ,LastResultQty      DECIMAL(19,5)       --전년실적-수량
                                        ,LastComQtyRate     DECIMAL(19,5)       --전년비(%)-수량
                                        ,SalesGoalsAmt      DECIMAL(19,5)       --판매목표-금액
                                        ,TodaySalesAmt      DECIMAL(19,5)       --당일판매-금액
                                        ,TodaySalesAmtTOT   DECIMAL(19,5)       --당일누계-금액
                                        ,AchieveAmtRate     DECIMAL(19,5)       --달성율(%)-금액
                                        ,LastResultAmt      DECIMAL(19,5)       --전년실적-금액          
                                        ,LastComAmtRate     DECIMAL(19,5)       --전년비(%)-금액     
                                    )                                           



	/*

	계획데이터 담기

	<연간판매계획입력> : _TSLPlanYearSales
	<월실행판매계획> : _TSLPlanMonthSales

	*/
	INSERT INTO #TMP_SalesGroupSUM(
									BizUnit         ,CustSeq        ,DeptSeq        ,EmpSeq             ,ItemSeq,
									ItemClassLSeq   ,ItemClassMSeq  ,ItemClassSSeq  ,UMDistribuSystem   ,UMArea,
									SalesGoalsQty   ,SalesGoalsAmt  
								   )
	SELECT A.BizUnit
		  ,A.CustSeq
		  ,A.DeptSeq
		  ,A.EmpSeq
		  ,A.ItemSeq
		  ,C.ItemClassLSeq
		  ,C.ItemClassMSeq
		  ,C.ItemClassSSeq
		  ,E.UMCustClass    AS UMDistribuSystem
		  ,G.UMCustClass    AS UMArea
		  ,A.PlanQty        AS SalesGoalsQty    --판매목표 수량
		  ,A.PlanAmt        AS SalesGoalsAmt    --판매목표 금액
	  FROM _TSLPlanMonthSales               AS A
	  LEFT OUTER JOIN _TDAItem              AS I ON I.CompanySeq = A.CompanySeq AND I.ItemSeq = A.ItemSeq
	  LEFT OUTER JOIN _VDAGetItemClass      AS C ON C.CompanySeq = A.CompanySeq AND C.ItemSeq = A.ItemSeq
	  LEFT OUTER JOIN _TDACustClass         AS E ON E.CompanySeq = A.CompanySeq 
												AND E.CustSeq = A.CustSeq 
												AND E.UMajorCustClass = 8004    --유통구조 
	  LEFT OUTER JOIN _TDACustClass         AS G ON G.CompanySeq = A.CompanySeq         
												AND G.CustSeq = A.CustSeq 
												AND G.UMajorCustClass = 8001    --지역              
	 WHERE A.CompanySeq = @CompanySeq
	   AND (@BizUnit            = 0 OR A.BizUnit            = @BizUnit            ) 
	   AND (@DeptSeq            = 0 OR A.DeptSeq            = @DeptSeq            ) 
	   AND (@EmpSeq             = 0 OR A.EmpSeq             = @EmpSeq             ) 
	   AND (@ItemClassLSeq      = 0 OR C.ItemClassLSeq      = @ItemClassLSeq      ) 
	   AND (@ItemClassMSeq      = 0 OR C.ItemClassMSeq      = @ItemClassMSeq      ) 
	   AND (@ItemClassSSeq      = 0 OR C.ItemClassSSeq      = @ItemClassSSeq      ) 
	   AND (@CustSeq            = 0 OR A.CustSeq            = @CustSeq            ) 
	   AND (@UMDistribuSystem   = 0 OR E.UMCustClass        = @UMDistribuSystem   ) 
	   AND (@UMArea             = 0 OR G.UMCustClass        = @UMArea             ) 
	   AND (I.ItemName          LIKE @ItemName  + '%' )  
	   AND (I.ItemNo            LIKE @ItemNo    + '%' )  
	   AND (I.Spec              LIKE @Spec      + '%' )  
	   AND A.PlanYM BETWEEN LEFT(@StdFromDate,6) AND LEFT(@StdToDate,6)


	-- 거래명세서 기준
	IF @SMInvoORSalesSeq = 8058001	
	BEGIN       
		INSERT INTO #TMP_SalesGroupSUM(
										BizUnit         ,CustSeq            ,DeptSeq        ,EmpSeq             ,ItemSeq            ,
										ItemClassLSeq   ,ItemClassMSeq      ,ItemClassSSeq  ,UMDistribuSystem   ,UMArea             ,
										TodaySalesQty   ,TodaySalesQtyTOT   ,LastResultQty  ,TodaySalesAmt      ,TodaySalesAmtTOT   ,
										LastResultAmt     
									   )
		SELECT A.BizUnit
			  ,A.CustSeq
			  ,A.DeptSeq
			  ,A.EmpSeq
			  ,B.ItemSeq
			  ,C.ItemClassLSeq
			  ,C.ItemClassMSeq
			  ,C.ItemClassSSeq
			  ,E.UMCustClass                                                                            AS UMDistribuSystem
			  ,G.UMCustClass                                                                            AS UMArea
			  ,CASE WHEN A.InvoiceDate = @StdToDate THEN B.STDQty 
					ELSE 0 END                                                                          AS TodaySalesQty
			  ,CASE WHEN A.InvoiceDate BETWEEN @StdFromDate AND @StdToDate THEN B.STDQty 
					ELSE 0 END                                                                          AS TodaySalesQtyTOT
			  ,CASE WHEN A.InvoiceDate BETWEEN @LYStdFromDate AND @LYStdToDate THEN B.STDQty             
					ELSE 0 END                                                                          AS LastResultQty
			  ,CASE WHEN A.InvoiceDate = @StdToDate THEN B.DomAmt 
					ELSE 0 END                                                                          AS TodaySalesAmt
			  ,CASE WHEN A.InvoiceDate BETWEEN @StdFromDate AND @StdToDate THEN B.DomAmt
					ELSE 0 END                                                                          AS TodaySalesAmtTOT
			  ,CASE WHEN A.InvoiceDate BETWEEN @LYStdFromDate AND @LYStdToDate THEN B.DomAmt
					ELSE 0 END                                                                          AS LastResultAmt
		  FROM _TSLInvoice                  AS A 
		  JOIN _TSLInvoiceItem              AS B ON B.CompanySeq = A.CompanySeq AND B.InvoiceSeq = A.InvoiceSeq
		  LEFT OUTER JOIN _TDAItem          AS I ON I.CompanySeq = B.CompanySeq AND I.ItemSeq = B.ItemSeq
		  LEFT OUTER JOIN _TDASMinorValue   AS MV1 ON MV1.CompanySeq = A.CompanySeq 
												  AND MV1.MinorSeq = A.SMExpKind
												  AND MV1.Serl = 1001       --내수
		  LEFT OUTER JOIN _TDASMinorValue   AS MV2 ON MV2.CompanySeq = A.CompanySeq 
												  AND MV2.MinorSeq = A.SMExpKind
												  AND MV2.Serl = 1002       --외수
		  LEFT OUTER JOIN _VDAGetItemClass  AS C ON C.CompanySeq = B.CompanySeq AND C.ItemSeq = B.ItemSeq
		  LEFT OUTER JOIN _TDACustClass     AS E ON E.CompanySeq = A.CompanySeq 
												AND E.CustSeq = A.CustSeq 
												AND E.UMajorCustClass = 8004    --유통구조                              
		  LEFT OUTER JOIN _TDACustClass     AS G ON G.CompanySeq = A.CompanySeq         
												AND G.CustSeq = A.CustSeq 
												AND G.UMajorCustClass = 8001    --지역
		 WHERE A.CompanySeq = @CompanySeq
		   AND (@BizUnit            = 0 OR A.BizUnit            = @BizUnit            ) 
		   AND (@DeptSeq            = 0 OR A.DeptSeq            = @DeptSeq            ) 
		   AND (@EmpSeq             = 0 OR A.EmpSeq             = @EmpSeq             ) 
		   AND (@ItemClassLSeq      = 0 OR C.ItemClassLSeq      = @ItemClassLSeq      ) 
		   AND (@ItemClassMSeq      = 0 OR C.ItemClassMSeq      = @ItemClassMSeq      ) 
		   AND (@ItemClassSSeq      = 0 OR C.ItemClassSSeq      = @ItemClassSSeq      ) 
		   AND (@CustSeq            = 0 OR A.CustSeq            = @CustSeq            ) 
		   AND (@UMDistribuSystem   = 0 OR E.UMCustClass        = @UMDistribuSystem   ) 
		   AND (@UMArea             = 0 OR G.UMCustClass        = @UMArea             ) 
		   AND (@SMImpType          = 0 
				OR (MV1.ValueText = 1 AND @SMImpType = 8007001) 
				OR (MV2.ValueText = 1 AND @SMImpType = 8007002)) 
		   AND ((A.InvoiceDate BETWEEN @StdFromDate AND @StdToDate) 
				OR(A.InvoiceDate BETWEEN @LYStdFromDate AND @LYStdToDate))
		   AND (I.ItemName          LIKE @ItemName  + '%' )  
		   AND (I.ItemNo            LIKE @ItemNo    + '%' )  
		   AND (I.Spec              LIKE @Spec      + '%' )  
	END

	-- 세금계산서 기준(8058002)
	ELSE 
	BEGIN 
		INSERT INTO #TMP_SalesGroupSUM(
										BizUnit         ,CustSeq            ,DeptSeq        ,EmpSeq             ,ItemSeq            ,
										ItemClassLSeq   ,ItemClassMSeq      ,ItemClassSSeq  ,UMDistribuSystem   ,UMArea             ,
										TodaySalesQty   ,TodaySalesQtyTOT   ,LastResultQty  ,TodaySalesAmt      ,TodaySalesAmtTOT   ,
										LastResultAmt     
									   )
		SELECT A.BizUnit
			  ,A.CustSeq
			  ,A.DeptSeq
			  ,A.EmpSeq
			  ,B.ItemSeq
			  ,C.ItemClassLSeq
			  ,C.ItemClassMSeq
			  ,C.ItemClassSSeq
			  ,E.UMCustClass                        AS UMDistribuSystem
			  ,G.UMCustClass                        AS UMArea
			  ,CASE WHEN A.SalesDate = @StdToDate THEN B.STDQty 
					ELSE 0 END                                                                          AS TodaySalesQty
			  ,CASE WHEN A.SalesDate BETWEEN @StdFromDate AND @StdToDate THEN B.STDQty 
					ELSE 0 END                                                                          AS TodaySalesQtyTOT
			  ,CASE WHEN A.SalesDate BETWEEN @LYStdFromDate AND @LYStdToDate THEN B.STDQty             
					ELSE 0 END                                                                          AS LastResultQty
			  ,CASE WHEN A.SalesDate = @StdToDate THEN B.DomAmt
					ELSE 0 END                                                                          AS TodaySalesAmt
			  ,CASE WHEN A.SalesDate BETWEEN @StdFromDate AND @StdToDate THEN B.DomAmt
					ELSE 0 END                                                                          AS TodaySalesAmtTOT
			  ,CASE WHEN A.SalesDate BETWEEN @LYStdFromDate AND @LYStdToDate THEN B.DomAmt
					ELSE 0 END                                                                          AS LastResultAmt
		  FROM _TSLSales                    AS A 
		  JOIN _TSLSalesItem                AS B ON B.CompanySeq = A.CompanySeq AND B.SalesSeq = A.SalesSeq
		  LEFT OUTER JOIN _TDAItem          AS I ON I.CompanySeq = B.CompanySeq AND I.ItemSeq = B.ItemSeq
		  LEFT OUTER JOIN _TDASMinorValue   AS MV1 ON MV1.CompanySeq = A.CompanySeq 
												  AND MV1.MinorSeq = A.SMExpKind
												  AND MV1.Serl = 1001       --내수
		  LEFT OUTER JOIN _TDASMinorValue   AS MV2 ON MV2.CompanySeq = A.CompanySeq 
												  AND MV2.MinorSeq = A.SMExpKind
												  AND MV2.Serl = 1002       --외수
		  LEFT OUTER JOIN _VDAGetItemClass  AS C ON C.CompanySeq = B.CompanySeq AND C.ItemSeq = B.ItemSeq
		  LEFT OUTER JOIN _TDACustClass     AS E ON E.CompanySeq = A.CompanySeq 
												AND E.CustSeq = A.CustSeq 
												AND E.UMajorCustClass = 8004    --유통구조                                    
		  LEFT OUTER JOIN _TDACustClass     AS G ON G.CompanySeq = A.CompanySeq         
												AND G.CustSeq = A.CustSeq 
												AND G.UMajorCustClass = 8001    --지역
		 WHERE A.CompanySeq = @CompanySeq
		   AND (@BizUnit            = 0 OR A.BizUnit            = @BizUnit            ) 
		   AND (@DeptSeq            = 0 OR A.DeptSeq            = @DeptSeq            ) 
		   AND (@EmpSeq             = 0 OR A.EmpSeq             = @EmpSeq             ) 
		   AND (@ItemClassLSeq      = 0 OR C.ItemClassLSeq      = @ItemClassLSeq      ) 
		   AND (@ItemClassMSeq      = 0 OR C.ItemClassMSeq      = @ItemClassMSeq      ) 
		   AND (@ItemClassSSeq      = 0 OR C.ItemClassSSeq      = @ItemClassSSeq      ) 
		   AND (@CustSeq            = 0 OR A.CustSeq            = @CustSeq            ) 
		   AND (@UMDistribuSystem   = 0 OR E.UMCustClass        = @UMDistribuSystem   ) 
		   AND (@UMArea             = 0 OR G.UMCustClass        = @UMArea             ) 
		   AND (@SMImpType          = 0 
				OR (MV1.ValueText = 1 AND @SMImpType = 8007001) 
				OR (MV2.ValueText = 1 AND @SMImpType = 8007002)) 
		   AND ((A.SalesDate BETWEEN @StdFromDate AND @StdToDate) 
				OR(A.SalesDate BETWEEN @LYStdFromDate AND @LYStdToDate))
		   AND (I.ItemName          LIKE @ItemName  + '%' )  
		   AND (I.ItemNo            LIKE @ItemNo    + '%' )  
		   AND (I.Spec              LIKE @Spec      + '%' ) 
	END


    SELECT   A.BizUnit            
            ,B.BizUnitName
            ,A.CustSeq    
            ,C.CustName        
            ,A.DeptSeq            
            ,D.DeptName
            ,A.EmpSeq             
            ,E.EmpName
            ,A.ItemSeq            
            ,I.ItemName
            ,I.ItemNo
            ,I.Spec
            ,A.ItemClassLSeq      
            ,G.ItemClasLName
            ,A.ItemClassMSeq      
            ,G.ItemClasMName
            ,A.ItemClassSSeq      
            ,G.ItemClasSName
            ,A.UMDistribuSystem   
            ,F.MinorName                                                                            AS UMDistribuSystemName
            ,A.UMArea             
            ,H.MinorName                                                                            AS UMAreaName
            ,SUM(ISNULL(A.SalesGoalsQty,0))                                                         AS SalesGoalsQty      
            ,SUM(ISNULL(A.TodaySalesQty,0))                                                         AS TodaySalesQty      
            ,SUM(ISNULL(A.TodaySalesQtyTOT,0))                                                      AS TodaySalesQtyTOT  
            ,SUM(ISNULL(A.LastResultQty,0))                                                         AS LastResultQty      
            ,SUM(ISNULL(A.SalesGoalsAmt,0))                                                         AS SalesGoalsAmt       
            ,SUM(ISNULL(A.TodaySalesAmt,0))                                                         AS TodaySalesAmt      
            ,SUM(ISNULL(A.TodaySalesAmtTOT,0))                                                      AS TodaySalesAmtTOT   
            ,SUM(ISNULL(A.LastResultAmt,0))                                                         AS LastResultAmt      
            ,1                                                                                      AS Kind
      INTO #TMP_SalesGroupSUM_Result
      FROM #TMP_SalesGroupSUM      AS A
      LEFT OUTER JOIN _TDABizUnit   AS B ON B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit
      LEFT OUTER JOIN _TDACust      AS C ON C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq
      LEFT OUTER JOIN _TDADept      AS D ON D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq
      LEFT OUTER JOIN _TDAEmp       AS E ON E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq
      LEFT OUTER JOIN _VDAGetItemClass  AS G ON G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq
      LEFT OUTER JOIN _TDAItem      AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq
      LEFT OUTER JOIN _TDAUMinor    AS F ON F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMDistribuSystem
      LEFT OUTER JOIN _TDAUMinor    AS H ON H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMArea 
     GROUP BY    A.BizUnit            
                ,B.BizUnitName
                ,A.CustSeq    
                ,C.CustName        
                ,A.DeptSeq            
                ,D.DeptName
                ,A.EmpSeq             
                ,E.EmpName
                ,A.ItemSeq            
                ,I.ItemName
                ,I.ItemNo
                ,I.Spec
                ,A.ItemClassLSeq      
                ,G.ItemClasLName
                ,A.ItemClassMSeq      
                ,G.ItemClasMName
                ,A.ItemClassSSeq      
                ,G.ItemClasSName
                ,A.UMDistribuSystem   
                ,F.MinorName          
                ,A.UMArea             
                ,H.MinorName      
    
    -- 환산단위 적용하기, 2016.07.22 by이재천 
    IF @UMUnitSeq = 1013353001
    BEGIN 
        UPDATE A
           SET SalesGoalsQty = ROUND(A.SalesGoalsQty * B.ExRate,2), 
               TodaySalesQty = ROUND(A.TodaySalesQty * B.ExRate,2), 
               TodaySalesQtyTOT = ROUND(A.TodaySalesQtyTOT * B.ExRate,2), 
               LastResultQty = ROUND(A.LastResultQty * B.ExRate,2)
          FROM #TMP_SalesGroupSUM_Result    AS A 
          JOIN HYE_VDAItemExRate            AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
    END 

	-- 조회기준에 따른 동적쿼리
					    
    DECLARE @SQL  NVARCHAR(MAX)               
    SET @SQL = ''                         
    SET @SQL = @SQL + ' SELECT SUM(ISNULL(SalesGoalsQty,0))    AS SalesGoalsQty    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(TodaySalesQty,0))    AS TodaySalesQty    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(TodaySalesQtyTOT,0)) AS TodaySalesQtyTOT '  + CHAR(13)  
    SET @SQL = @SQL + '       ,ISNULL((SUM(ISNULL(TodaySalesQtyTOT,0)) / NULLIF(SUM(ISNULL(SalesGoalsQty,0)),0))*100.0,0) AS AchieveQtyRate   '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(LastResultQty,0))    AS LastResultQty    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,ISNULL((SUM(ISNULL(TodaySalesQtyTOT,0)) / NULLIF(SUM(ISNULL(LastResultQty,0)),0))*100.0,0) AS LastComQtyRate   '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(SalesGoalsAmt,0))    AS SalesGoalsAmt    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(TodaySalesAmt,0))    AS TodaySalesAmt    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(TodaySalesAmtTOT,0)) AS TodaySalesAmtTOT '  + CHAR(13)  
    SET @SQL = @SQL + '       ,ISNULL((SUM(ISNULL(TodaySalesAmtTOT,0)) / NULLIF(SUM(ISNULL(SalesGoalsAmt,0)),0))*100.0,0) AS AchieveAmtRate   '  + CHAR(13)  
    SET @SQL = @SQL + '       ,SUM(ISNULL(LastResultAmt,0))    AS LastResultAmt    '  + CHAR(13)  
    SET @SQL = @SQL + '       ,ISNULL((SUM(ISNULL(TodaySalesAmtTOT,0)) / NULLIF(SUM(ISNULL(LastResultAmt,0)),0))*100.0,0) AS LastComAmtRate   '  + CHAR(13)  

		IF @SUMBizUnit          = '1' SET @SQL = @SQL + ' ,BizUnit ,BizUnitName ' + CHAR(13)   
		IF @SUMArea             = '1' SET @SQL = @SQL + ' ,UMArea ,UMAreaName ' +CHAR(13)  
		IF @SUMUMDistribuSystem = '1' SET @SQL = @SQL + ' ,UMDistribuSystem ,UMDistribuSystemName ' +CHAR(13)        
		IF @SUMItemClassLSeq    = '1' SET @SQL = @SQL + ' ,ItemClassLSeq ,ItemClasLName ' + CHAR(13)  
		IF @SUMItemClassMSeq    = '1' SET @SQL = @SQL + ' ,ItemClassMSeq ,ItemClasMName ' + CHAR(13)  
		IF @SUMItemClassSSeq    = '1' SET @SQL = @SQL + ' ,ItemClassSSeq ,ItemClasSName ' + CHAR(13)  
		IF @SUMCust             = '1' SET @SQL = @SQL + ' ,CustSeq ,CustName ' + CHAR(13)  
		IF @SUMDept             = '1' SET @SQL = @SQL + ' ,DeptSeq ,DeptName ' + CHAR(13)  
		IF @SUMEmp              = '1' SET @SQL = @SQL + ' ,EmpSeq ,EmpName ' + CHAR(13)  
		IF @SUMItemSeq          = '1' SET @SQL = @SQL + ' ,ItemSeq ,ItemName ,ItemNo ,Spec ' + CHAR(13)   

    SET @SQL = @SQL + ' FROM #TMP_SalesGroupSUM_Result ' + CHAR(13)     
		IF  @SUMBizUnit <> '1'      AND @SUMArea <> '1'         AND @SUMUMDistribuSystem <> '1' AND  
			@SUMItemClassLSeq <> '1'AND @SUMItemClassMSeq <> '1'AND @SUMItemClassSSeq <> '1'    AND 
			@SUMCust <> '1'         AND @SUMDept <> '1'         AND @SUMEmp <> '1'              AND
			@SUMItemSeq <> '1'                          
			SET @SQL = @SQL + ' GROUP BY Kind ' + CHAR(13)   
		ELSE    
			SET @SQL = @SQL + ' GROUP BY ' + CHAR(13)   
			IF @SUMBizUnit          = '1' SET @SQL = @SQL + ' BizUnit, BizUnitName,'  
			IF @SUMArea             = '1' SET @SQL = @SQL + ' UMArea, UMAreaName,'   
			IF @SUMUMDistribuSystem = '1' SET @SQL = @SQL + ' UMDistribuSystem, UMDistribuSystemName,'         
			IF @SUMItemClassLSeq    = '1' SET @SQL = @SQL + ' ItemClassLSeq, ItemClasLName,'  
			IF @SUMItemClassMSeq    = '1' SET @SQL = @SQL + ' ItemClassMSeq, ItemClasMName,'  
			IF @SUMItemClassSSeq    = '1' SET @SQL = @SQL + ' ItemClassSSeq, ItemClasSName,'  
			IF @SUMCust             = '1' SET @SQL = @SQL + ' CustSeq, CustName,'  
			IF @SUMDept             = '1' SET @SQL = @SQL + ' DeptSeq, DeptName,'  
			IF @SUMEmp              = '1' SET @SQL = @SQL + ' EmpSeq, EmpName,'  
			IF @SUMItemSeq          = '1' SET @SQL = @SQL + ' ItemSeq, ItemName, ItemNo, Spec,'  
			IF RIGHT(@SQL,1) = ',' SELECT @SQL = SUBSTRING(@SQL, 1, LEN(@SQL)-1)      
			
		IF  @SUMBizUnit <> '1'      AND @SUMArea <> '1'         AND @SUMUMDistribuSystem <> '1' AND  
			@SUMItemClassLSeq <> '1'AND @SUMItemClassMSeq <> '1'AND @SUMItemClassSSeq <> '1'    AND 
			@SUMCust <> '1'         AND @SUMDept <> '1'         AND @SUMEmp <> '1'              AND
			@SUMItemSeq <> '1'                          
        BEGIN 
			SET @SQL = @SQL 
        END 
		ELSE  
		BEGIN   
			SET @SQL = @SQL + ' ORDER BY ' + CHAR(13)   
			IF @SUMBizUnit          = '1' SET @SQL = @SQL + ' BizUnitName,'  
			IF @SUMCust             = '1' SET @SQL = @SQL + ' CustName,'  
			IF @SUMArea             = '1' SET @SQL = @SQL + ' UMAreaName,'   
			IF @SUMUMDistribuSystem = '1' SET @SQL = @SQL + ' UMDistribuSystemName,'         
			IF @SUMDept             = '1' SET @SQL = @SQL + ' DeptName,'  
			IF @SUMEmp              = '1' SET @SQL = @SQL + ' EmpName,'  
			IF @SUMItemClassLSeq    = '1' SET @SQL = @SQL + ' ItemClasLName,'  
			IF @SUMItemClassMSeq    = '1' SET @SQL = @SQL + ' ItemClasMName,'  
			IF @SUMItemClassSSeq    = '1' SET @SQL = @SQL + ' ItemClasSName,'  
			IF @SUMItemSeq          = '1' SET @SQL = @SQL + ' ItemName,'  
			IF RIGHT(@SQL,1) = ',' SELECT @SQL = SUBSTRING(@SQL, 1, LEN(@SQL)-1)      
        END 

      
        PRINT @SQL     
		                     
        EXEC SP_EXECUTESQL @SQL                            
        
		IF @@ERROR <> 0  RETURN    


    RETURN  

GO


begin tran 
exec zicos_SSLSalesSumListAnalysisQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit />
    <StdFromDate>20160101</StdFromDate>
    <StdToDate>20160722</StdToDate>
    <SMInvoORSalesSeq>8058002</SMInvoORSalesSeq>
    <SMImpType />
    <CustSeq />
    <UMDistribuSystem />
    <UMArea />
    <DeptSeq />
    <ItemClassLSeq />
    <ItemClassMSeq />
    <ItemClassSSeq />
    <EmpSeq />
    <ItemName />
    <ItemNo />
    <Spec />
    <SUMBizUnit>1</SUMBizUnit>
    <SUMArea>1</SUMArea>
    <SUMUMDistribuSystem>1</SUMUMDistribuSystem>
    <SUMItemSeq>1</SUMItemSeq>
    <SUMItemClassLSeq>1</SUMItemClassLSeq>
    <SUMItemClassMSeq>1</SUMItemClassMSeq>
    <SUMItemClassSSeq>1</SUMItemClassSSeq>
    <SUMCust>1</SUMCust>
    <SUMDept>1</SUMDept>
    <SUMEmp>1</SUMEmp>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037840,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030941
rollback 