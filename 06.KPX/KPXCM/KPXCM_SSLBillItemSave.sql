IF OBJECT_ID('KPXCM_SSLBillItemSave') IS NOT NULL 
    DROP PROC KPXCM_SSLBillItemSave
GO 

-- v2015.10.15 
/*********************************************************************************************************************
     화면명 : 세금계산서_세부저장
     SP Name: _SSLBillItemSave
     작성일 : 2008.08.13 : CREATEd by 정혜영    
     수정일 : 
 ********************************************************************************************************************/
 CREATE PROC KPXCM_SSLBillItemSave  
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
      CREATE TABLE #TSLBillItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TSLBillItem' 
    
    --IF @PgmSeq = 4801 
    --BEGIN 
    --    -- 외화금액 차액 원화금액에 보정처리
    --    DECLARE @DiffAmt DECIMAL(19,5) 
        
    --    SELECT @DiffAmt = FLOOR(SUM(A.CurAmt + A.CurVAT) * MAX(B.ExRate)) - SUM(A.DomAmt + A.DomVAT)               
    --      from #TSLBillItem    AS A 
    --      JOIN _TSLBill        AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
    --     WHERE A.WorkingTag IN ( 'A', 'U' ) 
        
    --    UPDATE A 
    --       SET DomAmt = A.DomAmt + @DiffAmt 
    --      FROM #TSLBillItem AS A 
    --      JOIN ( 
    --            SELECT TOP 1 IDX_NO 
    --              FROM #TSLBillItem AS Z 
    --             ORDER BY Z.DomAmt DESC 
    --           ) AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
    --     --외화금액 차액 원화금액에 보정처리, END 
    --END 
        
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLBillItem', -- 원테이블명
                    '#TSLBillItem', -- 템프테이블명
                    'BillSeq, BillSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                    'CompanySeq, BillSeq, BillSerl, BillPrtDate, ItemName, Spec, Qty, Price, CurAmt, CurVAT, KorPrice, DomAmt, DomVAT, Remark, LastUserSeq, LastDateTime, PgmSeq',
                    '', @PgmSeq 
  
  DECLARE @Word1 NVARCHAR(50),
    @Word2 NVARCHAR(50),
    @Word3 NVARCHAR(50),
    @MessageType  INT,
             @Status       INT,
             @Results      NVARCHAR(250)
  
  SELECT @Word3 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2377
  IF @@ROWCOUNT = 0 OR ISNULL( @Word3, '' ) = '' SELECT @Word3 = N'일자'
  
  SELECT @Word1 = Word + @Word3 FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 18247
  IF @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = N'출력용'
  
  SELECT @Word2 = Word + @Word3 FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2609
  IF @@ROWCOUNT = 0 OR ISNULL( @Word2, '' ) = '' SELECT @Word2 = N'계산서'
  
  EXEC dbo._SCOMMessage @MessageType OUTPUT,
                           @Status      OUTPUT,
                           @Results     OUTPUT,
                           1200, -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%큽%')
                           @LanguageSeq, 
                           '', ''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'   
  
  UPDATE C
     SET C.Result   = REPLACE( REPLACE( @Results, '@1', @Word1 ), '@2', @Word2 ),
      C.MessageType = @MessageType,
      C.Status   = @Status
       FROM #TSLBillItem AS C 
       JOIN _TSLBill  AS A ON ( A.CompanySeq = @CompanySeq AND A.BillSeq = C.BillSeq AND A.BillDate < C.BillPrtDate )
   WHERE C.WorkingTag <> 'D' 
     AND C.Status = 0 
      
 -- DELETE                                                                                                
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLBillItem  
           FROM _TSLBillItem AS A 
                  JOIN #TSLBillItem AS B  ON  A.BillSeq = B.BillSeq AND A.BillSerl = B.BillSerl
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'D' 
            AND B.Status = 0    
     END   
  -- Update                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLBillItem   
            SET BillPrtDate  = ISNULL(B.BillPrtDate, ''), 
                ItemName     = ISNULL(B.ItemName, ''), 
                Spec         = ISNULL(B.Spec, ''), 
                Qty          = ISNULL(B.Qty, 0), 
                Price        = ISNULL(B.Price, 0), 
                CurAmt       = ISNULL(B.CurAmt, 0), 
                CurVAT       = ISNULL(B.CurVAT, 0), 
                KorPrice     = ISNULL(B.KorPrice, 0), 
   DomAmt       = ISNULL(B.DomAmt, 0), 
                DomVAT       = ISNULL(B.DomVAT, 0), 
       Remark       = ISNULL(B.Remark, ''),
                LastUserSeq  = @UserSeq,
                LastDateTime = GETDATE(),
                PgmSeq       = @PgmSeq
           FROM _TSLBillItem AS A  
                  JOIN #TSLBillItem AS B ON A.BillSeq = B.BillSeq AND A.BillSerl = B.BillSerl
          WHERE B.WorkingTag = 'U' 
            AND B.Status = 0
            AND A.CompanySeq = @CompanySeq
   
         IF @@ERROR <> 0 RETURN   
     END 
  -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE WorkingTag = 'A' AND Status = 0 )  
    BEGIN          
         -- 서비스 INSERT  
         INSERT INTO _TSLBillItem (CompanySeq,   BillSeq,    BillSerl,   BillPrtDate,    ItemName, 
                                   Spec,         Qty,        Price,      CurAmt,         CurVAT, 
                                   KorPrice,     DomAmt,     DomVAT,     Remark,         LastUserSeq, 
                                   LastDateTime, PgmSeq)    
             SELECT @CompanySeq,             ISNULL(BillSeq, 0),    ISNULL(BillSerl, 0),   ISNULL(BillPrtDate, ''),   ISNULL(ItemName, ''), 
                    ISNULL(Spec, ''),        ISNULL(Qty, 0),        ISNULL(Price, 0),      ISNULL(CurAmt, 0),         ISNULL(CurVAT, 0), 
                    ISNULL(KorPrice, 0),     ISNULL(DomAmt, 0),     ISNULL(DomVAT, 0),     ISNULL(Remark, ''),         @UserSeq,      
                    GETDATE() ,              @PgmSeq  
               FROM #TSLBillItem  
              WHERE WorkingTag = 'A' AND Status = 0  
          IF @@ERROR <> 0 RETURN     
    END   
    
    
    SELECT * FROM #TSLBillItem 
    
  RETURN
  go
  begin tran 
  
  exec _SSLBillSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <IDX_NO>1</IDX_NO>
    <WorkingTag>A</WorkingTag>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BillSeq>1650</BillSeq>
    <BillNo>991231003</BillNo>
    <SMBillType>8026001</SMBillType>
    <UMBillKind>8027001</UMBillKind>
    <Gwon />
    <Ho />
    <FundArrangeDate xml:space="preserve">        </FundArrangeDate>
    <PrnReqDate xml:space="preserve">        </PrnReqDate>
    <SMBilling>8027002</SMBilling>
    <IsPrint>0</IsPrint>
    <IsDate>0</IsDate>
    <IsCust>0</IsCust>
    <TaxName>KPX케미칼(주) 울산공장</TaxName>
    <TaxUnit>3</TaxUnit>
    <EvidSeq>0</EvidSeq>
    <Remark />
    <VatAccSeq>115</VatAccSeq>
    <SMBillTypeName>계산서(일반)</SMBillTypeName>
    <UMBillKindName>일반매출</UMBillKindName>
    <EvidName />
    <VatAccName>부가세예수금</VatAccName>
    <IsPJT>0</IsPJT>
    <WBSSeq>0</WBSSeq>
    <PJTSeq>0</PJTSeq>
    <BizUnit>1</BizUnit>
    <SMExpKind>8009001</SMExpKind>
    <BillDate>99991231</BillDate>
    <DeptSeq>224</DeptSeq>
    <EmpSeq>1</EmpSeq>
    <CustSeq>7982</CustSeq>
    <CurrSeq>16</CurrSeq>
    <ExRate>1.000000</ExRate>
    <OppAccSeq>18</OppAccSeq>
    <BizUnitName>우레탄부문</BizUnitName>
    <SMExpKindName>내수</SMExpKindName>
    <DeptName>경리팀</DeptName>
    <EmpName>영림원</EmpName>
    <CustName>　무궁화엘앤비</CustName>
    <CurrName>KRW</CurrName>
    <OppAccName>외상매출금</OppAccName>
    <BillID>2</BillID>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=2637,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569

exec KPXCM_SSLBillItemSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <Status>0</Status>
    <IDX_NO>1</IDX_NO>
    <BillSeq>1650</BillSeq>
    <BillSerl>1</BillSerl>
    <BillPrtDate>99991231</BillPrtDate>
    <ItemName>GHPP-1000</ItemName>
    <Spec />
    <Qty>2.00000</Qty>
    <Price>0.00000</Price>
    <CurAmt>193248.00000</CurAmt>
    <CurVAT>19324.80000</CurVAT>
    <KorPrice>0.00000</KorPrice>
    <DomAmt>193248.00000</DomAmt>
    <DomVAT>19325.00000</DomVAT>
    <Remark />
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=2637,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3569

rollback 