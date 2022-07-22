  
IF OBJECT_ID('hencom_SPUDelvInBuyingAccSetting') IS NOT NULL   
    DROP PROC hencom_SPUDelvInBuyingAccSetting  
GO  
  
-- v2017.06.14 
  
-- 구매외주입고정산처리-계정과목가져오기 by 이재천
CREATE PROC hencom_SPUDelvInBuyingAccSetting  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #TPUBuyingAcc (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUBuyingAcc'   
    IF @@ERROR <> 0 RETURN    
    
    -----------------------------------------------------------------------------------------
    -- 입고기준으로 납품데이터 찾기, Srt
    -----------------------------------------------------------------------------------------
    -- 기준데이터
    CREATE TABLE #DelvIn
    (
        IDX_NO          INT IDENTITY, 
        DelvInSeq       INT, 
        DelvInSerl      INT, 
        BuyingAccSeq    INT, 
        DelvSeq         INT, 
        DelvSerl        INT 
    )
    INSERT INTO #DelvIn ( DelvInSeq, DelvInSerl, BuyingAccSeq ) 
    SELECT C.DelvInSeq, C.DelvInSerl, B.BuyingAccSeq 
      FROM #TPUBuyingAcc    AS A 
      JOIN _TPUBuyingAcc    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BuyingAccSeq = A.BuyingAccSeq ) 
      JOIN _TPUDelvInItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DelvInSeq = B.SourceSeq AND C.DelvInSerl = B.SourceSerl ) 

    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TPUDelvItem'   -- 찾을 데이터의 테이블

    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
          
    EXEC _SCOMSourceTracking 
        @CompanySeq = @CompanySeq, 
        @TableName = '_TPUDelvInItem',  -- 기준 테이블
        @TempTableName = '#DelvIn',  -- 기준템프테이블
        @TempSeqColumnName = 'DelvInSeq',  -- 템프테이블 Seq
        @TempSerlColumnName = 'DelvInSerl',  -- 템프테이블 Serl
        @TempSubSerlColumnName = '' 
    
    -- 원천 코드 메인Table 업데이트
    UPDATE A
       SET DelvSeq  = B.Seq, 
           DelvSerl = B.Serl
      FROM #DelvIn AS A 
      JOIN #TCOMSourceTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
    

    -----------------------------------------------------------------------------------------
    -- 사용자정의코드 : 매입계정과목연결_hencom ( 1015322 ) 
    -----------------------------------------------------------------------------------------
    SELECT B.ValueSeq AS ItemLClassSeq, -- 대분류코드
           C.ValueSeq AS AntiAccSeq,    -- 상대계정코드 
           D.ValueSeq AS EvidSeq,       -- 증빙코드 
           E.ValueSeq AS DeliAccSeq,    -- 운송계정코드 
           F.ValueSeq AS DeliVsAccSeq,  -- 운송상대계정코드 
           G.ValueSeq AS DeliVatAccSeq, -- 운송부가세계정 
           H.ValueSeq AS DeliEvidSeq    -- 운송증빙 
      INTO #AccSeq   
      FROM _TDAUMinor                 AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) -- 대분류
      LEFT OUTER JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) -- 상대계정
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000003 ) -- 증빙 
      LEFT OUTER JOIN _TDAUMinorValue AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.MinorSeq AND E.Serl = 1000004 ) -- 운송계정 
      LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.MinorSeq AND F.Serl = 1000005 ) -- 운송상대계정  
      LEFT OUTER JOIN _TDAUMinorValue AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.MinorSeq AND G.Serl = 1000006 ) -- 운송부가세 
      LEFT OUTER JOIN _TDAUMinorValue AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.MinorSeq AND H.Serl = 1000007 ) -- 운송증빙 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015322
    

    -----------------------------------------------------------------------------------------
    -- 사용자정의 값으로 설정한대로 업데이트하기 
    -----------------------------------------------------------------------------------------
    UPDATE A
       SET AntiAccSeq       = D.AntiAccSeq,     -- 상대계정코드 
           AntiAccName      = E.AccName,        -- 상대계정
           EvidSeq          = D.EvidSeq,        -- 증빙코드 
           EvidName         = F.EvidName,       -- 증빙
           DeliAccSeq       = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN D.DeliAccSeq ELSE 0 END,    -- 운송계정코드 ( 운송금액이 있는 건만 적용 ) 
           DeliAccName      = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN G.AccName ELSE '' END,      -- 운송계정 ( 운송금액이 있는 건만 적용 ) 
           DeliVsAccSeq     = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN D.DeliVsAccSeq ELSE 0 END,  -- 운송상대계정코드 ( 운송금액이 있는 건만 적용 ) 
           DeliVsAccName    = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN H.AccName ELSE '' END,      -- 운송상대계정 ( 운송금액이 있는 건만 적용 ) 
           DeliVatAccSeq    = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN D.DeliVatAccSeq ELSE 0 END, -- 운송부가세계정코드 ( 운송금액이 있는 건만 적용 ) 
           DeliVatAccName   = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN I.AccName ELSE '' END,      -- 운송부가세코드 ( 운송금액이 있는 건만 적용 ) 
           DeliEvidSeq      = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN D.DeliEvidSeq ELSE 0 END,   -- 운송증빙코드 ( 운송금액이 있는 건만 적용 ) 
           DeliEvidName     = CASE WHEN ISNULL(L.DeliChargeAmt,0) <> 0 THEN J.EvidName ELSE '' END,     -- 운송증빙 ( 운송금액이 있는 건만 적용 ) 
           IsChg            = '1'               -- 변경여부 
      FROM #TPUBuyingAcc            AS A 
      LEFT OUTER JOIN _TPUBuyingAcc AS K ON ( K.CompanySeq = @CompanySeq AND K.BuyingAccSeq = A.BuyingAccSeq ) 
      LEFT OUTER JOIN _TDAItemClass AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _VDAItemClass AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemClassSSeq = B.UMItemClass ) 
                 JOIN #AccSeq       AS D ON ( D.ItemLClassSeq = C.ItemClassLSeq )
      LEFT OUTER JOIN _TDAAccount   AS E ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = D.AntiAccSeq ) 
      LEFT OUTER JOIN _TDAEvid      AS F ON ( F.CompanySeq = @CompanySeq AND F.EvidSeq = D.EvidSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS G ON ( G.CompanySeq = @CompanySeq AND G.AccSeq = D.DeliAccSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS H ON ( H.CompanySeq = @CompanySeq AND H.AccSeq = D.DeliVsAccSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS I ON ( I.CompanySeq = @CompanySeq AND I.AccSeq = D.DeliVatAccSeq ) 
      LEFT OUTER JOIN _TDAEvid      AS J ON ( J.CompanySeq = @CompanySeq AND J.EvidSeq = D.DeliEvidSeq ) 
      LEFT OUTER JOIN #DelvIn       AS M ON ( M.BuyingAccSeq = A.BuyingAccSeq ) 
      LEFT OUTER JOIN hencom_TPUDelvItemAdd AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = M.DelvSeq AND L.DelvSerl = M.DelvSerl ) 
     WHERE K.SlipSeq IS NULL OR K.SlipSeq = 0 -- 전표생선된 내역 제외
    
    
    -----------------------------------------------------------------------------------------
    -- 처리결과반영하기 위한 조회
    -----------------------------------------------------------------------------------------
    SELECT * FROM #TPUBuyingAcc ORDER BY IDX_NO
    
    RETURN  
    go
begin tran 
exec hencom_SPUDelvInBuyingAccSetting @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>0</BuyingAccSeq>
    <ItemSeq>0</ItemSeq>
    <AntiAccSeq>0</AntiAccSeq>
    <AntiAccName />
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3472</BuyingAccSeq>
    <ItemSeq>4037</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3476</BuyingAccSeq>
    <ItemSeq>4060</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3598</BuyingAccSeq>
    <ItemSeq>4393</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3600</BuyingAccSeq>
    <ItemSeq>4367</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3996</BuyingAccSeq>
    <ItemSeq>4127</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3997</BuyingAccSeq>
    <ItemSeq>4127</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3998</BuyingAccSeq>
    <ItemSeq>4150</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3999</BuyingAccSeq>
    <ItemSeq>4153</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4000</BuyingAccSeq>
    <ItemSeq>4153</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4001</BuyingAccSeq>
    <ItemSeq>4128</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3466</BuyingAccSeq>
    <ItemSeq>4037</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3468</BuyingAccSeq>
    <ItemSeq>4060</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3471</BuyingAccSeq>
    <ItemSeq>4060</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3614</BuyingAccSeq>
    <ItemSeq>4367</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3615</BuyingAccSeq>
    <ItemSeq>4367</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4030</BuyingAccSeq>
    <ItemSeq>4127</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4031</BuyingAccSeq>
    <ItemSeq>4153</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4032</BuyingAccSeq>
    <ItemSeq>4128</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4033</BuyingAccSeq>
    <ItemSeq>4127</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4034</BuyingAccSeq>
    <ItemSeq>4153</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3609</BuyingAccSeq>
    <ItemSeq>4367</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3610</BuyingAccSeq>
    <ItemSeq>4393</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3611</BuyingAccSeq>
    <ItemSeq>4367</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3621</BuyingAccSeq>
    <ItemSeq>4060</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3930</BuyingAccSeq>
    <ItemSeq>4394</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4042</BuyingAccSeq>
    <ItemSeq>4127</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4336</BuyingAccSeq>
    <ItemSeq>4187</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5600</BuyingAccSeq>
    <ItemSeq>4187</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3453</BuyingAccSeq>
    <ItemSeq>4263</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3558</BuyingAccSeq>
    <ItemSeq>3933</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>32</IDX_NO>
    <DataSeq>32</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3497</BuyingAccSeq>
    <ItemSeq>4263</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>33</IDX_NO>
    <DataSeq>33</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3708</BuyingAccSeq>
    <ItemSeq>4263</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>34</IDX_NO>
    <DataSeq>34</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3481</BuyingAccSeq>
    <ItemSeq>3999</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>35</IDX_NO>
    <DataSeq>35</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3559</BuyingAccSeq>
    <ItemSeq>3939</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>36</IDX_NO>
    <DataSeq>36</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3593</BuyingAccSeq>
    <ItemSeq>4389</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>37</IDX_NO>
    <DataSeq>37</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3630</BuyingAccSeq>
    <ItemSeq>4359</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>38</IDX_NO>
    <DataSeq>38</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3469</BuyingAccSeq>
    <ItemSeq>3999</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>39</IDX_NO>
    <DataSeq>39</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3547</BuyingAccSeq>
    <ItemSeq>4149</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>40</IDX_NO>
    <DataSeq>40</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3619</BuyingAccSeq>
    <ItemSeq>4059</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>41</IDX_NO>
    <DataSeq>41</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3633</BuyingAccSeq>
    <ItemSeq>4359</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>42</IDX_NO>
    <DataSeq>42</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4567</BuyingAccSeq>
    <ItemSeq>4389</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>43</IDX_NO>
    <DataSeq>43</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3635</BuyingAccSeq>
    <ItemSeq>4359</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>44</IDX_NO>
    <DataSeq>44</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3480</BuyingAccSeq>
    <ItemSeq>3991</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>45</IDX_NO>
    <DataSeq>45</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3479</BuyingAccSeq>
    <ItemSeq>3991</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>46</IDX_NO>
    <DataSeq>46</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3467</BuyingAccSeq>
    <ItemSeq>3991</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>47</IDX_NO>
    <DataSeq>47</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3572</BuyingAccSeq>
    <ItemSeq>3991</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>48</IDX_NO>
    <DataSeq>48</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3596</BuyingAccSeq>
    <ItemSeq>4323</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>49</IDX_NO>
    <DataSeq>49</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3674</BuyingAccSeq>
    <ItemSeq>4233</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>50</IDX_NO>
    <DataSeq>50</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3601</BuyingAccSeq>
    <ItemSeq>4323</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>51</IDX_NO>
    <DataSeq>51</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3613</BuyingAccSeq>
    <ItemSeq>4383</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>52</IDX_NO>
    <DataSeq>52</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3700</BuyingAccSeq>
    <ItemSeq>4233</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>53</IDX_NO>
    <DataSeq>53</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3703</BuyingAccSeq>
    <ItemSeq>4233</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>54</IDX_NO>
    <DataSeq>54</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4072</BuyingAccSeq>
    <ItemSeq>4053</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>55</IDX_NO>
    <DataSeq>55</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4340</BuyingAccSeq>
    <ItemSeq>4203</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>56</IDX_NO>
    <DataSeq>56</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3629</BuyingAccSeq>
    <ItemSeq>4351</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>57</IDX_NO>
    <DataSeq>57</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3632</BuyingAccSeq>
    <ItemSeq>4351</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>58</IDX_NO>
    <DataSeq>58</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3637</BuyingAccSeq>
    <ItemSeq>4351</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>59</IDX_NO>
    <DataSeq>59</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3582</BuyingAccSeq>
    <ItemSeq>4381</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>60</IDX_NO>
    <DataSeq>60</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3612</BuyingAccSeq>
    <ItemSeq>4381</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>61</IDX_NO>
    <DataSeq>61</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3606</BuyingAccSeq>
    <ItemSeq>4381</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>62</IDX_NO>
    <DataSeq>62</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3542</BuyingAccSeq>
    <ItemSeq>4141</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>63</IDX_NO>
    <DataSeq>63</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3544</BuyingAccSeq>
    <ItemSeq>4141</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>64</IDX_NO>
    <DataSeq>64</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4038</BuyingAccSeq>
    <ItemSeq>4141</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>65</IDX_NO>
    <DataSeq>65</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3560</BuyingAccSeq>
    <ItemSeq>3931</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>66</IDX_NO>
    <DataSeq>66</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3551</BuyingAccSeq>
    <ItemSeq>3931</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>67</IDX_NO>
    <DataSeq>67</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4666</BuyingAccSeq>
    <ItemSeq>4164</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>68</IDX_NO>
    <DataSeq>68</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3604</BuyingAccSeq>
    <ItemSeq>4314</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>69</IDX_NO>
    <DataSeq>69</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3477</BuyingAccSeq>
    <ItemSeq>3977</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>70</IDX_NO>
    <DataSeq>70</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3473</BuyingAccSeq>
    <ItemSeq>4003</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>71</IDX_NO>
    <DataSeq>71</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3475</BuyingAccSeq>
    <ItemSeq>3977</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>72</IDX_NO>
    <DataSeq>72</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3573</BuyingAccSeq>
    <ItemSeq>4003</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>73</IDX_NO>
    <DataSeq>73</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3478</BuyingAccSeq>
    <ItemSeq>3993</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>74</IDX_NO>
    <DataSeq>74</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3631</BuyingAccSeq>
    <ItemSeq>4353</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>75</IDX_NO>
    <DataSeq>75</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3470</BuyingAccSeq>
    <ItemSeq>3993</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>76</IDX_NO>
    <DataSeq>76</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3634</BuyingAccSeq>
    <ItemSeq>4353</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>77</IDX_NO>
    <DataSeq>77</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3636</BuyingAccSeq>
    <ItemSeq>4353</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>78</IDX_NO>
    <DataSeq>78</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3543</BuyingAccSeq>
    <ItemSeq>4143</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>79</IDX_NO>
    <DataSeq>79</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3616</BuyingAccSeq>
    <ItemSeq>4383</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>80</IDX_NO>
    <DataSeq>80</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3545</BuyingAccSeq>
    <ItemSeq>4143</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>81</IDX_NO>
    <DataSeq>81</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3608</BuyingAccSeq>
    <ItemSeq>4383</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>82</IDX_NO>
    <DataSeq>82</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3489</BuyingAccSeq>
    <ItemSeq>3965</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>83</IDX_NO>
    <DataSeq>83</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3769</BuyingAccSeq>
    <ItemSeq>3954</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>84</IDX_NO>
    <DataSeq>84</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3427</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>85</IDX_NO>
    <DataSeq>85</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3438</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>86</IDX_NO>
    <DataSeq>86</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3566</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>87</IDX_NO>
    <DataSeq>87</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3474</BuyingAccSeq>
    <ItemSeq>4051</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>88</IDX_NO>
    <DataSeq>88</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4073</BuyingAccSeq>
    <ItemSeq>4051</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>89</IDX_NO>
    <DataSeq>89</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4265</BuyingAccSeq>
    <ItemSeq>4081</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>90</IDX_NO>
    <DataSeq>90</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3450</BuyingAccSeq>
    <ItemSeq>4261</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>91</IDX_NO>
    <DataSeq>91</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3492</BuyingAccSeq>
    <ItemSeq>4261</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>92</IDX_NO>
    <DataSeq>92</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3707</BuyingAccSeq>
    <ItemSeq>4261</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>93</IDX_NO>
    <DataSeq>93</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3448</BuyingAccSeq>
    <ItemSeq>4261</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>94</IDX_NO>
    <DataSeq>94</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3491</BuyingAccSeq>
    <ItemSeq>4261</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>95</IDX_NO>
    <DataSeq>95</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3561</BuyingAccSeq>
    <ItemSeq>3931</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>96</IDX_NO>
    <DataSeq>96</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3597</BuyingAccSeq>
    <ItemSeq>4321</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>97</IDX_NO>
    <DataSeq>97</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3672</BuyingAccSeq>
    <ItemSeq>4231</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>98</IDX_NO>
    <DataSeq>98</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4344</BuyingAccSeq>
    <ItemSeq>4201</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>99</IDX_NO>
    <DataSeq>99</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3602</BuyingAccSeq>
    <ItemSeq>4321</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>100</IDX_NO>
    <DataSeq>100</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3701</BuyingAccSeq>
    <ItemSeq>4231</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>101</IDX_NO>
    <DataSeq>101</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4345</BuyingAccSeq>
    <ItemSeq>4201</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>102</IDX_NO>
    <DataSeq>102</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3605</BuyingAccSeq>
    <ItemSeq>4321</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>103</IDX_NO>
    <DataSeq>103</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3704</BuyingAccSeq>
    <ItemSeq>4231</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>104</IDX_NO>
    <DataSeq>104</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4346</BuyingAccSeq>
    <ItemSeq>4201</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>105</IDX_NO>
    <DataSeq>105</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3451</BuyingAccSeq>
    <ItemSeq>4269</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>106</IDX_NO>
    <DataSeq>106</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3594</BuyingAccSeq>
    <ItemSeq>4389</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>107</IDX_NO>
    <DataSeq>107</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3494</BuyingAccSeq>
    <ItemSeq>4269</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>108</IDX_NO>
    <DataSeq>108</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3546</BuyingAccSeq>
    <ItemSeq>4149</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>109</IDX_NO>
    <DataSeq>109</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4040</BuyingAccSeq>
    <ItemSeq>4149</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>110</IDX_NO>
    <DataSeq>110</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3599</BuyingAccSeq>
    <ItemSeq>4329</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>111</IDX_NO>
    <DataSeq>111</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3673</BuyingAccSeq>
    <ItemSeq>4239</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>112</IDX_NO>
    <DataSeq>112</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4338</BuyingAccSeq>
    <ItemSeq>4209</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>113</IDX_NO>
    <DataSeq>113</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3603</BuyingAccSeq>
    <ItemSeq>4329</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>114</IDX_NO>
    <DataSeq>114</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3702</BuyingAccSeq>
    <ItemSeq>4239</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>115</IDX_NO>
    <DataSeq>115</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3607</BuyingAccSeq>
    <ItemSeq>4329</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>116</IDX_NO>
    <DataSeq>116</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3705</BuyingAccSeq>
    <ItemSeq>4239</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>117</IDX_NO>
    <DataSeq>117</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3454</BuyingAccSeq>
    <ItemSeq>4248</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>118</IDX_NO>
    <DataSeq>118</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3455</BuyingAccSeq>
    <ItemSeq>4273</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>119</IDX_NO>
    <DataSeq>119</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3456</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>120</IDX_NO>
    <DataSeq>120</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3457</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>121</IDX_NO>
    <DataSeq>121</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3524</BuyingAccSeq>
    <ItemSeq>4277</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>122</IDX_NO>
    <DataSeq>122</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3525</BuyingAccSeq>
    <ItemSeq>4277</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>123</IDX_NO>
    <DataSeq>123</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3526</BuyingAccSeq>
    <ItemSeq>4277</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>124</IDX_NO>
    <DataSeq>124</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3527</BuyingAccSeq>
    <ItemSeq>4277</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>125</IDX_NO>
    <DataSeq>125</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3528</BuyingAccSeq>
    <ItemSeq>4303</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>126</IDX_NO>
    <DataSeq>126</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3529</BuyingAccSeq>
    <ItemSeq>4278</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>127</IDX_NO>
    <DataSeq>127</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3530</BuyingAccSeq>
    <ItemSeq>4278</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>128</IDX_NO>
    <DataSeq>128</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3555</BuyingAccSeq>
    <ItemSeq>3944</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>129</IDX_NO>
    <DataSeq>129</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3556</BuyingAccSeq>
    <ItemSeq>3943</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>130</IDX_NO>
    <DataSeq>130</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3557</BuyingAccSeq>
    <ItemSeq>3917</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>131</IDX_NO>
    <DataSeq>131</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4172</BuyingAccSeq>
    <ItemSeq>4218</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>132</IDX_NO>
    <DataSeq>132</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4173</BuyingAccSeq>
    <ItemSeq>4243</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>133</IDX_NO>
    <DataSeq>133</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4179</BuyingAccSeq>
    <ItemSeq>4217</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>134</IDX_NO>
    <DataSeq>134</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4321</BuyingAccSeq>
    <ItemSeq>4307</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>135</IDX_NO>
    <DataSeq>135</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4322</BuyingAccSeq>
    <ItemSeq>4308</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>136</IDX_NO>
    <DataSeq>136</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4683</BuyingAccSeq>
    <ItemSeq>3759</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>137</IDX_NO>
    <DataSeq>137</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4684</BuyingAccSeq>
    <ItemSeq>3763</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>138</IDX_NO>
    <DataSeq>138</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3498</BuyingAccSeq>
    <ItemSeq>4248</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>139</IDX_NO>
    <DataSeq>139</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3499</BuyingAccSeq>
    <ItemSeq>4273</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>140</IDX_NO>
    <DataSeq>140</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3501</BuyingAccSeq>
    <ItemSeq>4274</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>141</IDX_NO>
    <DataSeq>141</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3503</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>142</IDX_NO>
    <DataSeq>142</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3504</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>143</IDX_NO>
    <DataSeq>143</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3533</BuyingAccSeq>
    <ItemSeq>4303</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>144</IDX_NO>
    <DataSeq>144</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3552</BuyingAccSeq>
    <ItemSeq>3944</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>145</IDX_NO>
    <DataSeq>145</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3553</BuyingAccSeq>
    <ItemSeq>3917</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>146</IDX_NO>
    <DataSeq>146</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3554</BuyingAccSeq>
    <ItemSeq>3943</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>147</IDX_NO>
    <DataSeq>147</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4175</BuyingAccSeq>
    <ItemSeq>4243</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>148</IDX_NO>
    <DataSeq>148</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4176</BuyingAccSeq>
    <ItemSeq>4217</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>149</IDX_NO>
    <DataSeq>149</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4177</BuyingAccSeq>
    <ItemSeq>4217</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>150</IDX_NO>
    <DataSeq>150</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4178</BuyingAccSeq>
    <ItemSeq>4218</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>151</IDX_NO>
    <DataSeq>151</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4323</BuyingAccSeq>
    <ItemSeq>4307</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>152</IDX_NO>
    <DataSeq>152</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4324</BuyingAccSeq>
    <ItemSeq>4308</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>153</IDX_NO>
    <DataSeq>153</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4686</BuyingAccSeq>
    <ItemSeq>3751</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>154</IDX_NO>
    <DataSeq>154</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4687</BuyingAccSeq>
    <ItemSeq>3764</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>155</IDX_NO>
    <DataSeq>155</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4688</BuyingAccSeq>
    <ItemSeq>3737</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>156</IDX_NO>
    <DataSeq>156</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3548</BuyingAccSeq>
    <ItemSeq>3944</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>157</IDX_NO>
    <DataSeq>157</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3549</BuyingAccSeq>
    <ItemSeq>3917</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>158</IDX_NO>
    <DataSeq>158</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3550</BuyingAccSeq>
    <ItemSeq>3943</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>159</IDX_NO>
    <DataSeq>159</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3622</BuyingAccSeq>
    <ItemSeq>4277</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>160</IDX_NO>
    <DataSeq>160</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3623</BuyingAccSeq>
    <ItemSeq>4303</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>161</IDX_NO>
    <DataSeq>161</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3624</BuyingAccSeq>
    <ItemSeq>4303</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>162</IDX_NO>
    <DataSeq>162</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3625</BuyingAccSeq>
    <ItemSeq>4278</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>163</IDX_NO>
    <DataSeq>163</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3626</BuyingAccSeq>
    <ItemSeq>4278</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>164</IDX_NO>
    <DataSeq>164</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3709</BuyingAccSeq>
    <ItemSeq>4248</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>165</IDX_NO>
    <DataSeq>165</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3710</BuyingAccSeq>
    <ItemSeq>4274</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>166</IDX_NO>
    <DataSeq>166</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3711</BuyingAccSeq>
    <ItemSeq>4273</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>167</IDX_NO>
    <DataSeq>167</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3712</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>168</IDX_NO>
    <DataSeq>168</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3713</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>169</IDX_NO>
    <DataSeq>169</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3714</BuyingAccSeq>
    <ItemSeq>4247</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>170</IDX_NO>
    <DataSeq>170</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4180</BuyingAccSeq>
    <ItemSeq>4217</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>171</IDX_NO>
    <DataSeq>171</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4181</BuyingAccSeq>
    <ItemSeq>4218</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>172</IDX_NO>
    <DataSeq>172</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4325</BuyingAccSeq>
    <ItemSeq>4307</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>173</IDX_NO>
    <DataSeq>173</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4326</BuyingAccSeq>
    <ItemSeq>4308</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>174</IDX_NO>
    <DataSeq>174</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4690</BuyingAccSeq>
    <ItemSeq>3751</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>175</IDX_NO>
    <DataSeq>175</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4691</BuyingAccSeq>
    <ItemSeq>3764</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>176</IDX_NO>
    <DataSeq>176</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4692</BuyingAccSeq>
    <ItemSeq>3763</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>177</IDX_NO>
    <DataSeq>177</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>4693</BuyingAccSeq>
    <ItemSeq>3737</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>178</IDX_NO>
    <DataSeq>178</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3531</BuyingAccSeq>
    <ItemSeq>4291</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>179</IDX_NO>
    <DataSeq>179</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3535</BuyingAccSeq>
    <ItemSeq>4291</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>180</IDX_NO>
    <DataSeq>180</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3628</BuyingAccSeq>
    <ItemSeq>4291</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>181</IDX_NO>
    <DataSeq>181</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3452</BuyingAccSeq>
    <ItemSeq>4269</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>182</IDX_NO>
    <DataSeq>182</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3495</BuyingAccSeq>
    <ItemSeq>4269</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>183</IDX_NO>
    <DataSeq>183</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3483</BuyingAccSeq>
    <ItemSeq>3723</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>184</IDX_NO>
    <DataSeq>184</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3486</BuyingAccSeq>
    <ItemSeq>3723</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>185</IDX_NO>
    <DataSeq>185</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3581</BuyingAccSeq>
    <ItemSeq>3723</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>186</IDX_NO>
    <DataSeq>186</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3484</BuyingAccSeq>
    <ItemSeq>3724</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>187</IDX_NO>
    <DataSeq>187</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3488</BuyingAccSeq>
    <ItemSeq>3724</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>188</IDX_NO>
    <DataSeq>188</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3587</BuyingAccSeq>
    <ItemSeq>3724</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>189</IDX_NO>
    <DataSeq>189</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3493</BuyingAccSeq>
    <ItemSeq>3969</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>190</IDX_NO>
    <DataSeq>190</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3439</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>191</IDX_NO>
    <DataSeq>191</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3513</BuyingAccSeq>
    <ItemSeq>3969</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>192</IDX_NO>
    <DataSeq>192</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3590</BuyingAccSeq>
    <ItemSeq>3969</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>193</IDX_NO>
    <DataSeq>193</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3532</BuyingAccSeq>
    <ItemSeq>4299</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>194</IDX_NO>
    <DataSeq>194</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3617</BuyingAccSeq>
    <ItemSeq>4299</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>195</IDX_NO>
    <DataSeq>195</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3627</BuyingAccSeq>
    <ItemSeq>4299</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>196</IDX_NO>
    <DataSeq>196</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3485</BuyingAccSeq>
    <ItemSeq>3721</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>197</IDX_NO>
    <DataSeq>197</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3487</BuyingAccSeq>
    <ItemSeq>3721</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>198</IDX_NO>
    <DataSeq>198</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3589</BuyingAccSeq>
    <ItemSeq>3721</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>199</IDX_NO>
    <DataSeq>199</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3681</BuyingAccSeq>
    <ItemSeq>4029</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>200</IDX_NO>
    <DataSeq>200</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3423</BuyingAccSeq>
    <ItemSeq>4179</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>201</IDX_NO>
    <DataSeq>201</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3685</BuyingAccSeq>
    <ItemSeq>4029</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>202</IDX_NO>
    <DataSeq>202</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3563</BuyingAccSeq>
    <ItemSeq>4179</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>203</IDX_NO>
    <DataSeq>203</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3690</BuyingAccSeq>
    <ItemSeq>4029</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>204</IDX_NO>
    <DataSeq>204</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3429</BuyingAccSeq>
    <ItemSeq>4111</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>205</IDX_NO>
    <DataSeq>205</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3490</BuyingAccSeq>
    <ItemSeq>3961</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>206</IDX_NO>
    <DataSeq>206</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5372</BuyingAccSeq>
    <ItemSeq>4021</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>207</IDX_NO>
    <DataSeq>207</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>6725</BuyingAccSeq>
    <ItemSeq>4111</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>208</IDX_NO>
    <DataSeq>208</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3422</BuyingAccSeq>
    <ItemSeq>4171</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>209</IDX_NO>
    <DataSeq>209</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3440</BuyingAccSeq>
    <ItemSeq>4111</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>210</IDX_NO>
    <DataSeq>210</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3512</BuyingAccSeq>
    <ItemSeq>3961</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>211</IDX_NO>
    <DataSeq>211</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3562</BuyingAccSeq>
    <ItemSeq>4171</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>212</IDX_NO>
    <DataSeq>212</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3565</BuyingAccSeq>
    <ItemSeq>4111</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>213</IDX_NO>
    <DataSeq>213</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3586</BuyingAccSeq>
    <ItemSeq>3961</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>214</IDX_NO>
    <DataSeq>214</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3686</BuyingAccSeq>
    <ItemSeq>4021</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>215</IDX_NO>
    <DataSeq>215</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3428</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>216</IDX_NO>
    <DataSeq>216</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3679</BuyingAccSeq>
    <ItemSeq>4021</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>217</IDX_NO>
    <DataSeq>217</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3680</BuyingAccSeq>
    <ItemSeq>4029</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>218</IDX_NO>
    <DataSeq>218</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3437</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>219</IDX_NO>
    <DataSeq>219</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3683</BuyingAccSeq>
    <ItemSeq>4021</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>220</IDX_NO>
    <DataSeq>220</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3568</BuyingAccSeq>
    <ItemSeq>4119</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>221</IDX_NO>
    <DataSeq>221</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3687</BuyingAccSeq>
    <ItemSeq>4021</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>222</IDX_NO>
    <DataSeq>222</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3689</BuyingAccSeq>
    <ItemSeq>4029</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>223</IDX_NO>
    <DataSeq>223</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3426</BuyingAccSeq>
    <ItemSeq>4113</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>224</IDX_NO>
    <DataSeq>224</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3496</BuyingAccSeq>
    <ItemSeq>3963</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>225</IDX_NO>
    <DataSeq>225</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3682</BuyingAccSeq>
    <ItemSeq>4023</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>226</IDX_NO>
    <DataSeq>226</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3424</BuyingAccSeq>
    <ItemSeq>4173</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>227</IDX_NO>
    <DataSeq>227</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3436</BuyingAccSeq>
    <ItemSeq>4113</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>228</IDX_NO>
    <DataSeq>228</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3514</BuyingAccSeq>
    <ItemSeq>3963</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>229</IDX_NO>
    <DataSeq>229</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3564</BuyingAccSeq>
    <ItemSeq>4173</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>230</IDX_NO>
    <DataSeq>230</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3567</BuyingAccSeq>
    <ItemSeq>4113</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>231</IDX_NO>
    <DataSeq>231</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3592</BuyingAccSeq>
    <ItemSeq>3963</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>232</IDX_NO>
    <DataSeq>232</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3692</BuyingAccSeq>
    <ItemSeq>4023</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>233</IDX_NO>
    <DataSeq>233</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3430</BuyingAccSeq>
    <ItemSeq>4124</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>234</IDX_NO>
    <DataSeq>234</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3431</BuyingAccSeq>
    <ItemSeq>4123</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>235</IDX_NO>
    <DataSeq>235</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3432</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>236</IDX_NO>
    <DataSeq>236</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3433</BuyingAccSeq>
    <ItemSeq>4117</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>237</IDX_NO>
    <DataSeq>237</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3434</BuyingAccSeq>
    <ItemSeq>4123</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>238</IDX_NO>
    <DataSeq>238</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3435</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>239</IDX_NO>
    <DataSeq>239</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3500</BuyingAccSeq>
    <ItemSeq>3947</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>240</IDX_NO>
    <DataSeq>240</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3506</BuyingAccSeq>
    <ItemSeq>3973</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>241</IDX_NO>
    <DataSeq>241</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3507</BuyingAccSeq>
    <ItemSeq>3974</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>242</IDX_NO>
    <DataSeq>242</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3888</BuyingAccSeq>
    <ItemSeq>4007</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>243</IDX_NO>
    <DataSeq>243</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3889</BuyingAccSeq>
    <ItemSeq>4033</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>244</IDX_NO>
    <DataSeq>244</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3890</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>245</IDX_NO>
    <DataSeq>245</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3891</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>246</IDX_NO>
    <DataSeq>246</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3441</BuyingAccSeq>
    <ItemSeq>4123</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>247</IDX_NO>
    <DataSeq>247</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3442</BuyingAccSeq>
    <ItemSeq>4124</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>248</IDX_NO>
    <DataSeq>248</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3443</BuyingAccSeq>
    <ItemSeq>4124</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>249</IDX_NO>
    <DataSeq>249</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3444</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>250</IDX_NO>
    <DataSeq>250</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3445</BuyingAccSeq>
    <ItemSeq>4117</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>251</IDX_NO>
    <DataSeq>251</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3446</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>252</IDX_NO>
    <DataSeq>252</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3447</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>253</IDX_NO>
    <DataSeq>253</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3458</BuyingAccSeq>
    <ItemSeq>4184</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>254</IDX_NO>
    <DataSeq>254</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3459</BuyingAccSeq>
    <ItemSeq>4157</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>255</IDX_NO>
    <DataSeq>255</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3460</BuyingAccSeq>
    <ItemSeq>4157</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>256</IDX_NO>
    <DataSeq>256</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3461</BuyingAccSeq>
    <ItemSeq>4183</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>257</IDX_NO>
    <DataSeq>257</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3462</BuyingAccSeq>
    <ItemSeq>4157</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>258</IDX_NO>
    <DataSeq>258</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3463</BuyingAccSeq>
    <ItemSeq>4184</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>259</IDX_NO>
    <DataSeq>259</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3508</BuyingAccSeq>
    <ItemSeq>3947</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>260</IDX_NO>
    <DataSeq>260</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3509</BuyingAccSeq>
    <ItemSeq>3973</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>261</IDX_NO>
    <DataSeq>261</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3510</BuyingAccSeq>
    <ItemSeq>3974</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>262</IDX_NO>
    <DataSeq>262</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3892</BuyingAccSeq>
    <ItemSeq>4007</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>263</IDX_NO>
    <DataSeq>263</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3893</BuyingAccSeq>
    <ItemSeq>4033</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>264</IDX_NO>
    <DataSeq>264</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3894</BuyingAccSeq>
    <ItemSeq>4033</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>265</IDX_NO>
    <DataSeq>265</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3895</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>266</IDX_NO>
    <DataSeq>266</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3896</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>267</IDX_NO>
    <DataSeq>267</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3569</BuyingAccSeq>
    <ItemSeq>4117</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>268</IDX_NO>
    <DataSeq>268</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3570</BuyingAccSeq>
    <ItemSeq>4097</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>269</IDX_NO>
    <DataSeq>269</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3571</BuyingAccSeq>
    <ItemSeq>4124</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>270</IDX_NO>
    <DataSeq>270</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3574</BuyingAccSeq>
    <ItemSeq>4184</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>271</IDX_NO>
    <DataSeq>271</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3575</BuyingAccSeq>
    <ItemSeq>4157</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>272</IDX_NO>
    <DataSeq>272</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3576</BuyingAccSeq>
    <ItemSeq>4183</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>273</IDX_NO>
    <DataSeq>273</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3577</BuyingAccSeq>
    <ItemSeq>4183</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>274</IDX_NO>
    <DataSeq>274</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3578</BuyingAccSeq>
    <ItemSeq>4183</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>275</IDX_NO>
    <DataSeq>275</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3579</BuyingAccSeq>
    <ItemSeq>4184</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>276</IDX_NO>
    <DataSeq>276</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3580</BuyingAccSeq>
    <ItemSeq>4157</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>277</IDX_NO>
    <DataSeq>277</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3585</BuyingAccSeq>
    <ItemSeq>3974</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>278</IDX_NO>
    <DataSeq>278</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3897</BuyingAccSeq>
    <ItemSeq>4007</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>279</IDX_NO>
    <DataSeq>279</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3898</BuyingAccSeq>
    <ItemSeq>4033</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>280</IDX_NO>
    <DataSeq>280</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3899</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>281</IDX_NO>
    <DataSeq>281</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>3900</BuyingAccSeq>
    <ItemSeq>4034</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>282</IDX_NO>
    <DataSeq>282</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5066</BuyingAccSeq>
    <ItemSeq>3947</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>283</IDX_NO>
    <DataSeq>283</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5067</BuyingAccSeq>
    <ItemSeq>3973</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>284</IDX_NO>
    <DataSeq>284</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5125</BuyingAccSeq>
    <ItemSeq>4293</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>285</IDX_NO>
    <DataSeq>285</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BuyingAccSeq>5126</BuyingAccSeq>
    <ItemSeq>4293</ItemSeq>
    <AntiAccSeq>102</AntiAccSeq>
    <AntiAccName>외상매입금_원재료</AntiAccName>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <DeliAccName />
    <DeliAccSeq>0</DeliAccSeq>
    <DeliVsAccName />
    <DeliVsAccSeq>0</DeliVsAccSeq>
    <DeliVatAccName />
    <DeliVatAccSeq>0</DeliVatAccSeq>
    <DeliEvidName />
    <DeliEvidSeq>0</DeliEvidSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033061,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027349
rollback 