IF OBJECT_ID('KPXCM_SPUORDApprovalReqGW') IS NOT NULL 
    DROP PROC KPXCM_SPUORDApprovalReqGW
GO 

/************************************************************    
 설  명 - 데이터-구매품의전자결재_KPXCM :     
 작성일 - 20150705    
 작성자 - 박상준    
 수정자 - 20150727 일부항목 수정(내외자구분, 종전가, 변동율, 평균사용량)   
		- 20150731 종전가 또는 1차견적가가 0인 경우 단가차이 0  
		- 20150804 종전가 정렬 수정, 구매금액 수정(품목별 원화금액계)
************************************************************/    

CREATE PROC dbo.KPXCM_SPUORDApprovalReqGW                    
    @xmlDocument   NVARCHAR(MAX) ,                
    @xmlFlags      INT = 0,                
    @ServiceSeq    INT = 0,                
    @WorkingTag    NVARCHAR(10)= '',                      
    @CompanySeq    INT = 1,                
    @LanguageSeq   INT = 1,                
    @UserSeq       INT = 0,                
    @PgmSeq        INT = 0           
    
AS            
        
    DECLARE  @docHandle         INT    
            ,@ApproReqSeq       INT    
            ,@TotDomAmt         DECIMAL(19,5)    
            ,@TotCurAmt         DECIMAL(19,5)    
            ,@Date              NCHAR(8)    
            ,@DateFr            NCHAR(8)    
            ,@DateTo            NCHAR(8)    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
    
    SELECT  @ApproReqSeq  = ApproReqSeq       
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (    
                ApproReqSeq   INT     
           )    
           
    DECLARE @BaseCurrSeq INT
    SET @BaseCurrSeq = (SELECT TOP 1 EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 13) -- 자국통화(KRW)
           
	/*=================================================================================================    
	=================================================================================================*/    
	  --1758,1759    
	SELECT @Date = ApproReqDate    
	FROM _TPUORDApprovalReq WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq    
	SELECT  @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,@Date),112)    
		   ,@DateFr = CONVERT(NCHAR(8),DATEADD(MM,-3,@Date),112)    
	    
	-- 대상품목    
	CREATE TABLE #GetInOutItem (        
		   ItemSeq INT,        
		   ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- 품목소분류       
		   ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- 품목중분류       
		   ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- 품목대분류   
		   )   
	 INSERT INTO #GetInOutItem(ItemSeq)   
	 SELECT ItemSeq   
	   FROM _TPUORDApprovalReqItem   
	  WHERE CompanySeq = @CompanySeq   
		AND ApproReqSeq = @ApproReqSeq    
	      
	 -- 입출고   
	 CREATE TABLE #GetInOutStock (       
			 WHSeq           INT,       
			 FunctionWHSeq   INT,       
			 ItemSeq         INT,       
			 UnitSeq         INT,       
			 PrevQty         DECIMAL(19,5),       
			 InQty           DECIMAL(19,5),       
			 OutQty          DECIMAL(19,5),       
			 StockQty        DECIMAL(19,5),       
			 STDPrevQty      DECIMAL(19,5),       
			 STDInQty        DECIMAL(19,5),       
			 STDOutQty       DECIMAL(19,5),       
			 STDStockQty     DECIMAL(19,5) )   
	           
	 -- 상세입출고내역    
	 CREATE TABLE #TLGInOutStock   (         
			 InOutType INT,         
			 InOutSeq  INT,         
			 InOutSerl INT,         
			 DataKind  INT,         
			 InOutSubSerl  INT,         
			 InOut INT,         
			 InOutDate NCHAR(8),         
			 WHSeq INT,         
			 FunctionWHSeq INT,         
			 ItemSeq INT,         
			 UnitSeq INT,         
			 Qty DECIMAL(19,5),         
			 StdQty DECIMAL(19,5),       
			 InOutKind INT,       
			 InOutDetailKind INT  )    
	    
		-- 창고재고 가져오기       
		EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- 법인코드                              
			 ,@BizUnit      = 0                   -- 사업부문                              
			 ,@FactUnit     = 0                   -- 생산사업장                              
			 ,@DateFr       = @DateFr             -- 조회기간Fr                              
			 ,@DateTo       = @DateTo             -- 조회기간To                              
			 ,@WHSeq        = 0                   -- 창고지정                              
			 ,@SMWHKind     = 0                   -- 창고구분                               
			   ,@CustSeq      = 0                   -- 수탁거래처                              
			 ,@IsTrustCust  = ''                  -- 수탁여부                              
			 ,@IsSubDisplay = 0                   -- 기능창고 조회                              
			 ,@IsUnitQry    = 0                   -- 단위별 조회                              
			 ,@QryType      = 'S'                 -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고                              
			 ,@MngDeptSeq   = 0                                                 
			 ,@IsUseDetail  = '1'    
			 
	SELECT  @CompanySeq                 AS CompanySeq    
			,ItemSeq    
			,SUM(ISNULL(STDOutQty,0))    AS OutQty    
	  INTO #OutQty    
	  FROM #GetInOutStock    
	 GROUP BY ItemSeq     
	 
	TRUNCATE TABLE #GetInOutStock    
	TRUNCATE TABLE #TLGInOutStock    
    
    -- 창고재고 가져오기       
    EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- 법인코드                              
         ,@BizUnit      = 0                   -- 사업부문                              
         ,@FactUnit     = 0                   -- 생산사업장                              
         ,@DateFr       = @Date               -- 조회기간Fr                              
         ,@DateTo       = @Date               -- 조회기간To                              
         ,@WHSeq        = 0                   -- 창고지정                              
         ,@SMWHKind     = 0                   -- 창고구분                               
         ,@CustSeq      = 0                   -- 수탁거래처                              
         ,@IsTrustCust  = ''                  -- 수탁여부                              
         ,@IsSubDisplay = 0                   -- 기능창고 조회                              
         ,@IsUnitQry    = 0                   -- 단위별 조회                              
         ,@QryType      = 'S'                 -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고                              
         ,@MngDeptSeq   = 0                                                 
         ,@IsUseDetail  = '1'    
    
	 SELECT  @CompanySeq                   AS CompanySeq    
	   ,ItemSeq    
	   ,SUM(ISNULL(STDStockQty,0))    AS StockQty    
	   INTO #StockQty    
	   FROM #GetInOutStock     
	  GROUP BY ItemSeq      
    
	CREATE TABLE #ApprovalReqPrice(ApproReqSeq INT, CustSeq INT, ItemSeq INT, Price DECIMAL(19,5))
	INSERT INTO #ApprovalReqPrice
	SELECT A.ApproReqSeq, B.CustSeq, B.ItemSeq, 
		   CASE WHEN B.SMImpType = 8008004 -- 직수입
			    THEN (SELECT TOP 1 ISNULL(S.Price, 0)
						FROM _TUIImpDelvItem AS S
						LEFT OUTER JOIN _TUIImpDelv AS V WITH(NOLOCK) ON V.CompanySeq = S.CompanySeq
																	 AND V.DelvSeq = S.DelvSeq
					   WHERE S.CompanySeq = @CompanySeq
						 AND V.DelvDate = Q.DelvDate
						 AND S.ItemSeq = Q.ItemSeq
						 AND V.CustSeq = Q.CustSeq
					   ORDER BY S.DelvSeq DESC) -- 종전 동일거래처의 수입입고가
				ELSE (SELECT TOP 1 ISNULL(T.Price, 0) AS Price 
						FROM _TPUDelvInItem AS T
						LEFT OUTER JOIN _TPUDelvIn AS U WITH(NOLOCK) ON U.CompanySeq = T.CompanySeq
																	AND U.DelvInSeq = T.DelvInSeq
					   WHERE T.CompanySeq = @CompanySeq
					     AND U.DelvInDate = L.DelvInDate
						 AND T.ItemSeq = L.ItemSeq
						 AND U.CustSeq = L.CustSeq
					   ORDER BY T.DelvInSeq DESC) -- 종전 동일거래처의 구입입고가
		   END
	  FROM _TPUORDApprovalReq                  AS A WITH(NOLOCK)
	  LEFT OUTER JOIN _TPUORDApprovalReqItem   AS B WITH(NOLOCK) ON A.CompanySeq    = B.CompanySeq
                                                                AND A.ApproReqSeq   = B.ApproReqSeq
	  OUTER APPLY (SELECT X.CompanySeq,MAX(Z.DelvInDate) AS DelvInDate,Z.CustSeq,X.ItemSeq
                     FROM _TPUDelvIn       AS Z
                     JOIN _TPUDelvInItem   AS X WITH(NOLOCK) ON Z.CompanySeq = X.CompanySeq
                                                            AND Z.DelvInSeq  = X.DelvInSeq
                    WHERE Z.CompanySeq = @CompanySeq
                      AND Z.DelvInDate <= A.ApproReqDate
                      AND X.ItemSeq    = B.ItemSeq
                      AND Z.CustSeq    = B.CustSeq
                    GROUP BY X.CompanySeq,Z.CustSeq,X.ItemSeq) AS L     
	  OUTER APPLY (SELECT X.CompanySeq,MAX(Z.DelvDate) AS DelvDate,Z.CustSeq,X.ItemSeq
                     FROM _TUIImpDelv       AS Z
                     JOIN _TUIImpDelvItem   AS X WITH(NOLOCK) ON Z.CompanySeq = X.CompanySeq
                                                             AND Z.DelvSeq  = X.DelvSeq
                    WHERE Z.CompanySeq = @CompanySeq
                      AND Z.DelvDate <= A.ApproReqDate
                      AND X.ItemSeq    = B.ItemSeq
                      AND Z.CustSeq    = B.CustSeq
                    GROUP BY X.CompanySeq,Z.CustSeq,X.ItemSeq) AS Q
       WHERE A.CompanySeq    = @CompanySeq
         AND A.ApproReqSeq   = @ApproReqSeq
         
          
/*=================================================================================================    
=================================================================================================*/    
     SELECT ROW_NUMBER() OVER(ORDER BY A.ApproReqSeq) AS Num,   
            /*마스터*/    
             ISNULL(A.CompanySeq     , 0)       AS CompanySeq    
            ,ISNULL(A.ApproReqSeq    , 0)       AS ApproReqSeq    
            ,ISNULL(A.ApproReqNo     ,'')       AS ApproReqNo    
            ,ISNULL(A.ApproReqDate   ,'')       AS ApproReqDate    
            ,ISNULL(A.DeptSeq        , 0)       AS DeptSeq    
            ,ISNULL(C.DeptName       ,'')       AS DeptName    
            ,ISNULL(B.CurrSeq        , 0)       AS CurrSeq    
            ,ISNULL(D.CurrName       ,'')       AS CurrName    
            ,ISNULL(A.EmpSeq         , 0)       AS EmpSeq    
            ,ISNULL(E.EmpName        ,'')       AS EmpName    
            ,ISNULL(B.ExRate         , 0)       AS ExRate    
            ,ISNULL(J.TotDomAmt      , 0)       AS TotDomAmt    
            ,ISNULL(A.Remark         ,'')       AS Remark    
            ,ISNULL(B.UnitSeq        , 0)       AS UnitSeq    
            ,ISNULL(K.UnitName       ,'')       AS UnitName   
            ,ISNULL(B.SMImpType   , 0)   AS SMImpType -- 내외자구분코드 -- 150730  
            ,ISNULL(P.MinorName   ,'')   AS SMImpTypeName -- 내외자구분 -- 150730  
            /*디테일*/    
            ,ISNULL(B.CustSeq        , 0)       AS CustSeq    
            ,ISNULL(F.CustName       ,'')       AS CustName    
            ,ISNULL(B.MakerSeq       , 0)       AS MakerSeq    
            ,ISNULL(G.CustName       ,'')       AS MakerName    
            ,ISNULL(B.ItemSeq        , 0)       AS ItemSeq    
            ,ISNULL(H.ItemName       ,'')       AS ItemName    
            ,ISNULL(H.ItemNo         ,'')       AS ItemNo    
            ,ISNULL(H.Spec           ,'')       AS Spec    
            ,ISNULL(B.Memo1          ,'')       AS PurPose              --용도    
            ,ISNULL(B.Memo5          , 0)       AS PackingSeq            --포장구분    
            ,ISNULL(I.MinorName      ,'')       AS PackingName          --포장구분    
			,CASE WHEN ISNULL(B.CurrSeq,0) = @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(INT,ISNULL(L.Price,0))) 
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(L.Price, 0))) 
				  END AS CurentPrice--종전가  -- 150730 -- 자국통화(KRW) 아닐 경우 소수점2자리 표시 
            ,CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Memo7, 0)))
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Memo7, 0)))
				  END  AS FirstPrice           --1차견적가    
            ,CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
				  THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Price, 0)))
				  ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Price, 0)))
				  END       AS LastPrice            --최종가(단가) 
            ,(CASE WHEN ISNULL(L.Price,0) = 0 AND ISNULL(B.Memo7,0) = 0 -- 150731 종전가와 1차견적가가 0인 경우 단가차이 0  
				   THEN (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
							  THEN '0.000'
							  ELSE '0' END)
				   ELSE (CASE WHEN ISNULL(L.Price, 0)=0  
							  THEN (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
										 THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(B.Memo7, 0) - ISNULL(B.Price, 0)))
										 ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(B.Memo7, 0) - ISNULL(B.Price, 0)))
										 END)  
							  ELSE (CASE WHEN ISNULL(B.CurrSeq,0) <> @BaseCurrSeq 
										 THEN CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,3),ISNULL(L.Price, 0) - ISNULL(B.Price, 0)))
										 ELSE CONVERT(NVARCHAR(100),CONVERT(DECIMAL(19,0),ISNULL(L.Price, 0) - ISNULL(B.Price, 0)))
										 END)
							  END)  
				   END)             AS DiffPrice          --단가차이        => ABS??? 
            ,CASE WHEN ISNULL(L.Price, 0)=0    
                  THEN 0    
                  ELSE ((CASE WHEN ISNULL(L.Price, 0)=0    
                              THEN ISNULL(B.Memo7, 0)    
                              ELSE ISNULL(L.Price, 0)    
                              END)-ISNULL(B.Price, 0))/ISNULL(L.Price, 0)    
                  END * 100                          AS TransRate          --변동율(%)  -- 150730  
            ,ISNULL(B.Qty            , 0)       AS Qty                --수량    
            ,ISNULL(B.DelvDate       ,'')       AS DelvDate           --납기요청일    
            --,ISNULL(J.TotCurAmt      , 0)       AS TotCurAmt          --구매금액    
            ,ISNULL(B.DomAmt,0) + ISNULL(B.DomVAT,0) AS TotCurAmt	   --구매금액
            ,ISNULL(N.OutQty         , 0)/3     AS OutQty             --평균사용량  -- 150730  
            ,ISNULL(O.StockQty       , 0)       AS StockQty           --현재고량
       FROM _TPUORDApprovalReq                  AS A WITH(NOLOCK)    
  LEFT OUTER JOIN _TPUORDApprovalReqItem              AS B WITH(NOLOCK)ON A.CompanySeq    = B.CompanySeq    
                  AND A.ApproReqSeq   = B.ApproReqSeq    
  LEFT OUTER JOIN _TDADept                            AS C WITH(NOLOCK)ON A.CompanySeq    = C.CompanySeq    
                  AND A.DeptSeq       = C.DeptSeq    
  LEFT OUTER JOIN _TDACurr                            AS D WITH(NOLOCK)ON B.CompanySeq    = D.CompanySeq    
                  AND B.CurrSeq       = D.CurrSeq    
  LEFT OUTER JOIN _TDAEmp                             AS E WITH(NOLOCK)ON A.CompanySeq    = E.CompanySeq    
                  AND A.EmpSeq        = E.EmpSeq    
  LEFT OUTER JOIN _TDACust                            AS F WITH(NOLOCK)ON B.CompanySeq    = F.CompanySeq    
                  AND B.CustSeq       = F.CustSeq    
  LEFT OUTER JOIN _TDACust                            AS G WITH(NOLOCK)ON B.CompanySeq    = G.CompanySeq    
                  AND B.MakerSeq      = G.CustSeq    
  LEFT OUTER JOIN _TDAItem                            AS H WITH(NOLOCK)ON B.CompanySeq    = H.CompanySeq    
                  AND B.ItemSeq       = H.ItemSeq    
  LEFT OUTER JOIN _TDAUMinor                          AS I WITH(NOLOCK)ON B.CompanySeq    = I.CompanySeq    
                  AND B.Memo5         = I.MinorSeq    
  LEFT OUTER JOIN (    
      SELECT  CompanySeq    
          ,ApproReqSeq    
          ,MAX(UnitSeq)            AS UnitSeq    
          ,SUM(DomAmt + DomVAT)    AS TotDomAmt    
          ,SUM(CurAmt + CurVAT)    AS TotCurAmt    
        FROM _TPUORDApprovalReqItem    
       WHERE CompanySeq  = @CompanySeq    
         AND ApproReqSeq = @ApproReqSeq    
       GROUP BY CompanySeq,ApproReqSeq    
     )                                   AS J             ON A.CompanySeq    = J.CompanySeq    
                  AND A.ApproReqSeq   = J.ApproReqSeq    
  LEFT OUTER JOIN _TDAUnit                            AS K WITH(NOLOCK)ON J.CompanySeq    = K.CompanySeq    
                  AND J.UnitSeq       = K.UnitSeq    
  --LEFT OUTER JOIN (    
  --    SELECT X.CompanySeq,MAX(X.DelvInSeq) AS DelvInSeq,X.DelvInSerl,X.ItemSeq    
  --      FROM _TPUDelvIn       AS Z    
  --      JOIN _TPUDelvInItem   AS X WITH(NOLOCK)ON Z.CompanySeq = X.CompanySeq    
  --              AND Z.DelvInSeq  = X.DelvInSeq    
  --     WHERE Z.CompanySeq = @CompanySeq    
  --       AND Z.DelvInDate <= (SELECT ApproReqDate     FROM _TPUORDApprovalReq     WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)    
  --       AND X.ItemSeq    IN (SELECT DISTINCT ItemSeq FROM _TPUORDApprovalReqItem WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)      --통화같은건진 나중에 확인하기    
  --     GROUP BY X.CompanySeq,X.DelvInSerl,X.ItemSeq    
  --   )                                   AS L             ON B.CompanySeq    = L.CompanySeq    
  --                AND B.ItemSeq       = L.ItemSeq     
  --LEFT OUTER JOIN _TPUDelvInItem                      AS M WITH(NOLOCK)ON L.CompanySeq    = M.CompanySeq    
  --                AND L.DelvInSeq     = M.DelvInSeq    
  --                AND L.DelvInSerl    = M.DelvInSerl 
	LEFT OUTER JOIN #ApprovalReqPrice      AS L WITH(NOLOCK) ON L.ApproReqSeq   = A.ApproReqSeq    
                     AND L.ItemSeq    = B.ItemSeq    
                     AND L.CustSeq    = B.CustSeq    
	LEFT OUTER JOIN #OutQty                             AS N WITH(NOLOCK)ON B.CompanySeq    = N.CompanySeq    
                  AND B.ItemSeq       = N.ItemSeq    
	LEFT OUTER JOIN #StockQty                           AS O WITH(NOLOCK)ON B.CompanySeq    = O.CompanySeq    
                  AND B.ItemSeq       = O.ItemSeq    
    LEFT OUTER JOIN _TDASMinor        AS P WITH(NOLOCK) ON P.CompanySeq   = B.CompanySeq    
                  AND P.MinorSeq   = B.SMImpType                                                           
                                                                    
      WHERE A.CompanySeq    = @CompanySeq    
        AND A.ApproReqSeq   = @ApproReqSeq    
    
    
  /*=================================================================================================    
=================================================================================================*/        
  RETURN  
  go 
  EXEC _SCOMGroupWarePrint 2, 1, 1, 1025093, 'ApprovalReq_CM', '106', ''