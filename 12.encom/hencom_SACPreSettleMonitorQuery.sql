IF OBJECT_ID('hencom_SACPreSettleMonitorQuery') IS NOT NULL 
    DROP PROC hencom_SACPreSettleMonitorQuery
GO 

-- v2017.03.31 

-- 규격대체전표여부 추가 
-- 입금, 입금통보, 감가, 유류, 로더 추가 
/************************************************************
 설  명 - 데이터-결산모니터링_hencom : 조회
 작성일 - 20160421
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SACPreSettleMonitorQuery               
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle      INT,
		    @DeptSeq    INT ,
            @YM         NCHAR(6)  ,
			@CostKeySeq  int
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq    = DeptSeq     ,
            @YM         = YM          
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (DeptSeq     INT ,
            YM          NCHAR(6) )
    
    
    ------------------------------------------------------------
    -- 규격대체전표여부 
    ------------------------------------------------------------
    -- TEMP TABLE 생성
    -- 집계
    CREATE TABLE #TempResult2(DeptSeq INT, CustSeq INT, PJTSeq INT, WorkDate NCHAR(8), SumMesKey NVARCHAR(30), SumMesKeyNo INT,  
                              GoodItemSeq INT, CurAmt DECIMAL(19,5), ReplaceRegSeq INT, ReplaceRegSerl INT,  ReplaceRegNo int, 
                              RepCustSeq INT, RepPJTSeq INT, RepItemSeq INT, RepCurAmt DECIMAL(19,5), 
                              ATARegSeq INT, GapAmt DECIMAL(19,5), AdjAmt DECIMAL(19,5), SlipSeq INT, IsAllReplace NCHAR(1), SortOrd int)      
    
    -- 구분                         
    CREATE TABLE #result ( SumMesKey int , ReplaceRegSeq int , RepCustSeq INT, Gubun nvarchar(200), GubunSeq INT )   
     
    -- 최종                                  
    CREATE TABLE #TempResult(DeptSeq INT, CustSeq INT, PJTSeq INT, WorkDate NCHAR(8), SumMesKey NVARCHAR(30), SumMesKeyNo INT,  
                             GoodItemSeq INT, CurAmt DECIMAL(19,5), ReplaceRegSeq INT, ReplaceRegSerl INT,   
                             RepCustSeq INT, RepPJTSeq INT, RepItemSeq INT, RepCurAmt DECIMAL(19,5), 
                             ATARegSeq INT, GapAmt DECIMAL(19,5), AdjAmt DECIMAL(19,5), SlipSeq INT, IsAllReplace NCHAR(1), 
                             Gubun NVARCHAR(200), GubunSeq INT, IDX INT,
                             CrAmt DECIMAL(19,5), CrAccSeq INT, CrCustSeq INT, DrAmt DECIMAL(19,5), DrAccSeq INT, DrCustSeq INT)
    
    -- 데이터 집계
    INSERT INTO #TempResult2(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,   
                             ReplaceRegSeq, ReplaceRegSerl,ReplaceRegNo, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, 
                             ATARegSeq, GapAmt, AdjAmt, SlipSeq, IsAllReplace, SortOrd)  
    SELECT CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END AS DeptSeq,    
           A.CustSeq,    
           A.PJTSeq,    
           A.WorkDate,     
           A.SumMesKey,     
           ROW_NUMBER() OVER (PARTITION BY A.SumMesKey ORDER BY a.SumMesKey) AS SumMesKeyNo,    
           A.GoodItemSeq,    
           A.CurAmt,    
           M.ReplaceRegSeq,    
           M.ReplaceRegSerl,  
           ROW_NUMBER() OVER (PARTITION BY M.ReplaceRegSeq,M.ReplaceRegSerl ORDER BY M.ReplaceRegSeq,M.ReplaceRegSerl) AS ReplaceRegNo,      
           RI.CustSeq as RepCustSeq,    
           RI.PJTSeq as RepPJTSeq,    
           RI.ItemSeq as RepItemSeq,    
           M.CurAmt as RepCurAmt,    
           0 as ATARegSeq,
           ISNULL(A.CurAmt,0) - ISNULL(M.CurAmt,0),
           0 as AdjAmt,
           0 as SlipSeq,
           '0',
           case when a.CustSeq = ri.CustSeq then 1 else 100 end
      FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)     
      LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq    
                                                                        AND M.SumMesKey = A.SumMesKey    
      LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS RI WITH(NOLOCK) ON RI.CompanySeq = A.CompanySeq    
                                                                     AND RI.ReplaceRegSeq = M.ReplaceRegSeq    
                                                                     AND RI.ReplaceRegSerl = M.ReplaceRegSerl         
     WHERE A.CompanySeq = @CompanySeq    
       AND A.WorkDate LIKE @YM + '%'    
       --AND CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END = @DeptSeq    
       AND ISNULL(a.SalesSeq,0) <> 0    
       AND ISNULL(ri.IsPreSales,'0') <> '1'  
       AND m.IsReplace = '1'
    
    -- 여러행 존재하는 건 업데이트
    UPDATE #TempResult2
       SET IsAllReplace = '1'
      FROM #TempResult2 AS A
      JOIN (SELECT ReplaceRegSeq, COUNT(distinct RepCustSeq) AS CustIDX
              FROM #TempResult2
             GROUP BY ReplaceRegSeq) AS B ON B.ReplaceRegSeq = A.ReplaceRegSeq
     WHERE CustIDX > 1

    UPDATE a
	   SET ATARegSeq = b.ATARegSeq,
	       SlipSeq = b.SlipSeq
 	  FROM #TempResult2 as a 
	  JOIN hencom_TAcAdjTempAccount as b on b.CompanySeq = @CompanySeq
	                                    and b.ReplaceRegSeq = a.ReplaceRegSeq
										and b.AdjAmt = GapAmt
    
    UPDATE a
	   SET ATARegSeq = b.ATARegSeq,
	       SlipSeq = b.SlipSeq
 	  FROM #TempResult2 as a 
	  JOIN hencom_TAcAdjTempAccount as b on b.CompanySeq = @CompanySeq
	                                    and b.ReplaceRegSeq = a.ReplaceRegSeq
     WHERE ISNULL(a.ATARegSeq,0) = 0
    
	---------------------------
     -- 구분(1:거래처변경/전액대체, 2: 금액변경, 3:금액거래처변경, 4:거래처변경/일부대체)
	---------------------------
    INSERT #result (SumMesKey, ReplaceRegSeq, RepCustSeq, Gubun, GubunSeq)    
    SELECT cu.SumMesKey,    
           at.ReplaceRegSeq,    
           AT.RepCustSeq,
           '금액거래처변경' AS gubun,
           3 AS GubunSeq    
      FROM (SELECT ReplaceRegSeq,
                   RepCustSeq,    
                   '금액변경' AS gubun,
                   2 AS GubunSeq    
             FROM #TempResult2    
            GROUP BY ReplaceRegSeq, RepCustSeq      
           HAVING SUM(curamt) <> SUM(repcuramt)) AS AT  
      JOIN (SELECT DISTINCT SumMesKey,    
                   ReplaceRegSeq,  
                   RepCustSeq,  
                   '거래처변경/전액대체' AS gubun  ,
                   1 AS GubunSeq      
              FROM #TempResult2    
               WHERE custseq <> repcustseq) AS cu on at.ReplaceRegSeq = cu.ReplaceRegSeq   
                                                 AND AT.RepCustSeq = CU.RepCustSeq
                 
    INSERT #result ( ReplaceRegSeq, RepCustSeq, Gubun, GubunSeq )    
    SELECT a.ReplaceRegSeq,    
           a.RepCustSeq,
           '금액변경'    ,
           2 AS GubunSeq      
      FROM (SELECT ReplaceRegSeq, RepCustSeq    
              FROM #TempResult2    
             GROUP BY ReplaceRegSeq, RepCustSeq      
            HAVING SUM(curamt) <> SUM(repcuramt)) AS a    
     WHERE NOT EXISTS (SELECT ReplaceRegSeq FROM #result WHERE ReplaceRegSeq = A.ReplaceRegSeq AND RepCustSeq = A.RepCustSeq)     
    
    INSERT #result         
    SELECT SumMesKey,    
           ReplaceRegSeq,    
           RepCustSeq,
           '거래처변경/전액대체',
           1 AS GubunSeq     
      FROM (SELECT DISTINCT SumMesKey,    
                   ReplaceRegSeq,
                   RepCustSeq  
              FROM #tempresult2    
             WHERE custseq <> repcustseq             
            except 
            SELECT SumMesKey, ReplaceRegSeq, RepCustSeq    
              FROM #result   
             WHERE --Gubun = '금액거래처변경'
                   GubunSeq = 3) AS A    
     WHERE NOT EXISTS (SELECT ReplaceRegSeq FROM #result WHERE ReplaceRegSeq = A.ReplaceRegSeq AND RepCustSeq = A.RepCustSeq)     
    
     -- 최종데이터집계테이블
     INSERT INTO #TempResult(DeptSeq, ATARegSeq, SlipSeq)
     SELECT A.DeptSeq, A.ATARegSeq, A.SlipSeq
       FROM #tempresult2 AS A  
       JOIN (SELECT DISTINCT ReplaceRegSeq, RepCustSeq, gubun, GubunSeq  
               FROM #result) AS R on R.ReplaceRegSeq = A.ReplaceRegSeq   
                                 AND R.RepCustSeq = A.RepCustSeq 
               
     INSERT INTO #TempResult(DeptSeq, ATARegSeq, SlipSeq)
     SELECT A.DeptSeq, A.ATARegSeq, A.SlipSeq
       FROM #tempresult2 AS A    
       JOIN (SELECT DISTINCT ReplaceRegSeq, RepCustSeq, gubun, GubunSeq  
               FROM #result) AS R on R.ReplaceRegSeq = A.ReplaceRegSeq    
                                 AND R.RepCustSeq = A.RepCustSeq 
      WHERE R.GubunSeq <> 2 AND (R.GubunSeq <> 3 OR IsAllReplace <> '1')
    
    -- QUERY
    SELECT A.DeptSeq, '0' AS IsReplace
      INTO #IsReplace
      FROM #TempResult            AS A
     WHERE ISNULL(A.ATARegSeq,0) <> 0 
       AND ISNULL(A.SlipSeq,0) = 0 
     GROUP BY A.DeptSeq
    ------------------------------------------------------------                              
    -- 규격대체전표여부, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- 입금 
    ------------------------------------------------------------
    SELECT A.DeptSeq, '0' AS IsReceipt
      INTO #Receipt 
      FROM _TSLReceipt      AS A 
      JOIN _TSLReceiptDesc  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ISNULL(A.SlipSeq,0) = 0 
       AND LEFT(A.ReceiptDate,6) = @YM
     GROUP BY A.DeptSeq 
    ------------------------------------------------------------
    -- 입금, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- 입금통보 
    ------------------------------------------------------------
    SELECT DISTINCT '0' AS IsRevNotifyDesc
      INTO #RevNotifyDesc
      FROM _TACRevNotifyDesc        AS A WITH(NOLOCK)        
                 JOIN _TACRevNotify AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.NotifySeq  = B.NotifySeq              
      LEFT OUTER JOIN (
                        SELECT A.CompanySeq, A.NotifySeq, A.NotifySerl, SUM(A.CurAmt * A.SMDrOrCr ) AS CfmForAmt, SUM(A.DomAmt * A.SMDrOrCr)  AS CfmAmt    
                          FROM _TSLReceiptDesc AS A WITH(NOLOCK)        
                          JOIN _TACRevNotifyDesc AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.NotifySeq = B.Notifyseq AND A.NotifySerl = B.Serl        
                         WHERE B.CompanySeq = @CompanySeq 
                         GROUP BY A.CompanySeq, A.NotifySeq, A.NotifySerl
                      ) AS F ON ( A.CompanySeq = F.CompanySeq AND A.Notifyseq = F.NotifySeq AND A.Serl = F.NotifySerl ) 
     WHERE A.CompanySeq = @CompanySeq     
       AND LEFT(B.NotifyDate,6) = @YM
       AND ISNULL(A.Amt, 0) - ISNULL(F.CfmAmt, 0) <> 0 
    ------------------------------------------------------------
    -- 입금통보, END 
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- 감가상각전표처리 
    ------------------------------------------------------------
    SELECT A.DeptSeq, '0' AS IsAsstDepre
      INTO #AsstDepre
      FROM _TACAsstDepreDept AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.DepreDate,6) = @YM 
       AND ISNULL(A.SlipSeq,0) = 0 
     GROUP BY A.DeptSeq 
    ------------------------------------------------------------
    -- 감가상각전표처리, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- 도급유류비정산처리전표
    ------------------------------------------------------------
    SELECT A.DeptSeq, '0' AS IsOil
      INTO #FuelCalc
      FROM hencom_TPUFuelCalc AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.FuelCalcYM,6) = @YM 
       AND ISNULL(A.SlipSeq,0) = 0 
     GROUP BY A.DeptSeq 
    ------------------------------------------------------------
    -- 도급유류비정산처리전표, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- WL사용정산처리
    ------------------------------------------------------------
    SELECT A.DeptSeq, '0' AS IsWL
      INTO #WL
      FROM hencom_TPUSubContrWL AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WLDate,6) = @YM 
       AND ISNULL(A.SlipSeq,0) = 0 
     GROUP BY A.DeptSeq 
    ------------------------------------------------------------
    -- WL사용정산처리, END 
    ------------------------------------------------------------
    
    select @CostKeySeq = CostKeySeq from _TESMDCostKey where companyseq = @CompanySeq and costym = @YM and SMCostMng = 5512001
    
	SELECT m.DeptSeq,
	       (select deptname from _tdadept where CompanySeq = @CompanySeq and deptseq = m.deptseq ) as DeptName, -- 사업소
		   case isnull(tout.cnt,-1) when 0 then '1' when -1 then '1' else '0' end  as Out,	-- 출고매출전표
		   case isnull(ttax.cnt,-1) when 0 then '1' when -1 then '1' else '0' end  as Tax,	-- 계산서청구전표
		   case isnull(tpur.cnt,-1) when 0 then '1' when -1 then '1' else '0' end  as Pur,	-- 
		   case isnull(tSubCont.cnt,-1) when 0 then '1' when -1 then '1' else '0' end  as SubCont,
		   case isnull(tpay.cnt,-1) when 0 then '1' when -1 then '1' else '0' end as Pay,
		   case isnull(tgencost.cnt,-1) when 0 then '1' when -1 then '1' else '0' end as GenCost,
           ISNULL(IR.IsReplace,'1') AS IsReplace, -- 규격대체
		   dept.FactUnit,
		    pp.EndTime   as PrevProc,		  -- 결산전집계
		   mp.EndTime as MFCostProc,		  -- 제조원가결산
		   mac.EndTime as MatCost,			  -- 제품단가계산
		   MFC.EndTime as MFCost,             -- 제조원가재료비대체전표
		   SC.EndTime as SalesCost,			  -- 제조원가전표
		   PSCS.EndTime as ProdSalesCostSlip, -- 제품/상품매출원가전표
		   EPS.EndTime as EtcInOutProdSlip,   -- 기타입출고전표(제품)
		   EGS.EndTime as EtcInOutGoodSlip,   -- 기타입출고전표(상품)
		   EMS.EndTime as EtcInOutMatSlip,    -- 기타입출고전표(자재)
		   ReStock.ReStock as ReStock,  	  -- 결산재집계
		   ReSum.ReSumDate as ReSale,		  -- 영업재집계
		   ReMon.ReMonth as ReMonth,		  -- 월별재집계
		   isNull(DC.DayC, 0) as DayClose,    -- 일마감(수불)
		   isNull(DM.MonC, 0) as MonthClost,  -- 월마감(수불)
		   DMC.DayMatC as DayMatCalc,		-- 일자별자재단가계산
		   GP.GoodPrice as GoodPrice,		-- 상품단가결산
           ISNULL(QQ.IsReceipt,'1') AS IsReceipt,       -- 입금 
           ISNULL(WW.IsAsstDepre,'1') AS IsAsstDepre,   -- 감가 
           ISNULL(EE.IsOil,'1') AS IsOil,               -- 유류 
           ISNULL(RR.IsWL,'1') AS IsWL,                 -- 로더 
           ISNULL(TT.IsRevNotifyDesc,'1') AS IsRevNotifyDesc -- 입금통보 

      FROM hencom_TDADeptAdd as m
	left outer  join _TDADept as dept on dept.CompanySeq = m.CompanySeq and dept.DeptSeq =  m.ProdDeptSeq  
left outer join (select a.deptseq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
					from _TSLSales as a with(nolock)
				   where a.CompanySeq = @CompanySeq
					 and a.SalesDate like @YM + '%'
					 and exists ( select salesseq from _tslsalesitem with(nolock) where CompanySeq = a.CompanySeq and SalesSeq = a.SalesSeq Group by salesseq Having Sum(CurAmt) <> 0 )
				group by a.deptseq) as tout on tout.DeptSeq = m.DeptSeq
left outer join (select a.DeptSeq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
				  from _TSLBill as a with(nolock)
				 where a.CompanySeq = @CompanySeq
				   and a.BillDate like @YM + '%'
				   and exists ( select billseq from _TSLSalesBillRelation with(nolock) where CompanySeq = a.CompanySeq and BillSeq = a.BillSeq Group by billseq Having sum(curamt) <> 0)
			  group by a.DeptSeq ) as ttax on ttax.DeptSeq = m.DeptSeq
left outer join (select a.DeptSeq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
				  from _TPUBuyingAcc as a with(nolock) 
				 where a.CompanySeq = @CompanySeq
				   and a.DelvInDate like @YM + '%'
			  group by a.DeptSeq  ) as tpur on tpur.DeptSeq = m.DeptSeq
left outer join (select a.DeptSeq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
				  from hencom_TPUSubContrCalc as a with(nolock) 
				 where a.CompanySeq = @CompanySeq
				   and a.WorkDate like @YM + '%'
				   and a.Amt + a.OTAmt + a.AddPayAmt - a.DeductionAmt <> 0
			  group by a.DeptSeq   ) as tSubCont on tSubCont.DeptSeq = m.DeptSeq
left outer join (select a.DeptSeq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
				  from _TPRAccPaySlip as a with(nolock) 
				 where a.CompanySeq = @CompanySeq
				   and a.PbYM like @YM + '%'
			  group by a.DeptSeq    ) as tpay on tpay.DeptSeq = m.DeptSeq
left outer join (select a.RegDeptSeq as DeptSeq, sum(case isnull(a.slipseq,0) when 0 then 1 else 0 end) as cnt
				  from _TARUsualCost as a with(nolock) 
				  JOIN _TARUsualCost AS b ON B.CompanySeq = A.CompanySeq AND B.UsualCostSeq = A.UsualCostSeq  
				 where a.CompanySeq = @CompanySeq
				   and a.RegDate like @YM + '%'
				   and exists ( select UsualCostSeq from _TARUsualCostAmt with(nolock) where CompanySeq = a.CompanySeq and UsualCostSeq = a.UsualCostSeq)
			  group by a.RegDeptSeq     ) as tgencost on tgencost.DeptSeq = m.DeptSeq     
left outer join (
					select a.EndTime
					  from _TESMCSttlProc as a
					  join _TESMBSttlMst as m on m.CompanySeq = a.CompanySeq
											 and m.WorkSeq = a.WorkSeq
					where a.CompanySeq = @CompanySeq
					  and a.WorkSeq = 6
					  and a.CostKeySeq = @CostKeySeq
					  and a.SttlProcSeq = (select max(SttlProcSeq) from _TESMCSttlProc where companyseq = @CompanySeq and workseq = 6 and  CostKeySeq = @CostKeySeq )
                ) as PP on 1 = 1
left outer join (
					select a.CostUnit,a.EndTime
					  from _TESMCSttlProc as a
					  join _TESMBSttlMst as m on m.CompanySeq = a.CompanySeq
											 and m.WorkSeq = a.WorkSeq
					where a.CompanySeq = @CompanySeq
					  and a.WorkSeq = 311
					  and a.CostKeySeq = @CostKeySeq
					  and a.SttlProcSeq = (select max(SttlProcSeq) from _TESMCSttlProc where companyseq = @CompanySeq and workseq = 311 and  CostKeySeq = @CostKeySeq and CostUnit = a.CostUnit )
                )  as MP on MP.CostUnit = dept.FactUnit
left outer join (
					  select max(a.pricingcalcdate) as EndTime
					  --case isnull(c.IsClose,'0') when '0' then null else    case when a.IsPricingCalc = '1' and a.PricingCalcDate >= c.LastDateTime then a.PricingCalcDate else null end  end as EndTime
						from _TESMCProdSttlClosing as a
			 left outer join _TCOMClosingYM c on c.companyseq = a.companyseq
											 and c.ClosingSeq = 69 
											 and c.ClosingYM = @YM
											 and c.DtlUnitSeq = 2
											 and c.IsClose = '1'
											 and c.UnitSeq = a.CostUnit
					   where a.CompanySeq = @companyseq
						 and a.CostKeySeq = @CostKeySeq
						 and a.CostUnit = 1
			   			 and a.CostUnitKind = 5502002
						 and a.SMPriceCalcKind  = 5515001
                ) as MAC on 1=1
left outer join (
				  SELECT    A.CostUnit, case slipseq when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = a.TransSeq )        end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522001  
				) as MFC on MFC.CostUnit = dept.FactUnit
left outer join (
				  SELECT    A.CostUnit, case slipseq when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = a.TransSeq )        end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522002  
				) as SC on SC.CostUnit = dept.FactUnit
left outer join (
				  SELECT    A.CostUnit, case slipseq when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = a.TransSeq )        end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522003  
				) as PSCS on PSCS.CostUnit = dept.FactUnit
left outer join (
				  SELECT   a.deptseq as CostUnit, case max(slipseq) when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = max(a.TransSeq) )        end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522006  
						and a.deptseq <> 0
            group by a.deptseq  
				) as EPS on EPS.CostUnit = dept.FactUnit
left outer join (
				  SELECT    a.deptseq as CostUnit, case max(slipseq) when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = max(a.TransSeq) )         end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522005  
            group by a.deptseq  
				) as EGS on EGS.CostUnit = dept.FactUnit
left outer join (
				 SELECT a.deptseq as CostUnit, case max(slipseq) when 0 then null else (select max(LastDateTime) from _TESMCProdSlipD where CompanySeq = @CompanySeq and TransSeq = max(a.TransSeq) )       end as EndTime
					 FROM  _TESMCProdSlipM                 AS A WITH(NOLOCK)  
									  JOIN _TESMDCostKey   AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq  
					  WHERE A.CompanySeq     = @CompanySeq  
						AND K.CostYm         = @YM  
						AND K.CompanySeq     = @CompanySeq  
						AND K.SMCostMng      = 5512001  
						AND A.SMSlipKind     = 5522004  
            group by a.deptseq  
				) as EMS on EMS.CostUnit = dept.FactUnit
left outer join (
				 SELECT Max(st.LastDateTime) as ReStock
				 FROM	_TLGReInOutStockHist AS st WITH(NOLOCK)
				 Where	st.PgmSeq IN (5956, 10321)
				 And	st.InOutYm = @YM
				) as ReStock on 1 = 1
left outer join (
				 SELECT Max(rs.LastDateTime) as ReSumDate
				 FROM	_TSLReSumHistory AS rs WITH(NOLOCK)
				 Where	rs.ReSumYM = @YM
				 And	rs.ResumName = '전체재집계'
				) as ReSum on 1 = 1
left outer join (
				 SELECT Max(Rem.CalcDateTime) as ReMonth
				 FROM	_TACSlipSumReCalcHist AS Rem WITH(NOLOCK)
				 Where	Rem.AccYM = @YM
				) as ReMon on 1 = 1
left outer join (
				SELECT	IIf(Sign(Sum(DC.IsClose - 1))= 0, 1, 0) as DayC
				FROM	_TCOMClosingDate As DC WITH(NOLOCK)
				WHERE	DC.CLOSINGDATE LIKE @YM + '%'
				AND		DC.CLOSINGSEQ = 70
				AND		DC.UnitSeq in (1, 3, 7)
				) as DC on 1 = 1
left outer join (
				SELECT	IIf(Sign(Sum(DM.IsClose - 1))= 0, 1, 0) as MonC
				FROM	_TCOMClosingYM As DM WITH(NOLOCK)
				WHERE	DM.ClosingYM LIKE @YM
				AND		DM.ClosingSeq = 69
				AND		DM.UnitSeq in (1, 3, 7)
				) as DM on 1 = 1
left  outer join (
				SELECT	MIN(PricingCalcDate) as DayMatC
				FROM	_TESMCProdSttlClosingDay AS a WITH(NOLOCK)
				WHERE	SMPriceCalcKind = '5515002'
				AND		CalcDate LIKE @YM + '%'
				) as DMC on 1 = 1
left outer join (
				SELECT	MAX(PricingCalcDate) as GoodPrice
				FROM	_TESMCProdClosingList WITH(NOLOCK)
				WHERE	PriceCalcKind = '5515003'
				And		SMCostMng = '5512001'
				And		CostYM =  @YM
				) as GP on 1 = 1
left outer join #IsReplace AS IR ON ( IR.DeptSeq = M.DeptSeq ) 
left outer join ( 
                SELECT MAX(DeptSeq) AS DeptSeq 
                  FROM hencom_TAcAdjTempAccount 
                 WHERE CompanySeq = @CompanySeq 
                   AND AdjYM = @YM 
                ) AS ACC ON ( ACC.DeptSeq = M.DeptSeq ) 
left outer join #Receipt        AS QQ ON ( QQ.DeptSeq = M.DeptSeq ) 
left outer join #AsstDepre      AS WW ON ( WW.DeptSeq = M.DeptSeq ) 
left outer join #FuelCalc       AS EE ON ( EE.DeptSeq = M.DeptSeq ) 
left outer join #WL             AS RR ON ( RR.DeptSeq = M.DeptSeq ) 
left outer join #RevNotifyDesc  AS TT ON ( 1 = 1 ) 
     WHERE m.CompanySeq = @CompanySeq
       AND ISNULL(m.UMTotalDiv,0) <> 0
       AND (@DeptSeq = 0 OR m.DeptSeq = @DeptSeq)
     order by m.DispSeq
    
    RETURN

GO 
begin tran 
exec hencom_SACPreSettleMonitorQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <YM>201509</YM>
    <DeptSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036606,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029996
rollback 