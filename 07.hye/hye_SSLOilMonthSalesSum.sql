IF OBJECT_ID('hye_SSLOilMonthSalesSum') IS NOT NULL 
    DROP PROC hye_SSLOilMonthSalesSum
GO 

-- v2016.10.27 

-- 주유소판매월보등록-POS데이터집계 by이재천 
CREATE PROC hye_SSLOilMonthSalesSum
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
            @BizUnit    INT, 
            --@BizUnitSub INT, 
            @StdYM      NCHAR(6)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
    
    SELECT @BizUnit = ISNULL( BizUnit, 0 ),
           @StdYM   = ISNULl( StdYM, '')
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )     
      WITH (
              BizUnit   INT, 
              StdYM     NCHAR(6)
           )  

      
    --SELECT @BizUnitSub = B.ValueSeq 
    --  FROM _TDAUMinorValue              AS A 
    --  LEFT OUTER JOIN _TDAUMinorValue   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
    -- WHERE A.CompanySeq = @CompanySeq 
    --   AND A.MajorSeq = 1013753
    --   AND A.Serl = 1000002 
    --   AND A.ValueText = @BizUnit 


   --SELECT @POSType = CASE WHEN IsOil = '1' THEN 'SKPOS' ELSE 'JWPOS' END 
   --  FROM hye_TCOMPOSEnv
   -- WHERE CompanySeq = @CompanySeq 
   --   AND BizUnit = @BizUnit 
    
      -- 1.계기현황
      DELETE FROM pos800t
            WHERE div_code = @BizUnit
              AND yyyymm = @StdYM

      INSERT INTO pos800t(div_code,             yyyymm,              item_code,        tank_no,            nozzle_no,
                          before_meter,         current_meter,       flow_qty,         extra_out_qty,      insp_qty,
                          trans_in_qty,         trans_out_qty,       keeping_qty,      self_consume_qty,   net_sale_qty)
		             SELECT @BizUnit,          @StdYM,           item_code,        tank_no,            nozzle_no,
                          MIN(before_meter),    MAX(current_meter),  sum(flow_qty),    sum(extra_out_qty), sum(insp_qty),
                          SUM(trans_in_qty),    SUM(trans_out_qty),  sum(keeping_qty), sum(self_consume_qty),    sum(net_sale_qty)
		               FROM pos700t
		              WHERE div_code = @BizUnit
			             AND yyyymmdd LIKE @StdYM + '%'
                    GROUP BY item_code,     tank_no,       nozzle_no

                    --select * From pos700t where div_code = '801'


      -- 전일계기량 및 순매출량 Update
/*
      UPDATE pos800t
         SET before_meter  = ISNULL(b.current_meter,0),
             current_meter = ISNULL(b.current_meter,0) + a.flow_qty,
             net_sale_qty  = a.flow_qty
        FROM pos800t a
		LEFT OUTER JOIN 
             ( SELECT div_code, item_code, tank_no, nozzle_no, current_meter
                 FROM pos800t
                WHERE div_code = @BizUnit
                  AND yyyymm = CONVERT(VARCHAR(6), DATEADD(mm,-1,@StdYM+'01'),112) 
             ) b ON a.div_code   = b.div_code
                AND a.item_code  = b.item_code
                AND a.tank_no    = b.tank_no
                AND a.nozzle_no  = b.nozzle_no
       WHERE a.div_code = @BizUnit
         AND a.yyyymm = @StdYM 
*/

      -- 2.상품수불 및 재고현황
      DELETE FROM pos810t
            WHERE div_code = @BizUnit
              AND yyyymm = @StdYM

      INSERT INTO pos810t(div_code,				   yyyymm,			      item_code,			tank_no,
							     basis_qty,			   in_qty,			      sale_qty,			re_in_qty,
							     re_out_qty,			   onhand_qty,		      real_qty,			month_diff_qty,
							     before_month_qty,	   next_month_qty,	   descr)
                   SELECT @BizUnit,			   @StdYM,           a.item_code,	   a.tank_no,
                          SUM(CASE WHEN a.yyyymmdd = b.min_yyyymmdd THEN a.basis_qty ELSE 0 END) AS basis_qty,		   
                          sum(in_qty),	         sum(sale_qty),		   sum(extra_in_qty),
                          sum(extra_out_qty),	0 AS onhand_qty,
                          SUM(CASE WHEN a.yyyymmdd = b.max_yyyymmdd THEN a.real_qty ELSE 0 END) AS real_qty,		   
                          SUM(day_diff_qty),
						        0 AS before_month_qty,0 AS next_month_qty,	'' AS descr
                     FROM pos710t a, 
                          ( SELECT item_code, tank_no, MIN(yyyymmdd) AS min_yyyymmdd, MAX(yyyymmdd) AS max_yyyymmdd
                              FROM pos710t
					              WHERE div_code     =    @BizUnit
						             AND yyyymmdd     LIKE @StdYM + '%'
                             GROUP BY item_code, tank_no 
                           ) b
					     WHERE a.item_code    = b.item_code
                      AND a.tank_no      = b.tank_no
                      AND a.div_code     = @BizUnit
						    AND a.yyyymmdd     LIKE @StdYM + '%'
					     GROUP BY a.item_code,  a.tank_no
 
      -- 전월 재고량, 과부족 누계 Update
      UPDATE pos810t
         SET onhand_qty       = a.basis_qty + a.in_qty - a.sale_qty + a.re_in_qty - a.re_out_qty,
             before_month_qty = ISNULL(b.next_month_qty,0) 
        FROM pos810t a
		       LEFT OUTER JOIN 
             ( SELECT div_code, item_code,  tank_no,  real_qty, next_month_qty
                 FROM pos810t
                WHERE div_code  = @BizUnit
                  AND yyyymm    = CONVERT(VARCHAR(6), DATEADD(mm,-1,@StdYM+'01'),112) 
             ) b ON a.div_code  = b.div_code
                AND a.item_code = b.item_code
                AND a.tank_no   = b.tank_no
       WHERE a.div_code = @BizUnit
         AND a.yyyymm   = @StdYM 

      -- 3.판매현황
      /*
      * 거래구분
      CASH   : 현금
      DCCARD : 우대카드
      CARD   : 카드
      AR     : 외상
      GIFT   : 상품권
      OKCASH : OK Cash  Bag
      COUPON : 주유할인권
      */
      DELETE FROM pos820t
            WHERE div_code = @BizUnit
              AND yyyymm = @StdYM

      -- 외상, 신용카드 금액 먼저 계산
      INSERT INTO pos820t(div_code,	      yyyymm,	         item_code,	      pay_code,
						        sale_price,	   sale_qty,	      sale_amt,	      vat_amt,
						        total_amt,	   descr)
				       SELECT @BizUnit,	   @StdYM,	      item_code,	      pay_code,
							     sale_price,	   sum(sale_qty),	   sum(sale_amt),	   sum(vat_amt),
							     sum(total_amt),	'' as descr
				         FROM pos720t
				        WHERE div_code    =    @BizUnit
				          AND yyyymmdd    LIKE @StdYM + '%'
				        GROUP BY item_code,	pay_code,	sale_price


      -- 4.수금현황
      DELETE FROM pos830t
            WHERE div_code = @BizUnit
              AND yyyymm = @StdYM


      INSERT INTO pos830t(div_code,          yyyymm,           pay_code,         pos_custom_code,
                          basis_amt,         no_vat_amt,		   vat_amt,		      sale_amt_pos,
						        sale_amt,          in_amt,           charge_amt,       balance_amt)
				       SELECT @BizUnit,		   @StdYM,		   a.pay_code,		   a.pos_custom_code,
						        SUM(CASE WHEN a.yyyymmdd = b.min_yyyymmdd THEN a.basis_amt ELSE 0 END),	
                          SUM(no_vat_amt),   SUM(vat_amt),		SUM(sale_amt_pos),
						        SUM(sale_amt),	   SUM(in_amt + in_amt2),		SUM(charge_amt),	
						        SUM(CASE WHEN a.yyyymmdd = b.max_yyyymmdd THEN a.balance_amt ELSE 0 END)
				         FROM pos730t a,
                          ( SELECT pay_code, pos_custom_code, MIN(yyyymmdd) AS min_yyyymmdd, MAX(yyyymmdd) AS max_yyyymmdd
                              FROM pos730t
					              WHERE div_code     =    @BizUnit
						             AND yyyymmdd     LIKE @StdYM + '%'
                             GROUP BY pay_code, pos_custom_code
                           ) b
					     WHERE a.pay_code        = b.pay_code
                      AND a.pos_custom_code = b.pos_custom_code
				          AND a.div_code        = @BizUnit
					       AND a.yyyymmdd        LIKE @StdYM + '%'
					     GROUP BY a.pay_code,	a.pos_custom_code


/*
      -- 전일잔액 및 금일잔액 UPDATE
      UPDATE pos830t
         SET basis_amt            = ISNULL(b.balance_amt,0),
             balance_amt          = ISNULL(b.balance_amt,0) + sale_amt - CASE WHEN a.pay_code = 'CASH' THEN ISNULL(b.balance_amt,0) ELSE in_amt END,
             no_vat_amt           = FLOOR(sale_amt * 10/11),
             vat_amt              = sale_amt - FLOOR(sale_amt * 10/11)
        FROM pos830t a
   		LEFT OUTER JOIN 
             ( SELECT div_code,  pay_code,  pos_custom_code, balance_amt
                 FROM pos830t
                WHERE div_code  = @BizUnit
                  AND yyyymm  = CONVERT(VARCHAR(6), DATEADD(mm,-1,@StdYM),112) 
             ) b ON a.div_code        = b.div_code
                AND a.pay_code        = b.pay_code
                AND a.pos_custom_code = b.pos_custom_code
       WHERE a.div_code = @BizUnit
         AND a.yyyymm = @StdYM 
*/
      -- 5.1 기타상품 수불 및 재고현황
      DELETE FROM pos840t
            WHERE div_code = @BizUnit
              AND yyyymm   = @StdYM

      INSERT INTO pos840t(	div_code,		yyyymm,		basis_amt,		month_incoupon,
							      refueling_amt,	loan_amt,	industry_amt,	total_amt,
							      month_amt,		basis_bal,	issue_coupon,	destruc_coupon,
							      month_bal)
		              SELECT	@BizUnit,		@StdYM,		
						         SUM(CASE WHEN a.yyyymmdd = b.min_yyyymmdd THEN a.basis_amt ELSE 0 END),	
                           SUM(a.today_incoupon),  SUM(a.refueling_amt),	SUM(a.loan_amt),	SUM(a.industry_amt),	SUM(a.total_amt),
					            SUM(a.today_amt),		
						         SUM(CASE WHEN a.yyyymmdd = b.max_yyyymmdd THEN a.basis_bal ELSE 0 END),	
                           SUM(a.issue_coupon),	SUM(a.destruc_coupon), SUM(a.today_bal)
			             FROM pos740t a,
                          ( SELECT div_code, MIN(yyyymmdd) AS min_yyyymmdd, MAX(yyyymmdd) AS max_yyyymmdd
                              FROM pos740t
					              WHERE div_code     =    @BizUnit
						             AND yyyymmdd     LIKE @StdYM + '%'
                             GROUP BY div_code
                           ) b
			            WHERE a.div_code   = b.div_code
                       AND a.div_code   = @BizUnit
				           AND yyyymmdd    LIKE @StdYM + '%'
/*
		   UPDATE pos840t
		 	  SET basis_amt = ISNULL(b.month_amt, 0),
				  basis_bal = ISNULL(b.month_bal, 0)
			FROM pos840t a
			LEFT OUTER JOIN 
				 ( SELECT div_code,  month_amt,  month_bal
					 FROM pos840t
					WHERE div_code  = @BizUnit
					  AND yyyymm  = CONVERT(VARCHAR(6), DATEADD(mm,-1,@StdYM),112) 
				 ) b ON a.div_code        = b.div_code
		   WHERE a.div_code = @BizUnit
			 AND a.yyyymm = @StdYM 
*/
      -- 5.2 세차현황
      DELETE FROM pos850t
            WHERE div_code = @BizUnit
              AND yyyymm = @StdYM

      INSERT INTO pos850t(	div_code,		yyyymm,			   before_meter,		   current_meter,
							      flow_cnt,		charge_cnt,		   nocharge_cnt,		   test_cnt , sale_cnt)
		              SELECT	@BizUnit,	@StdYM,		
						         SUM(CASE WHEN a.yyyymmdd = b.min_yyyymmdd THEN a.before_meter ELSE 0 END),	
						         SUM(CASE WHEN a.yyyymmdd = b.max_yyyymmdd THEN a.current_meter ELSE 0 END),	
   				            SUM(flow_cnt),	SUM(charge_cnt),	SUM(nocharge_cnt),	SUM(test_cnt) , SUM(sale_cnt)
			             FROM pos750t a,
                          ( 
                            SELECT div_code, MIN(yyyymmdd) AS min_yyyymmdd, MAX(yyyymmdd) AS max_yyyymmdd
                              FROM pos750t
	                          WHERE div_code     =    @BizUnit
		                         AND yyyymmdd     LIKE @StdYM + '%'
                             GROUP BY div_code
                           ) b
			            WHERE a.div_code = @BizUnit
			              AND a.yyyymmdd LIKE @StdYM + '%'

/*
		   UPDATE pos850t
		 	  SET before_meter = ISNULL(b.current_meter, 0),
				  current_meter = ISNULL(c.current_meter, 0)
			FROM pos850t a
			LEFT OUTER JOIN 
				 ( SELECT div_code,  current_meter
					 FROM pos850t
					WHERE div_code  = @BizUnit
					  AND yyyymm  = CONVERT(VARCHAR(6), DATEADD(mm,-1,@StdYM),112) 
				 ) b ON a.div_code        = b.div_code
			LEFT OUTER JOIN 
				 ( SELECT TOP 1 div_code,  current_meter
					 FROM pos750t
					WHERE div_code  = @BizUnit
					  AND yyyymmdd >= @StdYM + '01'
					  AND yyyymmdd <= @StdYM + '31'
				 ORDER BY yyyymmdd desc
				 ) c ON a.div_code        = c.div_code
		   WHERE a.div_code = @BizUnit
			 AND a.yyyymm = @StdYM 
*/


-- 작업구분이 등록(N)일 경우: 청명 IC 주유소의 경우 수금현황만 사용 2012.11.19 By Joo
    IF @BizUnit = '907'
    BEGIN

        -- 4.수금현황
        DELETE FROM pos830t
              WHERE div_code = @BizUnit
                AND yyyymm = @StdYM


          INSERT INTO pos830t(div_code,          yyyymm,           pay_code,         pos_custom_code,
                              basis_amt,         no_vat_amt,		   vat_amt,		      sale_amt_pos,
						            sale_amt,          in_amt,           charge_amt,       balance_amt)
				           SELECT @BizUnit,		   @StdYM,		   a.pay_code,		   a.pos_custom_code,
						            SUM(CASE WHEN a.yyyymmdd = b.min_yyyymmdd THEN a.basis_amt ELSE 0 END),	
                              SUM(no_vat_amt),   SUM(vat_amt),		SUM(sale_amt_pos),
						            SUM(sale_amt),	   SUM(in_amt + in_amt2),		SUM(charge_amt),	
						            SUM(CASE WHEN a.yyyymmdd = b.max_yyyymmdd THEN a.balance_amt ELSE 0 END)
				             FROM pos730t a,
                              ( SELECT pay_code, pos_custom_code, MIN(yyyymmdd) AS min_yyyymmdd, MAX(yyyymmdd) AS max_yyyymmdd
                                  FROM pos730t
					                  WHERE div_code     =    @BizUnit
						                 AND yyyymmdd     LIKE @StdYM + '%'
                                 GROUP BY pay_code, pos_custom_code
                               ) b
					         WHERE a.pay_code        = b.pay_code
                          AND a.pos_custom_code = b.pos_custom_code
				              AND a.div_code        = @BizUnit
					           AND a.yyyymmdd        LIKE @StdYM + '%'
					         GROUP BY a.pay_code,	a.pos_custom_code
    END 


return 



