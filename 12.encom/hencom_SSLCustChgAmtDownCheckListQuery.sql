IF OBJECT_ID('hencom_SSLCustChgAmtDownCheckListQuery') IS NOT NULL 
    DROP PROC hencom_SSLCustChgAmtDownCheckListQuery
GO 

-- v2017.06.28
/************************************************************
 설  명 - 데이터-송장규격대체비교현황_hencom : 조회
 작성일 - 20170228
 작성자 - free박수영
************************************************************/
CREATE PROC dbo.hencom_SSLCustChgAmtDownCheckListQuery                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @docHandle      INT,
		    @DeptSeq		INT ,
            @DateFr			NCHAR(8) ,
            @DateTo			NCHAR(8) ,
            @DeptName		NVARCHAR(100)  ,
			@IsCust			NCHAR(1) ,
			@IsPJT			NCHAR(1) ,
			@IsItem			NCHAR(1) ,
			@IsDate			NCHAR(1) ,
			@IsQty			NCHAR(1) ,
			@IsAmt			NCHAR(1) ,
			@IsPrice		NCHAR(1),
			@IsChange		NCHAR(1) ,
			@CustName		NVARCHAR(100),
			@PJTName	    NVARCHAR(100),
			@GoodItemName	NVARCHAR(100),
			@IsPreSales		NCHAR(1)
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq     = DeptSeq      ,
            @DateFr      = DateFr       ,
            @DateTo      = DateTo       ,
            @DeptName    = DeptName     ,
			@IsCust		 = IsCust		,
			@IsPJT		 = IsPJT		,
			@IsItem		 = IsItem		,
			@IsDate		 = [IsDate]		,
			@IsQty		 = IsQty		,
			@IsAmt		 = IsAmt		,
			@IsPrice	 = IsPrice		,
			@CustName	 = CustName		,
			@PJTName		 = PJTName		,
			@GoodItemName	 = GoodItemName ,
			@IsPreSales		= IsPreSales
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (DeptSeq     INT ,
            DateFr      NCHAR(8) ,
            DateTo      NCHAR(8) ,
            DeptName    NVARCHAR(100) ,
			IsCust		NCHAR(1) ,
			IsPJT		NCHAR(1) ,
			IsItem		NCHAR(1) ,
			[IsDate]	NCHAR(1) ,
			IsQty		NCHAR(1) ,
			IsAmt		NCHAR(1) ,
			IsPrice		NCHAR(1) ,
			CustName		NVARCHAR(100),
			PJTName		NVARCHAR(100),
			GoodItemName		NVARCHAR(100),
			IsPreSales		NCHAR(1) )
    

    CREATE TABLE #ReplaceRegSeq ( ReplaceRegSeq INT ) 

    IF @IsCust = 1 
    BEGIN 
        SELECT DISTINCT B.ReplaceRegseq, REPLACE(C.BizNo,'-','') AS BizNo
          INTO #CustBefore
          FROM hencom_TIFProdWorkReportCloseSum AS A 
          JOIN hencom_TSLCloseSumReplaceMapping AS B ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey ) 
          LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WorkDate BETWEEN @DateFr AND @DateTo
           AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
           AND B.IsReplace = '1'

        SELECT DISTINCT A.ReplaceRegseq, REPLACE(C.BizNo,'-','') AS BizNo
          INTO #CustAfter
          FROM hencom_TSLInvoiceReplaceItem AS A 
          JOIN #CustBefore                      AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
          LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
    
        INSERT INTO #ReplaceRegSeq ( ReplaceRegSeq ) 
        SELECT DISTINCT A.ReplaceRegSeq 
          FROM #CustBefore AS A 
          JOIN #CustAfter AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
         WHERE A.BizNo <> B.BizNo 
    END 
    
    IF @IsAmt = 1 
    BEGIN 
        SELECT B.ReplaceRegseq, B.SumMesKey, MAX(A.CurAmt) AS CurAmt 
          INTO #AmtBefore_Sub
          FROM hencom_TIFProdWorkReportCloseSum AS A 
          JOIN hencom_TSLCloseSumReplaceMapping AS B ON ( B.CompanySeq = @CompanySeq aND B.SumMesKey = A.SumMesKey ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WorkDate BETWEEN @DateFr AND @DateTo
           AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
           AND B.IsReplace = '1'
         GROUP BY B.ReplaceRegSeq, B.SumMesKey

        SELECT A.ReplaceRegseq, SUM(A.CurAmt) AS CurAmt 
          INTO #AmtBefore
          FROM #AmtBefore_Sub AS A 
         GROUP BY ReplaceRegSeq 

        SELECT A.ReplaceRegSeq, SUM(A.CurAmt) AS CurAmt
          INTO #AmtAfter
          FROM hencom_TSLInvoiceReplaceItem AS A 
          JOIN #AmtBefore                     AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
         GROUP BY A.ReplaceRegSeq 

    


        INSERT INTO #ReplaceRegSeq ( ReplaceRegSeq ) 
        SELECT DISTINCT A.ReplaceRegSeq 
          FROM #AmtBefore AS A 
          JOIN #AmtAfter AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
         WHERE A.CurAmt > B.CurAmt 
    END 
    
    
	SELECT R.SumMesKey  ,
           R.DeptSeq,
           (select DeptName FROM _TDADept  WHERE CompanySeq = @CompanySeq AND DeptSeq = R.DeptSeq ) AS DeptName ,
           R.WorkDate,
           R.PJTSeq,
           P.PJTName AS PJTName ,
           R.CustSeq,
           C.CustName AS CustName ,
           C.BizNo AS BizNo, 
           R.GoodItemSeq,
           I.ItemName AS GoodItemName,
           R.OutQty ,
           R.Price,
           R.CurAmt ,
           R.CurVAT ,
           M.ReplaceRegSeq ,
           M.ReplaceRegSerl,
           ----------
           A.SumMesKey AS Re_SumMesKey,
           M.InvoiceDate AS Re_InvoiceDate,
           M.PJTSeq AS Re_PJTSeq,
           (select PJTName FROM _TPJTProject  WHERE CompanySeq = @CompanySeq AND PJTSeq = M.PJTSeq ) AS Re_PJTName,
           M.CustSeq AS Re_CustSeq, 
           (select CustName FROM _TDACust  WHERE CompanySeq = @CompanySeq AND CustSeq = M.CustSeq ) AS Re_CustName,
           (select BizNo FROM _TDACust  WHERE CompanySeq = @CompanySeq AND CustSeq = M.CustSeq ) AS Re_BizNo,
           M.ItemSeq AS Re_ItemSeq,
           (select ItemName FROM _TDAItem  WHERE CompanySeq = @CompanySeq AND ItemSeq = M.ItemSeq ) AS Re_ItemName,
           M.Qty AS Re_Qty,
           M.Price AS Re_Price,
           M.CurAmt AS Re_CurAmt, 
           M.CurVAT AS Re_CurVAT,
           M.IsPreSales,
           CASE WHEN M.CustSeq <> R.CustSeq THEN 1 ELSE 0 END AS IsCust ,
           CASE WHEN M.PJTSeq <> R.PJTSeq THEN 1 ELSE 0 END AS IsPJT ,
           CASE WHEN M.ItemSeq <> R.GoodItemSeq THEN 1 ELSE 0 END AS IsItem ,
           CASE WHEN M.InvoiceDate <> R.WorkDate THEN 1 ELSE 0 END AS [IsDate] ,
           CASE WHEN M.Qty <> R.OutQty THEN 1 ELSE 0 END AS IsQty ,
           CASE WHEN M.CurAmt <> R.CurAmt THEN 1 ELSE 0 END AS IsAmt ,
           CASE WHEN M.Price <> R.Price THEN 1 ELSE 0 END AS IsPrice
      FROM hencom_TSLInvoiceReplaceItem     AS M 
      JOIN #ReplaceRegSeq                   AS Z ON ( Z.ReplaceRegSeq = M.ReplaceRegSeq ) 
	  JOIN hencom_TSLCloseSumReplaceMapping AS A ON A.CompanySeq = M.CompanySeq 
											    AND A.ReplaceRegSeq = M.ReplaceRegSeq 
											    AND A.ReplaceRegSerl = M.ReplaceRegSerl
      JOIN hencom_TIFProdWorkReportCloseSum AS R ON R.CompanySeq = A.CompanySeq 
											    AND R.SumMesKey = A.SumMesKey 
      LEFT OUTER JOIN _TPJTProject          AS P ON P.CompanySeq = @CompanySeq AND P.PJTSeq = R.PJTSeq
      LEFT OUTER JOIN _TDACust              AS C ON C.CompanySeq = @CompanySeq AND C.CustSeq = R.CustSeq
      LEFT OUTER JOIN _TDAItem              AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = R.GoodItemSeq
     WHERE M.CompanySeq = @CompanySeq
       AND A.IsReplace = '1' 
     ORDER BY R.DeptSeq,M.ReplaceRegSeq ,M.ReplaceRegSerl,R.SumMesKey,A.SumMesKey

RETURN

go 
begin tran 
exec hencom_SSLCustChgAmtDownCheckListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsPreSales>0</IsPreSales>
    <DateFr>20160101</DateFr>
    <DateTo>20170630</DateTo>
    <DeptSeq />
    <DeptName />
    <CustName />
    <GoodItemName />
    <PJTName />
    <IsCust>0</IsCust>
    <IsPJT>0</IsPJT>
    <IsItem>0</IsItem>
    <IsDate>0</IsDate>
    <IsQty>0</IsQty>
    <IsAmt>1</IsAmt>
    <IsPrice>0</IsPrice>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511363,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032938
rollback 