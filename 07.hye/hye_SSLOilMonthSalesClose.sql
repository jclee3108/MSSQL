IF OBJECT_ID('hye_SSLOilMonthSalesClose') IS NOT NULL 
    DROP PROC hye_SSLOilMonthSalesClose
GO 

-- v2016.10.31 
  
-- 주충판매월보마감_hye-마감 by 이재천 
CREATE PROC hye_SSLOilMonthSalesClose  
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
            @StdYM      NCHAR(6), 
            @p_div_code INT, 
            @p_yyyymm   NCHAR(6), 
            @POSType    NVARCHAR(20), 
            @IsClose    NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),
           @StdYM       = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )       
      WITH (
            BizUnit     INT,  
            StdYM       NCHAR(6)
           )
    
    DECLARE @v_bill_amt numeric(19,5),   -- 세금계산서 공급가액
            @v_bill_vat_amt numeric(19,5)    -- 세금계산서 부가세

    SELECT @p_div_code = @BizUnit 
    SELECT @p_yyyymm = @StdYM 


    
    IF EXISTS (SELECT 1 
                 FROM hye_TSLPOSSlipMonthRelation 
                WHERE CompanySeq = @CompanySeq 
                  AND BizUnit = @BizUnit 
                  AND StdYM = @StdYM 
              ) AND @WorkingTag = 'CC'
    BEGIN
            SELECT '전표가 반영되어 월마감을 취소 할 수 없습니다.' AS Result, 9999 AS Status, 9 AS IsClose
            RETURN 
    END 


    SELECT @IsClose = IsClose 
      FROM hye_TSLOilSalesIsClose 
     WHERE BizUnit      = @BizUnit
       AND StdYMDate    = @StdYM
       AND io_type      = 'O' -- 2011.04.11 추가


    IF @WorkingTag = 'C' AND ISNULL(@IsClose,'0') = '1' 
    BEGIN 
        SELECT '이미 일마감이 완료가 되어 있습니다.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 

    IF @WorkingTag = 'CC' AND ISNULL(@IsClose,'0') = '0' 
    BEGIN 
        SELECT '이미 일마감이 취소가 되어 있습니다.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 
    
    -- 1. 집계 전 선행과정 완료 여부 체크
   
    -- Process Category  
/*
   SD955 : 월말 사무소 계정처리
   SD956 : 월초 사무소 계정처리
*/


    DECLARE @t_PostingData TABLE 
    (
        seq               int identity,
        div_code          varchar(8)     not null,
        process_category  varchar(10)    not null,
        process_code      varchar(10)    not null,
        debit_credit      varchar(1)     not null, -- '1'차변, '2':대변
        accnt             varchar(8)     not null,
        posting_amt_i     numeric(19,5)  not null,
        supply_amt_i      numeric(19,5)  not null DEFAULT 0,-- 공급가
        bill_type         varchar(2)     not null DEFAULT ''
    )

    -- 2. 회계 데이터 집계
    -- 2.0 이전 데이터 정리
    DELETE FROM POS910T
    WHERE date_type     = 'MM'
      AND div_code      = @p_div_code
      AND process_date  = @p_yyyymm
    
    IF @WorkingTag = 'CC' 
    BEGIN 

        UPDATE A
            SET IsClose = '0', 
                CloseDate = ''
            FROM hye_TSLOilSalesIsClose AS A 
            WHERE A.CompanySeq = @CompanySeq 
            AND A.BizUnit = @BizUnit 
            AND A.StdYMDate = @StdYM 
            AND io_type = 'O' 

        SELECT '월마감취소가 완료 되습니다.' AS Result, 0 AS Status, 2 AS IsClose
        RETURN 
    END 

   -- POS 유형
   SELECT @POSType = CASE WHEN IsOil = '1' THEN 'SKPOS' ELSE 'JWPOS' END 
     FROM hye_TCOMPOSEnv
    WHERE CompanySeq = @CompanySeq 
      AND BizUnit = @BizUnit 



   -- SK POS일 경우
   IF (@POSType  = 'SKPOS')
   BEGIN
        -- 거래처 신규건 채번
        -- 사업장 번호나 주민 번호에서 '-' 없애기
        UPDATE skpMMTaxInvoice
           SET busirgst_no = REPLACE(ISNULL(busirgst_no,''),'-',''),
               jumin_no = REPLACE(ISNULL(jumin_no,''),'-','')
         WHERE div_code = @p_div_code
           AND close_ym   = @p_yyyymm
    
        SELECT a.close_date AS bill_date,  
               @p_div_code AS site_code, 
               a.supt_amt AS supply_amt,    
               a.vatt_amt AS tax_amt,   
               tott_amt     AS total_amt
          INTO #skpMMTaxInvoice
          FROM skpMMTaxInvoice a
         WHERE a.div_code = @p_div_code
           AND a.close_ym = @p_yyyymm
         ORDER BY a.close_date, a.cus_code


        SELECT @v_bill_amt      = ISNULL(x.supply_amt,0),
               @v_bill_vat_amt  = ISNULL(x.tax_amt,0)
          FROM ( 
                SELECT SUM(supply_amt) AS supply_amt,
                       SUM(tax_amt) AS tax_amt
                  FROM #skpMMTaxInvoice a
                 WHERE a.bill_date LIKE @p_yyyymm + '%'
                   AND a.site_code = @p_div_code
               ) x    
    END 
   -------------------------------------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------------------------------------
   -- 장위 POS일 경우
   ELSE IF (@POSType  = 'JWPOS')
   BEGIN

        -- 사업장 번호나 주민 번호에서 '-' 없애기
        UPDATE jwpMMTaxInvoice
           SET vehicle_reg_num = REPLACE(ISNULL(vehicle_reg_num,''),'-',''),
               social_no = REPLACE(ISNULL(social_no,''),'-','')
         WHERE div_code = @p_div_code
           AND yyyymm   = @p_yyyymm
        

        SELECT a.create_date AS bill_date,  
               @p_div_code AS site_code, 
               a.sale_amt AS supply_amt,    
               a.vat_amt AS tax_amt,   
               a.total_amt AS total_amt
          INTO #jwpMMTaxInvoice
          FROM jwpMMTaxInvoice a
         WHERE a.div_code        = @p_div_code
           AND a.create_date     LIKE @p_yyyymm + '%'
         GROUP BY a.create_date, a.cs_code, a.vehicle_reg_num , a.sale_amt,  a.vat_amt,  a.total_amt, a.item_code, a.seq
    
        SELECT @v_bill_amt      = ISNULL(x.supply_amt,0),
               @v_bill_vat_amt  = ISNULL(x.tax_amt,0)
          FROM ( 
                SELECT SUM(supply_amt) AS supply_amt,
                       SUM(tax_amt) AS tax_amt
                  FROM #jwpMMTaxInvoice a
                 WHERE a.bill_date LIKE @p_yyyymm + '%'
                   AND a.site_code = @p_div_code
               ) x    

   END



   -- SD952 : 부가세유형조정(현금<->계산서)
   -- 월중 과세-기타(현금매출)로 처리한 건들 중 월말 세금계산서 발행한 금액만큼에 대해
   -- 부가세 유형을 바꾸어 준다
   /*
                / (-)부가세예수금  ( 부가세유형 - 'AB':과세-기타)
                / (+)부가세예수금  ( 부가세유형 - '':기타계산서 발행건으로 별도 집계되기 때문에 전표상에는 부가세 증빙유형을 빈값으로 처리)

   */

    
    -- 금액 <> 0 인 경우 전표 처리
    IF (@v_bill_vat_amt <> 0)
    BEGIN

        -- (-)예수부가세
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i,   supply_amt_i, bill_type
        )
        SELECT @p_div_code,         'SD950',               'SD952',
               '2',
               ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD950' AND sys_code = 'SD952' AND case_code = 'SD952'),''),
               @v_bill_vat_amt * (-1) , @v_bill_amt * (-1) , 'AB'

        -- (+)예수부가세
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i,   supply_amt_i, bill_type
        )
        SELECT @p_div_code,         'SD950',               'SD952',
               '2',
               ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD950' AND sys_code = 'SD952' AND case_code = 'SD952'),''),
               @v_bill_vat_amt, @v_bill_amt, ''

    END
    
    --select * from @t_PostingData 
    --return 
    
    INSERT INTO POS910t
    (
        div_code,          date_type,     process_date,     process_category,
        process_code,      posting_seq,   debit_credit,     accnt,
        amount_i,          supply_amt,    bill_type, io_type
    )            
    SELECT div_code,          'MM',          @p_yyyymm,      process_category,      
           process_code,      seq,           debit_credit,     accnt,            
           posting_amt_i,     supply_amt_i,  bill_type, 'O'
      FROM @t_PostingData
     WHERE posting_amt_i != 0
        
    INSERT INTO hye_TSLOilSalesIsClose
    (
        CompanySeq, BizUnit, StdYMDate, IsClose, CloseDate, 
        io_type, LastUserSeq, LastDateTime, PgmSeq
    )
    SELECT @CompanySeq, @BizUnit, @StdYM, '0', '', 
            'O', @UserSeq, GETDATE(), @PgmSeq 
        WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsClose WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdYM)
        
    UPDATE A
        SET IsClose = '1' , 
            CloseDate = CONVERT(NCHAR(8),GETDATE(),112)
        FROM hye_TSLOilSalesIsClose AS A 
        WHERE A.CompanySeq = @CompanySeq 
        AND A.BizUnit = @BizUnit 
        AND A.StdYMDate = @StdYM
        AND A.io_type = 'O'

    SELECT '월마감이 완료 되었습니다.' AS Result, 0 AS Status, 1 AS IsClose
    
    RETURN  
GO
begin tran 
exec hye_SSLOilMonthSalesClose @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>902</BizUnit>
    <StdYM>201606</StdYM>
  </DataBlock15>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730140,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730044
rollback 