IF OBJECT_ID('mnpt_SSLInvoiceEngUnloadPrintQuery') IS NOT NULL 
    DROP PROC mnpt_SSLInvoiceEngUnloadPrintQuery
GO 
/************************************************************
 설  명		- 청구서(출력물)-영문청구서(하역료)
 작성일		- 2017년 11월 01일 
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
 CREATE PROC mnpt_SSLInvoiceEngUnloadPrintQuery  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
	DECLARE @InvoiceSeq		INT,
			@SumAmt			DECIMAL(19, 5),
			@HanAmt			NVARCHAR(100),
			@AllItemName	NVARCHAR(1000),
			@PJTTypeName	NVARCHAR(100)
	SELECT @InvoiceSeq = ISNULL(InvoiceSeq, 0)
	  FROM #BIZ_IN_DataBlock1
	DECLARE @Photo	NVARCHAR(MAX)
	SELECT @Photo	= Photo
	  FROM mnpt_TSLEEStamp
	 WHERE CompanySeq	= @CompanySeq  
	   AND StdSeq		= 4
	SELECT F.TaxEngName									AS TaxEngName,
		   F.AddrEng1 + F.AddrEng2						AS AddrEng,
		   K.EngCustName								AS EngCustName,
		   A.InvoiceDate								AS InvoiceDate,
		   ISNULL(N.EnShipName, '')						AS EnShipName,
		   '#' + M.BERTH								AS Berth,
		   LEFT(M.InDateTime, 4) + '/' + SUBSTRING(M.InDateTime, 5, 2) + '/' + SUBSTRING(M.InDateTime, 7, 2) + ' ~ ' +
		   LEFT(M.OutDateTime, 4) + '/' + SUBSTRING(M.OutDateTime, 5, 2) + '/' + SUBSTRING(M.OutDateTime, 7, 2)	AS Period,
		   O.ItemEngName								AS ItemName,
		   
           P.Qty1 AS Qty1, 
           CASE WHEN ISNULL(Q.Remark, '') = '' THEN Q.UnitName ELSE ISNULL(Q.Remark, '') END AS UnitName, 

           REPLACE(CONVERT(NVARCHAR(30),CAST(P.Qty1 AS MONEY),1),'.00','') +  CASE WHEN ISNULL(Q.Remark, '') = '' THEN Q.UnitName
																				   ELSE ISNULL(Q.Remark, '')
																				   END								AS QtyData,
            


		   CASE WHEN S.CurrSeq = 1 THEN '\ ' + REPLACE(CONVERT(NVARCHAR(30),CAST(B.Price AS MONEY),1),'.00','') + '/' + CASE WHEN ISNULL(Q.Remark, '') = '' THEN Q.UnitName
																															 ELSE ISNULL(Q.Remark, '')
																															 END
			    ELSE S.CurrUnit + ' ' + REPLACE(CONVERT(NVARCHAR(30),CAST(B.Price AS MONEY),1),'.00','') + '/' + CASE WHEN ISNULL(Q.Remark, '') = '' THEN Q.UnitName
																													  ELSE ISNULL(Q.Remark, '')
																													  END
				END AS PriceData,
		   CASE WHEN ISNULL(P.Qty2, 0) = 0 THEN ''
				ELSE  REPLACE(CONVERT(NVARCHAR(30),CAST(P.Qty2 AS MONEY),1),'.00','') + R.Remark
				END AS QtyData2,
		   B.Price										AS Price,
		   B.CurAmt										AS CurAmt,
		   I.BankEngName								AS BankEngName,
		   H.BankAccNo									AS BankAccNo,
		   F.AddrEng3									AS EngOwner,
		   CASE WHEN S.CurrSeq = 1 THEN '\' 
			    ELSE S.CurrUnit
				END AS CurrName,
		   ISNULL(@Photo, '')							AS Photo
	  FROM _TSLInvoice AS A WITH(NOLOCK)
		   LEFT  JOIN _TSLInvoiceItem AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN _TDACust AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  AND C.CustSeq		= A.CustSeq
		   LEFT  JOIN _TDAUMinorValue AS D WITH(NOLOCK)
				   ON D.CompanySeq	= A.CompanySeq
				  AND D.MajorSeq	= 1016119
				  AND D.Serl		= 1000001
				  AND D.ValueSeq	= A.BizUnit
		   LEFT  JOIN _TDAUMinorValue AS E WITH(NOLOCK)
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.MinorSeq	= D.MinorSeq
				  AND E.Serl		= 1000002
		   LEFT  JOIN _TDATaxUnit AS F WITH(NOLOCK)
				   ON F.CompanySeq	= E.CompanySeq
				  AND F.TaxUnit		= E.ValueSeq
		   LEFT  JOIN _TDAUMinorValue AS G WITH(NOLOCK)
				   ON G.CompanySeq	= D.CompanySeq
				  AND G.MinorSeq	= D.MinorSeq
				  AND G.Serl		= 1000003
		   LEFT  JOIN _TDABankAcc AS H WITH(NOLOCK)
				   ON H.CompanySeq	= G.CompanySeq
				  AND H.BankAccSeq	= G.ValueSeq
		   LEFT  JOIN _TDABank AS I WITH(NOLOCK)
				   ON I.CompanySeq	= H.CompanySeq
				  AND I.BankSeq		= H.BankSeq
		   LEFT  JOIN _TDAUMinor AS J WITH(NOLOCK)
				   ON J.CompanySeq	= I.CompanySeq
				  AND J.MinorSeq	= I.BankHQ
		   LEFT  JOIN _TDACustAdd AS K WITH(NOLOCK)
				   ON K.CompanySeq	= A.CompanySeq
				  AND K.CustSeq		= A.CustSeq
		   LEFT  JOIN mnpt_TPJTLinkInvoiceItem AS L WITH(NOLOCK)
				   ON L.CompanySeq	= B.CompanySeq
				  AND L.InvoiceSeq	= B.InvoiceSeq
				  AND L.InvoiceSerl	= B.InvoiceSerl
		   LEFT  JOIN mnpt_TPJTShipDetail AS M WITH(NOLOCK)
				   ON M.CompanySeq	= L.CompanySeq
				  AND M.ShipSeq		= L.ShipSeq
				  AND M.ShipSerl	= L.ShipSerl
		   LEFT  JOIN mnpt_TPJTShipMaster AS N WITH(NOLOCK)
				   ON N.CompanySeq	= M.CompanySeq
				  AND N.ShipSeq		= M.ShipSeq
		   LEFT  JOIN _TDAItem O WITH(NOLOCK)
				   ON O.CompanySeq	= B.CompanySeq
				  AND O.ItemSeq		= B.ItemSeq
		   LEFT  JOIN mnpt_TSLInvoiceItem AS P WITH(NOLOCK)
				   ON P.CompanySeq	= B.CompanySeq
				  AND P.InvoiceSeq	= B.InvoiceSeq
				  AND P.InvoiceSerl	= B.InvoiceSerl
		   LEFT  JOIN _TDAUnit AS Q WITH(NOLOCK)
				   ON Q.CompanySeq	= B.CompanySeq
				  AND Q.UnitSeq		= B.UnitSeq
		   LEFT  JOIN _TDAUnit AS R WITH(NOLOCK)
				   ON R.CompanySeq	= P.CompanySeq
				  AND R.UnitSeq		= P.UnitSeq2
		   LEFT  JOIN _TDACurr AS S WITH(NOLOCK)
				   ON S.CompanySeq	= A.CompanySeq
				  AND S.CurrSeq		= A.CurrSeq
	 WHERE A.CompanySeq	= @CompanySeq
	   AND A.InvoiceSeq	= @InvoiceSeq
