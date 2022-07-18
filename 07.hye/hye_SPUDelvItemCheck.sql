IF OBJECT_ID('hye_SPUDelvItemCheck') IS NOT NULL 
    DROP PROC hye_SPUDelvItemCheck
GO 

-- v2016.09.29 

-- 구매납품입력_디테일체크 by이재천 
/************************************************************    
설  명 - 구매납품체크(디테일)    
작성일 - 2008년 8월 20일     
작성자 - 노영진    
UPDATE ::  기준단위수량 구할때 소수점 자리 처리              :: 12.01.25 BY 김세호  
       ::  원천건의 발주일자보다 납품일이 이전이 일경우 체크 :: 12.04.24 BY 김세호
       ::  검사구분 '0' 들어갈 경우 체크                     :: 12.05.29 BY 김세호
************************************************************/          
CREATE PROC hye_SPUDelvItemCheck     
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10) = '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS      
    -- 변수 선언        
    DECLARE @docHandle      INT,        
            @MessageType    INT,        
            @MessageStatus  INT,        
            @Results        NVARCHAR(300),        
            @Count          INT,        
            @Seq            INT,        
            @Status         INT,       
            @DelvSeq        INT,  
            @BizUnit        INT,       
            @MaxDelvSerl    INT,  
            @QCAutoIn       NCHAR(1),  
            @QtyPoint         INT         
      
    -- 임시 테이블 생성  _TPUORDQutoReq        
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)        
    -- 임시 테이블에 지정된 컬럼을 추가하고, xml로부터의 값을 insert한다.     
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'        
    IF @@ERROR <> 0 RETURN        
  
    -- 확정체크 추가 by이재천 
    UPDATE A
       SET Result = '전자결재가 진행 된 구매납품 건은 수정/삭제 할 수 없습니다.(상품)', 
           Status = 1234,
           MessageType = 1234 
      FROM #TPUDelvItem                AS A 
      LEFT OUTER JOIN _TPUDelv_Confirm  AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND B.IsAuto = '0' 
       AND B.CfmCode <> 0 
    -- 확정체크, END 


     
    -- 상품과 상품이 아닌 것 같이 저장 할 수 없음
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('A', 'U')) AND NOT EXISTS (SELECT 1 FROM #TPUDelvItem WHERE Status <> 0)
    BEGIN
        DECLARE @ItemKind INT -- 1:상품 , 0:상품X

        CREATE TABLE #Item 
        (
            IDX_NO      INT IDENTITY, 
            ItemSeq     INT, 
            ItemKind    INT 
        )

        INSERT INTO #Item ( ItemSeq, ItemKind ) 
        SELECT A.ItemSeq, CASE WHEN C.SMAssetGrp = 6008001 THEN 1 ELSE 0 END  
          FROM _TPUDelvItem             AS A 
          LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.DelvSeq = ( SELECT TOP 1 DelvSeq FROM #TPUDelvItem ) 
           AND NOT EXISTS ( SELECT 1 FROM #TPUDelvItem WHERE DelvSeq = A.DelvSeq AND DelvSerl = A.DelvSerl ) 
        UNION ALL 
        SELECT A.ItemSeq, CASE WHEN C.SMAssetGrp = 6008001 THEN 1 ELSE 0 END  
          FROM #TPUDelvItem             AS A 
          LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
    
        SELECT @ItemKind = A.ItemKind
          FROM #Item                    AS A 
         WHERE A.IDX_NO = 1 
        

        IF EXISTS ( SELECT 1 FROM #Item WHERE ItemKind <> @ItemKind )
        BEGIN
            UPDATE A
               SET Result = '상품과 상품이 아닌 품목을 같이 저장 할 수 없습니다.', 
                   Status = 1234,
                   MessageType = 1234 
              FROM #TPUDelvItem AS A 
        END 
    END 
    -- 상품과 상품이 아닌 것 같이 저장 할 수 없음, END 




    ---- 상품과 상품이 아닌 것 같이 저장 할 수 없음

    --SELECT C.SMAssetGrp
    --  FROM #TPUDelvItem             AS A 
    --  LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
    --  LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
    -- WHERE A.Status = 0 
    --   AND A.WorkingTag IN ( 'U', 'D' ) 



    --UPDATE A
    --   SET Result = '품목분류가 상품과 상품이 품목은 저장 할 수 없습니다.', 
    --       Status = 1234,
    --       MessageType = 1234 
    --  FROM #TPUDelvItem                AS A 
    --  LEFT OUTER JOIN _TDAItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
    -- WHERE A.Status = 0 
    --   AND A.WorkingTag IN ( 'U', 'D' ) 
    --   AND B.IsAuto = '0' 
    --   AND B.CfmCode <> 0 
    ---- 확정체크, END 


    SELECT @DelvSeq = DelvSeq      
      FROM #TPUDelvItem      
  
    SELECT @QCAutoIn = EnvValue   
      FROM _TCOMEnv  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq     = 6500  

    SELECT  DISTINCT ISNULL(B.IsNotAutoIn,0) AS IsNotAutoIn
      INTO #ROWCOUNT
      FROM #TPUDelvItem AS A  
           LEFT OUTER JOIN _TPDBaseItemQCType AS B ON B.CompanySeq = @CompanySeq  
                                                  AND B.ItemSeq    = A.ItemSeq

    -- 자동입고 사용할 경우 자동입고미사용에 체크 된 품목이 있으면 체크 --2013.10.04 UPDATED BY 김권우  
    IF @QCAutoIn = '1' -- 자동입고일 경우  
    BEGIN  
        IF 1 < (SELECT COUNT(*) FROM #ROWCOUNT)
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,    
            @Status      OUTPUT,    
            @Results     OUTPUT,    
            2064               , -- @1 @2이 포함되어 있어 저장 할 수 없습니다.
            @LanguageSeq       ,     
            16790,'자동입고미사용',7,'품목'   -- SELECT * FROM _TCADictionary WHERE WordSeq IN (16790, 7)

            UPDATE #TPUDelvItem    
               SET Result        = @Results    ,    
                   MessageType   = @MessageType,    
                   Status        = @Status    
              FROM #TPUDelvItem AS A
                   JOIN _TPDBaseItemQCType AS B ON B.CompanySeq = @CompanySeq
                                               AND B.ItemSeq    = A.ItemSeq
             WHERE Status = 0   
               AND WorkingTag IN ('A', 'U') 
               AND B.IsNotAutoIn = '1' 
        END
    END

    -- 검사구분(SMQCType) 0인 경우 체크         -- 12.05.29 BY 김세호
    -- (행복사로 인해 검사구분 0으로 들어가는경우 간혈적으로 발생 해서 추가)

    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('A', 'U'))
     BEGIN

        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @을(를) 확인하세요
                              @LanguageSeq       ,   
                              474,''   -- select * from _TCADictionary where WOrd ='검사구분'


        UPDATE #TPUDelvItem  
           SET Result        = @Results    ,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem       
         WHERE Status = 0 
           AND (SMQCType IS NULL OR SMQCType = 0)
           AND WorkingTag IN ('A', 'U')
     END


       
    -- 구매입고 진행 된 건은 삭제 제한  
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('U', 'D') )  
    BEGIN  
        -------------------  
        --입고진행여부-----  
        -------------------  
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))      
            
        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))      
          
      
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))        
      
        CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))  
      
        INSERT #TMP_PROGRESSTABLE       
        SELECT 1, '_TPUDelvInItem'               -- 구매입고  
  
        -- 구매납품  
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)      
        SELECT  A.DelvSeq, A.DelvSerl, '2'      
          FROM #TPUDelvItem AS A WITH(NOLOCK)       
         WHERE A.WorkingTag IN ('U', 'D')  
           AND A.Status = 0  
  
        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''      
         
          
        INSERT INTO #OrderTracking      
        SELECT IDX_NO,      
               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),      
               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)     
          FROM #TCOMProgressTracking      
         GROUP BY IDX_No      
  
        UPDATE #Temp_Order   
          SET IsDelvIn = '1'  
           FROM   #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  

  
        IF @QCAutoIn <> '1'    -- 무검사품 자동입고가 아닐 경우  
        BEGIN  
            -------------------  
            --입고진행여부END------  
            -------------------  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1044               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                                  @LanguageSeq       ,   
                                  0,'납품예정일'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
            UPDATE #TPUDelvItem  
               SET Result        = @Results    ,  
                   MessageType   = @MessageType,  
                   Status        = @Status  
              FROM #TPUDelvItem     AS A  
                   JOIN #Temp_Order AS B ON A.DelvSeq = B.OrderSeq  
             WHERE B.IsDelvIn = '1'  
        END  
  
        -------------------  
        --입고진행여부END------  
        -------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1044               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'납품예정일'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
        UPDATE #TPUDelvItem  
           SET Result        = @Results    ,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem     AS A  
               JOIN #Temp_Order AS B ON A.DelvSeq  = B.OrderSeq  
                                    AND A.DelvSerl = B.OrderSerl  
         WHERE B.IsDelvIn = '1'  
           AND A.SMQCType <> 6035001
    END        
    -- 사업부문 내의 창고가 아닐 경우 오류 처리  
    SELECT @BizUnit = ISNULL(BizUnit, 0)   
      FROM #TPUDelvItem   
  
    IF EXISTS (SELECT 1 FROM #TPUDelvItem           AS A  
                             LEFT OUTER JOIN _TDAWH AS B ON A.WHSeq      = B.WHSeq  
                                                        AND B.CompanySeq = @CompanySeq  
                       WHERE B.BizUnit <> @BizUnit   
                         AND A.WorkingTag IN ('A', 'U')  
                         AND A.Status     = 0)  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              11               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'사업부문'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
        UPDATE #TPUDelvItem  
           SET Result        = REPLACE(@Results,'@2', '창고'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem     AS A  
    END  
    -- 인수검사가 완료된 건은 삭제/수정 제한  
    IF EXISTS (SELECT 1 FROM _TPDQCTestReport  AS A  
                             JOIN #TPUDelvItem AS B ON A.SourceSeq  = B.DelvSeq   
                                                   AND A.SourceSerl = B.DelvSerl  
                       WHERE A.CompanySeq = @CompanySeq AND A.SourceType = '1' AND B.WorkingTag IN ('U', 'D') AND B.Status = 0)  
    BEGIN  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                  @Status      OUTPUT,      
                                  @Results     OUTPUT,      
                                  18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)      
                                  @LanguageSeq       ,       
                                    0, '구매인수검사로 진행된 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'              
             UPDATE #TPUDelvItem      
                SET Result        = @Results,      
                    MessageType   = @MessageType,      
                    Status        = @Status    
              FROM  #TPUDelvItem        
    END          
      
     -------------------------------------------        
     -- 의제매입선택시 증빙체크   2012. 1. 2. hkim  
     -------------------------------------------        
     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                           @Status      OUTPUT,        
                           @Results     OUTPUT,        
                           1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)        
                           @LanguageSeq       ,         
                           341,''   -- SELECT * FROM _TCADictionary WHERE Word like '%증빙%'                
     UPDATE #TPUDelvItem        
        SET Result        = @Results,        
            MessageType   = @MessageType,        
            Status        = @Status        
      WHERE IsFiction = '1' AND EvidSeq = 0         
                 
  
     
     -------------------------------------------        
     -- 원천건의 발주일자보다 납품일이 이전일 경우 체크      12.04.24 BY 김세호
     ------------------------------------------- 
    
      
    IF EXISTS(SELECT 1 FROM #TPUDelvItem WHERE FromTableSeq = 13 ANd FromSeq <> 0)
     BEGIN


        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              1150                  , -- @1는 @2보다 커야 합니다.
                              @LanguageSeq       ,         
                              141,'',   -- 납품일
                              166,''    -- 발주일

        UPDATE A
           SET   Result        = @Results,      
                 MessageType   = @MessageType,      
                 Status        = @Status  
          FROM #TPUDelvItem     AS A
          JOIN _TPUORDPO        AS B ON @CompanySeq = B.CompanySeq
                                    AND A.FromSeq = B.POSeq                                  
         WHERE A.DelvDate < B.PODate
           AND A.Status = 0
           AND A.WorkingTag IN ('A', 'U')
     END




    -- 순번update---------------------------------------------------------------------------------------------------------------      
    SELECT @MaxDelvSerl = ISNULL(MAX(DelvSerl), 0)      
      FROM _TPUDelvItem       
     WHERE DelvSeq = @DelvSeq     
      AND CompanySeq   = @CompanySeq  
  
    UPDATE #TPUDelvItem      
       SET DelvSerl = @MaxDelvSerl + DataSeq      
      FROM #TPUDelvItem      
     WHERE WorkingTag = 'A'       
       AND Status = 0      
                 
    IF @WorkingTag = 'D'      
        UPDATE #TPUDelvItem      
           SET WorkingTag = 'D'      
  
  
    -- 기준단위계산  
    UPDATE #TPUDelvItem  
      SET StdUnitSeq = B.UnitSeq,  
          StdUnitQty = (CASE ISNULL(C.ConvDen,0) WHEN  0 THEN 0 ELSE Qty * (C.ConvNum/C.ConvDen) END)  
     FROM #TPUDelvItem AS A LEFT OUTER JOIN  _TDAItem AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A.ItemSeq = B.ItemSeq  
                              LEFT OUTER JOIN _TDAItemUnit AS C ON C.CompanySeq = @CompanySeq  
                                                               AND A.ItemSeq = C.ItemSeq  
                                                               AND A.UnitSeq = C.UnitSeq  
  
  
    -- 기준단위수량 소수점 자리 처리        -- 12.01.25 BY 김세호    
      
    EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@QtyPoint OUTPUT   -- 구매/자재 수량 소수점 자리수     
  
    UPDATE #TPUDelvItem    
      SET STDUnitQty = CASE WHEN B.SMDecPointSeq = 1003001 THEN ROUND(StdUnitQty, @QtyPoint, 0)     
                            WHEN B.SMDecPointSeq = 1003002 THEN ROUND(StdUnitQty, @QtyPoint, -1)                 
                            WHEN B.SMDecPointSeq = 1003003 THEN ROUND(StdUnitQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)         
                            ELSE ROUND(StdUnitQty  , @QtyPoint, 0) END    
     FROM #TPUDelvItem AS A     
     JOIN _TDAUnit         AS B ON B.CompanySeq = @CompanySeq    
                               AND A.StdUnitSeq = B.UnitSeq      
  
              
    SELECT * FROM #TPUDelvItem      
       
             
RETURN  
go
begin tran 
exec hye_SPUDelvItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>데스크탑 컴퓨터</ItemName>
    <ItemNo>DeskTop PC</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>3</Price>
    <Qty>4</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>12</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>13</TotCurAmt>
    <DomPrice>0.03</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>제품창고</WHName>
    <WHSeq>1</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>무검사</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>4</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>1</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>1</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>26</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>민석_상품1(Lot)</ItemName>
    <ItemNo>민석_상품1(Lot)</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>3</Price>
    <Qty>2</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>6</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>7</TotCurAmt>
    <DomPrice>0.03</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>제품창고</WHName>
    <WHSeq>1</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>무검사</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>2</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>1</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>1</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>4</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>석회석(금산)中</ItemName>
    <ItemNo>MLLSGSMID4565</ItemNo>
    <Spec>40/60MM</Spec>
    <UnitName>KG</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>4</Price>
    <Qty>2</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>8</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>9</TotCurAmt>
    <DomPrice>0.04</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>(일반창고)단양1공장창고</WHName>
    <WHSeq>129</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>미검사</SMQcTypeName>
    <SMQcType>6035002</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>KG</STDUnitName>
    <STDUnitQty>2</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>2</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>2</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>71</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730087,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730012
rollback 