
IF OBJECT_ID('KPX_SPUDelvMROIF') IS NOT NULL 
    DROP PROC KPX_SPUDelvMROIF
GO 

-- v2015.01.05 

-- 구매납품 생성(MRO 연동) by이재천
 CREATE PROC KPX_SPUDelvMROIF
    
    --@CompanySeq     INT 
    
    
     --@xmlDocument    NVARCHAR(MAX),        
     --@xmlFlags       INT = 0,        
     --@ServiceSeq     INT = 0,        
     --@WorkingTag     NVARCHAR(10)= '',        
     --@CompanySeq     INT = 1,        
     --@LanguageSeq    INT = 1,        
     --@UserSeq        INT = 0,        
     --@PgmSeq         INT = 0    
  AS    
     DECLARE @VatAccSeq         INT,
             @QCAutoIn          NCHAR(1),
             @DelvInSeq         INT,
             @DelvInSerl        INT,
             @DelvInNo          NCHAR(12),
             @SMImpType         INT,
             @VATEnvSeq         INT,
             @AmtEnvSeq         INT,
             @DomPointEnvSeq    INT,
             @DataSeq           INT, 
             @BaseDate          NCHAR(8), 
             @DelvNo            NVARCHAR(200), 
             @Count             INT, 
             @UserSeq           INT 
    
    SELECT @UserSeq = 1 
    
    -- 서비스 마스타 등록 생성
    --CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)    
    --EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelvIn'    
    --IF @@ERROR <> 0 RETURN    
    -- CREATE TABLE #TPUDelvInItem (WorkingTag NCHAR(1) NULL)  
    --EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2608, 'DataBlock2', '#TPUDelvInItem'     
    --IF @@ERROR <> 0 RETURN    
    
    DECLARE @DelvSeq    INT, 
            @CompanySeq INT 
             
    
    
    ------------------------------------------------------------------------------------------------------
    -- 구매납품 마스터, 세부사항 담기  
    ------------------------------------------------------------------------------------------------------
    
    CREATE TABLE #TPUDelv_Sub
    (
        IFSerl          INT, 
        CompanySeq      INT, 
        DelvSeq         INT, 
        BizUnit         INT, 
        DelvNo          NVARCHAR(100), 
        SMImpType       INT, 
        DelvDate        NCHAR(8), 
        DeptSeq         INT, 
        EmpSeq          INT, 
        CustSeq         INT, 
        CurrSeq         INT, 
        ExRate          DECIMAL(19,5), 
        SMDelvType      INT, 
        Remark          NVARCHAR(2000), 
        SMStkType       INT, 
        DataSeq         INT 
    )
    
    INSERT INTO #TPUDelv_Sub
    ( 
        IFSerl    ,        CompanySeq,        DelvSeq   ,        BizUnit   ,        DelvNo    ,        
        SMImpType ,        DelvDate  ,        DeptSeq   ,        EmpSeq    ,        CustSeq   ,        
        CurrSeq   ,        ExRate    ,        SMDelvType,        Remark    ,        SMStkType , 
        DataSeq   
    )
    SELECT A.Serl, A.CompanySeq, 0, A.BizUnit, '', 
           8008001, A.DelvDate, D.DeptSeq, C.EmpSeq, E.EnvValue, 
           ISNULL(B.EnvValue,0), 1, 6034001, 'MRO 입고번호 ' + A.GRNO , 6033001, 
           ROW_NUMBER() OVER(PARTITION BY A.CompanySeq ORDER BY A.CompanySeq, A.Serl)
      FROM KPX_TPUDelvItem_IF   AS A 
      LEFT OUTER JOIN _TCOMEnv  AS B ON ( B.CompanySeq = A.CompanySeq AND B.EnvSeq = 13 ) 
      LEFT OUTER JOIN _TDAEmpIn AS C ON ( C.CompanySeq = A.CompanySeq AND C.EmpID = A.EmpID ) 
      LEFT OUTER JOIN _THRAdmOrdEmp AS D ON ( D.CompanySeq = A.CompanySeq
                                         AND D.EmpSeq = C.EmpSeq
                                         AND D.OrdDate <=  C.RetireDate -- 퇴직일자 이전발령기준
                                         AND D.OrdDate      <= CASE WHEN ISNULL(C.RetireDate, '') > CONVERT(NCHAR(8), GETDATE(), 112)
                                                                                                                   THEN CONVERT(NCHAR(8), GETDATE(), 112)
                                                                                                                   ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(C.RetireDate, '')), 112) END
                                         AND D.OrdEndDate   >= CASE WHEN ISNULL(C.RetireDate, '') > CONVERT(NCHAR(8), GETDATE(), 112)
                                                                                                                   THEN CONVERT(NCHAR(8), GETDATE(), 112)
                                                                                                                   ELSE CONVERT(NCHAR(8), DATEADD(dd, -1, ISNULL(C.RetireDate, '')), 112) END
                                            ) 
      LEFT OUTER JOIN KPX_TCOMEnvItem AS E ON ( E.CompanySeq = A.CompanySeq AND E.EnvSeq = 20 AND E.EnvSerl = 1 ) 
     WHERE A.STATUS = 'C' 
       AND A.ItemSeq IS NOT NULL 
       AND A.ProcYN = '0' 
     ORDER BY A.CompanySeq, A.Serl 
    

    CREATE TABLE #Company
    (
        IDX_NO      INT IDENTITY, 
        CompanySeq  INT 
    )
    INSERT INTO #Company
    SELECT DISTINCT CompanySeq
      FROM #TPUDelv_Sub 
     ORDER BY CompanySeq 

--    SELECT * FROm #Company 
    
--return 
    
    
    CREATE TABLE #TPUDelv
    (
        IFSerl          INT, 
        CompanySeq      INT, 
        DelvSeq         INT, 
        BizUnit         INT, 
        DelvNo          NVARCHAR(100), 
        SMImpType       INT, 
        DelvDate        NCHAR(8), 
        DeptSeq         INT, 
        EmpSeq          INT, 
        CustSeq         INT, 
        CurrSeq         INT, 
        ExRate          DECIMAL(19,5), 
        SMDelvType      INT, 
        Remark          NVARCHAR(2000), 
        SMStkType       INT, 
        DataSeq         INT 
    )
    
    CREATE TABLE #TPUDelvItem 
    (
        IFSerl      INT, 
        CompanySeq  INT, 
        DelvSeq     INT, 
        DelvSerl    INT, 
        ItemSeq     INT, 
        UnitSeq     INT, 
        Price       DECIMAL(19,5), 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        VAT         DECIMAL(19,5), 
        SMQcType    INT, 
        WHSeq       INT, 
        DataSeq     INT, 
        Remark      NVARCHAR(100)
    ) 
    
    
    CREATE TABLE #TPUDelvIn 
    (   
        WorkingTag nchar(1) NULL   ,    
        IDX_NO int NULL, 
        DataSeq int NULL, 
        Selected int NULL   ,    
        MessageType int NULL   ,    
        Status int NULL   ,    
        Result nvarchar(255) NULL   ,    
        ROW_IDX int NULL   ,    
        IsChangedMst nchar(1) NULL   ,    
        DelvSeq int NULL   ,    
        DelvSerl int NULL   ,    
        DelvInSeq int NULL   ,    
        DelvInSerl int NULL   ,    
        SourceType int NULL   ,    
        DeptSeq int NULL   ,    
        EmpSeq int NULL   ,    
        Qty decimal(19,5) NULL   ,    
        QCSeq int NULL   ,    
        DelvInDate nchar(8) NULL   ,    
        DelvInNo nvarchar(20) NULL   ,    
        STDQty decimal(19,5) NULL   ,    
        SMPriceType int NULL   ,    
        SMPriceTypeName nvarchar(200) NULL, 
        IFSerl INT NULL   
    ) 
    
    CREATE TABLE #TPUDelvInItem 
    (   
        WorkingTag nchar(1) NULL   ,   
        IDX_NO int NULL,
        DataSeq int NULL   ,   
        Selected int NULL   ,   
        MessageType int NULL   , 
        Status int NULL   ,   
        Result nvarchar(255) NULL   ,    
        ROW_IDX int NULL   ,  
        IsChangedMst nchar(1) NULL   ,  
        DelvInSeq int NULL   ,   
        DelvInSerl int NULL   ,  
        SMImpType int NULL   ,    
        ItemName nvarchar(200) NULL   ,   
        ItemNo nvarchar(200) NULL   ,   
        Spec nvarchar(200) NULL   ,   
        UnitName nvarchar(200) NULL   ,   
        CurrSeq int NULL   ,   
        CurrName nvarchar(200) NULL   ,   
        ExRate decimal(19,5) NULL   ,   
        Price decimal(19,5) NULL   ,    
        Qty decimal(19,5) NULL   ,   
        CurAmt decimal(19,5) NULL   ,   
        DomPrice decimal(19,5) NULL   ,  
        DomAmt decimal(19,5) NULL   ,   
        WHSeq int NULL   ,   
        WHName nvarchar(200) NULL   , 
        DelvCustName nvarchar(200) NULL   ,  
        DelvCustSeq int NULL   ,    
        SalesCustName nvarchar(200) NULL   ,   
        SalesCustSeq int NULL   , 
        STDUnitName nvarchar(200) NULL   ,  
        STDUnitQty decimal(19,5) NULL   ,   
        StdConvQty decimal(19,5) NULL   ,  
        STDUnitSeq int NULL   ,   
        SMPayType int NULL   ,  
        SMPayTypeName nvarchar(200) NULL   , 
        SMDelvType int NULL   ,   
        SMDelvTypeName nvarchar(200) NULL   ,  
        SMStkType int NULL   ,   
        SMStkTypeName nvarchar(200) NULL   ,   
        ItemSeq int NULL   ,    
        UnitSeq int NULL   ,    
        LotNo nvarchar(30) NULL   ,    
        FromSerial nvarchar(20) NULL   ,    
        ToSerial nvarchar(20) NULL   ,    
        Remark nvarchar(100) NULL   ,   
        LotMngYN nchar(1) NULL   ,   
        AccSeq int NULL   ,   
        AccName nvarchar(200) NULL   ,  
        AntiAccSeq int NULL   ,  
        AntiAccName nvarchar(200) NULL   , 
        IsFiction nchar(1) NULL   ,  
        FicRateNum decimal(19,5) NULL   , 
        FicRateDen decimal(19,5) NULL   ,
        EvidSeq int NULL   ,  
        EvidName nvarchar(200) NULL   ,   
        IsReturn nchar(1) NULL   ,  
        SlipSeq int NULL   ,    
        BuyingAccSeq int NULL   ,  
        CustName nvarchar(200) NULL   , 
        CustSeq int NULL   ,    
        BizUnit int NULL   ,   
        BizUnitName nvarchar(200) NULL   ,   
        FactUnit int NULL   ,   
        FactUnitName nvarchar(200) NULL   ,   
        DelvInDate nchar(8) NULL   ,   
        CurVAT decimal(19,5) NULL   ,    
        EmpName nvarchar(200) NULL   ,   
        DomVAT decimal(19,5) NULL   ,   
        EmpSeq int NULL   ,  
        DeptSeq int NULL   ,   
        TotCurAmt decimal(19,5) NULL   ,  
        DeptName nvarchar(200) NULL   ,   
        TotDomAmt decimal(19,5) NULL   ,    
        SourceType nchar(1) NULL   ,  
        SourceSeq int NULL   ,    
        SourceSerl int NULL   ,    
        SourceTypeName nvarchar(200) NULL   ,   
        VatRate decimal(19,5) NULL   ,   
        IsPurVat nchar(1) NULL   ,    
        PJTName nvarchar(60) NULL   ,    
        PJTNo nvarchar(40) NULL   ,    
        PJTSeq int NULL   ,   
        WBSName nvarchar(80) NULL   ,    
        WBSSeq int NULL   ,   
        TotAmt decimal(19,5) NULL   ,  
        VATAccSeq int NULL   ,   
        VATAccName decimal(19,5) NULL   , 
        IsVAT nchar(1) NULL   ,   
        STDQty decimal(19,5) NULL   ,   
        FromSeq int NULL   ,   
        FromSerl int NULL   ,   
        ItemSeqOLD int NULL   ,    
        LotNoOLD nvarchar(50) NULL   ,  
        FromQty decimal(19,5) NULL   ,   
        SMPriceType int NULL   ,   
        SMPriceTypeName nvarchar(200) NULL   
    ) 
    
    CREATE TABLE #TPUDelvIn_Result 
    (   
        WorkingTag nchar(1) NULL   ,    
        IDX_NO int NULL, 
        DataSeq int NULL, 
        Selected int NULL   ,    
        MessageType int NULL   ,    
        Status int NULL   ,    
        Result nvarchar(255) NULL   ,    
        ROW_IDX int NULL   ,    
        IsChangedMst nchar(1) NULL   ,    
        DelvSeq int NULL   ,    
        DelvSerl int NULL   ,    
        DelvInSeq int NULL   ,    
        DelvInSerl int NULL   ,    
        SourceType int NULL   ,    
        DeptSeq int NULL   ,    
        EmpSeq int NULL   ,    
        Qty decimal(19,5) NULL   ,    
        QCSeq int NULL   ,    
        DelvInDate nchar(8) NULL   ,    
        DelvInNo nvarchar(20) NULL   ,    
        STDQty decimal(19,5) NULL   ,    
        SMPriceType int NULL   ,    
        SMPriceTypeName nvarchar(200) NULL, 
        IFSerl INT NULL   
    ) 
    
    -- 진행관련 테이블
    CREATE TABLE #SCOMSourceDailyBatch 
    (          
        ToTableName   NVARCHAR(100),          
        ToSeq         INT,          
        ToSerl        INT,          
        ToSubSerl     INT,          
        FromTableName NVARCHAR(100),          
        FromSeq     INT,          
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
    -- 재고 반영
    Create Table #TLGInOutMinusCheck  
    (    
        WHSeq           INT,  
        FunctionWHSeq   INT,  
        ItemSeq         INT
    )  
    CREATE TABLE #TLGInOutDailyBatch
    (   
        InOutType    INT     ,
        InOutSeq     INT     ,
        Result       NVARCHAR(250),
        MessageType  INT     ,
        Status       INT
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
    Create Table #TLGInOutMonthLot      
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
    CREATE TABLE #TMP_Item_Prog
    (
        IDX_NO      INT,
        OrderSeq    INT,
        OrderSerl   INT,
        Qty         DECIMAL(19, 5),
        STDQty      DECIMAL(19, 5)
    ) 
    -- 진행 추적관련 테이블
    CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
    
    CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))            
    
    CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
    
    CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))

    DECLARE @Cnt INT 
    
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        TRUNCATE TABLE #TPUDelv 
        
        INSERT INTO #TPUDelv 
        SELECT * 
          FROM #TPUDelv_Sub 
         WHERE CompanySeq = (SELECT CompanySeq FROM #Company WHERE IDX_NO = @Cnt) 
        

        SELECT @CompanySeq = (SELECT CompanySeq FROM #Company WHERE IDX_NO = @Cnt) 
        
        SELECT @DataSeq = 0          
            
        WHILE ( 1 = 1 )           
        BEGIN          
            SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = DelvDate          
              FROM #TPUDelv          
             WHERE DataSeq > @DataSeq          
             ORDER BY DataSeq          
                  
            IF @@ROWCOUNT = 0 BREAK       
      
            -- DelvNo 생성          
            EXEC _SCOMCreateNo 'PU', '_TPUDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT          
              
          
            SELECT @count = COUNT(*)            
              FROM #TPUDelv            
                  
            IF @count > 0          
            BEGIN       
                EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TPUDelv', 'DelvSeq', 1      
            END          
              
            UPDATE #TPUDelv          
               SET DelvSeq = @DelvSeq + 1,--DataSeq, :: 루프로 한건씩 처리되므로 일괄처리시 사용하면 1씩 증가되어야 하므로 20120828 by 천경민  
                   DelvNo  = @DelvNo          
             WHERE DataSeq = @DataSeq          
        END          
          
        UPDATE #TPUDelv  
           SET SMImpType = 8008001  
         WHERE ISNULL(SMIMPType,0) = 0  
        
        
        --DECLARE @WHSeq INT 
        --SELECT @WHSeq = ISNULL((SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1 ),0)
        TRUNCATE TABLE #TPUDelvItem 
        --CREATE TABLE #TPUDelvItem 
        --(
        --    IFSerl      INT, 
        --    CompanySeq  INT, 
        --    DelvSeq     INT, 
        --    DelvSerl    INT, 
        --    ItemSeq     INT, 
        --    UnitSeq     INT, 
        --    Price       DECIMAL(19,5), 
        --    Qty         DECIMAL(19,5), 
        --    Amt         DECIMAL(19,5), 
        --    VAT         DECIMAL(19,5), 
        --    SMQcType    INT, 
        --    WHSeq       INT, 
        --    DataSeq     INT 
        --) 
        
        
        
        INSERT INTO #TPUDelvItem 
        (
            IFSerl, CompanySeq, DelvSeq, DelvSerl, ItemSeq, 
            UnitSeq, Price, Qty, Amt, VAT, 
            SMQcType, WHSeq, DataSeq, Remark
        )
        SELECT A.Serl, @CompanySeq, 0, 1, A.ItemSeq, 
               B.UnitSeq, A.Price, A.DelvQty, A.Price * A.DelvQty, ISNULL((A.Price * A.DelvQty) / CONVERT(INT,REPLACE(D.MinorName,'%','')),0), 
               6035001, F.WHSeq, E.DataSeq, 'MRO 입고번호 ' + A.GRNO
               
          FROM KPX_TPUDelvItem_IF       AS A 
          LEFT OUTER JOIN _TDAItem      AS B WITH(NOLOCK) ON ( B.CompanySeq = @COmpanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemSales AS C WITH(NOLOCK) ON ( C.CompanySeq = @COmpanySeq AND C.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDASMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @COmpanySeq AND D.MinorSeq = C.SMVatType ) 
          LEFT OUTER JOIN #TPUDelv      AS E              ON ( E.IFSerl = A.Serl ) 
          OUTER APPLY (SELECT TOP 1 Z.WHSeq 
                         FROM _TDAWHItem AS Z 
                         JOIN _TDAWH     AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.BizUnit = A.BizUnit AND Y.WHSeq = Z.WHSeq ) 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.ItemSeq = A.ItemSeq 
                      ) AS F 
         WHERE A.STATUS = 'C' 
           AND A.ItemSeq IS NOT NULL 
           AND A.ProcYN = '0' 
           AND A.CompanySeq = @CompanySeq 
        
        
        
        UPDATE A 
           SET DelvSeq = B.DelvSeq 
          FROM #TPUDelvItem AS A 
          JOIN #TPUDelv     AS B ON ( A.IFSerl = B.IFSerl ) 
        
        ------------------------------------------------------------------------------------------------------
        -- 구매납품 마스터, 세부사항 담기, END 
        ------------------------------------------------------------------------------------------------------
        
        ------------------------------------------------------------------------------------------------------
        -- 데이터 저장 
        ------------------------------------------------------------------------------------------------------
        INSERT INTO _TPUDelv
        (
            CompanySeq,     DelvSeq,        BizUnit,        DelvNo,         SMImpType,    
            DelvDate,       DeptSeq,        EmpSeq,         CustSeq,        CurrSeq,    
            ExRate,         SMDelvType,     Remark,         IsPJT,          SMStkType,    
            IsReturn,       LastUserSeq,    LastDateTime,    DelvMngNo
        )
        SELECT CompanySeq,  DelvSeq,        BizUnit,        DelvNo,         SMImpType,    
               DelvDate,    DeptSeq,        EmpSeq,         CustSeq,        CurrSeq,    
               ExRate,      SMDelvType,     Remark,         '0',            SMStkType,    
               '0',         @UserSeq,       GETDATE(),      ''   
          FROM #TPUDelv
        
    
        INSERT INTO _TPUDelvItem 
        (
            CompanySeq,         DelvSeq,        DelvSerl,       ItemSeq,        UnitSeq,        
            Price,              Qty,            CurAmt,         CurVAT,         DomPrice,        
            DomAmt,             DomVAT,         IsVAT,          StdUnitSeq,     StdUnitQty,        
            SMQcType,           QcEmpSeq,       QcDate,         QcQty,          QcCurAmt,        
            WHSeq,              LOTNo,          FromSerial,     ToSerial,       SalesCustSeq,        
            DelvCustSeq,        PJTSeq,         WBSSeq,         UMDelayType,    Remark,        
            IsReturn,           LastUserSeq,    LastDateTime,   MakerSeq,       SourceSeq,        
            SourceSerl,         BadQty,         ProgFromSeq,    ProgFromSerl,   ProgFromSubSerl,        
            ProgFromTableSeq,   SourceType,     FicRateNum,     FicRateDen,     EvidSeq,        
            IsFiction,          OriCurAmt,      OriCurVAT,      OriDomAmt,      OriDomVAT,        
            SupplyAmt,          SupplyVAT,      Memo1,          Memo2,          Memo3,        
            Memo4,              Memo5,          Memo6,          Memo7,          Memo8,        
            SMPriceType
        )    
        SELECT CompanySeq,          DelvSeq,        DelvSerl,       ItemSeq,        UnitSeq,        
               Price,               Qty,            Amt,            VAT,            Price,
               Amt,                 VAT,            '0',            UnitSeq,        Qty,        
               SMQcType,            NULL,           '',             0,              0,        
               WHSeq,               '',             '',             '',             0,        
               0,                   0,              0,              NULL,           Remark,        
               NULL,                @UserSeq,       GETDATE(),      0,              NULL, 
               NULL,                NULL,           NULL,           NULL,           NULL,        
               NULL,                NULL,           0,              0,              0,        
               '0',                 NULL,           NULL,           NULL,           NULL,        
               Amt,                 0,              '',             '',             '',        
               '',                  '',             '',             0,              0,        
               0
          FROM #TPUDelvItem 
        
        ------------------------------------------------------------------------------------------------------
        -- 데이터 저장, END 
        ------------------------------------------------------------------------------------------------------
        TRUNCATE TABLE #TPUDelvIn 
        --CREATE TABLE #TPUDelvIn 
        --(   
        --    WorkingTag nchar(1) NULL   ,    
        --    IDX_NO int NULL, 
        --    DataSeq int NULL, 
        --    Selected int NULL   ,    
        --    MessageType int NULL   ,    
        --    Status int NULL   ,    
        --    Result nvarchar(255) NULL   ,    
        --    ROW_IDX int NULL   ,    
        --    IsChangedMst nchar(1) NULL   ,    
        --    DelvSeq int NULL   ,    
        --    DelvSerl int NULL   ,    
        --    DelvInSeq int NULL   ,    
        --    DelvInSerl int NULL   ,    
        --    SourceType int NULL   ,    
        --    DeptSeq int NULL   ,    
        --    EmpSeq int NULL   ,    
        --    Qty decimal(19,5) NULL   ,    
        --    QCSeq int NULL   ,    
        --    DelvInDate nchar(8) NULL   ,    
        --    DelvInNo nvarchar(20) NULL   ,    
        --    STDQty decimal(19,5) NULL   ,    
        --    SMPriceType int NULL   ,    
        --    SMPriceTypeName nvarchar(200) NULL, 
        --    IFSerl INT NULL   
        --) 
        TRUNCATE TABLE #TPUDelvInItem 
        --CREATE TABLE #TPUDelvInItem 
        --(   
        --    WorkingTag nchar(1) NULL   ,   
        --    IDX_NO int NULL,
        --    DataSeq int NULL   ,   
        --    Selected int NULL   ,   
        --    MessageType int NULL   , 
        --    Status int NULL   ,   
        --    Result nvarchar(255) NULL   ,    
        --    ROW_IDX int NULL   ,  
        --    IsChangedMst nchar(1) NULL   ,  
        --    DelvInSeq int NULL   ,   
        --    DelvInSerl int NULL   ,  
        --    SMImpType int NULL   ,    
        --    ItemName nvarchar(200) NULL   ,   
        --    ItemNo nvarchar(200) NULL   ,   
        --    Spec nvarchar(200) NULL   ,   
        --    UnitName nvarchar(200) NULL   ,   
        --    CurrSeq int NULL   ,   
        --    CurrName nvarchar(200) NULL   ,   
        --    ExRate decimal(19,5) NULL   ,   
        --    Price decimal(19,5) NULL   ,    
        --    Qty decimal(19,5) NULL   ,   
        --    CurAmt decimal(19,5) NULL   ,   
        --    DomPrice decimal(19,5) NULL   ,  
        --    DomAmt decimal(19,5) NULL   ,   
        --    WHSeq int NULL   ,   
        --    WHName nvarchar(200) NULL   , 
        --    DelvCustName nvarchar(200) NULL   ,  
        --    DelvCustSeq int NULL   ,    
        --    SalesCustName nvarchar(200) NULL   ,   
        --    SalesCustSeq int NULL   , 
        --    STDUnitName nvarchar(200) NULL   ,  
        --    STDUnitQty decimal(19,5) NULL   ,   
        --    StdConvQty decimal(19,5) NULL   ,  
        --    STDUnitSeq int NULL   ,   
        --    SMPayType int NULL   ,  
        --    SMPayTypeName nvarchar(200) NULL   , 
        --    SMDelvType int NULL   ,   
        --    SMDelvTypeName nvarchar(200) NULL   ,  
        --    SMStkType int NULL   ,   
        --    SMStkTypeName nvarchar(200) NULL   ,   
        --    ItemSeq int NULL   ,    
        --    UnitSeq int NULL   ,    
        --    LotNo nvarchar(30) NULL   ,    
        --    FromSerial nvarchar(20) NULL   ,    
        --    ToSerial nvarchar(20) NULL   ,    
        --    Remark nvarchar(100) NULL   ,   
        --    LotMngYN nchar(1) NULL   ,   
        --    AccSeq int NULL   ,   
        --    AccName nvarchar(200) NULL   ,  
        --    AntiAccSeq int NULL   ,  
        --    AntiAccName nvarchar(200) NULL   , 
        --    IsFiction nchar(1) NULL   ,  
        --    FicRateNum decimal(19,5) NULL   , 
        --    FicRateDen decimal(19,5) NULL   ,
        --    EvidSeq int NULL   ,  
        --    EvidName nvarchar(200) NULL   ,   
        --    IsReturn nchar(1) NULL   ,  
        --    SlipSeq int NULL   ,    
        --    BuyingAccSeq int NULL   ,  
        --    CustName nvarchar(200) NULL   , 
        --    CustSeq int NULL   ,    
        --    BizUnit int NULL   ,   
        --    BizUnitName nvarchar(200) NULL   ,   
        --    FactUnit int NULL   ,   
        --    FactUnitName nvarchar(200) NULL   ,   
        --    DelvInDate nchar(8) NULL   ,   
        --    CurVAT decimal(19,5) NULL   ,    
        --    EmpName nvarchar(200) NULL   ,   
        --    DomVAT decimal(19,5) NULL   ,   
        --    EmpSeq int NULL   ,  
        --    DeptSeq int NULL   ,   
        --    TotCurAmt decimal(19,5) NULL   ,  
        --    DeptName nvarchar(200) NULL   ,   
        --    TotDomAmt decimal(19,5) NULL   ,    
        --    SourceType nchar(1) NULL   ,  
        --    SourceSeq int NULL   ,    
        --    SourceSerl int NULL   ,    
        --    SourceTypeName nvarchar(200) NULL   ,   
        --    VatRate decimal(19,5) NULL   ,   
        --    IsPurVat nchar(1) NULL   ,    
        --    PJTName nvarchar(60) NULL   ,    
        --    PJTNo nvarchar(40) NULL   ,    
        --    PJTSeq int NULL   ,   
        --    WBSName nvarchar(80) NULL   ,    
        --    WBSSeq int NULL   ,   
        --    TotAmt decimal(19,5) NULL   ,  
        --    VATAccSeq int NULL   ,   
        --    VATAccName decimal(19,5) NULL   , 
        --    IsVAT nchar(1) NULL   ,   
        --    STDQty decimal(19,5) NULL   ,   
        --    FromSeq int NULL   ,   
        --    FromSerl int NULL   ,   
        --    ItemSeqOLD int NULL   ,    
        --    LotNoOLD nvarchar(50) NULL   ,  
        --    FromQty decimal(19,5) NULL   ,   
        --    SMPriceType int NULL   ,   
        --    SMPriceTypeName nvarchar(200) NULL   
        --) 
        
        --TRUNCATE TABLE #TPUDelvIn 
        INSERT INTO #TPUDelvIn
        (
            WorkingTag, IDX_NO, DataSeq, Selected, Status, 
            DelvSeq, DelvSerl, Qty, STDQty, IFSerl
        )
        select 'A',DataSeq, DataSeq, 0, 0, 
               DelvSeq, DelvSerl, Qty, Qty, IFSerl
          From #TPUDelvItem 
        

        
        -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정) 
        IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvIn' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUDelvIn ADD PgmSeq INT NULL
        END 
         IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvInLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUDelvInLog ADD PgmSeq INT NULL
        END  
        
        -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정) 
        IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvInItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUDelvInItem ADD PgmSeq INT NULL
        END 
         IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvInItemLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUDelvInItemLog ADD PgmSeq INT NULL
        END  
        
        -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정) 
        IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUBuyingAcc' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUBuyingAcc ADD PgmSeq INT NULL
        END 
         IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUBuyingAccLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
        BEGIN
            ALTER TABLE _TPUBuyingAccLog ADD PgmSeq INT NULL
        END  
        
        TRUNCATE TABLE #TPUDelvIn_Result
        --SELECT * INTO #TPUDelvIn_Result FROM #TPUDelvIn
        INSERT INTO #TPUDelvIn_Result 
        SELECT *
          FROM #TPUDelvIn
        
        
        TRUNCATE TABLE #SCOMSourceDailyBatch 
        TRUNCATE TABLE #TLGInOutMinusCheck 
        TRUNCATE TABLE #TLGInOutDailyBatch 
        TRUNCATE TABLE #TLGInOutMonth 
        TRUNCATE TABLE #TLGInOutMonthLot 
        TRUNCATE TABLE #TMP_Item_Prog 
        TRUNCATE TABLE #TMP_PROGRESSTABLE 
        TRUNCATE TABLE #Temp_Order 
        TRUNCATE TABLE #TCOMProgressTracking 
        TRUNCATE TABLE #OrderTracking 
        
        ---- 진행관련 테이블
        --CREATE TABLE #SCOMSourceDailyBatch 
        --(          
        --    ToTableName   NVARCHAR(100),          
        --    ToSeq         INT,          
        --    ToSerl        INT,          
        --    ToSubSerl     INT,          
        --    FromTableName NVARCHAR(100),          
        --    FromSeq     INT,          
        --    FromSerl      INT,          
        --    FromSubSerl   INT,          
        --    ToQty         DECIMAL(19,5),          
        --    ToStdQty      DECIMAL(19,5),          
        --    ToAmt         DECIMAL(19,5),          
        --    ToVAT         DECIMAL(19,5),          
        --    FromQty       DECIMAL(19,5),          
        --    FromSTDQty    DECIMAL(19,5),          
        --    FromAmt       DECIMAL(19,5),          
        --    FromVAT       DECIMAL(19,5)          
        --) 
        ---- 재고 반영
        --Create Table #TLGInOutMinusCheck  
        --(    
        --    WHSeq           INT,  
        --    FunctionWHSeq   INT,  
        --    ItemSeq         INT
        --)  
        --CREATE TABLE #TLGInOutDailyBatch
        --(   
        --    InOutType    INT     ,
        --    InOutSeq     INT     ,
        --    Result       NVARCHAR(250),
        --    MessageType  INT     ,
        --    Status       INT
        --)
        --CREATE TABLE #TLGInOutMonth      
        --(        
        --    InOut           INT,      
        --    InOutYM         NCHAR(6),      
        --    WHSeq           INT,      
        --    FunctionWHSeq   INT,      
        --    ItemSeq         INT,      
        --    UnitSeq         INT,      
        --    Qty             DECIMAL(19, 5),      
        --    StdQty          DECIMAL(19, 5),      
        --    ADD_DEL         INT      
        --)    
        --Create Table #TLGInOutMonthLot      
        --(        
        --    InOut           INT,      
        --    InOutYM         NCHAR(6),      
        --    WHSeq           INT,      
        --    FunctionWHSeq   INT,      
        --    LotNo           NVARCHAR(30),      
        --    ItemSeq         INT,      
        --    UnitSeq         INT,      
        --    Qty             DECIMAL(19, 5),      
        --    StdQty          DECIMAL(19, 5),            
        --    ADD_DEL         INT            
        --)      
        --CREATE TABLE #TMP_Item_Prog
        --(
        --    IDX_NO      INT,
        --    OrderSeq    INT,
        --    OrderSerl   INT,
        --    Qty         DECIMAL(19, 5),
        --    STDQty      DECIMAL(19, 5)
        --) 
        ---- 진행 추적관련 테이블
        --CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
        
        --CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))            
        
        --CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
        
        --CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
        
        -- 자동입고할 품목이 없을 경우 끝냄
        IF NOT EXISTS (SELECT 1 FROM #TPUDelvIn)
        BEGIN
            SELECT * FROM #TPUDelvIn_Result
            RETURN
        END
        
        UPDATE #TPUDelvIn
           SET DelvInDate = D.DelvDate
          FROM #TPUDelvIn    AS I
               JOIN _TPUDelv AS D ON I.DelvSeq = D.DelvSeq
         WHERE D.CompanySeq = @CompanySeq
        
        
        DECLARE @SMRNPMethod INT, @PayDate NCHAR(8), @CustSeq INT, @DelvInDate NCHAR(8),@SMPayType INT
        
        -- 자동입고일경우 건별로 DelvInSeq, DelvInNo 생성 위해(검사일괄처리는 여러건, 일반 자동입고는 한건)  
        SELECT @DataSeq = 0  
        
        WHILE( 1 > 0)   
        BEGIN  
            SELECT TOP 1 @DataSeq = DataSeq      
              FROM #TPUDelvIn          
             WHERE WorkingTag = 'A'          
               AND Status = 0          
               AND DataSeq > @DataSeq          
             ORDER BY DataSeq          
      
            IF @@ROWCOUNT = 0 BREAK       
         
        SELECT @DelvInDate = DelvInDate FROM #TPUDelvIn WHERE DataSeq = @DataSeq  
        EXEC @DelvInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUDelvIn', 'DelvInSeq', 1 
        EXEC dbo._SCOMCreateNo 'PU', '_TPUDelvIn', @CompanySeq, '', @DelvInDate, @DelvInNo OUTPUT  
        
        UPDATE #TPUDelvIn  
           SET DelvInSeq = @DelvInSeq + 1, -- 여러건이 들어올 경우 While을 돌면서 한건식 처리하기 때문에 1을 더해줌  
               DelvInNo  = @DelvInNo  
         WHERE WorkingTag = 'A'  
           AND Status  = 0  
           AND DataSeq = @DataSeq  
        END 
        
        
        SELECT DISTINCT DelvSeq, DelvInSeq, DelvInNo, DelvInDate
          INTO #DelvIn
          FROM #TPUDelvIn
         WHERE WorkingTag IN ('A', 'U')
           AND Status = 0
        
        -- 입고코드 업데이트
        UPDATE #TPUDelvIn_Result
           SET DelvInSeq = B.DelvInSeq
          FROM #TPUDelvIn_Result AS A
          JOIN #TPUDelvIn  AS B ON A.IDX_NO = B.IDX_NO
         WHERE A.WorkingTag IN ('A', 'U')
        
        
        SELECT @DataSeq = 0
        WHILE ( 1 > 0 )
        BEGIN
            SELECT TOP 1 @DataSeq = DataSeq    
              FROM #TPUDelvIn        
             WHERE WorkingTag IN ('A', 'U')  
               AND Status = 0        
               AND DataSeq > @DataSeq        
             ORDER BY DataSeq      
            
            IF @@ROWCOUNT = 0 BREAK     
            
            INSERT INTO _TPUDelvIn
            (
                CompanySeq,         DelvInSeq,      BizUnit,        DelvInNo,       SMImpType,
                DelvInDate,         DeptSeq,        EmpSeq,         CustSeq,        Remark,
                TaxDate,            PayDate,        IsPJT,          IsReturn,       IsRetroACT,
                SMWareHouseType,    CurrSeq,        ExRate,         LastUserSeq,    LastDateTime,
                DtiProcType
            )
            SELECT @CompanySeq,     B.DelvInSeq,    A.BizUnit,  B.DelvInNo,     A.SMImpType, 
                   B.DelvInDate,    A.DeptSeq,      A.EmpSeq,   A.CustSeq,      A.Remark   , 
                   '',              '',             A.IsPJT,    A.IsReturn,     ''       , 
                   '',              A.CurrSeq,      A.ExRate,   @UserSeq ,      GETDATE() , 
                   ''
              FROM _TPUDelv     AS A WITH(NOLOCK)
              JOIN #TPUDelvIn AS B ON A.DelvSeq = B.DelvSeq
             WHERE A.CompanySeq = @CompanySeq
               AND B.DataSeq = @DataSeq
        
            UPDATE #TPUDelvIn
               SET DelvInSerl = IDX_NO + 1
             WHERE WorkingTag IN ('A', 'U')
            
            -- 내외자구분 가져오기
            SELECT @SMImpType = SMImpType 
              FROM _TPUDelv     AS A WITH(NOLOCK)
              JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
             WHERE A.CompanySeq = @CompanySeq
            
            
            INSERT INTO #TPUDelvInItem
            (
                DelvInSeq,      DelvInSerl,     SMImpType,  SMDelvType,     SMStkType, 
                ItemSeq,        UnitSeq,        Price,      DomPrice,       Qty,
                CurAmt,         DomAmt,         StdUnitSeq, StdUnitQty,     IsVAT, 
                CurVAT,         DomVAT,         WHSeq,      SalesCustSeq,   DelvCustSeq,
                LOTNo,          FromSerial,     ToSerial,   SMPayType,      IsFiction, 
                FicRateNum,     FicRateDen,     EvidSeq,    PJTSeq,         WBSSeq, 
                Remark,         IsReturn,       SlipSeq,    SourceType,     SourceSeq, 
                SourceSerl,     WorkingTag,     Status,     IDX_NO,         Result, 
                MessageType,    DataSeq,        CurrSeq,    ExRate,         SMPriceType 
            )
            SELECT C.DelvInSeq, 1, E.SMImpType, 0, 0, 
                   A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
                   
                   -- 금액
                   CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
                        ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                                  ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
                   END,
                   -- 원화금액
                   CASE WHEN A.Qty = B.Qty THEN A.DomAmt
                       ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                      ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
                       END
                   END,                          
                   A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
                   
                   -- 부가세
                   CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
                       ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                                 ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / ISNULL(Rate.VatRate,0)
                                 END
                     ELSE 0 END
                   END,
                   -- 원화부가세
                   CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
                       ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                                 ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / ISNULL(Rate.VatRate,0)
                                 END
                     ELSE 0 END
                   END,
                   A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
                   
                   A.LOTNo    , A.FromSerial, A.ToSerial, 0, A.IsFiction, 
                   
                   A.FicRateNum, A.FicRateDen, A.EvidSeq, A.PJTSeq, A.WBSSeq, 
                   
                   A.Remark, A.IsReturn, 0, '',  A.DelvSeq, 
                   
                   A.DelvSerl, 'A', 0, @DataSeq, B.Result, 
                   
                   B.MessageType, @DataSeq, E.CurrSeq, E.ExRate, A.SMPriceType
        
              FROM _TPUDelvItem     AS A
              JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq AND A.DelvSerl = B.DelvSerl
              JOIN #TPUDelvIn     AS C ON A.DelvSeq = C.DelvSeq
              JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq AND C.DelvSeq = E.DelvSeq
              LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq AND A.ItemSeq = D.ItemSeq
              LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq AND D.AssetSeq = S.AssetSeq AND S.AssetAccKindSeq = 1
              LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq AND S.AccSeq = T.AccSeq  
              LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq AND D.AssetSeq = SS.AssetSeq AND S.AssetAccKindSeq = 9
              LEFT OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq AND S.AccSeq     = TT.AccSeq
              LEFT OUTER JOIN _TDAItemSales    AS Sales ON A.CompanySeq = Sales.CompanySeq AND A.ItemSeq    = Sales.ItemSeq
              LEFT OUTER JOIN _TDAVATRate  AS Rate  ON Sales.CompanySeq = Rate.CompanySeq AND E.DelvDate >= Rate.SDate AND E.DelvDate <= Rate.EDate AND Sales.SMVatType = Rate.SMVatType 
             WHERE A.CompanySeq = @CompanySeq
               AND A.SMQCType NOT IN (6035002, 6035004)
               AND B.DataSeq = @DataSeq 
               AND C.DataSeq = @DataSeq     
        END
        
        
        -- 출납방법/ 지불일자 가져오기 
        
        ALTER TABLE #TPUDelvInItem ADD SMRNPMethod INT, PayDate NCHAR(8)
        
        SELECT @CustSeq =A.CustSeq, 
               @DelvInDate = A.DelvDate
          FROM _TPUDelv     AS A WITH(NOLOCK) 
          JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
         WHERE A.CompanySeq = @CompanySeq
        
        SELECT @SMRNPMethod = SMRNPMethod,
               @PayDate     = PayDate,
               @SMPayType   = SMPayMethod
          FROM dbo._FPDGetSMRNPMethod(@CompanySeq, 4012, @CustSeq, @DelvInDate)
        
        UPDATE A
           SET A.SMRNPMethod = ISNULL(@SMRNPMethod, 0)
              ,A.PayDate    = ISNULL(@PayDate, '')
              ,A.SMPayType    = ISNULL(@SMPayType, '')
          FROM #TPUDelvInItem AS A
        
        -- ## 원화금액 소수점 처리 ## --
        -- 원화부가세, 원화금액 소수점 처리 환경설정 가져오기(구매)
        EXEC dbo._SCOMEnv @CompanySeq,6504,@UserSeq,@@PROCID,@VATEnvSeq OUTPUT  
        EXEC dbo._SCOMEnv @CompanySeq,6505,@UserSeq,@@PROCID,@AmtEnvSeq OUTPUT  
        -- 원화부가세, 원화금액 소수점 자리수 가져오기
        EXEC dbo._SCOMEnv @CompanySeq,15,@UserSeq,@@PROCID,@DomPointEnvSeq OUTPUT  
        
        -- 부가세 소수점 자리 처리
        IF RIGHT(@VATEnvSeq, 1) = '1'        -- 반올림    
            UPDATE #TPUDelvInItem
               SET DomVAT = ROUND(DomVAT, @DomPointEnvSeq)
        ELSE IF RIGHT(@VATEnvSeq, 1) = '2'   -- 절사
            UPDATE #TPUDelvInItem
               SET DomVAT = ROUND(DomVAT, @DomPointEnvSeq , @DomPointEnvSeq + 1 )
        ELSE                                 -- 올림
            UPDATE #TPUDelvInItem
               SET DomVAT = ROUND(DomVAT + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@DomPointEnvSeq + 1)), @DomPointEnvSeq)
        -- 금액 소수점 자리 처리
        IF RIGHT(@AmtEnvSeq, 1) = '1'        -- 반올림
            UPDATE #TPUDelvInItem
               SET DomAmt = ROUND(DomAmt, @DomPointEnvSeq)
        ELSE IF RIGHT(@AmtEnvSeq, 1) = '2'   -- 절사
            UPDATE #TPUDelvInItem
               SET DomAmt = ROUND(DomAmt, @DomPointEnvSeq , @DomPointEnvSeq + 1 )
        ELSE                                 -- 올림
            UPDATE #TPUDelvInItem
               SET DomAmt = ROUND(DomAmt + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@DomPointEnvSeq + 1)), @DomPointEnvSeq) 
        
        DECLARE @MaxDelvInSerl INT, 
                @QtyPoint     INT        
        
        
        
        
        -- 기준단위계산  
        UPDATE #TPUDelvInItem  
          SET StdUnitSeq = B.UnitSeq,  
              StdUnitQty = (CASE ISNULL(C.ConvDen,0) WHEN  0 THEN 0 ELSE Qty * (C.ConvNum/C.ConvDen) END)  
         FROM #TPUDelvInItem AS A LEFT OUTER JOIN  _TDAItem AS B ON B.CompanySeq = @CompanySeq  
                                                                AND A.ItemSeq = B.ItemSeq  
                                  LEFT OUTER JOIN _TDAItemUnit AS C ON C.CompanySeq = @CompanySeq  
                                                                   AND A.ItemSeq = C.ItemSeq  
                                                                   AND A.UnitSeq = C.UnitSeq  
        
      
        -- 기준단위수량 소수점 자리 처리        -- 12.01.25 BY 김세호    
          
        EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@QtyPoint OUTPUT   -- 구매/자재 수량 소수점 자리수     
      
        UPDATE #TPUDelvInItem    
          SET STDUnitQty = CASE WHEN B.SMDecPointSeq = 1003001 THEN ROUND(StdUnitQty, @QtyPoint, 0)     
                                WHEN B.SMDecPointSeq = 1003002 THEN ROUND(StdUnitQty, @QtyPoint, -1)                 
                                WHEN B.SMDecPointSeq = 1003003 THEN ROUND(StdUnitQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)         
                                ELSE ROUND(StdUnitQty  , @QtyPoint, 0) END    
         FROM #TPUDelvInItem AS A     
         JOIN _TDAUnit         AS B ON B.CompanySeq = @CompanySeq    
                                   AND A.StdUnitSeq = B.UnitSeq    
        
        
        
        
        INSERT INTO _TPUDelvInItem
        (
            CompanySeq   ,DelvInSeq    ,DelvInSerl   ,SMImpType     ,SMDelvType   ,    
            SMStkType    ,ItemSeq      ,UnitSeq      ,--CurrSeq      ,ExRate       ,    
            Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq   ,    
            StdUnitQty   ,CurVAT     ,WHSeq        ,SalesCustSeq ,DelvCustSeq  ,    
            LOTNo        ,FromSerial   ,ToSerial     ,SMPayType    ,    
            AccSeq   ,    
            AntiAccSeq   ,    
            IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq      ,    
            PJTSeq       ,WBSSeq       ,Remark       ,IsReturn     ,LastUserSeq  ,    
            DomPrice     ,DomVAT       ,IsVAT        ,    
            LastDateTime ,SupplyAmt    ,SupplyVAT    ,SMPriceType
        )      
        SELECT  @CompanySeq    ,A.DelvInSeq    ,A.DelvInSerl   ,A.SMImpType      ,A.SMDelvType   ,    
                 A.SMStkType    ,A.ItemSeq      ,A.UnitSeq      ,--A.CurrSeq        ,A.ExRate       ,    
                 A.Price        ,A.Qty          ,A.CurAmt       ,A.DomAmt         ,A.StdUnitSeq   ,    
                 A.StdUnitQty   ,A.CurVAT       ,A.WHSeq        ,A.SalesCustSeq   ,A.DelvCustSeq  ,    
                 A.LotNo        ,A.FromSerial   ,A.ToSerial     ,A.SMPayType      ,    
                 CASE ISNULL(A.AccSeq, 0)     WHEN 0 THEN T.AccSeq  ELSE ISNULL(A.AccSeq, 0)     END AS AccSeq,    
                 CASE WHEN @SMImpType = 8008001 THEN ISNULL(TT.AccSeq, 0) ELSE ISNULL(TTT.AccSeq, 0) END AS AntiAccSeq,    
                 A.IsFiction    ,A.FicRateNum   ,A.FicRateDen   ,A.EvidSeq        ,    
                 A.PJTSeq       ,A.WBSSeq       ,A.Remark       ,A.IsReturn       ,@UserSeq     ,    
                 A.DomPrice     ,A.DomVAT       ,A.IsVAT        ,     
                 GETDATE()    ,A.DomAmt    ,0              ,SMPriceType
          FROM #TPUDelvInItem AS A         
          LEFT OUTER JOIN _TDAItem         AS B ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq    
          LEFT OUTER JOIN _TDAItemAssetAcc AS S WITH(NOLOCK) ON B.CompanySeq = S.CompanySeq AND B.AssetSeq = S.AssetSeq AND S.AssetAccKindSeq = 1    
          LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON S.CompanySeq = T.CompanySeq AND S.AccSeq = T.AccSeq      
          LEFT OUTER JOIN _TDAItemAssetAcc AS SS WITH(NOLOCK) ON B.CompanySeq = SS.CompanySeq AND B.AssetSeq = SS.AssetSeq AND SS.AssetAccKindSeq = 9    
          LEFT OUTER JOIN _TDAAccount      AS TT WITH(NOLOCK) ON SS.CompanySeq = TT.CompanySeq AND SS.AccSeq   = TT.AccSeq      
          LEFT OUTER JOIN _TDAItemAssetAcc AS SSS WITH(NOLOCK) ON B.CompanySeq  = SSS.CompanySeq     --  Local 채무계정이 들어가도록 수정    
                                                              AND B.AssetSeq    = SSS.AssetSeq     
                                                              AND SSS.AssetAccKindSeq = 12    
          LEFT OUTER JOIN _TDAAccount      AS TTT WITH(NOLOCK) ON SSS.CompanySeq = TTT.CompanySeq AND SSS.AccSeq   = TTT.AccSeq 
        
        DECLARE @SlipType           INT, 
                @SlipAutoEnvSeq     INT 

        -- 원천 테이블    
        CREATE TABLE #TMP_SOURCETABLE    
        (    
            IDOrder     INT,    
            TABLENAME   NVARCHAR(100)    
        )    
               
        -- 원천 데이터 테이블    
        CREATE TABLE #TCOMSourceTracking    
        (    
            IDX_NO      INT,    
            IDOrder     INT,    
            Seq         INT,    
            Serl        INT,    
            SubSerl     INT,    
            Qty         DECIMAL(19,5),    
            STDQty      DECIMAL(19,5),    
            Amt         DECIMAL(19,5),    
            VAT         DECIMAL(19,5)    
        )    
        
        -- 폼세부정보분개 방식인지 테이블 방식인지 가져오기    
        SELECT @SlipType = JourMethod     
          FROM _TACSlipKind    
         WHERE CompanySeq = @CompanySeq    
           AND SlipKindNo = 'FrmPUBuyingAcc'    
        
        
        
        
        IF @SlipType = 4030002 -- 폼정보자동분개    
        BEGIN    
        --자동전표코드 가져오기    
            SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
              FROM _TACSlipKind                     AS A WITH(NOLOCK)     
              LEFT OUTER JOIN _TACSlipAutoEnv       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SlipKindNo = B.SlipKindNo    
             WHERE A.CompanySeq = @CompanySeq    
               AND A.SlipKindNo = 'FrmPUBuyingAcc'     
            
            -- 부가세계정 가져오기    
            SELECT @VatAccSeq = B.AccSeq    
              FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)    
              JOIN _TDAAccount  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq AND B.SMAccType = 4002009 
             WHERE A.companyseq     = @CompanySeq      
               AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
        
            IF EXISTS (SELECT 1 FROM #TPUDelvInItem AS A
                                JOIN _TPUDelvIn     AS B ON A.DelvInSeq = B.DelvInSeq AND @CompanySeq = B.CompanySeq
                               WHERE ISNULL(B.IsPJT, '0') = '1'
                      )     -- 프로젝트 입고건일경우 전표유형 '프로젝트구매외주매입정산'에서 계정 가져오도록 수정 -12 .03.09 BY 김세호
            BEGIN   
                SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
                  FROM _TACSlipKind                    AS A WITH(NOLOCK)     
                  LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SlipKindNo = B.SlipKindNo    
                 WHERE A.CompanySeq = @CompanySeq    
                   AND A.SlipKindNo = 'FrmPUBuyingAcc_PMSPur'     
                
                -- 부가세계정 가져오기    
                SELECT @VatAccSeq = B.AccSeq    
                  FROM _TACSlipAutoEnvRow   AS A WITH(NOLOCK)    
                  JOIN _TDAAccount          AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq AND B.SMAccType = 4002009    
                 WHERE A.companyseq = @CompanySeq      
                   AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
            END     
        END    
        
        ELSE IF @SlipType = 4030003 -- 테이블정보자동분개    
        BEGIN    
            SELECT @VatAccSeq = B.AccSeq    
              FROM _TACSlipRowAutoEnvTable AS A WITH(NOLOCK)     
              JOIN _TDAAccount     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq  = B.AccSeq AND B.SMAccType  = 4002009    
             WHERE A.Companyseq = @CompanySeq     
               AND A.SlipKindNo = 'FrmPUBuyingAcc'    
        END     
        
        -- 마스터의 내외자구분 가져오기    
        SELECT @SMImpType = MAX(A.SMImpType)    
          FROM _TPUDelvIn           AS A WITH(NOLOCK)     
          JOIN #TPUDelvInItem       AS B ON A.DelvInSeq = B.DelvInSeq    
         WHERE A.CompanySeq = @CompanySeq    

         ---------------------------------------------------------------------------    
         -- 입고정산 데이터 생성
         ---------------------------------------------------------------------------
         DECLARE @BuyingAccSeq INT 
                 --@count INT    
     
         SELECT  @DataSeq = 0    
               
         WHILE ( 1 = 1 )             
         BEGIN            
             SELECT TOP 1 @DataSeq = DataSeq        
             FROM #TPUDelvInItem            
              WHERE DataSeq > @DataSeq            
              ORDER BY DataSeq            
     
             IF @@ROWCOUNT = 0 BREAK         
     
             SELECT @count = COUNT(*)              
               FROM #TPUDelvInItem              
                       
             IF @count > 0            
             BEGIN            
                 EXEC @BuyingAccSeq = _SCOMCreateSeq @CompanySeq, '_TPUBuyingAcc', 'BuyingAccSeq', 1             
             END            
     
             UPDATE #TPUDelvInItem            
                SET BuyingAccSeq = @BuyingAccSeq + 1    
               WHERE DataSeq = @DataSeq 
         END    
            
        -- 구매요청 원천 데이터 가져오기(구매납품코드로 구매요청의 활동센터 가져오기 위함) 추가 by 천경민    
        INSERT #TMP_SOURCETABLE    
        SELECT 1, '_TPUORDPOReqItem'   -- 구매요청품목    
     
            EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvInItem', 'SourceSeq', 'SourceSerl', ''    
        
            
         SELECT DISTINCT A.IDX_NO, B.CCtrSeq -- 중복 저장 오류 발생해서 수정 2011. 1. 21 hkim    
           INTO #CCtrSeq    
           FROM #TCOMSourceTracking   AS A    
                JOIN _TPUORDPOReqItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                       AND A.Seq        = B.POReqSeq    
                                                       AND A.Serl       = B.POReqSerl    
                JOIN _TPUORDPOReq     AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                                       AND B.POReqSeq   = C.POReqSeq    
     /*    
     활동센터 세팅 순서    
     IF 프로젝트    
      무조건 프로젝트의 활동센터    
     ELSE    
      1. 구매요청의 활동센터    
      2. 구매입고부서의 활동센터    
     */    
        
        
        INSERT INTO _TPUBuyingAcc
        (
            CompanySeq         ,BuyingAccSeq     ,SourceType       ,SourceSeq        ,SourceSerl       ,    
            BizUnit          ,FactUnit         ,BuyingAccDate    ,DelvInNo         ,DelvInDate       ,    
            ItemSeq          ,CustSeq          ,EmpSeq           ,DeptSeq         ,UnitSeq          ,    
            CurrSeq          ,ExRate           ,Price            ,DomPrice         ,Qty              ,    
            PriceUnitSeq     ,PriceQty         ,CurAmt           ,CurVAT           ,DomAmt           ,    
            DomVAT           ,StdUnitSeq       ,StdUnitQty       ,IsVAT            ,SMImpType        ,    
            WHSeq            ,DelvCustSeq      ,SMPayType        ,AccSeq           ,MatAccSeq        ,    
            AntiAccSeq       ,VatAccSeq        ,IsFiction        ,FicRateNum       ,FicRateDen       ,    
            EvidSeq          ,PjtSeq           ,WBSSeq           ,Remark           ,IsReturn         ,    
            SlipSeq          ,TaxDate          ,PayDate          ,ImpDomAmt        ,ImpCurAmt        ,    
            LastUserSeq      ,LastDateTime     ,SMRNPMethod      ,CCtrSeq     ,SupplyAmt   ,SupplyVAT
        ) -- 활동센터 추가 2010.05.11 by bgKeum    
        SELECT A.CompanySeq ,C.BuyingAccSeq ,'1'            ,A.DelvInSeq            ,A.DelvInSerl       ,    
               B.BizUnit    ,0              ,B.DelvInDate   ,B.DelvInNo             ,B.DelvInDate       ,    
               A.ItemSeq    ,B.CustSeq      ,B.EmpSeq       ,B.DeptSeq              ,A.UnitSeq          ,    
               B.CurrSeq    ,B.ExRate       ,A.Price        ,A.DomPrice             ,A.Qty              ,                 
               A.UnitSEq    ,A.Qty          ,A.CurAmt       ,A.CurVAT               ,A.DomAmt           ,    
               A.DomVAT     ,A.StdUnitSeq   ,A.StdUnitQty   ,A.IsVAT                ,A.SMImpType        ,    
               A.WHSeq      ,A.DelvCustSeq  ,A.SMPayType    ,A.AccSeq               ,0                  ,    
               A.AntiAccSeq ,@VatAccSeq     ,A.IsFiction    ,A.FicRateNum           ,A.FicRateDen       ,    
               A.EvidSeq    ,A.PjtSeq       ,A.WBSSeq       ,A.Remark               , ''                ,    
               0            ,''             ,C.PayDate      ,0                      ,0                  ,     
               --@UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) -- 활동센터 추가 2010.05.11 by bgKeum    
               @UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,    
               CASE WHEN A.PJTSeq <> 0 THEN P.CCTRSeq     
               ELSE ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) END, -- 20110407 윤삼혁 프로젝트 활동센터    
               A.DomAmt  ,0--A.DomVAT   -- 2012. 5. 22 hkim 공급가액 컬럼 추가 
          FROM _TPUDelvInItem           AS A WITH(NOLOCK)      
          JOIN _TPUDelvIn               AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DelvInSeq = B.DelvInSeq    
          JOIN #TPUDelvInItem           AS C              ON A.DelvInSeq  = C.DelvInSeq AND A.DelvInSerl = C.DelvInSerl    
          -- 20110407 윤삼혁 프로젝트 활동센터    
          LEFT OUTER JOIN _TPJTProject   AS P             ON A.CompanySeq = P.CompanySeq AND A.PJTSeq  = P.PJTSeq    
          LEFT OUTER JOIN dbo._FnAdmEmpCCtr(@CompanySeq, @DelvInDate) AS CC ON B.EmpSeq = CC.EmpSeq -- 활동센터 추가 2010.05.11 by bgKeum    
          LEFT OUTER JOIN #CCtrSeq AS D ON C.IDX_NO = D.IDX_NO  -- 우선 구매요청의 활동센터 먼저 저장 by 천경민    
         WHERE A.CompanySeq = @CompanySeq    
        ---------------------------------------------------------------------------    
         -- 입고정산 데이터 생성, END 
        ---------------------------------------------------------------------------
        ---------------------------------------------------------------------------
        -- 진행연결
        ---------------------------------------------------------------------------
        TRUNCATE TABLE #SComSourceDailyBatch  
        INSERT INTO #SCOMSourceDailyBatch  
        SELECT '_TPUDelvInItem', P.DelvInSeq, P.DelvInSerl, 0,   
               '_TPUDelvItem'  , P.SourceSeq, P.SourceSerl, 0,  
               P.Qty, P.StdUnitQty, P.CurAmt,   P.CurVAT,  
               P.Qty, P.StdUnitQty, P.CurAmt,   P.CurVAT
          FROM #TPUDelvInItem    AS P
         WHERE P.Status = 0  
         EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
        ---------------------------------------------------------------------------
        -- 진행연결, END 
        ---------------------------------------------------------------------------
        ---------------------------------------------------------------------------
        -- 수불관리 
        ---------------------------------------------------------------------------
        INSERT INTO #TLGInOutDailyBatch  
        SELECT DISTINCT 170, A.DelvInSeq, '', 0, 0  
          FROM #TPUDelvInItem    AS A
         WHERE A.Status = 0  
        
        
        EXEC _SLGInOutDailyINSERT @CompanySeq
        EXEC _SLGWHStockUPDATE @CompanySeq    
        EXEC _SLGLOTStockUPDATE @CompanySeq    
        EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
        EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
        ---------------------------------------------------------------------------
        -- 수불관리, END 
        ---------------------------------------------------------------------------
        
        UPDATE A 
           SET ProcYN = '1', 
               ProcDate = GETDATE(), 
               DelvSeq = B.DelvSeq, 
               IsErr = B.Status, 
               ErrorMessage = B.Result
          FROM KPX_TPUDelvItem_IF AS A 
          JOIN #TPUDelvIn_Result  AS B ON ( B.IFSerl = A.Serl ) 
    
        IF @Cnt = (SELECT MAX(IDX_NO) FROM #Company) 
        BEGIN
            BREAK
        END 
        ELSE 
        BEGIn
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    
    SELECT A.* 
      FROM KPX_TPUDelvItem_IF AS A 
      JOIN #TPUDelv_Sub       AS B ON ( B.IFSerl = A.Serl ) 
    
    RETURN    
 --GO 
 begin tran 
 exec KPX_SPUDelvMROIF 
 
-- exec KPX_SPUDelvMROIF @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <DelvSeq>1001870</DelvSeq>
--    <DelvSerl>1</DelvSerl>
--    <Qty>200.00000</Qty>
--    <STDQty>200.00000</STDQty>
--  </DataBlock1>
--    <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <DelvSeq>1001871</DelvSeq>
--    <DelvSerl>1</DelvSerl>
--    <Qty>200.00000</Qty>
--    <STDQty>200.00000</STDQty>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=5545,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1134

--select * from _TPUDelv where companyseq = 1
--select * from _TPUDelvItem where companyseq = 1

--select * from _TPUDelvIn where companyseq = 1 
--select * from _TPUDelvInItem where companyseq = 1

--select * from _TPUBuyingAcc where companyseq = 1 and Sourceseq in ( 100000632, 100000633 )


--select * From _TCOMsourceDaily where companyseq = 1 and FromTableSeq = 10 and fromseq IN ( 1001887, 1001888 ) 
select * from KPX_TPUDelvItem_IF 
--select * from _TLGWHStock where CompanySeq = 1 and ItemSeq = 87
rollback 

