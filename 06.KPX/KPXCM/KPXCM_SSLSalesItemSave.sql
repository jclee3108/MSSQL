IF OBJECT_ID('KPXCM_SSLSalesItemSave') IS NOT NULL 
    DROP PROC KPXCM_SSLSalesItemSave
GO 

-- v2015.10.15 
 /*********************************************************************************************************************
     화면명 : 매출처리_세부저장
     SP Name: test_SSLSalesItemSave
     작성일 : 2008.10.10 : CREATEd by 정혜영    
     수정일 : 2011.12.10 : Price 추가 modify by 오성근
 ********************************************************************************************************************/
 CREATE PROC KPXCM_SSLSalesItemSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
     DECLARE @docHandle      INT 
      CREATE TABLE #TSLSalesItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLSalesItem' 
    
    --IF @PgmSeq = 4801 
    --BEGIN 
        
    --    -- 외화금액 차액 원화금액에 보정처리
    --    DECLARE @DiffAmt DECIMAL(19,5) 
        
    --    SELECT @DiffAmt = FLOOR(SUM(A.CurAmt + A.CurVAT) * MAX(B.ExRate)) - SUM(A.DomAmt + A.DomVAT)               
    --      from #TSLSalesItem    AS A 
    --      JOIN _TSLSales        AS B ON ( B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq ) 
    --     WHERE A.WorkingTag IN ( 'A', 'U' ) 
        
        
    --    UPDATE A 
    --       SET DomAmt = A.DomAmt + @DiffAmt 
    --      FROM #TSLSalesItem AS A 
    --      JOIN ( 
    --            SELECT TOP 1 IDX_NO 
    --              FROM #TSLSalesItem AS Z 
    --             ORDER BY Z.DomAmt DESC 
    --           ) AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
    --    -- 외화금액 차액 원화금액에 보정처리, END 
    --END 
        
      -- 2012-08-27 이성덕 수정
     -- 출고매출일 경우, 환경설정에 부가세가계정이 있으면, 부가세가계정을 설정해 준다.
     DECLARE @FakeVATSeq             INT
      -- EnvSeq = 8060 (부가세가계정)
     EXEC @FakeVATSeq = dbo._SCOMEnvR @CompanySeq, 8060, @UserSeq, @@PROCID    
  
     
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLSalesItem', -- 원테이블명
                    '#TSLSalesItem', -- 템프테이블명
                    'SalesSeq, SalesSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                    'CompanySeq, SalesSeq, SalesSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT, STDUnitSeq, STDQty, WHSeq, 
                     Remark, AccSeq, VATSeq, OppAccSeq, LotNo, SerialNo, MngSalesSerl, IsSetItem, PJTSeq, WBSSeq, CustSeq, DeptSeq, EmpSeq, LastUserSeq, LastDateTime, Price, PgmSeq', 
                    '', @PgmSeq 
    
    
    
    
    
    
    
 -- DELETE                                                                                                
     IF EXISTS (SELECT 1 FROM #TSLSalesItem WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLSalesItem  
           FROM _TSLSalesItem AS A
                  JOIN #TSLSalesItem AS B ON A.SalesSeq = B.SalesSeq 
                                         AND (B.SalesSerl IS NULL OR A.SalesSerl = B.SalesSerl) -- 출고매출일 경우 Serl이 Null로 들어와서 삭제되지 않는 문제가 있어 변경 11.04.29 정혜영
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'D' 
            AND B.Status = 0    
     END   
  -- Update                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLSalesItem WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLSalesItem   
            SET ItemSeq      = ISNULL(B.ItemSeq, 0), 
                UnitSeq      = ISNULL(B.UnitSeq, 0), 
                ItemPrice    = ISNULL(B.ItemPrice, 0), 
                CustPrice    = ISNULL(B.CustPrice, 0), 
                Qty          = ISNULL(B.Qty, 0), 
                CurAmt       = ISNULL(B.CurAmt, 0), 
                CurVAT       = ISNULL(B.CurVAT, 0), 
                DomAmt       = ISNULL(B.DomAmt, 0), 
                DomVAT       = ISNULL(B.DomVAT, 0), 
                STDUnitSeq   = ISNULL(B.STDUnitSeq, 0), 
                STDQty       = ISNULL(B.STDQty, 0), 
                WHSeq        = ISNULL(B.WHSeq, 0), 
                Remark       = ISNULL(B.Remark, ''), 
                AccSeq       = ISNULL(B.AccSeq, 0), 
                VATSeq       = ISNULL(B.VATSeq, 0), 
 --               OppAccSeq    = ISNULL(B.OppAccSeq, 0), 
                LotNo        = ISNULL(B.LotNo, ''), 
                SerialNo     = ISNULL(B.SerialNo, ''),
 --                MngSalesSerl = ISNULL(B.MngSalesSerl,0),
 --                IsSetItem    = ISNULL(B.IsSetItem, '0'),
                IsInclusedVAT= ISNULL(B.IsInclusedVAT, ''),
                VATRate      = ISNULL(B.VATRate, 0),
                PJTSeq       = ISNULL(B.PJTSeq, 0),
                WBSSeq       = ISNULL(B.WBSSeq, 0),
                LastUserSeq  = @UserSeq,
                LastDateTime = GETDATE(),
                Price        = B.Price,
                PgmSeq       = @PgmSeq
           FROM _TSLSalesItem AS A 
                  JOIN #TSLSalesItem AS B ON A.SalesSeq = B.SalesSeq AND A.SalesSerl = B.SalesSerl
          WHERE B.WorkingTag = 'U' 
            AND B.Status = 0
            AND A.CompanySeq = @CompanySeq
   
         IF @@ERROR <> 0 RETURN   
     END 
  -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLSalesItem WHERE WorkingTag = 'A' AND Status = 0 )  
     BEGIN          
         
         IF EXISTS (SELECT 1 FROM #TSLSalesItem WHERE ISNULL(CustSeq,0) = 0)
         BEGIN
             UPDATE #TSLSalesItem 
                SET CustSeq = ISNULL(B.CustSeq, 0),
                    DeptSeq = ISNULL(B.DeptSeq, 0),
                    EmpSeq  = ISNULL(B.EmpSeq, 0)
               FROM #TSLSalesItem AS A
                    JOIN _TSLSales AS B ON B.CompanySeq = @CompanySeq
                                       AND A.SalesSeq   = B.SalesSeq
              WHERE ISNULL(A.CustSeq,0) = 0
         END
          -- 서비스 INSERT  
         INSERT INTO _TSLSalesItem (CompanySeq,  SalesSeq,       SalesSerl,  ItemSeq,    UnitSeq, 
                                    ItemPrice,   CustPrice,      Qty,        IsInclusedVAT, VATRate,
                                    CurAmt,      CurVAT, 
                                    DomAmt,      DomVAT,         STDUnitSeq, STDQty,      WHSeq, 
                                    Remark,      AccSeq,         
                                    VATSeq,
                                    OppAccSeq,   LotNo, 
                                    SerialNo,    MngSalesSerl,   IsSetItem,  PJTSeq,      WBSSeq , 
                                    CustSeq,     DeptSeq,        EmpSeq,     LastUserSeq, LastDateTime, 
                                    Price,       PgmSeq)    
             SELECT @CompanySeq,             ISNULL(SalesSeq, 0),      ISNULL(SalesSerl, 0),  ISNULL(ItemSeq, 0),        ISNULL(UnitSeq, 0), 
                    ISNULL(ItemPrice, 0),    ISNULL(CustPrice, 0),     ISNULL(Qty, 0),        ISNULL(IsInclusedVAT, ''), ISNULL(VATRate, 0),
                    ISNULL(CurAmt, 0),       ISNULL(CurVAT, 0), 
                    ISNULL(DomAmt, 0),       ISNULL(DomVAT, 0),        ISNULL(STDUnitSeq, 0), ISNULL(STDQty, 0),         ISNULL(WHSeq, 0), 
                    ISNULL(Remark, ''),      ISNULL(AccSeq, 0),        
                    CASE WHEN ISNULL(@FakeVATSeq,0) <> 0 THEN @FakeVATSeq ELSE ISNULL(VATSeq, 0) END,
                    ISNULL(OppAccSeq, 0),      ISNULL(LotNo, ''), 
                    ISNULL(SerialNo, ''),    ISNULL(MngSalesSerl,0),   '',                    ISNULL(PJTSeq,0),          ISNULL(WBSSeq,0),     
                    ISNULL(CustSeq, 0),      ISNULL(DeptSeq, 0),       ISNULL(EmpSeq, 0),     @UserSeq,                  GETDATE(), 
                    ISNULL(Price,0)   ,      @PgmSeq
               FROM #TSLSalesItem  
              WHERE WorkingTag = 'A' 
                AND Status = 0  
                AND ISNULL( UMEtcOutKind, 0 ) = 0 -- 기타출고구분이 없는 건만 생성  
          IF @@ERROR <> 0 RETURN     
          UPDATE _TSLSalesItem
            SET OppAccSeq = C.OppAccSeq
           FROM _TSLSalesItem AS A
                JOIN #TSLSalesItem AS B ON A.CompanySeq = @CompanySeq
                                       AND A.SalesSeq   = B.SalesSeq
                                       AND A.SalesSerl  = B.SalesSerl
                JOIN _TSLSales AS C ON C.CompanySeq = @CompanySeq
                                   AND B.SalesSeq   = C.SalesSeq
          WHERE B.WorkingTag = 'A' AND B.Status = 0  
          IF @@ERROR <> 0 RETURN     
     END   
     
     SELECT * FROM #TSLSalesItem 
   
     RETURN  
GO
--begin tran 

--exec _SSLSalesSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <IDX_NO>1</IDX_NO>
--    <WorkingTag>A</WorkingTag>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <Status>0</Status>
--    <SalesSeq>1646</SalesSeq>
--    <SalesNo>2015101500003</SalesNo>
--    <BKCustSeq>0</BKCustSeq>
--    <AGCustSeq>0</AGCustSeq>
--    <BizUnit>1</BizUnit>
--    <SMExpKind>8009001</SMExpKind>
--    <SalesDate>20151015</SalesDate>
--    <DeptSeq>224</DeptSeq>
--    <EmpSeq>1</EmpSeq>
--    <CustSeq>7982</CustSeq>
--    <CurrSeq>17</CurrSeq>
--    <ExRate>1.490000</ExRate>
--    <OppAccSeq>18</OppAccSeq>
--    <BillID>2</BillID>
--    <BizUnitName>우레탄부문</BizUnitName>
--    <SMExpKindName>내수</SMExpKindName>
--    <DeptName>경리팀</DeptName>
--    <EmpName>영림원</EmpName>
--    <CustName>　무궁화엘앤비</CustName>
--    <CurrName>USD</CurrName>
--    <OppAccName>외상매출금</OppAccName>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=2629,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569


--exec test_SSLSalesItemSave @xmlDocument=N'<ROOT>
--  <DataBlock2>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <TABLE_NAME>DataBlock2</TABLE_NAME>
--    <ItemSeq>82495</ItemSeq>
--    <UnitSeq>9</UnitSeq>
--    <ItemPrice>0.00000</ItemPrice>
--    <CustPrice>0.00000</CustPrice>
--    <Qty>4.00000</Qty>
--    <STDUnitSeq>9</STDUnitSeq>
--    <STDQty>4.00000</STDQty>
--    <WHSeq>0</WHSeq>
--    <Remark />
--    <AccSeq>187</AccSeq>
--    <OppAccSeq>0</OppAccSeq>
--    <CheckStatus xml:space="preserve"> </CheckStatus>
--    <CheckOrigin>0</CheckOrigin>
--    <ItemName>(상품)GHPP-1000</ItemName>
--    <ItemNo>GHPP-1000</ItemNo>
--    <Spec />
--    <UnitName>KG</UnitName>
--    <STDUnitName>KG</STDUnitName>
--    <WHName />
--    <AccName>상품매출</AccName>
--    <OppAccName />
--    <VATSeq>0</VATSeq>
--    <VATName />
--    <Price>135.00000</Price>
--    <LotNo />
--    <IsInclusedVAT>0</IsInclusedVAT>
--    <VATRate>10.00000</VATRate>
--    <WBSSeq>0</WBSSeq>
--    <PJTSeq>0</PJTSeq>
--    <CustSeq>0</CustSeq>
--    <DeptSeq>0</DeptSeq>
--    <EmpSeq>0</EmpSeq>
--    <SalesSeq>1646</SalesSeq>
--    <SalesSerl>1</SalesSerl>
--    <CurAmt>540.00000</CurAmt>
--    <CurVAT>54.00000</CurVAT>
--    <DomAmt>805.00000</DomAmt>
--    <DomVAT>80.00000</DomVAT>
--  </DataBlock2>
--  <DataBlock2>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ItemSeq>33</ItemSeq>
--    <UnitSeq>9</UnitSeq>
--    <ItemPrice>0.00000</ItemPrice>
--    <CustPrice>0.00000</CustPrice>
--    <Qty>46.00000</Qty>
--    <STDUnitSeq>9</STDUnitSeq>
--    <STDQty>46.00000</STDQty>
--    <WHSeq>0</WHSeq>
--    <Remark />
--    <AccSeq>187</AccSeq>
--    <OppAccSeq>0</OppAccSeq>
--    <CheckStatus xml:space="preserve"> </CheckStatus>
--    <CheckOrigin>0</CheckOrigin>
--    <ItemName>(상품)GP-3000</ItemName>
--    <ItemNo>31190012</ItemNo>
--    <Spec />
--    <UnitName>KG</UnitName>
--    <STDUnitName>KG</STDUnitName>
--    <WHName />
--    <AccName>상품매출</AccName>
--    <OppAccName />
--    <VATSeq>0</VATSeq>
--    <VATName />
--    <Price>756.00000</Price>
--    <LotNo />
--    <IsInclusedVAT>0</IsInclusedVAT>
--    <VATRate>10.00000</VATRate>
--    <WBSSeq>0</WBSSeq>
--    <PJTSeq>0</PJTSeq>
--    <CustSeq>0</CustSeq>
--    <DeptSeq>0</DeptSeq>
--    <EmpSeq>0</EmpSeq>
--    <SalesSeq>1646</SalesSeq>
--    <SalesSerl>2</SalesSerl>
--    <CurAmt>34776.00000</CurAmt>
--    <CurVAT>3477.60000</CurVAT>
--    <DomAmt>51816.00000</DomAmt>
--    <DomVAT>5182.00000</DomVAT>
--  </DataBlock2>
--  <DataBlock2>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ItemSeq>82352</ItemSeq>
--    <UnitSeq>9</UnitSeq>
--    <ItemPrice>0.00000</ItemPrice>
--    <CustPrice>0.00000</CustPrice>
--    <Qty>78.00000</Qty>
--    <STDUnitSeq>9</STDUnitSeq>
--    <STDQty>78.00000</STDQty>
--    <WHSeq>0</WHSeq>
--    <Remark />
--    <AccSeq>187</AccSeq>
--    <OppAccSeq>0</OppAccSeq>
--    <CheckStatus xml:space="preserve"> </CheckStatus>
--    <CheckOrigin>0</CheckOrigin>
--    <ItemName>(상품)GP-3001</ItemName>
--    <ItemNo>31290098</ItemNo>
--    <Spec />
--    <UnitName>KG</UnitName>
--    <STDUnitName>KG</STDUnitName>
--    <WHName />
--    <AccName>상품매출</AccName>
--    <OppAccName />
--    <VATSeq>0</VATSeq>
--    <VATName />
--    <Price>786.00000</Price>
--    <LotNo />
--    <IsInclusedVAT>0</IsInclusedVAT>
--    <VATRate>10.00000</VATRate>
--    <WBSSeq>0</WBSSeq>
--    <PJTSeq>0</PJTSeq>
--    <CustSeq>0</CustSeq>
--    <DeptSeq>0</DeptSeq>
--    <EmpSeq>0</EmpSeq>
--    <SalesSeq>1646</SalesSeq>
--    <SalesSerl>3</SalesSerl>
--    <CurAmt>61308.00000</CurAmt>
--    <CurVAT>6130.80000</CurVAT>
--    <DomAmt>91349.00000</DomAmt>
--    <DomVAT>9135.00000</DomVAT>
--  </DataBlock2>
--</ROOT>',@xmlFlags=2,@ServiceSeq=2629,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569


--rollback 