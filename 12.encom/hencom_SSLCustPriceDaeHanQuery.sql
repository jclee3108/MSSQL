IF OBJECT_ID('hencom_SSLCustPriceDaeHanQuery') IS NOT NULL 
    DROP PROC hencom_SSLCustPriceDaeHanQuery
GO 

-- v2017.04.24
/************************************************************
 설  명 - 거래처별단가등록(대한)조회_hencom
 작성일 - 2015.10.19
 작성자 - kth
 수정자 -
************************************************************/		
CREATE PROCEDURE hencom_SSLCustPriceDaeHanQuery
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE   @docHandle    INT,    
              @DeptSeq		INT,
			  @IsStopTag	INT
              --@IsLast        NCHAR(1)           -- 최종여부
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @DeptSeq      = ISNULL(DeptSeq,0),
			@IsStopTag		=	IsNull(IsStopTag,0)
            --@IsLast         = ISNULL(IsLast,  '')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (  DeptSeq          INT,
	        IsStopTag        int
            --IsLast           NCHAR(1)
            )
    

    SELECT  x.CompanySeq,
		    x.BuyPriceSeq,
		    x.ProdDistrictSeq,
		    x.CurrSeq,
		    x.UnitSeq,
		    x.ItemPrice,
		    x.AidDeliCharge,
		    x.RealItemPrice,
		    x.StartDate,
		    x.IsDeliCharge,
		    x.DeliCustSeq,
		    x.DeliChargePrice,
		    x.Remark,
		    x.LastUserSeq,
		    x.LastDateTime,
		    x.FirstUserSeq,
		    x.FirstDateTime,
		    x.DeptSeq,
		    x.ItemSeq,
		    x.CustSeq,
		    x.UMPayMethod,
		    x.PayPeriod,
		    x.DeliUMPayMethod,
		    x.DeliPayPeriod,
		    x.SalesCustSeq,
		    x.PuPunctuality,
		    x.DeliPunctuality,
		    x.IsStop,
            CASE WHEN (SELECT MAX(StartDate)   
                         FROM hencom_TPUBASEBuyPriceItem   
                        WHERE X.CompanySeq = CompanySeq   
                          AND X.CustSeq = CustSeq 
                          AND X.DeptSeq = DeptSeq   
                          AND X.ProdDistrictSeq = ProdDistrictSeq 
                          AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
                          AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
                          AND X.ItemSeq = ItemSeq) = X.StartDate THEN '99991231'  
            ELSE
            (SELECT CONVERT(NCHAR(8),DATEADD(D, -1, MIN(StartDate)),112) 
               FROM hencom_TPUBASEBuyPriceItem
              WHERE X.CompanySeq = CompanySeq
                AND X.CustSeq = CustSeq 
                AND X.DeptSeq = DeptSeq 
                AND X.ProdDistrictSeq = ProdDistrictSeq 
                AND X.ItemSeq = ItemSeq 
                AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
                AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
                AND X.StartDate < StartDate) END AS EndDate,        -- 적용종료일
            CASE WHEN X.StartDate = (SELECT TOP 1 StartDate 
                                       FROM hencom_TPUBASEBuyPriceItem WITH(NOLOCK)
                                      WHERE CompanySeq = X.CompanySeq
                                        AND ItemSeq = X.ItemSeq
                                        AND CustSeq = X.CustSeq
                                        AND DeptSeq = X.DeptSeq
                                        AND ProdDistrictSeq = X.ProdDistrictSeq
                                        AND ISNULL(DeliCustSeq, 0) = ISNULL(X.DeliCustSeq, 0)
                                        AND ISNULL(SalesCustSeq, 0) = ISNULL(X.SalesCustSeq, 0)
                                      ORDER BY StartDate DESC ) THEN '1' END AS IsLast     -- 최종여부
      INTO #hencom_TPUBASEBuyPriceItem 
      FROM hencom_TPUBASEBuyPriceItem AS X 


	 SELECT  A.CPDRegSeq, A.DeptSeq, A.DeptName, A.CustSeq, A.CustName, A.ProdDistrictSeq, A.ProdDistrictName, A.ItemSeq, A.ItemName,
			A.ItemNo, A.Spec, A.PUCustSeq, A.PUCustName, A.DeliCustSeq, A.DeliCustName, A.DeptItemPrice, A.AidDeliCharge, A.RealItemPrice,
			A.DeliChargePrice, A.SumPrice, A.SalesPrice, A.IsDeliCharge, A.StartDate, A.IsStop, A.EndDate, A.IsLast, Remark, A.LastUserName,
			A.LastDateTime
	 FROM (
			SELECT  X.CPDRegSeq,
					X.DeptSeq,
					F.DeptName,
					X.CustSeq,
					G.CustName,                     -- 판매거래처
					X.ProdDistrictSeq,
					PA.ProdDistirct AS ProdDistrictName,
					X.ItemSeq,
					A.ItemName  AS ItemName,
					A.ItemNo    AS ItemNo,
					A.Spec      AS Spec,
					X.PUCustSeq,
					H.CustName AS PUCustName,       -- 매입거래처
					X.DeliCustSeq,
					BC.CustName AS DeliCustName,    -- 기본운송처
					-- 사업소산지별단가 영역
					B.ItemPrice AS DeptItemPrice,   -- 품대
					B.AidDeliCharge,                -- 운송보조비
					B.RealItemPrice,                -- 실품대
					B.DeliChargePrice,              -- 운송비
					B.RealItemPrice + B.DeliChargePrice AS SumPrice,    -- 매입단가

					X.SalesPrice,                   -- 판매단가
					X.IsDeliCharge,
					X.StartDate,
					X.IsStop,
					(SELECT CONVERT(NCHAR(8),DATEADD(D, -1, MIN(StartDate)),112) 
					   FROM hencom_TSLCustPriceDaeHan
					  WHERE X.CompanySeq = CompanySeq
						AND X.CustSeq = CustSeq 
						AND X.DeptSeq = DeptSeq 
						AND X.ProdDistrictSeq = ProdDistrictSeq 
						AND X.ItemSeq = ItemSeq 
						AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
						AND ISNULL(X.PUCustSeq, 0) = ISNULL(PUCustSeq, 0)
						AND X.StartDate < StartDate) AS EndDate,        -- 적용종료일
					CASE WHEN X.StartDate = (SELECT TOP 1 StartDate 
											   FROM hencom_TSLCustPriceDaeHan WITH(NOLOCK)
											  WHERE CompanySeq = X.CompanySeq
												AND ItemSeq = X.ItemSeq
												AND CustSeq = X.CustSeq
												AND DeptSeq = X.DeptSeq
												AND ProdDistrictSeq = X.ProdDistrictSeq
												AND ISNULL(DeliCustSeq, 0) = ISNULL(X.DeliCustSeq, 0)
												AND ISNULL(PUCustSeq, 0) = ISNULL(X.PUCustSeq, 0)
											  ORDER BY StartDate DESC ) THEN '1' END AS IsLast,     -- 최종여부
					X.Remark,
					LU.UserName AS LastUserName,
					X.LastDateTime
				FROM hencom_TSLCustPriceDaeHan AS X WITH(NOLOCK) 
					--LEFT OUTER JOIN hencom_TPUDeptCustAddInfo AS P1 WITH(NOLOCK) ON P1.CompanySeq = X.CompanySeq    
					--                                                            AND P1.DeptSeq = X.DeptSeq   
					--                                                            AND P1.CustSeq = X.CustSeq  
					--LEFT OUTER JOIN hencom_TPUDeptCustAddInfo AS P2 WITH(NOLOCK) ON P2.CompanySeq = X.CompanySeq    
				   --                                                             AND P2.DeptSeq = X.DeptSeq   
					--   AND P2.CustSeq = X.DeliCustSeq  
                                                               
					-- 2015.10.28   kth     산지, 기본운송처 추가
					LEFT OUTER JOIN hencom_TPUPurchaseArea AS PA WITH(NOLOCK) ON PA.CompanySeq = X.CompanySeq    
																			 AND PA.ProdDistrictSeq = X.ProdDistrictSeq                                                                          
					LEFT OUTER JOIN _TDADept AS F WITH(NOLOCK) ON F.CompanySeq = X.CompanySeq    
															  AND F.DeptSeq = X.DeptSeq                     
					LEFT OUTER JOIN _TDACust AS G WITH(NOLOCK) ON G.CompanySeq = X.CompanySeq  
															  AND G.CustSeq = X.CustSeq       
					LEFT OUTER JOIN _TDACust AS H WITH(NOLOCK) ON H.CompanySeq = X.CompanySeq  
															  AND H.CustSeq = X.PUCustSeq  
					LEFT OUTER JOIN _TDACust AS BC WITH(NOLOCK) ON BC.CompanySeq = X.CompanySeq  
															   AND BC.CustSeq = X.DeliCustSeq                                                        
					LEFT OUTER JOIN _TDAItem  AS A WITH(NOLOCK) ON A.CompanySeq = X.CompanySeq
															   AND A.ItemSeq = X.ItemSeq
					LEFT OUTER JOIN _TCAUSER AS LU WITH(NOLOCK) ON LU.CompanySeq = X.CompanySeq  
															   AND LU.UserSeq  = X.LastUserSeq 
					LEFT OUTER JOIN #hencom_TPUBASEBuyPriceItem AS B WITH(NOLOCK) ON B.CompanySeq = X.CompanySeq
                                                                                 AND B.DeptSeq = X.DeptSeq
                                                                                 AND B.ItemSeq = X.ItemSeq
                                                                                 AND B.CustSeq = X.PUCustSeq        -- 매입거래처
                                                                                 AND ISNULL(B.ProdDistrictSeq, 0) = ISNULL(X.ProdDistrictSeq, 0)
                                                                                 AND ISNULL(B.DeliCustSeq, 0) = ISNULL(X.DeliCustSeq, 0)    -- 기본운송처
                                                                                 AND ISNULL(B.SalesCustSeq, 0) = ISNULL(X.CustSeq, 0)       -- 판매처
                                                                                 -- 2016.02.18  kth 최종이 아닌 적용일에 걸린 단가 가져오게 수정
                                                                                 --AND ISNULL(B.IsLast, '0') = '1'  
                                                                                 AND X.StartDate BETWEEN B.StartDate AND B.EndDate  
					-- 품목 소/중/대분류
					--LEFT OUTER JOIN _TDAItemClass AS O WITH(NOLOCK) ON A.CompanySeq = O.CompanySeq 
					--                                               AND A.ItemSeq = O.ItemSeq 
					--                                               AND O.UMajorItemClass IN (2001,2004) 
					--LEFT OUTER JOIN _TDAUMinor AS N WITH(NOLOCK) ON O.CompanySeq = N.CompanySeq    
					--                                            AND O.UMItemClass = N.MinorSeq             
					--LEFT OUTER JOIN _TDAUMinorValue X1 WITH(NOLOCK) ON N.CompanySeq = X1.CompanySeq
					--                                            AND N.MinorSeq = X1.MinorSeq
					--                                            AND X1.Serl IN (1001, 2001)
					--LEFT OUTER JOIN _TDAUMinor      X2 WITH(NOLOCK) ON X1.CompanySeq = X2.CompanySeq
					--                                            AND X1.ValueSeq = X2.MinorSeq
					--LEFT OUTER JOIN _TDAUMinorValue Y1 WITH(NOLOCK) ON X2.CompanySeq = Y1.CompanySeq
		 --                                             AND X2.MinorSeq = Y1.MinorSeq
					--  AND Y1.Serl = 2001
					--LEFT OUTER JOIN _TDAUMinor      Y2 WITH(NOLOCK) ON Y1.CompanySeq  = Y2.CompanySeq
					--                                            AND Y1.ValueSeq = Y2.MinorSeq
					--LEFT OUTER JOIN _TPUBASEBuyPriceItem AS D WITH(NOLOCK) ON  A.CompanySeq = D.CompanySeq
					--                                            AND A.ItemSeq = D.ItemSeq
					--LEFT OUTER JOIN _TDASMinor   AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
					--                                            AND A.SMStatus   = E.MinorSeq
			WHERE A.CompanySeq  = @CompanySeq
				--AND (@ItemNo   = '' OR A.ItemNo   LIKE @ItemNo   + '%')
				--AND (@ItemName = '' OR A.ItemName LIKE @ItemName + '%')
				  AND (@DeptSeq  = 0 OR X.DeptSeq = @DeptSeq)
				  AND (@IsStopTag = 0 OR IsNull(X.IsStop,0) = (CASE WHEN @IsStopTag = 1 THEN 0 ELSE 1 END))
				--AND (@CustSeq  = 0 OR X.CustSeq = @CustSeq)
				--AND (@ItemSeq  = 0 OR X.ItemSeq = @ItemSeq)
				--AND (@ItemClassSSeq = 0 OR @ItemClassSSeq = O.UMItemClass)    
				--AND (@ItemClassMSeq = 0 OR @ItemClassMSeq = X2.MinorSeq)    
				--AND (@ItemClassLSeq = 0 OR @ItemClassLSeq = Y2.MinorSeq)     
				--AND (@IsLast        = '0' OR X.StartDate = (SELECT TOP 1 StartDate 
				--                                              FROM hencom_TPUBASEBuyPriceItem WITH(NOLOCK)
				--                                             WHERE CompanySeq = X.CompanySeq
				--                                               AND ItemSeq = X.ItemSeq
				--                                               AND CustSeq = X.CustSeq
				--                                               AND DeptSeq = X.DeptSeq
				--                                               AND ProdDistrictSeq = X.ProdDistrictSeq
				--                                             ORDER BY StartDate DESC ))
				--ORDER BY X.StartDate
			)	A
	 WHERE	(@IsStopTag = 0 OR IsNull(A.IsLast,0) = (CASE WHEN @IsStopTag = 1 THEN 1 ELSE 0 END))
go
begin tran 
exec hencom_SSLCustPriceDaeHanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>13</DeptSeq>
    <IsStopTag>0</IsStopTag>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032636,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027041
rollback 