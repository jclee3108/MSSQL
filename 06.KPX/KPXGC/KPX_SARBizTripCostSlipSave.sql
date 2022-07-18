  
IF OBJECT_ID('KPX_SARBizTripCostSlipSave') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostSlipSave  
GO  
  
-- v2015.01.08 

-- 출장비지출품의서-Slip저장 by 이재천
CREATE PROC KPX_SARBizTripCostSlipSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #TACSlip_Sub (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TACSlip_Sub'   
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #TACSlip
    (
        SlipMstSeq      INT, 
        SlipMstID       NVARCHAR(100), 
        AccUnit         INT, 
        SlipUnit        INT, 
        AccDate         NCHAR(8), 
        SlipNo          NVARCHAR(100), 
        SlipKind        INT, 
        RegEmpSeq       INT, 
        RegDeptSeq      INT, 
        Remark          NVARCHAR(2000)
    )   
    
    
    
    INSERT INTO #TACSlip ( AccUnit, SlipUnit, AccDate, SlipKind, RegEmpSeq, RegDeptSeq, Remark ) 
    SELECT TOP 1 C.AccUnit, A.SlipUnitSub, CONVERT(NCHAR(8),GETDATE(),112), 10001, ISNULL(A.EmpSeqSub,0), ISNULL(B.DeptSeq,0), ''
      FROM #TACSlip_Sub AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '')  AS B ON ( B.EmpSeq = A.EmpSeqSub ) 
      LEFT OUTER JOIN _TDACCtr  AS C ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.CCtrSeqSub ) 
    
    

    DECLARE @SlipMstID NVARCHAR(20), 
            @SlipUnit  INT, 
            @AccUnit   INT, 
            @SlipNo    NVARCHAR(20), 
            @AccDate   NCHAR(8), 
            @Seq       INT 
    
    SELECT @SlipUnit = SlipUnit,
           @AccUnit = AccUnit, 
           @AccDate = AccDate 
      FROM #TACSlip
             

    EXEC dbo._SCOMCreateNo  'AC'        , -- 회계(HR/AC/SL/PD/ESM/PMS/SI/SITE)
                             '_TACSlip'  , -- 테이블
                             @CompanySeq , -- 법인코드
                             @AccUnit    , -- 부문코드
                             @AccDate  ,  -- 취득일
                             @SlipMstID  OUTPUT,
                             @SlipUnit   ,
                             0           ,
                             @SlipNo     OUTPUT,
                             'SlipMstID'   --컬럼명  
         
     --외부키업데이트
    UPDATE #TACSlip 
       SET SlipMstID = @SlipMstID,
           SlipNo = @SlipNo 
    
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlip', 'SlipMstSeq', 1
    -- Temp Talbe 에 생성된 키값 UPDATE
    UPDATE #TACSlip
       SET SlipMstSeq = @Seq + 1
    
     
    UPDATE A
       SET SlipMstSeq = @Seq + 1, 
           SlipUnit = (SELECT TOP 1 SlipUnitSub FROM #TACSlip_Sub)
      FROM KPX_TARBizTripCost AS A 
     WHERE BizTripSeq = (SELECT TOP 1 BizTripSeq FROM #TACSlip_Sub)
    
    UPDATE A 
       SET A.SlipMstID = B.SlipMstID, 
           A.SlipMstSeq = B.SlipMstSeq 
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
      

    CREATE TABLE #TACSlipRow 
    (
        IDX_NO          INT IDENTITY, 
        SlipSeq         INT, 
        SlipMstSeq      INT, 
        SlipMstID       NVARCHAR(100), 
        SlipID          NVARCHAR(100), 
        SlipNo          NVARCHAR(20), 
        RowNo           NVARCHAR(20), 
        AccSeq          INT, 
        UMCostType      INT, 
        SMDrOrCr        INT, 
        DrAmt           DECIMAL(19,5), 
        CrAmt           DECIMAL(19,5), 
        DrForAmt        DECIMAL(19,5), 
        CrForAmt        DECIMAL(19,5), 
        CurrSeq         INT, 
        ExRate          DECIMAL(19,5), 
        Summary         NVARCHAR(200), 
        Sort            INT, 
        DataSeq         INT, 
        AccUnit         INT, 
        SlipUnit        INT, 
        AccDate         NCHAR(8), 
        EmpSeq          INT, 
    ) 
    
    INSERT INTO #TACSlipRow 
    ( 
        SlipMstSeq, AccSeq, UMCostType, SMDrOrCr, DrAmt, 
        CrAmt, DrForAmt, CrForAmt, CurrSeq, ExRate, 
        Summary, Sort, DataSeq, SlipMstID, SlipNo, 
        AccUnit, SlipUnit, AccDate, EmpSeq 
    ) 
    SELECT B.SlipMstSeq, AccSeq, A.UMCostType, 1, CostAmtDr, 
           0, CostAmtDr, 0, 0, 0, 
           A.Remark, 1 AS Sort, DataSeq, B.SlipMstID, B.SlipNo, 
           B.AccUnit, B.SlipUnit, B.AccDate, A.EmpSeqSub
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
    
    UNION ALL 
    
    SELECT B.SlipMstSeq, AddTaxAccSeq, 0, 1, UpdateVat, 
           0, UpdateVat, 0, 0, 0, 
           A.Remark, 2 AS Sort, DataSeq, B.SlipMstID, B.SlipNo, 
           B.AccUnit, B.SlipUnit, B.AccDate, A.EmpSeqSub
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
     WHERE VatSel = '1'
    
    UNION ALL 
    
    SELECT B.SlipMstSeq, CrAccSeq, A.UMCostType, -1, 0, 
           ApprAmt, 0, ApprAmt, 0, 0, 
           A.Remark, 3, DataSeq, B.SlipMstID, B.SlipNo, 
           B.AccUnit, B.SlipUnit, B.AccDate, A.EmpSeqSub
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
    ORDER BY DataSeq, Sort
    
    --select * From #TACSlip_Sub 
    --return 
    INSERT INTO #TACSlipRow 
    ( 
        SlipMstSeq, AccSeq, UMCostType, SMDrOrCr, DrAmt, 
        CrAmt, DrForAmt, CrForAmt, CurrSeq, ExRate, 
        Summary, Sort, DataSeq, SlipMstID, SlipNo, 
        AccUnit, SlipUnit, AccDate, EmpSeq 
    ) 
    SELECT TOP 1 B.SlipMstSeq, A.AccSeqSub, A.UMCostTypeSub, 1, A.CardOutCostSub, 
           0, A.CardOutCostSub, 0, 0, 0, 
           '출장비 법인카드 외 비용', 98,DataSeq + 100, B.SlipMstID, B.SlipNo, 
           B.AccUnit, B.SlipUnit, B.AccDate, A.EmpSeqSub
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
    
    UNION ALL 
    
    SELECT TOP 1 B.SlipMstSeq, A.OppAccSeqSub, 0, -1, 0, 
           A.CardOutCostSub, 0, A.CardOutCostSub, 0, 0, 
           '출장비 법인카드 외 비용', 99, DataSeq + 100, B.SlipMstID, B.SlipNo, 
           B.AccUnit, B.SlipUnit, B.AccDate, A.EmpSeqSub
      FROM #TACSlip_Sub AS A 
      JOIN #TACSlip     AS B ON ( 1 = 1 ) 
    

    
    --SELECT * FROM #TACSlipRow 
    --return 
    DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TACSlipRow'
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlipRow', 'SlipSeq', 1
    
    DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TACSlipRow'
        
    UPDATE A 
       SET SlipSeq = @Seq + A.IDX_NO 
      FROM #TACSlipRow AS A 
    
    -------------------------------------------
    -- 전표 번호부여(맨 마지막 처리)
    -------------------------------------------
    DECLARE @RowCnt INT 
     
    EXEC dbo._SCOMEnv @CompanySeq,4011,@UserSeq,@@PROCID, @RowCnt OUTPUT
    
    
    IF @RowCnt = 0 OR @RowCnt IS NULL SELECT @RowCnt = 3
    
    UPDATE #TACSlipRow
       SET RowNo = RIGHT('0000' + CAST(IDX_NO AS NVARCHAR), @RowCnt)
      WHERE RowNo = '' OR RowNo IS NULL
      
      UPDATE #TACSlipRow
        SET SlipID = SlipMstID + '-' + RowNo
    
    
    --SELECT * FROM #TACSlipRow 
    
    CREATE TABLE #TACSlipCost 
    (
        SlipSeq     INT, 
        Serl        INT, 
        CostDeptSeq INT, 
        CostCCtrSeq INT, 
        DivRate     DECIMAL(19,5), 
        DrAmt       DECIMAL(19,5), 
        CrAmt       DECIMAL(19,5), 
        DrForAmt    DECIMAL(19,5), 
        CrForAmt    DECIMAL(19,5)
    )
    
    INSERT INTO #TACSlipCost 
    (
        SlipSeq, Serl, CostDeptSeq, CostCCtrSeq, DivRate, 
        DrAmt, CrAmt, DrForAmt, CrForAmt 
    )
    SELECT A.SlipSeq, 1, 0, 0, 100, 
           A.DrAmt, A.CrAmt, A.DrAmt, A.CrAmt
      FROM #TACSlipRow AS A 
    
    
    CREATE TABLE #TACSlipRem 
    (
        SlipSeq     INT, 
        RemSeq      INT, 
        RemValSeq   INT, 
        RemValText  NVARCHAR(100) 
    )
    
    -- 법인카드 관리항목 
    INSERT INTO #TACSlipRem ( SlipSeq, RemSeq, RemValSeq, RemValText ) 
    SELECT A.SlipSeq, B.RemSeq, B.RemValSeq, B.RemValText 
      FROM #TACSlipRow AS A 
      LEFT OUTER JOIN (
                        SELECT A.DataSeq, 1017 AS RemSeq, A.CustSeq AS RemValSeq, '' AS RemValText
                          FROM #TACSlip_Sub  AS A 
                        
                        UNION ALL 
                        
                        SELECT A.DataSeq, 1006 AS RemSeq, B.CardSeq, ''
                          FROM #TACSlip_Sub AS A 
                          LEFT OUTER JOIN _TDACard AS B ON ( B.CompanySeq = @CompanySeq AND LTRIM(RTRIM(REPLACE(B.CardNo,'-',''))) = LTRIM(RTRIM(A.CardNo)) ) 
                        
                        UNION ALL 
                        
                        SELECT A.DataSeq, 3015 AS RemSeq, 0, A.ChainName
                          FROM #TACSlip_Sub A
                        
                        UNION ALL 
                        
                        SELECT A.DataSeq, 3117 AS RemSeq, 0, ApprNo
                          FROM #TACSlip_Sub AS A 
                          
                        UNION ALL 
                        
                        SELECT A.DataSeq, 3011 AS RemSeq, 0, ApprDate
                          FROM #TACSlip_Sub AS A 
                      ) AS B ON ( B.DataSeq = A.DataSeq ) 
     WHERE A.DataSeq < 100 
       AND A.CrAmt <> 0 
    

    -- 법인카드 외 비용 관리항목(사원)
    INSERT INTO #TACSlipRem ( SlipSeq, RemSeq, RemValSeq, RemValText ) 
    SELECT A.SlipSeq, 1002, A.EmpSeq, '' 
      FROM #TACSlipRow AS A 
     WHERE A.Sort = 99 
    
    
    INSERT INTO _TACSlip
    (
        CompanySeq,     SlipMstSeq,     SlipMstID,      AccUnit,        SlipUnit,        
        AccDate,        SlipNo,         SlipKind,       RegEmpSeq,      RegDeptSeq,        
        Remark,         SMCurrStatus,   AptDate,        AptEmpSeq,      AptDeptSeq,        
        AptRemark,      SMCheckStatus,  CheckOrigin,    IsSet,          SetSlipNo,        
        SetEmpSeq,      SetDeptSeq,     LastUserSeq,    LastDateTime,   RegDateTime,        
        RegAccDate,     SetSlipID
    ) 
    SELECT @CompanySeq,     A.SlipMstSeq,     A.SlipMstID,      A.AccUnit,        A.SlipUnit,        
           A.AccDate,       A.SlipNo,         A.SlipKind,       A.RegEmpSeq,      A.RegDeptSeq,        
           A.Remark,        0,                '',               0,                0,        
           '',              0,                0,                '',               '',        
           0,               0,                @UserSeq,         GETDATE(),        GETDATE(),        
           A.AccDate,       ''
      FROM #TACSlip AS A 
    
    
    INSERT INTO _TACSlipRow
    (
        CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,         
        SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit,         
        AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,         
        DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         DivExRate,         
        EvidSeq,        TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind,         
        CostItemSeq,    Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq,         
        IsSet,          CoCustSeq,      LastDateTime,   LastUserSeq
    )
    SELECT @CompanySeq,     A.SlipSeq,        A.SlipMstSeq,     A.SlipID,         A.AccUnit,         
           A.SlipUnit,      A.AccDate,        A.SlipNo,         A.RowNo,          A.SlipUnit,         
           A.AccSeq,        A.UMCostType,     A.SMDrOrCr,       A.DrAmt,          A.CrAmt,         
           A.DrForAmt,      A.CrForAmt,       A.CurrSeq,        A.ExRate,         0,         
           0,               NULL,             NULL,             0,                0,         
           0,               A.Summary,        0,                0,                0,         
           '',              0,                GETDATE(),        @UserSeq
      FROM #TACSlipRow AS A 
    
    INSERT INTO _TACSlipCost 
    (
        CompanySeq,     SlipSeq,        Serl,       CostDeptSeq,    CostCCtrSeq,         
        DivRate,        DrAmt,          CrAmt,      DrForAmt,       CrForAmt
    )
    SELECT @COmpanySeq, A.SlipSeq, A.Serl, A.CostDeptSeq, A.CostCCtrSeq, 
           A.DivRate, A.DrAmt, A.CrAmt, A.DrForAmt, A.CrForAmt
      FROM #TACSlipCost AS A  
    
    INSERT INTO _TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) 
    SELECT @CompanySeq, A.SlipSeq, A.RemSeq, A.RemValSeq, A.RemValText
      FROM #TACSlipRem AS A 
    
    
    -- 전표 확정데이터 생성
    CREATE TABLE #TCOMConfirmCreate ( TABLENAME NVARCHAR(20), CfmSeq INT, CfmSerl INT, CfmSubSerl INT )
    INSERT INTO #TCOMConfirmCreate
    SELECT DISTINCT '_TACSlip', SlipMstSeq, 0, 0
      FROM #TACSlip
    
    EXEC _SCOMConfirmCreateSub @CompanySeq, '#TCOMConfirmCreate', 'TABLENAME', 'CfmSeq', 'CfmSerl', 'CfmSubSerl', @UserSeq, 3093 -- 분개전표입력
    
    IF @@ERROR <> 0 RETURN 
    
    
    UPDATE B 
       SET SlipSeq = A.SlipSeq 
      FROM #TACSlipRow AS A 
      JOIN #TACSlip_Sub AS B ON ( B.DataSeq = A.DataSeq ) 
     WHERE A.SMDrOrCr = 1 
       AND A.Sort IN ( 1, 98 ) 
    
    UPDATE A 
       SET SlipSeq = B.SlipSeq 
      FROM _TSIAFebCardCfm AS A 
      JOIN #TACSlip_Sub    AS B ON ( B.CardNo = A.CARD_CD AND A.APPR_DATE = B.ApprDate AND A.APPR_NO = B.ApprNo AND A.APPR_SEQ = B.ApprSeq AND A.CANCEL_YN = B.CANCEL_YN ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    SELECT * FROM #TACSlip_Sub 
      
    RETURN  
GO 
begin tran 
exec KPX_SARBizTripCostSlipSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccName>복리후생비 간식대</AccName>
    <AccSeq>532</AccSeq>
    <AccSeqOld>532</AccSeqOld>
    <AddTaxAccNameOld>부가세대급금</AddTaxAccNameOld>
    <AddTaxAccSeq>64</AddTaxAccSeq>
    <AddTaxAccSeqOld>64</AddTaxAccSeqOld>
    <APPR_BUY_SEQ>0</APPR_BUY_SEQ>
    <APPR_TIME xml:space="preserve">            </APPR_TIME>
    <ApprAmt>50000.00000</ApprAmt>
    <ApprDate>20080805</ApprDate>
    <ApprNo>74195094</ApprNo>
    <ApprSeq>1</ApprSeq>
    <ApprTax>0.00000</ApprTax>
    <APPRTOT>0.00000</APPRTOT>
    <BizUnit>2</BizUnit>
    <BizUnitName>상정-본사</BizUnitName>
    <CANCEL_YN>1</CANCEL_YN>
    <CancelYN>승</CancelYN>
    <CardCustName>은행나무집</CardCustName>
    <CardCustSeq>6312</CardCustSeq>
    <CardName>4336-9270-2834-9307</CardName>
    <CardNo>4336927028349307</CardNo>
    <CardSeq>58</CardSeq>
    <CCtrName />
    <CCtrSeq>0</CCtrSeq>
    <CHAIN_TYPE xml:space="preserve">  </CHAIN_TYPE>
    <ChainBizNo>6098163043</ChainBizNo>
    <ChainName>주식회사불모</ChainName>
    <ChainType>미확인       </ChainType>
    <ChannelName>FBS법인카드사용거래처</ChannelName>
    <ChannelSeq>8004036</ChannelSeq>
    <ComOrPriv>4019001</ComOrPriv>
    <ComOrPrivName>법인</ComOrPrivName>
    <CostAmtDr>45455.00000</CostAmtDr>
    <CrAccName>미지급금</CrAccName>
    <CrAccSeq>223</CrAccSeq>
    <CURAMT>0.00000</CURAMT>
    <CustName>주식회사불모</CustName>
    <CustSeq>41488</CustSeq>
    <DayOfTheWeek>화요일</DayOfTheWeek>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <DisSupplyAmt>0.00000</DisSupplyAmt>
    <Dummy1 />
    <Dummy10 />
    <Dummy2 />
    <Dummy3 />
    <Dummy4 />
    <Dummy5 />
    <Dummy6>0.00000</Dummy6>
    <Dummy7>0.00000</Dummy7>
    <Dummy8 />
    <Dummy9 />
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EvidName>신용카드</EvidName>
    <EvidSeq>3</EvidSeq>
    <HALBU>0                   </HALBU>
    <IsCustSave>1</IsCustSave>
    <IsDefine>0</IsDefine>
    <IsDisVatYN>0</IsDisVatYN>
    <IsEmpSave>1</IsEmpSave>
    <IsNonVat>0</IsNonVat>
    <LastDateTime>2015-01-08T14:20:56</LastDateTime>
    <LastUserName />
    <LastUserSeq>50322</LastUserSeq>
    <MASTER>Master</MASTER>
    <MCCCODE>1234</MCCCODE>
    <MCCNAME>IT</MCCNAME>
    <MCodeHelpParams>2014||||</MCodeHelpParams>
    <MCodeHelpSeq>40031</MCodeHelpSeq>
    <MERCHADDR1>서울시 강서구</MERCHADDR1>
    <MERCHADDR2>염창동 우림블루나인</MERCHADDR2>
    <MERCHCESSDATE xml:space="preserve">          </MERCHCESSDATE>
    <MERCHZIPCODE>123-45</MERCHZIPCODE>
    <ModDate>20150104</ModDate>
    <NotVatAmt>0.00000</NotVatAmt>
    <NotVatSel>0</NotVatSel>
    <PJTName xml:space="preserve"> </PJTName>
    <PJTSeq>0</PJTSeq>
    <ProcType>미처리     </ProcType>
    <PURDATE xml:space="preserve">        </PURDATE>
    <Remark>ㅅㅅ</Remark>
    <RemName>복리후생비세목</RemName>
    <RemSeq>2014</RemSeq>
    <RemValue />
    <RemValueSeq>0</RemValueSeq>
    <Sel>0</Sel>
    <SERVTYPEYN xml:space="preserve"> </SERVTYPEYN>
    <SlipId>0</SlipId>
    <SlipSeq>0</SlipSeq>
    <STTL_DATE xml:space="preserve">        </STTL_DATE>
    <SupplyAmt>45455.00000</SupplyAmt>
    <TAXTYPE />
    <TaxUnit>2</TaxUnit>
    <TaxUnitName>(주)영림산업12_0001</TaxUnitName>
    <TIP_AMT>0.00000</TIP_AMT>
    <TotalAmt>50000.00000</TotalAmt>
    <UMCardKind>4004002</UMCardKind>
    <UMCardKindName>씨티카드</UMCardKindName>
    <UMCostType>4001005</UMCostType>
    <UMCostTypeName>판매</UMCostTypeName>
    <UpdateVat>4545.00000</UpdateVat>
    <VatSel>1</VatSel>
    <VatSttlItem>부가세대급금</VatSttlItem>
    <VatYN>1</VatYN>
    <BizTripSeq>8</BizTripSeq>
    <CardOutCostSub>123124124.00000</CardOutCostSub>
    <SlipUnitSub>1</SlipUnitSub>
    <OppAccSeqSub>5</OppAccSeqSub>
    <EmpSeqSub>1317</EmpSeqSub>
    <UMCostTypeSub>4001001</UMCostTypeSub>
    <AccSeqSub>1182</AccSeqSub>
    <CCtrSeqSub>1239</CCtrSeqSub>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccName>복리후생비 간식대</AccName>
    <AccSeq>532</AccSeq>
    <AccSeqOld>532</AccSeqOld>
    <AddTaxAccNameOld>부가세대급금</AddTaxAccNameOld>
    <AddTaxAccSeq>64</AddTaxAccSeq>
    <AddTaxAccSeqOld>64</AddTaxAccSeqOld>
    <APPR_BUY_SEQ>0</APPR_BUY_SEQ>
    <APPR_TIME xml:space="preserve">            </APPR_TIME>
    <ApprAmt>-13900.00000</ApprAmt>
    <ApprDate>20080805</ApprDate>
    <ApprNo>36949294</ApprNo>
    <ApprSeq>2</ApprSeq>
    <ApprTax>0.00000</ApprTax>
    <APPRTOT>0.00000</APPRTOT>
    <BizUnit>2</BizUnit>
    <BizUnitName>상정-본사</BizUnitName>
    <CANCEL_YN>3</CANCEL_YN>
    <CancelYN xml:space="preserve"> </CancelYN>
    <CardCustName>은행나무집</CardCustName>
    <CardCustSeq>6312</CardCustSeq>
    <CardName>미영테스트</CardName>
    <CardNo>4336927028349406</CardNo>
    <CardSeq>59</CardSeq>
    <CCtrName>이찬복프로젝트</CCtrName>
    <CCtrSeq>862</CCtrSeq>
    <CHAIN_TYPE xml:space="preserve">  </CHAIN_TYPE>
    <ChainBizNo>4098518024</ChainBizNo>
    <ChainName>삼성테스코(주)홈플러스동광주점</ChainName>
    <ChainType>미확인       </ChainType>
    <ChannelName>FBS법인카드사용거래처</ChannelName>
    <ChannelSeq>8004036</ChannelSeq>
    <ComOrPriv>4019001</ComOrPriv>
    <ComOrPrivName>법인</ComOrPrivName>
    <CostAmtDr>-12636.00000</CostAmtDr>
    <CrAccName>미지급금</CrAccName>
    <CrAccSeq>223</CrAccSeq>
    <CURAMT>0.00000</CURAMT>
    <CustName>삼성테스코(주)홈플러스동광주점</CustName>
    <CustSeq>41492</CustSeq>
    <DayOfTheWeek>화요일</DayOfTheWeek>
    <DeptName>생산관리팀</DeptName>
    <DeptSeq>23</DeptSeq>
    <DisSupplyAmt>0.00000</DisSupplyAmt>
    <Dummy1 />
    <Dummy10 />
    <Dummy2 />
    <Dummy3 />
    <Dummy4 />
    <Dummy5 />
    <Dummy6>0.00000</Dummy6>
    <Dummy7>0.00000</Dummy7>
    <Dummy8 />
    <Dummy9 />
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EvidName>신용카드</EvidName>
    <EvidSeq>3</EvidSeq>
    <HALBU>0                   </HALBU>
    <IsCustSave>1</IsCustSave>
    <IsDefine>0</IsDefine>
    <IsDisVatYN>0</IsDisVatYN>
    <IsEmpSave>1</IsEmpSave>
    <IsNonVat>0</IsNonVat>
    <LastDateTime>2015-01-08T14:20:56</LastDateTime>
    <LastUserName />
    <LastUserSeq>50322</LastUserSeq>
    <MASTER>Master</MASTER>
    <MCCCODE>1234</MCCCODE>
    <MCCNAME>IT</MCCNAME>
    <MCodeHelpParams>2014||||</MCodeHelpParams>
    <MCodeHelpSeq>40031</MCodeHelpSeq>
    <MERCHADDR1>서울시 강서구</MERCHADDR1>
    <MERCHADDR2>염창동 우림블루나인</MERCHADDR2>
    <MERCHCESSDATE xml:space="preserve">          </MERCHCESSDATE>
    <MERCHZIPCODE>123-45</MERCHZIPCODE>
    <ModDate>20150104</ModDate>
    <NotVatAmt>0.00000</NotVatAmt>
    <NotVatSel>0</NotVatSel>
    <PJTName xml:space="preserve"> </PJTName>
    <PJTSeq>0</PJTSeq>
    <ProcType>미처리     </ProcType>
    <PURDATE xml:space="preserve">        </PURDATE>
    <Remark />
    <RemName>복리후생비세목</RemName>
    <RemSeq>2014</RemSeq>
    <RemValue>식대</RemValue>
    <RemValueSeq>2014002</RemValueSeq>
    <Sel>0</Sel>
    <SERVTYPEYN xml:space="preserve"> </SERVTYPEYN>
    <SlipId>0</SlipId>
    <SlipSeq>0</SlipSeq>
    <STTL_DATE xml:space="preserve">        </STTL_DATE>
    <SupplyAmt>-12636.00000</SupplyAmt>
    <TAXTYPE />
    <TaxUnit>2</TaxUnit>
    <TaxUnitName>(주)영림산업12_0001</TaxUnitName>
    <TIP_AMT>0.00000</TIP_AMT>
    <TotalAmt>-13900.00000</TotalAmt>
    <UMCardKind>4004002</UMCardKind>
    <UMCardKindName>씨티카드</UMCardKindName>
    <UMCostType>4001005</UMCostType>
    <UMCostTypeName>판매</UMCostTypeName>
    <UpdateVat>-1264.00000</UpdateVat>
    <VatSel>1</VatSel>
    <VatSttlItem>부가세대급금</VatSttlItem>
    <VatYN>1</VatYN>
    <BizTripSeq>8</BizTripSeq>
    <CardOutCostSub>123124124.00000</CardOutCostSub>
    <SlipUnitSub>1</SlipUnitSub>
    <OppAccSeqSub>5</OppAccSeqSub>
    <EmpSeqSub>1317</EmpSeqSub>
    <UMCostTypeSub>4001001</UMCostTypeSub>
    <AccSeqSub>1182</AccSeqSub>
    <CCtrSeqSub>1239</CCtrSeqSub>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022816

--select * from _TACSlip where companyseq = 1 and slipmstseq = 5003412
--select * from _TACSlipRow where companyseq = 1 and SlipMstSeq = ( select SlipMstSeq from _TACSlip where companyseq = 1 and slipmstseq = 5003412)
--select * from _TACSlipCost where companyseq = 1 and SlipSeq in (select SlipSeq from _TACSlipRow where companyseq = 1 and SlipMstSeq = ( select SlipMstSeq from _TACSlip where companyseq = 1 and slipmstseq = 5003412))
--select * from _TACSlipRem where companyseq = 1 and SlipSeq in (select SlipSeq from _TACSlipRow where companyseq = 1 and SlipMstSeq = ( select SlipMstSeq from _TACSlip where companyseq = 1 and slipmstseq = 5003412))
--select * From _TACSlip_Confirm where cfmseq = 5003412
rollback 