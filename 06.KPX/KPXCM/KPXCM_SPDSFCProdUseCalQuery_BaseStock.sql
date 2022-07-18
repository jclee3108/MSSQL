  
IF OBJECT_ID('KPXCM_SPDSFCProdUseCalQuery_BaseStock') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCProdUseCalQuery_BaseStock  
GO  
  
-- v2016.05.27 
  
-- 자가소비량계산-기초재고 by 이재천 
CREATE PROC KPXCM_SPDSFCProdUseCalQuery_BaseStock  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCProdUseCal (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPXCM_TPDSFCProdUseCal'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCProdUseCal')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'KPXCM_TPDSFCProdUseCal'    , -- 테이블명          
                  '#KPXCM_TPDSFCProdUseCal'    , -- 임시 테이블명          
                  'FactUnit,StdDateFr,SubItemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
    
    -- 입출고
    CREATE TABLE #GetInOutStock
    (
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
        STDStockQty     DECIMAL(19,5)
    )
    

    -- 상세입출고내역 
    CREATE TABLE #TLGInOutStock  
    (  
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
        InOutDetailKind INT 
    )  
    
    CREATE TABLE #GetInOutItem ( ItemSeq INT )
    INSERT INTO #GetInOutItem ( ItemSeq ) 
    SELECT SubItemSeq 
      FROM #KPXCM_TPDSFCProdUseCal
    
    
    DECLARE @BizUnit    INT, 
            @SrtDate    NCHAR(8), 
            @FactUnit   INT 

    SELECT @BizUnit = BizUnit FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND FactUnit = (SELECT TOP 1 FactUnit FROM #KPXCM_TPDSFCProdUseCal) 
    SELECT @SrtDate = (SELECT TOP 1 StdDateFr FROM #KPXCM_TPDSFCProdUseCal) 
    SELECT @FactUnit = (SELECT TOP 1 FactUnit FROM #KPXCM_TPDSFCProdUseCal) 
    

    -- 창고재고 가져오기
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                           @BizUnit      = @BizUnit,               -- 사업부문
                           @FactUnit     = @FactUnit,     -- 생산사업장
                           @DateFr       = @SrtDate,       -- 조회기간Fr
                           @DateTo       = @SrtDate,       -- 조회기간To
                           @WHSeq        = 0,        -- 창고지정
                           @SMWHKind     = 0,     -- 창고구분 
                           @CustSeq      = 0,      -- 수탁거래처
                           @IsTrustCust  = '0',  -- 수탁여부
                           @IsSubDisplay = '0', -- 기능창고 조회
                           @IsUnitQry    = '0',    -- 단위별 조회
                           @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                           @MngDeptSeq   = 0,
                           @IsUseDetail  = '0'
    
    -- 품목별 집계 
    SELECT ItemSeq, SUM(STDPrevQty) AS PrevQty 
      INTO #PrevQty 
      FROM #GetInOutStock 
     GROUP BY ItemSeq 
    
    
    
    -- TempTable 업데이트 
    UPDATE A 
       SET PrevQty = B.PrevQty 
      FROM #KPXCM_TPDSFCProdUseCal  AS A 
      JOIN #PrevQty                 AS B ON ( B.ItemSeq = A.SubItemSeq ) 

    -- 테이블에 있는 데이터 
    UPDATE A 
       SET PrevQty = B.PrevQty 
      FROM KPXCM_TPDSFCProdUseCal   AS A 
      JOIN #KPXCM_TPDSFCProdUseCal  AS B ON ( B.FactUnit = A.FactUnit 
                                          AND B.StdDateFr = A.StdDateFr 
                                          AND B.SubItemSeq = A.SubItemSeq 
                                            ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    -- 테이블에 없는 데이터 
    INSERT INTO KPXCM_TPDSFCProdUseCal 
    (
        CompanySeq, FactUnit, StdDateFr, SubItemSeq, PrevQty, 
        LastUserSeq, LastDateTime
    )
    SELECT @CompanySeq, FactUnit, A.StdDateFr, A.SubItemSeq, A.PrevQty, 
           @UserSeq, GETDATE() 
      FROM #KPXCM_TPDSFCProdUseCal AS A 
     WHERE NOT EXISTS (SELECT 1 
                        FROM KPXCM_TPDSFCProdUseCal 
                       WHERE CompanySeq = @CompanySeq 
                         AND FactUnit = A.FactUnit 
                         AND StdDateFr = A.StdDateFr 
                         AND SubItemSeq = A.SubItemSeq 
                      )
    
    SELECT * FROM #KPXCM_TPDSFCProdUseCal   
    
    RETURN  
    go
    begin tran
exec KPXCM_SPDSFCProdUseCalQuery_BaseStock @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>0</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SubItemSeq>283</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <SubItemSeq>293</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SubItemSeq>295</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SubItemSeq>300</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SubItemSeq>301</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>5</ROW_IDX>
    <SubItemSeq>305</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>6</ROW_IDX>
    <SubItemSeq>306</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>7</ROW_IDX>
    <SubItemSeq>308</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>8</ROW_IDX>
    <SubItemSeq>311</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <SubItemSeq>315</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <SubItemSeq>318</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <SubItemSeq>322</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>12</ROW_IDX>
    <SubItemSeq>335</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>13</ROW_IDX>
    <SubItemSeq>338</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>14</ROW_IDX>
    <SubItemSeq>339</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>15</ROW_IDX>
    <SubItemSeq>342</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>16</ROW_IDX>
    <SubItemSeq>353</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>17</ROW_IDX>
    <SubItemSeq>354</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>18</ROW_IDX>
    <SubItemSeq>355</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>19</ROW_IDX>
    <SubItemSeq>356</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>20</ROW_IDX>
    <SubItemSeq>358</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>21</ROW_IDX>
    <SubItemSeq>359</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>22</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>22</ROW_IDX>
    <SubItemSeq>361</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>23</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>23</ROW_IDX>
    <SubItemSeq>370</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>24</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>24</ROW_IDX>
    <SubItemSeq>1700</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>25</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>25</ROW_IDX>
    <SubItemSeq>393</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>26</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>26</ROW_IDX>
    <SubItemSeq>1706</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>27</IDX_NO>
    <DataSeq>28</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>27</ROW_IDX>
    <SubItemSeq>420</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>28</IDX_NO>
    <DataSeq>29</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>28</ROW_IDX>
    <SubItemSeq>425</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>29</IDX_NO>
    <DataSeq>30</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>29</ROW_IDX>
    <SubItemSeq>427</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>30</IDX_NO>
    <DataSeq>31</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>30</ROW_IDX>
    <SubItemSeq>428</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>31</IDX_NO>
    <DataSeq>32</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>31</ROW_IDX>
    <SubItemSeq>445</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>32</IDX_NO>
    <DataSeq>33</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>32</ROW_IDX>
    <SubItemSeq>756</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>33</IDX_NO>
    <DataSeq>34</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>33</ROW_IDX>
    <SubItemSeq>81793</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>34</IDX_NO>
    <DataSeq>35</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>34</ROW_IDX>
    <SubItemSeq>804</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>35</IDX_NO>
    <DataSeq>36</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>35</ROW_IDX>
    <SubItemSeq>81795</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>36</IDX_NO>
    <DataSeq>37</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>36</ROW_IDX>
    <SubItemSeq>771</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>1.00</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>37</IDX_NO>
    <DataSeq>38</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>37</ROW_IDX>
    <SubItemSeq>772</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>38</IDX_NO>
    <DataSeq>39</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>38</ROW_IDX>
    <SubItemSeq>773</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>39</IDX_NO>
    <DataSeq>40</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>39</ROW_IDX>
    <SubItemSeq>81798</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>40</IDX_NO>
    <DataSeq>41</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>40</ROW_IDX>
    <SubItemSeq>775</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>41</IDX_NO>
    <DataSeq>42</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>41</ROW_IDX>
    <SubItemSeq>81769</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>42</IDX_NO>
    <DataSeq>43</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>42</ROW_IDX>
    <SubItemSeq>81799</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>43</IDX_NO>
    <DataSeq>44</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>43</ROW_IDX>
    <SubItemSeq>777</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>44</IDX_NO>
    <DataSeq>45</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>44</ROW_IDX>
    <SubItemSeq>81800</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>45</IDX_NO>
    <DataSeq>46</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>45</ROW_IDX>
    <SubItemSeq>778</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>46</IDX_NO>
    <DataSeq>47</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>46</ROW_IDX>
    <SubItemSeq>81803</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>47</IDX_NO>
    <DataSeq>48</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>47</ROW_IDX>
    <SubItemSeq>781</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>48</IDX_NO>
    <DataSeq>49</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>48</ROW_IDX>
    <SubItemSeq>783</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>49</IDX_NO>
    <DataSeq>50</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>49</ROW_IDX>
    <SubItemSeq>784</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>50</IDX_NO>
    <DataSeq>51</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>50</ROW_IDX>
    <SubItemSeq>81806</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>51</IDX_NO>
    <DataSeq>52</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>51</ROW_IDX>
    <SubItemSeq>786</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>52</IDX_NO>
    <DataSeq>53</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>52</ROW_IDX>
    <SubItemSeq>795</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>53</IDX_NO>
    <DataSeq>54</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>53</ROW_IDX>
    <SubItemSeq>81807</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>54</IDX_NO>
    <DataSeq>55</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>54</ROW_IDX>
    <SubItemSeq>797</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>55</IDX_NO>
    <DataSeq>56</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>55</ROW_IDX>
    <SubItemSeq>787</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>56</IDX_NO>
    <DataSeq>57</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>56</ROW_IDX>
    <SubItemSeq>801</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>57</IDX_NO>
    <DataSeq>58</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>57</ROW_IDX>
    <SubItemSeq>81808</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>58</IDX_NO>
    <DataSeq>59</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>58</ROW_IDX>
    <SubItemSeq>81809</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>59</IDX_NO>
    <DataSeq>60</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>59</ROW_IDX>
    <SubItemSeq>791</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>60</IDX_NO>
    <DataSeq>61</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>60</ROW_IDX>
    <SubItemSeq>89</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>61</IDX_NO>
    <DataSeq>62</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>61</ROW_IDX>
    <SubItemSeq>87</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>62</IDX_NO>
    <DataSeq>63</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>62</ROW_IDX>
    <SubItemSeq>80</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>63</IDX_NO>
    <DataSeq>64</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>63</ROW_IDX>
    <SubItemSeq>81</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>64</IDX_NO>
    <DataSeq>65</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>64</ROW_IDX>
    <SubItemSeq>82</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>65</IDX_NO>
    <DataSeq>66</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>65</ROW_IDX>
    <SubItemSeq>97</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>66</IDX_NO>
    <DataSeq>67</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>66</ROW_IDX>
    <SubItemSeq>99</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>67</IDX_NO>
    <DataSeq>68</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>67</ROW_IDX>
    <SubItemSeq>100</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>68</IDX_NO>
    <DataSeq>69</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>68</ROW_IDX>
    <SubItemSeq>102</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>69</IDX_NO>
    <DataSeq>70</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>69</ROW_IDX>
    <SubItemSeq>103</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>70</IDX_NO>
    <DataSeq>71</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>70</ROW_IDX>
    <SubItemSeq>104</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>71</IDX_NO>
    <DataSeq>72</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>71</ROW_IDX>
    <SubItemSeq>105</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>72</IDX_NO>
    <DataSeq>73</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>72</ROW_IDX>
    <SubItemSeq>106</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>73</IDX_NO>
    <DataSeq>74</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>73</ROW_IDX>
    <SubItemSeq>90</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>74</IDX_NO>
    <DataSeq>75</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>74</ROW_IDX>
    <SubItemSeq>108</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>75</IDX_NO>
    <DataSeq>76</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>75</ROW_IDX>
    <SubItemSeq>107</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>76</IDX_NO>
    <DataSeq>77</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>76</ROW_IDX>
    <SubItemSeq>109</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>77</IDX_NO>
    <DataSeq>78</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>77</ROW_IDX>
    <SubItemSeq>110</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>78</IDX_NO>
    <DataSeq>79</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>78</ROW_IDX>
    <SubItemSeq>112</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>79</IDX_NO>
    <DataSeq>80</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>79</ROW_IDX>
    <SubItemSeq>113</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>80</IDX_NO>
    <DataSeq>81</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>80</ROW_IDX>
    <SubItemSeq>115</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>81</IDX_NO>
    <DataSeq>82</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>81</ROW_IDX>
    <SubItemSeq>116</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>82</IDX_NO>
    <DataSeq>83</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>82</ROW_IDX>
    <SubItemSeq>119</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>83</IDX_NO>
    <DataSeq>84</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>83</ROW_IDX>
    <SubItemSeq>181</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>84</IDX_NO>
    <DataSeq>85</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>84</ROW_IDX>
    <SubItemSeq>121</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>85</IDX_NO>
    <DataSeq>86</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>85</ROW_IDX>
    <SubItemSeq>125</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>86</IDX_NO>
    <DataSeq>87</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>86</ROW_IDX>
    <SubItemSeq>131</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>87</IDX_NO>
    <DataSeq>88</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>87</ROW_IDX>
    <SubItemSeq>133</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>88</IDX_NO>
    <DataSeq>89</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>88</ROW_IDX>
    <SubItemSeq>134</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>89</IDX_NO>
    <DataSeq>90</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>89</ROW_IDX>
    <SubItemSeq>1512</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>90</IDX_NO>
    <DataSeq>91</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>90</ROW_IDX>
    <SubItemSeq>83400</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>91</IDX_NO>
    <DataSeq>92</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>91</ROW_IDX>
    <SubItemSeq>146</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>92</IDX_NO>
    <DataSeq>93</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>92</ROW_IDX>
    <SubItemSeq>149</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>93</IDX_NO>
    <DataSeq>94</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>93</ROW_IDX>
    <SubItemSeq>150</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>94</IDX_NO>
    <DataSeq>95</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>94</ROW_IDX>
    <SubItemSeq>193</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>95</IDX_NO>
    <DataSeq>96</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>95</ROW_IDX>
    <SubItemSeq>194</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>96</IDX_NO>
    <DataSeq>97</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>96</ROW_IDX>
    <SubItemSeq>159</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>97</IDX_NO>
    <DataSeq>98</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>97</ROW_IDX>
    <SubItemSeq>154</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>98</IDX_NO>
    <DataSeq>99</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>98</ROW_IDX>
    <SubItemSeq>1521</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>99</IDX_NO>
    <DataSeq>100</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>99</ROW_IDX>
    <SubItemSeq>165</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>100</IDX_NO>
    <DataSeq>101</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>100</ROW_IDX>
    <SubItemSeq>153</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>101</IDX_NO>
    <DataSeq>102</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>101</ROW_IDX>
    <SubItemSeq>169</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>102</IDX_NO>
    <DataSeq>103</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>102</ROW_IDX>
    <SubItemSeq>170</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>103</IDX_NO>
    <DataSeq>104</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>103</ROW_IDX>
    <SubItemSeq>182</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>104</IDX_NO>
    <DataSeq>105</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>104</ROW_IDX>
    <SubItemSeq>179</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>105</IDX_NO>
    <DataSeq>106</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>105</ROW_IDX>
    <SubItemSeq>180</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>106</IDX_NO>
    <DataSeq>107</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>106</ROW_IDX>
    <SubItemSeq>186</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>107</IDX_NO>
    <DataSeq>108</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>107</ROW_IDX>
    <SubItemSeq>187</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>108</IDX_NO>
    <DataSeq>109</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>108</ROW_IDX>
    <SubItemSeq>77</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>109</IDX_NO>
    <DataSeq>110</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>109</ROW_IDX>
    <SubItemSeq>195</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>110</IDX_NO>
    <DataSeq>111</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>110</ROW_IDX>
    <SubItemSeq>1515</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>111</IDX_NO>
    <DataSeq>112</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>111</ROW_IDX>
    <SubItemSeq>128</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>112</IDX_NO>
    <DataSeq>113</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>112</ROW_IDX>
    <SubItemSeq>199</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>113</IDX_NO>
    <DataSeq>114</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>113</ROW_IDX>
    <SubItemSeq>200</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>114</IDX_NO>
    <DataSeq>115</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>114</ROW_IDX>
    <SubItemSeq>201</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>115</IDX_NO>
    <DataSeq>116</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>115</ROW_IDX>
    <SubItemSeq>205</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>116</IDX_NO>
    <DataSeq>117</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>116</ROW_IDX>
    <SubItemSeq>126</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>117</IDX_NO>
    <DataSeq>118</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>117</ROW_IDX>
    <SubItemSeq>209</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>118</IDX_NO>
    <DataSeq>119</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>118</ROW_IDX>
    <SubItemSeq>210</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>119</IDX_NO>
    <DataSeq>120</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>119</ROW_IDX>
    <SubItemSeq>211</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>120</IDX_NO>
    <DataSeq>121</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>120</ROW_IDX>
    <SubItemSeq>212</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>121</IDX_NO>
    <DataSeq>122</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>121</ROW_IDX>
    <SubItemSeq>213</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>122</IDX_NO>
    <DataSeq>123</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>122</ROW_IDX>
    <SubItemSeq>81661</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>123</IDX_NO>
    <DataSeq>124</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>123</ROW_IDX>
    <SubItemSeq>81662</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>124</IDX_NO>
    <DataSeq>125</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>124</ROW_IDX>
    <SubItemSeq>1539</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>125</IDX_NO>
    <DataSeq>126</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>125</ROW_IDX>
    <SubItemSeq>215</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>126</IDX_NO>
    <DataSeq>127</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>126</ROW_IDX>
    <SubItemSeq>216</SubItemSeq>
    <FactUnit>3</FactUnit>
    <StdDateFr>20160601</StdDateFr>
    <PrevQty>0</PrevQty>
    <StdDateTo>20160608</StdDateTo>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031135,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025701
rollback 