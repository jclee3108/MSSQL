IF OBJECT_ID('hencom_VPUBASEBuyPriceItemDateAll') IS NOT NULL 
    DROP VIEW hencom_VPUBASEBuyPriceItemDateAll
GO 

/************************************************************
 설  명 - 뷰-사업소별구매단가등록_hencom
 작성일 - 2015.09.23
 작성자 - kth
 수정자 -
************************************************************/	
CREATE VIEW hencom_VPUBASEBuyPriceItemDateAll
  
AS   
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
FROM hencom_TPUBASEBuyPriceItem AS X 