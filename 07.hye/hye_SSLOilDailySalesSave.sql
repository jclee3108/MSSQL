  
IF OBJECT_ID('hye_SSLOilDailySalesSave') IS NOT NULL   
    DROP PROC hye_SSLOilDailySalesSave  
GO  
  
-- v2016.09.23 
  
-- 주유소판매일보등록-저장 by 이재천 
CREATE PROC hye_SSLOilDailySalesSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)
      
    CREATE TABLE #SS1( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#SS1'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS2( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#SS2'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS3( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#SS3'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS4( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#SS4'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS5( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock5', '#SS5'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS6( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock6', '#SS6'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS7( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock7', '#SS7'   
    IF @@ERROR <> 0 RETURN   

    CREATE TABLE #SS8( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock8', '#SS8'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS10( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock10', '#SS10'   
    IF @@ERROR <> 0 RETURN   
    
    
    -- 계기현황 
    UPDATE A
       SET flow_qty          = B.flow_qty -- 계기회전량 
          ,extra_out_qty    = B.extra_out_qty -- 계기외출하량 
          ,insp_qty         = B.insp_qty -- 검사/회수량 
          ,trans_in_qty     = B.trans_in_qty -- 이수 
          ,trans_out_qty    = B.trans_out_qty -- 이관 
          ,keeping_qty      = B.keeping_qty -- 보관 
          ,self_consume_qty = B.self_consume_qty -- 자가소비량 
          ,descr            = B.descr -- 적요 
      FROM pos700t  AS A 
      JOIN #SS1     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.tank_no = A.tank_no 
                          AND B.nozzle_no = A.nozzle_no
                            )
    
    -- 수불현황
    UPDATE A
       SET in_qty           = B.in_qty -- 입고량 
          ,extra_in_qty     = B.extra_in_qty -- 반입량 
          ,extra_out_qty    = B.extra_out_qty -- 반출량 
          ,real_qty         = B.real_qty -- 실측재고  
          ,descr            = B.descr -- 적요 
      FROM pos710t  AS A 
      JOIN #SS2     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd
                          AND B.item_code = A.item_code 
                          AND B.tank_no = A.tank_no 
                            )


    -- 판매현황 

    -- 고객적립금 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'POINT' AS pay_code
      INTO #pos720t
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- 상품권 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'GIFT' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- OKCashbag 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'OKCASH' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL 
    -- 주유할인권 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'COUPON' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- 모바일 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'M_COUPON' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price


    --select * from #pos720t 
    --return 

    INSERT INTO pos720t 
    (
        div_code, yyyymmdd, item_code, pay_code, sale_price, 
        sale_qty, sale_amt, vat_amt, total_amt, descr
    ) 
    SELECT div_code, yyyymmdd, item_code, pay_code, sale_price, 
           0, 0, 0, 0, ''
      FROM #pos720t AS A 
     WHERE NOT EXISTS (
                       SELECT 1 
                         FROM pos720t 
                        WHERE div_code = A.div_code 
                          AND yyyymmdd = A.yyyymmdd 
                          AND item_code = A.item_code 
                          AND sale_price = A.sale_price 
                          AND pay_code = A.pay_code 
                      )
    
    UPDATE A
       SET total_amt = CASE WHEN A.pay_code = 'POINT' THEN B.POINT_sale_amt -- 고객적립금
                            WHEN A.pay_code = 'GIFT' THEN B.GIFT_sale_amt -- 상품권 
                            WHEN A.pay_code = 'OKCASH' THEN B.OKCASH_sale_amt -- OKCashbag
                            WHEN A.pay_code = 'COUPON' THEN B.COUPON_sale_amt -- 주유소할인권
                            WHEN A.pay_code = 'M_COUPON' THEN B.M_COUPON_sale_amt -- 모바일
                            ELSE A.total_amt END 
          ,descr    = B.descr3 -- 적요
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )

    -- 수금현황 
    UPDATE A
       SET sale_amt     = B.sale_amt -- 금일매출액(조정) 
          ,in_amt       = B.in_amt -- 금일입금(보통예금) 
          ,charge_amt   = B.charge_amt -- 수수료 
          ,descr        = B.descr -- 적요
      FROM pos730t  AS A 
      JOIN #SS4     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.pay_code = A.pay_code 
                          AND B.pos_custom_code = A.pos_custom_code
                            )


    -- 기타상품 수불 및 재고현황 

    -- 세차현황 
    UPDATE A
       SET current_meter    = B.current_meter -- 금일계기
          ,flow_cnt          = B.flow_cnt -- 회전량
          ,charge_cnt       = B.charge_cnt -- 현금세차
          ,nocharge_cnt     = B.nocharge_cnt -- 무료세차
          ,test_cnt         = B.test_cnt -- 테스트
          ,sale_cnt         = B.sale_cnt -- 판매촉진비
      FROM pos750t  AS A 
      JOIN #SS5     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    
    -- 주유할인권불출 및 회수내역
    UPDATE A
       SET today_incoupon   = B.today_incoupon -- 당일회수
          ,refueling_amt    = B.refueling_amt -- 주유
          ,loan_amt         = B.loan_amt -- 대여금
          ,industry_amt     = B.industry_amt -- 공업사
          ,total_amt        = B.total_amt -- 계
          ,today_amt        = B.today_amt -- 금일잔액
      FROM pos740t  AS A 
      JOIN #SS6     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    

    -- 주유할인권 관리내역
    UPDATE A
       SET basis_bal        = B.basis_bal -- 당일회수
          ,issue_coupon     = B.issue_coupon -- 회수할인권
          ,destruc_coupon   = B.destruc_coupon -- 파기할인권
          ,today_bal        = B.today_bal -- 금일잔고
      FROM pos740t   AS A 
      JOIN #SS10     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    



    SELECT * FROM #SS1
    SELECT * FROM #SS2
    SELECT * FROM #SS3
    SELECT * FROM #SS4
    SELECT * FROM #SS5
    SELECT * FROM #SS6
    SELECT * FROM #SS7
    SELECT * FROM #SS8
    SELECT * FROM #SS10 
      
    RETURN  
    go

begin tran 

exec hye_SSLOilDailySalesSave @xmlDocument=N'<ROOT>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>02</cs_code>
    <cs_name>세종지부</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <TABLE_NAME>DataBlock7</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>10</cs_code>
    <cs_name>(자)연기운수</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>850351</ar_amt>
    <balance_amt>850351</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>12</cs_code>
    <cs_name>행복택시주식회사</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>1280524</ar_amt>
    <balance_amt>1280524</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>14</cs_code>
    <cs_name>웅진택시(자)</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>62062</ar_amt>
    <balance_amt>62062</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>17</cs_code>
    <cs_name>충남연기자활후견기관</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>18</cs_code>
    <cs_name>세종경찰서</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>19</cs_code>
    <cs_name>연기퓨리나축우특약</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>80791</ar_amt>
    <balance_amt>80791</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>21</cs_code>
    <cs_name>(주)한국기계</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>25</cs_code>
    <cs_name>세종재가노인지원센터</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>16421</ar_amt>
    <balance_amt>16421</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>26</cs_code>
    <cs_name>주식회사돌쇠출장세</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>24610</ar_amt>
    <balance_amt>24610</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>27</cs_code>
    <cs_name>주식회사 휴먼에듀피아</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>28</cs_code>
    <cs_name>오비에스 경인티브이 주식회사</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>30</cs_code>
    <cs_name>경석제화</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>42</cs_code>
    <cs_name>중부도시가스세종고객센터</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code />
    <cs_name>합계</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>2314759</ar_amt>
    <balance_amt>2314759</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>AR</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>2314759</sale_amt_pos>
    <sale_amt>2314759</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>2314759</balance_amt>
    <descr />
    <TABLE_NAME>DataBlock4</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>B_PRODUCT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>1</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr>2</descr>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>BLUE_POINT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>006</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>480805</sale_amt_pos>
    <sale_amt>480805</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>480805</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>008</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>59422</sale_amt_pos>
    <sale_amt>59422</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>59422</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>016</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1215634</sale_amt_pos>
    <sale_amt>1215634</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1215634</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>018</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>945046</sale_amt_pos>
    <sale_amt>945046</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>945046</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>026</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1352014</sale_amt_pos>
    <sale_amt>1352014</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1352014</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>027</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>707352</sale_amt_pos>
    <sale_amt>707352</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>707352</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>029</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1713093</sale_amt_pos>
    <sale_amt>1713093</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1713093</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>031</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>444896</sale_amt_pos>
    <sale_amt>444896</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>444896</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>047</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>257983</sale_amt_pos>
    <sale_amt>257983</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>257983</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD 소계</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>7176245</sale_amt_pos>
    <sale_amt>7176245</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>7176245</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>699000</sale_amt_pos>
    <sale_amt>699000</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>699000</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>COUPON</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>E_PRODUCT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>GIFT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>LOAN</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>M_COUPON</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>OKCASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>POINT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>WASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>합계</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>7176245</sale_amt_pos>
    <sale_amt>7176245</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>7176245</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>750</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>1</GIFT_sale_amt>
    <OKCASH_sale_amt>2</OKCASH_sale_amt>
    <COUPON_sale_amt>3</COUPON_sale_amt>
    <M_COUPON_sale_amt>4</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3>5</descr3>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>0</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3 />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>0</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3 />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr>5</descr>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>소계</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <tank_no>합계</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>1</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>1565.024</current_meter>
    <flow_qty>1</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>1565.024</net_sale_qty>
    <descr>7</descr>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>2</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>7162.445</current_meter>
    <flow_qty>7162.445</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>7162.445</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>3</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>2060.772</current_meter>
    <flow_qty>2060.772</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>2060.772</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>4</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>2798.399</current_meter>
    <flow_qty>2798.399</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>2798.399</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>소계</tank_no>
    <nozzle_no />
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>13586.64</current_meter>
    <flow_qty>12022.616</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>13586.64</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <tank_no>합계</tank_no>
    <nozzle_no />
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>13586.64</current_meter>
    <flow_qty>12022.616</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>13586.64</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730008

rollback 

