IF OBJECT_ID('KPXCM_SSLInvoiceLocalConvertSave') IS NOT NULL 
    DROP PROC KPXCM_SSLInvoiceLocalConvertSave
GO 

-- v2016.08.01 
  -- Local 전환입력 - 저장 
 /*********************************************************************************************************************    
     화면명 : Local 전환입력저장
     SP Name: _SSLInvoiceLocalConvertSave    
     작성일 : 2010.01 : CREATEd by JMKIM
     수정일 : 2015.06.15 L/C No,비고1,비고2 추가(DummyCol4~6)
			  2015.09.22 Local 추가로 인한 활동센터 세팅 변경
			  2015.09.30 사업부 계산적용 반영
			  2015.10.07 일부 전환(신규생성)시 활동센터 세팅 수정
 ********************************************************************************************************************/    
 CREATE PROC KPXCM_SSLInvoiceLocalConvertSave
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS        
    
     DECLARE @docHandle      INT,    
             @BizUnit        INT,     
             @nPrice         INT,    
             @nQty           INT,
             @nDomAmt        INT,
             @nCurAmt        INT,
             @Count          INT,
             @Seq            INT,
             @InvoiceDate    NCHAR(8),
             @InvoiceSeq     INT,
             @InvoiceNo      NVARCHAR(30),
             @SalesSeq       INT,
             @SalesNo        NVARCHAR(30),
             @IDXSeq         INT,
             @MessageType    INT,
             @Status         INT,
             @Results        NVARCHAR(250),
             @Date           NVARCHAR(8),  
             @MaxNo          NVARCHAR(50),
             @MaxSeq         INT
  
     -- 실적집계
     CREATE TABLE #SSLInvoiceSeq (SumSeq INT)  
      -- 진행            
     CREATE TABLE #SComSourceDailyBatch  
     (
         ToTableName   NVARCHAR(100),
         ToSeq         INT,
         ToSerl        INT,
         ToSubSerl     INT,
         FromTableName NVARCHAR(100),
         FromSeq       INT,
         FromSerl      INT,
         FromSubSerl   INT,
         ToQty         DECIMAL(19,5),
         ToStdQty      DECIMAL(19,5),
         ToAmt         DECIMAL(19,5),
         ToVAT         DECIMAL(19,5),
         FromQty       DECIMAL(19,5),
         FromSTDQty    DECIMAL(19,5),
         FromAmt       DECIMAL(19,5),
         FromVAT       DECIMAL(19,5)
     )
      CREATE TABLE #TSLInvoiceSource
     (
         InvoiceSeq    INT,
         InvoiceSerl   INT,
         FromTableSeq  INT,
         FromSeq       INT,
         FromSerl      INT,
         FromSubSerl   INT,
         FromQty       DECIMAL(19,5),
         FromSTDQty    DECIMAL(19,5),
         FromAmt       DECIMAL(19,5),
         FromVAT       DECIMAL(19,5)
     )
      CREATE TABLE #TSLSalesSource
     (
         InvoiceSeq    INT,
         InvoiceSerl   INT,
         ToTableSeq    INT,
         ToSeq         INT,
         ToSerl        INT,
         ToSubSerl     INT,
         ToQty         DECIMAL(19,5),
         ToSTDQty      DECIMAL(19,5),
         ToAmt         DECIMAL(19,5),
         ToVAT         DECIMAL(19,5)
     )
      CREATE TABLE #TSLInvoiceConvert
     (
         InvoiceSeq  INT,
         InvoiceSerl INT,
         LocalQty    DECIMAL(19,5),
         DummyCol4	 NVARCHAR(100),
         DummyCol5	 NVARCHAR(100),
         DummyCol6	 NVARCHAR(100),
         LocalDeptSeq INT
     )
      CREATE TABLE #TSLInvoiceConvert2
     (
         InvoiceSeq  INT,
         InvoiceSerl INT,
         LocalQty    DECIMAL(19,5),
         DummyCol4	 NVARCHAR(100),
         DummyCol5	 NVARCHAR(100),
         DummyCol6	 NVARCHAR(100),
         LocalDeptSeq INT
     )
      -- 재고반영    
     Create Table #TLGInOutMinusCheck    
     (      
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT  
     )    
   
     CREATE TABLE #TLGInOutMonth          
     (            
         InOut           INT,          
         InOutYM         NCHAR(6),          
         WHSeq           INT,          
         FunctionWHSeq   INT,          
         ItemSeq         INT,          
         UnitSeq         INT,          
         Qty             DECIMAL(19, 5),          
         StdQty          DECIMAL(19, 5),          
         ADD_DEL         INT          
     )                  
      CREATE TABLE #TLGInOutMonthLot      
     (        
         InOut           INT,      
         InOutYM         NCHAR(6),      
         WHSeq           INT,      
         FunctionWHSeq   INT,      
         LotNo           NVARCHAR(30),      
         ItemSeq         INT,      
         UnitSeq         INT,      
         Qty             DECIMAL(19, 5),      
         StdQty          DECIMAL(19, 5),            
         ADD_DEL         INT            
     )      
   
     CREATE TABLE #TLGInOutDailyBatch    
     (    
         InOutType       INT,    
         InOutSeq        INT,  
         MessageType     INT,  
         Result          NVARCHAR(250),  
         Status          INT  
     )    
      DECLARE @TSLInvoice TABLE
     (
         IDXSeq      INT IDENTITY,
         InvoiceSeq  INT,
         BizUnit     INT,
         SMExpKind   INT,
         InvoiceNo   NVARCHAR(30),
         InvoiceDate NCHAR(8),
         UMOutKind   INT,
         DeptSeq     INT,
         EmpSeq      INT,
         CustSeq     INT,
         BKCustSeq   INT,
         AGCustSeq   INT,
         DVPlaceSeq  INT,
         CurrSeq   INT,
         ExRate    DECIMAL(19,5),
         IsOverCredit NCHAR(1),
         IsMinAmt     NCHAR(1),
         IsStockSales NCHAR(1),
         Remark       NVARCHAR(1000),
         Memo         NVARCHAR(1000),
         ArrivalDate  NCHAR(8),
         ArrivalTime  NCHAR(4),
         IsDelvCfm    NCHAR(1),
         DelvCfmEmpSeq INT,
         DelvCfmDate   NCHAR(8),
         IsAuto        NCHAR(1),
         IsSalesWith   NCHAR(1),
         SMSalesCrtKind INT,
         IsPJT         NCHAR(1),
         SMConsignKind INT,
         SourceInvoiceSeq  INT,
         DVPlaceAreaSeq INT,
         AppPriceType	INT,
         TransGubun		INT,
         DummyCol1		INT,
         DummyCol2		INT,
         DummyCol3		INT,
         DummyCol4		NVARCHAR(600),
         DummyCol5		NVARCHAR(600),
         DummyCol6		NVARCHAR(600),
         DummyCol7		DECIMAL(19,5),
         DummyCol8		DECIMAL(19,5),
         DummyCol9		DECIMAL(19,5),
         AssignGubunSeq	INT,
         SLDeptSeq		INT,
         UMOrderKind	INT,
         UMDVConditionSeq INT
     )
      DECLARE @TSLInvoiceItem TABLE
     (
         IDXSerl      INT IDENTITY,
         InvoiceSeq   INT,
         InvoiceSerl  INT,
         ItemSeq      INT,
         UnitSeq      INT,
         ItemPrice    DECIMAL(19,5),
         CustPrice    DECIMAL(19,5),
         Price        DECIMAL(19,5),
         Qty          DECIMAL(19,5),
         IsInclusedVAT NCHAR(1),
         VATRate      DECIMAL(19,5),
         CurAmt       DECIMAL(19,5),
         CurVAT       DECIMAL(19,5),
         DomAmt       DECIMAL(19,5),
         DomVAT       DECIMAL(19,5),
         STDUnitSeq   INT,
         STDQty       DECIMAL(19,5),
         WHSeq        INT,
         Remark       NVARCHAR(500),
         TrustCustSeq INT,
         LotNo        NVARCHAR(30),
         SerialNo     NVARCHAR(30),
         UMEtcOutKind INT,
         PJTSeq       INT,
         WBSSeq       INT,
         SourceOptionSeq INT,
         CCtrSeq INT,
         DVPlaceSeq INT,
         SourceInvoiceSeq  INT,
         SourceInvoiceSerl INT,
         DummyCol4	 NVARCHAR(100),
         DummyCol5	 NVARCHAR(100),
         DummyCol6	 NVARCHAR(100),
         UMUseType	 INT,
         PackingGubun INT
     )
      CREATE TABLE #TSLInvoiceLocal (WorkingTag NCHAR(1) NULL)  
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoiceLocal' 
  
     EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@nQty OUTPUT
     EXEC dbo._SCOMEnv @CompanySeq,10,@UserSeq,@@PROCID,@nPrice OUTPUT
     EXEC dbo._SCOMEnv @CompanySeq,14,@UserSeq,@@PROCID,@nCurAmt OUTPUT
     EXEC dbo._SCOMEnv @CompanySeq,15,@UserSeq,@@PROCID,@nDomAmt OUTPUT
      SELECT InvoiceSeq, SUM(LocalConvertQty) AS LocalQty
       INTO #TSLInvoiceALL
       FROM #TSLInvoiceLocal
      WHERE WorkingTag = 'U' 
        AND Status = 0 
        AND LocalConvertQty = Qty 
        AND LocalConvertQty > 0
      GROUP BY InvoiceSeq
    
    
    SELECT @BizUnit = B.BizUnit 
      FROM #TSLInvoiceLocal AS A 
      JOIN _TSLInvoice      AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
    
    
	DECLARE @IsCalcApply NCHAR(1) -- 150930 사업부단가계산적용
	SELECT @IsCalcApply = CASE WHEN ISNULL(B.ValueText,'0') = '0' THEN '2' ELSE '1' END
      FROM _TDAUMinorValue AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
													   AND B.MinorSeq = A.MinorSeq
													   AND B.Serl = 1000002
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1011495
       AND A.Serl  = 1000001 
       AND A.ValueSeq = @BizUnit
    
	SELECT @IsCalcApply = CASE WHEN ISNULL(@IsCalcApply,'0') = '0' THEN '0' ELSE @IsCalcApply END
  
  
     --***** 매출내역 없고 전량 Local전환
     IF EXISTS (SELECT 1
                  FROM #TSLInvoiceALL AS X
                       JOIN (SELECT A.InvoiceSeq, SUM(B.Qty) AS Qty
                               FROM #TSLInvoiceALL AS A
                                    JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                           AND A.InvoiceSeq = B.InvoiceSeq
                              GROUP BY A.InvoiceSeq) AS Y ON X.InvoiceSeq = Y.InvoiceSeq
                 WHERE X.LocalQty = Y.Qty)
     BEGIN
         INSERT INTO #TSLInvoiceConvert(InvoiceSeq, InvoiceSerl, LocalQty, DummyCol4, DummyCol5, DummyCol6)
         SELECT N.InvoiceSeq, N.InvoiceSerl, N.LocalConvertQty, N.DummyCol4, N.DummyCol5, N.DummyCol6
           FROM #TSLInvoiceLocal AS N
                JOIN (SELECT X.InvoiceSeq
                        FROM #TSLInvoiceALL AS X
                        JOIN (SELECT A.InvoiceSeq, SUM(B.Qty) AS Qty
                                FROM #TSLInvoiceALL AS A
                                     JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                            AND A.InvoiceSeq = B.InvoiceSeq
                               GROUP BY A.InvoiceSeq) AS Y ON X.InvoiceSeq = Y.InvoiceSeq
                       WHERE X.LocalQty = Y.Qty) AS M ON N.InvoiceSeq = M.InvoiceSeq
          WHERE N.WorkingTag = 'U' 
            AND N.Status = 0 
            AND N.LocalConvertQty = Qty 
            AND N.LocalConvertQty > 0
            
                        
         UPDATE #TSLInvoiceConvert
            SET LocalDeptSeq = E.ValueSeq
           FROM #TSLInvoiceConvert AS A
           JOIN KPX_TSLInvoiceAdd AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
												AND B.InvoiceSeq = A.InvoiceSeq
           JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
												 AND C.MajorSeq = 1011628
												 AND C.Serl = 1000002
												 AND C.ValueSeq = 8009002
		   JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
												 AND D.MinorSeq = C.MinorSeq
												 AND D.Serl = 1000001
												 AND D.ValueSeq = B.UMOrderKind
		   JOIN _TDAUMinorValue AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
												 AND E.MinorSeq = D.MinorSeq
												 AND E.Serl = 1000003
												 		
          INSERT INTO #SSLInvoiceSeq(SumSeq)  
         SELECT DISTINCT InvoiceSeq  
           FROM #TSLInvoiceConvert  
                   
         --***** 기존실적삭제
         EXEC _SSLInvoiceSum 'D', @CompanySeq  
          --***** 마스터 수정
         UPDATE _TSLInvoice
            SET SMExpKind = 8009002,
				DeptSeq = CASE WHEN ISNULL(B.LocalDeptSeq,0) = 0 THEN A.DeptSeq ELSE ISNULL(B.LocalDeptSeq,0) END, -- 150922
                LastUserSeq = @UserSeq,
                LastDateTime = GETDATE(), 
                PgmSeq = @PgmSeq                 
           FROM _TSLInvoice          AS A 
           JOIN #TSLInvoiceConvert   AS B ON A.CompanySeq = @CompanySeq
                                            AND A.InvoiceSeq = B.InvoiceSeq

		 --***** 추가테이블(KPX_TSLInvoiceItemAdd)
		 IF EXISTS (SELECT TOP 1 1 FROM KPX_TSLInvoiceItemAdd AS A
								   JOIN #TSLInvoiceConvert   AS B ON A.InvoiceSeq  = B.InvoiceSeq
																 AND A.InvoiceSerl = B.InvoiceSerl 
								  WHERE A.CompanySeq = @CompanySeq)
		 BEGIN
			UPDATE KPX_TSLInvoiceItemAdd
			   SET DummyCol4 = B.DummyCol4,
				   DummyCol5 = B.DummyCol5,
				   DummyCol6 = B.DummyCol6,
				   LocalDate = CONVERT(NCHAR(8),GETDATE(),112),
				   LastUserSeq = @UserSeq,
				   LastDateTime = GETDATE()
			  FROM KPX_TSLInvoiceItemAdd AS A
			  JOIN #TSLInvoiceConvert   AS B ON A.InvoiceSeq  = B.InvoiceSeq
											AND A.InvoiceSerl = B.InvoiceSerl 
			 WHERE A.CompanySeq = @CompanySeq
		 END
		 ELSE
		 BEGIN
			INSERT INTO KPX_TSLInvoiceItemAdd(CompanySeq, InvoiceSeq, InvoiceSerl, DummyCol4, DummyCol5, DummyCol6, LocalDate, LastUserSeq, LastDateTime)
			SELECT @CompanySeq, InvoiceSeq, InvoiceSerl, DummyCol4, DummyCol5, DummyCol6, CONVERT(NCHAR(8),GETDATE(),112), @UserSeq, GETDATE()
			  FROM #TSLInvoiceConvert			
		 END
         
         --***** 품목 수정
         UPDATE _TSLInvoiceItem
            SET VATRate = 0,
                CurVat  = 0,
                DomVat  = 0,
                IsLocal = '1',
                LocalInvoiceSeq  = A.InvoiceSeq,
                LocalInvoiceSerl = A.InvoiceSerl,
                LastUserSeq = @UserSeq,
                LastDateTime = GETDATE(), 
                CurAmt = A.CurAmt + CASE WHEN A.IsInclusedVAT = '1' THEN A.CurVAT ELSE 0 END,
                DomAmt = A.DomAmt + CASE WHEN A.IsInclusedVAT = '1' THEN A.DomVAT ELSE 0 END,
                PgmSeq = @PgmSeq                 
           FROM _TSLInvoiceItem      AS A 
           JOIN #TSLInvoiceConvert   AS B ON A.CompanySeq  = @CompanySeq
                                            AND A.InvoiceSeq  = B.InvoiceSeq
                                            AND A.InvoiceSerl = B.InvoiceSerl
         
         --***** 신규실적INSERT (부가세)
         EXEC _SSLInvoiceSum 'A', @CompanySeq  
         INSERT INTO #TSLInvoiceConvert2
         SELECT * FROM #TSLInvoiceConvert
         DELETE #TSLInvoiceConvert
         DELETE #SSLInvoiceSeq
      END
     
     IF EXISTS (SELECT 1 FROM #TSLInvoiceLocal AS A
                               LEFT OUTER JOIN #TSLInvoiceConvert2 AS B ON A.InvoiceSeq = B.InvoiceSeq 
                                                                      AND B.InvoiceSerl = B.InvoiceSerl
                 WHERE ISNULL(B.InvoiceSeq,0) = 0)
     BEGIN
         INSERT INTO #TSLInvoiceConvert(InvoiceSeq, InvoiceSerl, LocalQty, DummyCol4, DummyCol5, DummyCol6)
         SELECT A.InvoiceSeq, A.InvoiceSerl, A.LocalConvertQty, A.DummyCol4, A.DummyCol5, A.DummyCol6
           FROM #TSLInvoiceLocal AS A
                LEFT OUTER JOIN #TSLInvoiceConvert2 AS B ON A.InvoiceSeq = B.InvoiceSeq 
                                                        AND B.InvoiceSerl = B.InvoiceSerl
          WHERE A.WorkingTag = 'U' 
            AND A.Status = 0 
            AND ISNULL(B.InvoiceSeq,0) = 0
            AND A.LocalConvertQty > 0
            
         UPDATE #TSLInvoiceConvert
            SET LocalDeptSeq = E.ValueSeq
           FROM #TSLInvoiceConvert AS A
           JOIN KPX_TSLInvoiceAdd AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
												AND B.InvoiceSeq = A.InvoiceSeq
           JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
												 AND C.MajorSeq = 1011628
												 AND C.Serl = 1000002
												 AND C.ValueSeq = 8009002
		   JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
												 AND D.MinorSeq = C.MinorSeq
												 AND D.Serl = 1000001
												 AND D.ValueSeq = B.UMOrderKind
		   JOIN _TDAUMinorValue AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
												 AND E.MinorSeq = D.MinorSeq
												 AND E.Serl = 1000003
		 WHERE ISNULL(LocalDeptSeq,0) = 0
  
         INSERT INTO #SSLInvoiceSeq(SumSeq)  
         SELECT DISTINCT InvoiceSeq  
           FROM #TSLInvoiceConvert  
                   
         --***** 기존실적삭제
         EXEC _SSLInvoiceSum 'D', @CompanySeq  
  
         --***** 진행연결(기존진행원천수정)
         -- 진행연결삭제(FromTableSeq => 거래명세서)    
         INSERT INTO #TSLInvoiceSource
         SELECT InvoiceSeq, InvoiceSerl, FromTableSeq, FromSeq, FromSerl, FromSubSerl, FromQty, FromSTDQty, FromAmt, FromVAT
           FROM (SELECT A.InvoiceSeq, A.InvoiceSerl, B.FromTableSeq, B.FromSeq, B.FromSerl, B.FromSubSerl, 
                        B.FromQty, B.FromSTDQty, B.FromAmt, B.FromVAT, 1 AS ADD_DEL  
                   FROM #TSLInvoiceConvert AS A   
                        JOIN _TCOMSource AS B WITH (NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                           AND A.InvoiceSeq   = B.ToSeq  
                                                           AND A.InvoiceSerl  = B.ToSerl  
                                                          AND B.ToTableSeq   = 18 
                 UNION ALL  
                  SELECT A.InvoiceSeq, A.InvoiceSerl, B.FromTableSeq, B.FromSeq, B.FromSerl, B.FromSubSerl, 
                        B.FromQty, B.FromSTDQty, B.FromAmt, B.FromVAT, ADD_DEL  
                   FROM #TSLInvoiceConvert AS A   
                        JOIN _TCOMSourceDaily AS B WITH (NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                                AND A.InvoiceSeq   = B.ToSeq  
                                                                AND A.InvoiceSerl  = B.ToSerl  
                                                                AND B.ToTableSeq   = 18 ) X  
          GROUP BY InvoiceSeq, InvoiceSerl, FromTableSeq, FromSeq, FromSerl, FromSubSerl, FromQty, FromSTDQty, FromAmt, FromVAT
          HAVING SUM(ADD_DEL) = 1
  
         DELETE FROM  #SComSourceDailyBatch      
          INSERT INTO #SComSourceDailyBatch    
         SELECT '_TSLInvoiceItem', A.InvoiceSeq, A.InvoiceSerl, 0,     
                C.ProgTableName, A.FromSeq, A.FromSerl, A.FromSubSerl,    
                B.Qty, B.STDQty, B.CurAmt, B.CurVAT,    
                A.FromQty, A.FromSTDQty, A.FromAmt,   A.FromVAT    
           FROM #TSLInvoiceSource AS A    
                JOIN _TSLInvoiceItem AS B ON B.CompanySeq = @CompanySeq
                                         AND A.InvoiceSeq = B.InvoiceSeq
                                         AND A.InvoiceSerl = B.InvoiceSerl
                JOIN _TCOMProgTable AS C ON A.FromTableSeq = C.ProgTableSeq    
          EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq    
  
         --***** 진행연결(기존진행수정) -- 매출발생건
         -- 진행연결삭제(거래명세서 => 매출)    
         INSERT INTO #TSLSalesSource
         SELECT InvoiceSeq, InvoiceSerl, ToTableSeq, ToSeq, ToSerl, ToSubSerl, ToQty, ToSTDQty, ToAmt, ToVAT
           FROM (SELECT A.InvoiceSeq, A.InvoiceSerl, B.ToTableSeq, B.ToSeq, B.ToSerl, B.ToSubSerl, 
                        B.ToQty, B.ToSTDQty, B.ToAmt, B.ToVAT, 1 AS ADD_DEL  
                   FROM #TSLInvoiceConvert AS A   
                        JOIN #TSLInvoiceLocal AS C ON A.InvoiceSeq  = C.InvoiceSeq
                                                  AND A.InvoiceSerl = C.InvoiceSerl
                        JOIN _TCOMSource AS B WITH (NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                           AND A.InvoiceSeq   = B.FromSeq  
                                                           AND A.InvoiceSerl  = B.FromSerl  
                                                           AND B.FromTableSeq = 18 
                                                           AND B.ToTableSeq   = 20
                  WHERE C.SalesQty <> 0
                 UNION ALL  
                  SELECT A.InvoiceSeq, A.InvoiceSerl, B.ToTableSeq, B.ToSeq, B.ToSerl, B.ToSubSerl, 
                        B.ToQty, B.ToSTDQty, B.ToAmt, B.ToVAT, ADD_DEL  
                   FROM #TSLInvoiceConvert AS A   
                        JOIN #TSLInvoiceLocal AS C ON A.InvoiceSeq  = C.InvoiceSeq
                                                  AND A.InvoiceSerl = C.InvoiceSerl
                        JOIN _TCOMSourceDaily AS B WITH (NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                                AND A.InvoiceSeq   = B.FromSeq  
                                                                AND A.InvoiceSerl  = B.FromSerl 
                                                                AND B.FromTableSeq = 18 
                                                                AND B.ToTableSeq   = 20
                  WHERE C.SalesQty <> 0 ) X  
          GROUP BY InvoiceSeq, InvoiceSerl, ToTableSeq, ToSeq, ToSerl, ToSubSerl, ToQty, ToSTDQty, ToAmt, ToVAT
          HAVING SUM(ADD_DEL) = 1
          DELETE FROM  #SComSourceDailyBatch      
          INSERT INTO #SComSourceDailyBatch    
         SELECT '_TSLSalesItem', A.ToSeq, A.ToSerl, 0,     
                '_TSLInvoiceItem', B.InvoiceSeq, B.InvoiceSerl, 0,    
                A.ToQty, A.ToSTDQty, A.ToAmt, A.ToVAT,    
                B.Qty, B.STDQty, B.CurAmt, B.CurVAT
           FROM #TSLSalesSource AS A    
                JOIN _TSLInvoiceItem AS B ON B.CompanySeq = @CompanySeq
                                         AND A.InvoiceSeq = B.InvoiceSeq
                                         AND A.InvoiceSerl = B.InvoiceSerl
          EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq    
  
          --***** 거래명세서 신규
         INSERT INTO @TSLInvoice(InvoiceSeq, BizUnit, SMExpKind, InvoiceNo, InvoiceDate, UMOutKind, DeptSeq, EmpSeq, 
                                 CustSeq, BKCustSeq, AGCustSeq, DVPlaceSeq, CurrSeq, ExRate, IsOverCredit, IsMinAmt, IsStockSales, 
                                 Remark, Memo, ArrivalDate, ArrivalTime, IsDelvCfm, DelvCfmEmpSeq, DelvCfmDate, IsAuto, IsSalesWith, 
                                 SMSalesCrtKind, IsPJT, SMConsignKind, SourceInvoiceSeq,DVPlaceAreaSeq ,AppPriceType,TransGubun,
                                 DummyCol1		,DummyCol2		,DummyCol3		,DummyCol4		,DummyCol5		,DummyCol6		,
                                 DummyCol7		,DummyCol8		,DummyCol9		,AssignGubunSeq	,SLDeptSeq		,UMOrderKind	,UMDVConditionSeq)
         SELECT DISTINCT 0, ISNULL(B.BizUnit,0), 8009002, '', ISNULL(B.InvoiceDate,''), ISNULL(B.UMOutKind,0), 
						 CASE WHEN ISNULL(A.LocalDeptSeq,0) = 0 THEN ISNULL(B.DeptSeq,0) ELSE ISNULL(A.LocalDeptSeq,0) END, ISNULL(B.EmpSeq,0), 
                         ISNULL(B.CustSeq,0), ISNULL(B.BKCustSeq,0), ISNULL(B.AGCustSeq, 0), ISNULL(B.DVPlaceSeq,0), 
                         ISNULL(B.CurrSeq,0), ISNULL(B.ExRate,0), ISNULL(B.IsOverCredit,'0'), ISNULL(B.IsMinAmt,'0'), ISNULL(B.IsStockSales,'0'),
                         ISNULL(B.Remark,''), ISNULL(B.Memo,''), ISNULL(B.ArrivalDate,''), ISNULL(B.ArrivalTime,''), 
                         ISNULL(B.IsDelvCfm,''), ISNULL(B.DelvCfmEmpSeq,0), ISNULL(B.DelvCfmDate,0), ISNULL(B.IsAuto,'0'), '', 
                         ISNULL(B.SMSalesCrtKind,0), ISNULL(B.IsPJT,''), ISNULL(B.SMConsignKind,0), ISNULL(A.InvoiceSeq, 0), 
                         C.DVPlaceAreaSeq, C.AppPriceType, C.TransGubun,
                         C.DummyCol1, C.DummyCol2, C.DummyCol3, C.DummyCol4, C.DummyCol5, C.DummyCol6,
                         C.DummyCol7, C.DummyCol8, C.DummyCol9, C.AssignGubunSeq, C.SLDeptSeq, C.UMOrderKind, B.UMDVConditionSeq
           FROM #TSLInvoiceConvert AS A
                JOIN _TSLInvoice AS B ON B.CompanySeq = @CompanySeq
                                     AND A.InvoiceSeq = B.InvoiceSeq
                LEFT OUTER JOIN KPX_TSLInvoiceAdd AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
																   AND C.InvoiceSeq = A.InvoiceSeq
          SELECT   @IDXSeq = 0
          WHILE ( 1 = 1 )
         BEGIN
             SELECT TOP 1 @IDXSeq = IDXSeq, @InvoiceDate = InvoiceDate
               FROM @TSLInvoice
              WHERE IDXSeq > @IDXSeq
              ORDER BY IDXSeq
         
             IF @@ROWCOUNT = 0 BREAK
              -- InvoiceNo 생성
             EXEC _SCOMCreateNo 'SL', '_TSLInvoice', @CompanySeq, '', @InvoiceDate, @InvoiceNo OUTPUT
              -- InvoiceSeq 생성
             EXEC @InvoiceSeq = _SCOMCreateSeq @CompanySeq, '_TSLInvoice', 'InvoiceSeq', 1 
              IF EXISTS (SELECT 1 FROM _TSLInvoice WHERE CompanySeq = @CompanySeq AND InvoiceSeq = @InvoiceSeq)
             BEGIN
                 SELECT @MaxSeq = MAX(InvoiceSeq) 
                   FROM _TSLInvoice 
                  WHERE CompanySeq = @CompanySeq
                  UPDATE _TCOMCreateSeqMax 
                    SET MaxSeq = @MaxSeq + 1
                  WHERE CompanySeq = @CompanySeq 
                    AND TableName = '_TSLInvoice'
             
                 -- InvoiceSeq 생성
                 EXEC @InvoiceSeq = _SCOMCreateSeq @CompanySeq, '_TSLInvoice', 'InvoiceSeq', 1 
             END
              UPDATE @TSLInvoice
                SET InvoiceSeq = @InvoiceSeq, 
                    InvoiceNo = @InvoiceNo
              WHERE IDXSeq = @IDXSeq
         END
         
         INSERT INTO @TSLInvoiceItem
         (
             InvoiceSeq,InvoiceSerl,ItemSeq,UnitSeq,ItemPrice,CustPrice,Price,
             Qty,IsInclusedVAT,VATRate,CurAmt,CurVAT,
             DomAmt,DomVAT,STDUnitSeq,STDQty,WHSeq,Remark,
             TrustCustSeq,LotNo,SerialNo,UMEtcOutKind, PJTSeq, WBSSeq,
             SourceOptionSeq, CCtrSeq, DVPlaceSeq, SourceInvoiceSeq, SourceInvoiceSerl,
             DummyCol4, DummyCol5, DummyCol6, UMUseType, PackingGubun
         )
         SELECT ISNULL(B.InvoiceSeq,0), 0, ISNULL(C.ItemSeq,0), ISNULL(C.UnitSeq,0), ISNULL(C.ItemPrice,0), ISNULL(C.CustPrice,0), 
                --ISNULL(C.Price, (CASE WHEN ISNULL(C.Qty,0) = 0 THEN 0 ELSE (CASE WHEN C.IsInclusedVAT = '1' 
                --                                                                 THEN ROUND((ISNULL(C.CurAmt,0) + ISNULL(C.CurVat,0)) / ISNULL(C.Qty,0), @nPrice)  
                --                                    ELSE ROUND(ISNULL(C.CurAmt,0) / ISNULL(C.Qty,0), @nPrice) 
                --                                                                 END) 
                --                      END)
                --) AS Price, -- 150930
                ISNULL(C.Price, (CASE WHEN @IsCalcApply = '1' 
									  THEN (CASE WHEN ISNULL(C.Qty,0) = 0 THEN 0 
												 ELSE (CASE WHEN C.IsInclusedVAT = '1' 
                                                            THEN ROUND((ISNULL(C.CurAmt,0) + ISNULL(C.CurVat,0)) / ISNULL(C.Qty,0), @nPrice)  
															ELSE ROUND(ISNULL(C.CurAmt,0) / ISNULL(C.Qty,0), @nPrice) 
                                                       END) 
                                            END) 
                                      ELSE (CASE WHEN C.IsInclusedVAT = '1' 
                                                 THEN ROUND((ISNULL(C.CurAmt,0) + ISNULL(C.CurVat,0)) / ISNULL(C.StdQty,0), @nPrice)  
                                                 ELSE ROUND(ISNULL(C.CurAmt,0) / ISNULL(C.StdQty,0), @nPrice) 
                                            END) 
                                      END)) AS Price, -- 150930
                ISNULL(A.LocalQty,0), ISNULL(C.IsInclusedVAT,'0'), 0, ISNULL(C.CurAmt,0), 0, 
                ISNULL(C.DomAmt,0), 0, ISNULL(C.STDUnitSeq,0), 
                ISNULL(A.LocalQty,0),  -- 이후 업데이트
                ISNULL(C.WHSeq,0), ISNULL(C.Remark,''), 
                ISNULL(C.TrustCustSeq,0), ISNULL(C.LotNo,''), ISNULL(C.SerialNo,''), ISNULL(C.UMEtcOutKind,0), ISNULL(C.PJTSeq,0), ISNULL(C.WBSSeq,0),
                ISNULL(C.SourceOptionSeq,0), ISNULL(C.CCtrSeq,0),ISNULL(C.DVPlaceSeq,0), ISNULL(A.InvoiceSeq,0),ISNULL(A.InvoiceSerl,0),
                A.DummyCol4, A.DummyCol5, A.DummyCol6, D.UMUseType, D.PackingGubun
           FROM #TSLInvoiceConvert   AS A
           JOIN @TSLInvoice          AS B ON A.InvoiceSeq = B.SourceInvoiceSeq
           JOIN _TSLInvoiceItem      AS C ON C.CompanySeq  = @CompanySeq
                                         AND A.InvoiceSeq  = C.InvoiceSeq
                                         AND A.InvoiceSerl = C.InvoiceSerl
           LEFT OUTER JOIN KPX_TSLInvoiceItemAdd AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
																  AND D.InvoiceSeq = C.InvoiceSeq
																  AND D.InvoiceSerl = C.InvoiceSerl
          ORDER BY B.InvoiceSeq
         
         UPDATE @TSLInvoiceItem
            SET InvoiceSerl = A.IDXSerl - B.Serl + 1
           FROM @TSLInvoiceItem AS A
                JOIN (SELECT InvoiceSeq, MIN(IDXSerl) AS Serl
                        FROM @TSLInvoiceItem
                       GROUP BY InvoiceSeq) AS B ON A.InvoiceSeq = B.InvoiceSeq
         
         -- 중량생성
         UPDATE @TSLInvoiceItem
            SET --CurAmt = ROUND(A.Qty * A.Price, @nCurAmt),
                --DomAmt = ROUND(ROUND(A.Qty * A.Price, @nCurAmt) * B.ExRate, @nDomAmt),
                STDQty = CASE WHEN ISNULL(C.ConvDen,0) = 0 THEN 0 ELSE ROUND(ISNULL(A.Qty,0) * (ISNULL(C.ConvNum,0)/ISNULL(C.ConvDen,0)),@nQty) END
           FROM @TSLInvoiceItem AS A 
                JOIN @TSLInvoice AS B ON A.InvoiceSeq = B.InvoiceSeq
                LEFT OUTER JOIN _TDAItemUnit AS C ON C.CompanySeq = @CompanySeq
                                                 AND A.ItemSeq    = C.ItemSeq
                                                 AND A.UnitSeq    = C.UnitSeq
  
         UPDATE @TSLInvoiceItem
            SET CurAmt = (CASE WHEN @IsCalcApply = '1' 
							   THEN ROUND(A.Qty * A.Price, @nCurAmt)
							   ELSE ROUND(A.STDQty * A.Price, @nCurAmt) END),
                DomAmt = (CASE WHEN @IsCalcApply = '1' 
							   THEN ROUND(ROUND(A.Qty * A.Price, @nCurAmt) * B.ExRate, @nDomAmt)
							   ELSE ROUND(ROUND(A.STDQty * A.Price, @nCurAmt) * B.ExRate, @nDomAmt)
							   END)							   
           FROM @TSLInvoiceItem AS A 
                JOIN @TSLInvoice AS B ON A.InvoiceSeq = B.InvoiceSeq
  
         -- MASTER INSERT(거래명세서)
         INSERT INTO _TSLInvoice
         (
             CompanySeq, InvoiceSeq, BizUnit, SMExpKind, InvoiceNo,
             InvoiceDate, UMOutKind, DeptSeq, EmpSeq, CustSeq,
             BKCustSeq, AGCustSeq, DVPlaceSeq, CurrSeq, ExRate,
             IsOverCredit, IsMinAmt, IsStockSales, Remark, Memo,
             ArrivalDate, ArrivalTime, IsDelvCfm, DelvCfmEmpSeq, DelvCfmDate,
             IsAuto, SMSalesCrtKind, LastUserSeq, LastDateTime, IsPJT, BillSeq, SMConsignKind,
             PgmSeq, UMDVConditionSeq
         )
         SELECT @CompanySeq, InvoiceSeq, BizUnit, SMExpKind, InvoiceNo,
                InvoiceDate, UMOutKind, DeptSeq, EmpSeq, CustSeq,
                BKCustSeq, AGCustSeq, DVPlaceSeq, CurrSeq, ExRate,
                IsOverCredit, IsMinAmt, IsStockSales, Remark, Memo,
                ArrivalDate, ArrivalTime, IsDelvCfm, DelvCfmEmpSeq, DelvCfmDate,
                IsAuto, SMSalesCrtKind, @UserSeq,   GETDATE(), IsPJT, 0, SMConsignKind,
                @PgmSeq, UMDVConditionSeq
           FROM @TSLInvoice
         
         IF @@ERROR <> 0    
         BEGIN
             RETURN    
         END  
         
          -- 품목 INSERT(거래명세서)
         INSERT INTO _TSLInvoiceItem 
         (
             CompanySeq,  InvoiceSeq,   InvoiceSerl,  ItemSeq,        UnitSeq,   
             ItemPrice,   CustPrice,  Qty,            IsInclusedVAT,  VATRate,   
             CurAmt,      CurVAT,     DomAmt,      DomVAT,         STDUnitSeq, 
             STDQty,      WHSeq,      Remark,         UMEtcOutKind,   TrustCustSeq,
             LotNo,       SerialNo,   PJTSeq,         WBSSeq, 
             SourceOptionSeq, CCtrSeq, DVPlaceSeq,    LastUserSeq,    LastDateTime, IsLocal, LocalInvoiceSeq, LocalInvoiceSerl,
             Price, PgmSeq
         )      
         SELECT  @CompanySeq, InvoiceSeq, InvoiceSerl,    ItemSeq,        UnitSeq,
                ItemPrice,   CustPrice,  Qty,            IsInclusedVAT,  VATRate,   
                CurAmt,      CurVAT,     DomAmt,         DomVAT,         STDUnitSeq, 
                STDQty,      WHSeq,      Remark,         UMEtcOutKind,   TrustCustSeq,
                LotNo,       SerialNo,   PJTSeq,         WBSSeq, 
                SourceOptionSeq, CCtrSeq, DVPlaceSeq,    @UserSeq,       GETDATE(), '1', SourceInvoiceSeq, SourceInvoiceSerl,
                Price, @PgmSeq 
           FROM @TSLInvoiceItem    
         
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END
         
		 -- 마스터추가정보(KPX_TSLInvoiceAdd)
			INSERT INTO KPX_TSLInvoiceAdd(CompanySeq, InvoiceSeq, DVPlaceAreaSeq, AppPriceType, TransGubun, DummyCol1, DummyCol2, DummyCol3, 
										  DummyCol4, DummyCol5, DummyCol6, DummyCol7, DummyCol8, DummyCol9, LastUserSeq, LastDateTime, AssignGubunSeq,
										  SLDeptSeq, UMOrderKind)
			SELECT @CompanySeq, InvoiceSeq, DVPlaceAreaSeq, AppPriceType, TransGubun, DummyCol1, DummyCol2, DummyCol3, 
				   DummyCol4, DummyCol5, DummyCol6, DummyCol7, DummyCol8, DummyCol9, @UserSeq, GETDATE(), AssignGubunSeq,
				   SLDeptSeq, UMOrderKind
			  FROM @TSLInvoice	   
         
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END
         
		 -- 품목추가정보(KPX_TSLInvoiceItemAdd)
			INSERT INTO KPX_TSLInvoiceItemAdd(CompanySeq, InvoiceSeq, InvoiceSerl, UMUseType, PackingGubun, DummyCol4, DummyCol5, DummyCol6, LocalDate, LastUserSeq, LastDateTime)
			SELECT @CompanySeq, InvoiceSeq, InvoiceSerl, UMUseType, PackingGubun, DummyCol4, DummyCol5, DummyCol6, CONVERT(NCHAR(8),GETDATE(),112), @UserSeq, GETDATE()
			  FROM @TSLInvoiceItem	   
         
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END
         
          --***** 거래명세서 기존수정
         IF EXISTS (SELECT 1 FROM @TSLInvoice WHERE IsDelvCfm = '1')
         BEGIN
             -- 재고반영    
             DELETE FROM #TLGInOutDailyBatch    
         
             INSERT INTO #TLGInOutDailyBatch    
             SELECT 10, SourceInvoiceSeq, 0,'',0  
               FROM @TSLInvoice    
              WHERE IsDelvCfm = '1'
              -- 거래명세서 출고삭제    
             EXEC _SLGInOutDailyDELETE @CompanySeq        
         END
          /**** 자국통화와 거래명세서 통화가 같으면 CurAmt, VAT는 Dom과 동일하게 세팅 :: 20130705 박성호 ****/
          DECLARE @CurrSeq INT
          EXEC dbo._SCOMEnv @CompanySeq, 13, @UserSeq, @@PROCID, @CurrSeq OUTPUT
         
          -- Price(NULL) 보정    
         SELECT A.InvoiceSeq, A.InvoiceSerl, 
				ISNULL(A.Price, (CASE WHEN @IsCalcApply = '1' 
									  THEN (CASE ISNULL(A.Qty, 0) WHEN 0
                                                       THEN 0
                                                       ELSE (CASE A.IsInclusedVAT WHEN '1'
                                                                                  THEN ROUND((ISNULL(A.CurAmt, 0) + ISNULL(A.CurVat, 0)) / ISNULL(A.Qty, 0), @nPrice) 
                                                                                  ELSE ROUND (ISNULL(A.CurAmt, 0) / ISNULL(A.Qty, 0), @nPrice) 
                                                                                  END) 
                                                       END)
                                      ELSE (CASE ISNULL(A.STDQty, 0) WHEN 0
                                                       THEN 0
                                                       ELSE (CASE A.IsInclusedVAT WHEN '1'
                                                                                  THEN ROUND((ISNULL(A.CurAmt, 0) + ISNULL(A.CurVat, 0)) / ISNULL(A.STDQty, 0), @nPrice) 
                                                                                  ELSE ROUND (ISNULL(A.CurAmt, 0) / ISNULL(A.STDQty, 0), @nPrice) 
                                                                                  END) 
                                                       END)
                                      END
                                )) AS Price
           INTO #TSLInvItemPrice
           FROM _TSLInvoiceItem      AS A
                JOIN @TSLInvoiceItem AS B ON A.InvoiceSeq  = B.SourceInvoiceSeq
                                         AND A.InvoiceSerl = B.SourceInvoiceSerl
          WHERE A.CompanySeq = @CompanySeq
         
          -- 자국통화일 때에는 원화와 외화의 계산 로직이 같음
             UPDATE _TSLInvoiceItem
                SET CurVAT = CASE WHEN @IsCalcApply = '1' 
								  THEN (ROUND((CASE WHEN A.IsInclusedVAT = '1' 
												    THEN ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                    ELSE ROUND(( ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                    END), @nDomAmt))
                                  ELSE (ROUND((CASE WHEN A.IsInclusedVAT = '1' 
												    THEN ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                    ELSE ROUND(( ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                    END), @nDomAmt))
                                  END,
                    DomVAT =  CASE WHEN @IsCalcApply = '1' 
								   THEN (ROUND((CASE WHEN A.IsInclusedVAT = '1' THEN ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                     ELSE ROUND(( ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                     END), @nDomAmt))
								   ELSE (ROUND((CASE WHEN A.IsInclusedVAT = '1' THEN ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                     ELSE ROUND(( ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                     END), @nDomAmt))
								   END,
                    CurAmt = CASE WHEN @IsCalcApply = '1' 
								   THEN (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price - ROUND(ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt), @nDomAmt)
                                                                    ELSE (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * D.Price END)
                                   ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price - ROUND(ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt), @nDomAmt)
                                                                    ELSE (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * D.Price END)
                                   END,
                    DomAmt = CASE WHEN @IsCalcApply = '1' 
								  THEN (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price - ROUND(ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt), @nDomAmt)
                                                                    ELSE (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * D.Price END)
                                  ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price - ROUND(ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt), @nDomAmt)
                                                                    ELSE (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * D.Price END)
                                  END,                    
                    Qty          = ISNULL(A.Qty   , 0) - ISNULL(B.Qty   , 0),
                    STDQty       = ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0),
                    LastUserSeq  = @UserSeq ,
                    LastDateTime = GETDATE(),
                    PgmSeq       = @PgmSeq    
                FROM _TSLInvoiceItem      AS A 
                    JOIN @TSLInvoiceItem AS B ON A.CompanySeq  = @CompanySeq
                                             AND A.InvoiceSeq  = B.SourceInvoiceSeq
                                             AND A.InvoiceSerl = B.SourceInvoiceSerl
                    JOIN @TSLInvoice     AS C ON B.InvoiceSeq  = C.InvoiceSeq
                    JOIN #TSLInvItemPrice AS D ON D.InvoiceSeq  = A.InvoiceSeq
                                              AND D.InvoiceSerl = A.InvoiceSerl
              WHERE C.CurrSeq = @CurrSeq
              
         -- 자국통화가 아닐 경우에는 환율과 자리수를 고려하여 로직이 구성됨
              UPDATE _TSLInvoiceItem
                SET CurVAT = CASE WHEN @IsCalcApply = '1' 
								  THEN (ROUND((CASE WHEN A.IsInclusedVAT = '1' 
													THEN ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                    ELSE ROUND(( ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                    END), @nCurAmt))
                                  ELSE (ROUND((CASE WHEN A.IsInclusedVAT = '1' 
													THEN ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                    ELSE ROUND(( ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                    END), @nCurAmt))
                                  END,
                    DomVAT = CASE WHEN @IsCalcApply = '1' 
								  THEN (ROUND((CASE WHEN A.IsInclusedVAT = '1' THEN ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                                    ELSE ROUND(( ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                                    END) * ISNULL(C.ExRate, 0), @nDomAmt))
                                  ELSE (ROUND((CASE WHEN A.IsInclusedVAT = '1' THEN ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt)
                                                    ELSE ROUND(( ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * (A.VatRate / 100)      , @nCurAmt)
                                                    END) * ISNULL(C.ExRate, 0), @nDomAmt))
                                  END,
                     CurAmt = CASE WHEN @IsCalcApply = '1' 
								   THEN (CASE WHEN A.IsInclusedVAT = '1'  THEN (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price 
                                                                   - (ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt))
                                                               ELSE (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * D.Price END)
                                   ELSE (CASE WHEN A.IsInclusedVAT = '1'  THEN (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price 
                                                                   - (ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt))
                                                               ELSE (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * D.Price END)
                                   END,
                     DomAmt = CASE WHEN @IsCalcApply = '1' 
								   THEN (CASE WHEN A.IsInclusedVAT = '1'  
											  THEN (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * ISNULL(C.ExRate, 0)
                                                                     - ROUND(ROUND(((ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt) * ISNULL(C.ExRate, 0), @nDomAmt)
                                              ELSE (ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)) * D.Price * ISNULL(C.ExRate, 0) END)
                                   ELSE (CASE WHEN A.IsInclusedVAT = '1'  
											  THEN (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * ISNULL(C.ExRate, 0)
                                                                     - ROUND(ROUND(((ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * B.Price * 10) / (100 + A.VatRate), @nCurAmt) * ISNULL(C.ExRate, 0), @nDomAmt)
                                              ELSE (ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0)) * D.Price * ISNULL(C.ExRate, 0) END)
                                   END,
                    Qty          = ISNULL(A.Qty   , 0) - ISNULL(B.Qty   , 0),
                    STDQty       = ISNULL(A.STDQty, 0) - ISNULL(B.STDQty, 0),
                    LastUserSeq  = @UserSeq ,
                    LastDateTime = GETDATE(),
                    PgmSeq       = @PgmSeq    
               FROM _TSLInvoiceItem      AS A
                    JOIN @TSLInvoiceItem AS B ON A.CompanySeq  = @CompanySeq
                                       AND A.InvoiceSeq  = B.SourceInvoiceSeq
                                             AND A.InvoiceSerl = B.SourceInvoiceSerl
                    JOIN @TSLInvoice     AS C ON B.InvoiceSeq  = C.InvoiceSeq
                    JOIN #TSLInvItemPrice AS D ON D.InvoiceSeq  = A.InvoiceSeq
                                              AND D.InvoiceSerl = A.InvoiceSerl
              WHERE C.CurrSeq <> @CurrSeq
          
         /********************************************************************************************/
         
        DELETE KPX_TSLInvoiceItemAdd
          FROM KPX_TSLInvoiceItemAdd AS X
          JOIN _TSLInvoiceItem AS A WITH(NOLOCK) ON A.CompanySeq = X.CompanySeq
												AND A.InvoiceSeq = X.InvoiceSeq
												AND A.InvoiceSerl = X.InvoiceSerl
          JOIN @TSLInvoiceItem AS B ON A.InvoiceSeq = B.SourceInvoiceSeq
                                         AND A.InvoiceSerl = B.SourceInvoiceSerl
          JOIN @TSLInvoice AS C ON B.InvoiceSeq = C.InvoiceSeq
          WHERE A.CompanySeq = @CompanySeq
            AND A.Qty = 0 AND A.STDQty = 0
         
         DELETE _TSLInvoiceItem
           FROM _TSLInvoiceItem AS A 
                JOIN @TSLInvoiceItem AS B ON A.CompanySeq = @CompanySeq
                                         AND A.InvoiceSeq = B.SourceInvoiceSeq
                                         AND A.InvoiceSerl = B.SourceInvoiceSerl
                JOIN @TSLInvoice AS C ON B.InvoiceSeq = C.InvoiceSeq
          WHERE A.Qty = 0 AND A.STDQty = 0
         
         IF EXISTS (SELECT 1 FROM @TSLInvoice WHERE IsDelvCfm = '1')
         BEGIN
             -- 재고반영    
             DELETE FROM #TLGInOutDailyBatch    
         
             INSERT INTO #TLGInOutDailyBatch    
             SELECT 10, SourceInvoiceSeq, 0,'',0  
               FROM @TSLInvoice    
              WHERE IsDelvCfm = '1'
             UNION
             SELECT 10, InvoiceSeq, 0,'',0  
               FROM @TSLInvoice    
              WHERE IsDelvCfm = '1'
              -- 거래명세서 출고    
             EXEC _SLGInOutDailyINSERT @CompanySeq     
         END
          EXEC _SLGWHStockUPDATE @CompanySeq    
         EXEC _SLGLOTStockUPDATE @CompanySeq    
  --        EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
 --        EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
          UPDATE #TSLInvoiceLocal  
            SET Result        = B.Result     ,      
                MessageType   = B.MessageType,      
                Status        = B.Status      
           FROM #TSLInvoiceLocal AS A   
             JOIN #TLGInOutDailyBatch    AS B ON A.InvoiceSeq = B.InOutSeq  
          WHERE B.Status <> 0   
          -- 실적집계
         IF EXISTS (SELECT 1 FROM @TSLInvoice WHERE InvoiceSeq <> 0)
         BEGIN
             INSERT INTO #SSLInvoiceSeq(SumSeq)  
             SELECT InvoiceSeq  
               FROM @TSLInvoice  
                   
             EXEC _SSLInvoiceSum 'A', @CompanySeq  
         END  
          --***** 진행연결(신규/수정진행원천)
         -- 진행연결(FromTableSeq => 거래명세서)
         DELETE FROM  #SComSourceDailyBatch      
          INSERT INTO #SComSourceDailyBatch    
         SELECT '_TSLInvoiceItem', A.InvoiceSeq, A.InvoiceSerl, 0,     
                C.ProgTableName, A.FromSeq, A.FromSerl, A.FromSubSerl,    
                B.Qty, B.STDQty, B.CurAmt, B.CurVAT,    
                A.FromQty, A.FromSTDQty, A.FromAmt,   A.FromVAT    
           FROM #TSLInvoiceSource AS A    
                JOIN _TSLInvoiceItem AS B ON B.CompanySeq = @CompanySeq
                                         AND A.InvoiceSeq = B.InvoiceSeq
                                         AND A.InvoiceSerl = B.InvoiceSerl
                JOIN _TCOMProgTable AS C ON A.FromTableSeq = C.ProgTableSeq    
          UNION ALL
          SELECT '_TSLInvoiceItem', C.InvoiceSeq, C.InvoiceSerl, 0,     
                D.ProgTableName, A.FromSeq, A.FromSerl, A.FromSubSerl,    
                C.Qty, C.STDQty, C.CurAmt, C.CurVAT,    
                A.FromQty, A.FromSTDQty, A.FromAmt,   A.FromVAT    
           FROM #TSLInvoiceSource AS A    
                JOIN @TSLInvoiceItem AS B ON A.InvoiceSeq  = B.SourceInvoiceSeq
                                         AND A.InvoiceSerl = B.SourceInvoiceSerl
                JOIN _TSLInvoiceItem AS C ON C.CompanySeq = @CompanySeq
                                         AND B.InvoiceSeq = C.InvoiceSeq
                                         AND B.InvoiceSerl = C.InvoiceSerl
                JOIN _TCOMProgTable AS D ON A.FromTableSeq = D.ProgTableSeq    
          EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq    
          IF EXISTS (SELECT 1 FROM #TSLSalesSource)
         BEGIN
             --***** 진행연결(신규/수정진행원천)
             -- 진행연결(거래명세서 => 매출)
             DELETE FROM  #SComSourceDailyBatch      
              INSERT INTO #SComSourceDailyBatch    
             SELECT '_TSLSalesItem', A.ToSeq, A.ToSerl, 0,     
                    '_TSLInvoiceItem', B.InvoiceSeq, B.InvoiceSerl, 0,    
                    A.ToQty, A.ToSTDQty, A.ToAmt, A.ToVAT,    
                    B.Qty, B.STDQty, B.CurAmt, B.CurVAT
               FROM #TSLSalesSource AS A    
                    JOIN _TSLInvoiceItem AS B ON B.CompanySeq = @CompanySeq
                                             AND A.InvoiceSeq = B.InvoiceSeq
                              AND A.InvoiceSerl = B.InvoiceSerl
              EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq    
         END
     END
      SELECT * FROM #TSLInvoiceLocal
      RETURN

GO


