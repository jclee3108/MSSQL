
IF OBJECT_ID('DTI_SPUDelvItemSave') IS NOT NULL
    DROP PROC DTI_SPUDelvItemSave
    
GO

--v2013.06.12

-- 구매납품_DTI (매출처/EndUser 추가) By이재천
/************************************************************    
 설  명 - 구매견적 상세 저장    
 작성일 - 2008년 8월 20일     
 작성자 - 노영진    
 수정일 - 2009년 9월 2일    
 수정자 - 김현(무검사품 자동입고 추가)    
 수정일 - 2010년 10월 21일  
 수정자 - 이용춘( MakerSeq 추가)  
 수정일 - 2011. 12. 30 hkim (의제매입 관련 저장, 업데이트 되도록 수정)
 ************************************************************/    
CREATE PROC DTI_SPUDelvItemSave    
    @xmlDocument   NVARCHAR(MAX),      
    @xmlFlags     INT = 0,      
    @ServiceSeq   INT = 0,      
    @WorkingTag   NVARCHAR(10)= '',      
    @CompanySeq   INT = 1,      
    @LanguageSeq  INT = 1,      
    @UserSeq      INT = 0,      
    @PgmSeq       INT = 0      
AS 
    
    DECLARE @VatAccSeq    INT,    
            @QCAutoIn     NCHAR(1),    
            @DelvInSeq    INT,    
            @DelvInSerl   INT,    
            @DelvInNo     NCHAR(12),    
            @DelvInDate   NCHAR(8),    
            @BuyingAccSeq INT    

    -- 서비스 마스타 등록 생성    
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'         
    IF @@ERROR <> 0 RETURN        
     
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog @CompanySeq   ,    
                  @UserSeq      ,    
                  '_TPUDelvItem', -- 원테이블명    
                  '#TPUDelvItem', -- 템프테이블명    
                  'DelvSeq,DelvSerl' , -- 키가 여러개일 경우는 , 로 연결한다.     
                  'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,    
                   Price,Qty,CurAmt,CurVAT,DomPrice,    
                   DomAmt,DomVAT,IsVAT,StdUnitSeq,StdUnitQty,    
                   SMQcType,QcEmpSeq,QcDate,QcQty,QcCurAmt,    
                   WHSeq,LOTNo,FromSerial,ToSerial,SalesCustSeq,    
                   DelvCustSeq,PJTSeq,WBSSeq,UMDelayType,Remark,    
                   IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl,IsFiction,FicRateNum,FicRateDen,EvidSeq'    
    
    -- DELETE        
    IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvItem WHERE WorkingTag = 'D' AND Status = 0)      
    BEGIN      
        DELETE _TPUDelvItem    
          FROM _TPUDelvItem A JOIN #TPUDelvItem B ON ( A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl ) 
         WHERE B.WorkingTag = 'D' AND B.Status = 0 
           AND A.CompanySeq  = @CompanySeq    
        
        IF @@ERROR <> 0  RETURN    
    
    END      
    
    -- UPDATE        
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'U' AND Status = 0)      
    BEGIN    
        UPDATE _TPUDelvItem    
           SET ItemSeq      = B.ItemSeq      ,    
               UnitSeq      = B.UnitSeq      ,    
               Price        = ISNULL(B.Price        , 0),    
               DomPrice     = ISNULL(B.DomPrice     , 0),    
               Qty          = ISNULL(B.Qty          , 0),    
               CurAmt       = ISNULL(B.CurAmt       , 0),    
               DomAmt       = ISNULL(B.DomAmt       , 0),    
               CurVAT       = ISNULL(B.CurVAT       , 0),    
               DomVAT       = ISNULL(B.DomVAT       , 0),    
               IsVAT        = B.IsVAT        ,    
               StdUnitSeq   = B.StdUnitSeq   ,    
               StdUnitQty   = B.StdUnitQty   ,    
               SMQcType     = B.SMQcType     ,    
               QcEmpSeq     = B.QcEmpSeq     ,    
               QcDate       = B.QcDate       ,    
               QcQty        = B.QcQty        ,    
               QcCurAmt     = B.QcCurAmt     ,    
               WHSeq        = B.WHSeq        ,    
               LOTNo        = B.LOTNo        ,    
               FromSerial   = B.FromSerial   ,    
               ToSerial     = B.ToSerial     ,    
               SalesCustSeq = B.SalesCustSeq ,    
               DelvCustSeq  = B.DelvCustSeq  ,    
               PJTSeq       = B.PJTSeq       ,    
               WBSSeq       = B.WBSSeq       ,    
               UMDelayType  = B.UMDelayType  ,    
               Remark       = B.Remark       ,    
               IsReturn     = B.IsReturn     ,    
               LastUserSeq  = @UserSeq,    
               LastDateTime = GETDATE(),  
               MakerSeq     = B.MakerSeq     ,         -- MakerSeq  추가  
               IsFiction    = B.IsFiction    ,         --2011. 12. 30 hkim 추가
               FicRateNum   = B.FicRateNum   ,         --2011. 12. 30 hkim 추가
               FicRateDen   = B.FicRateDen   ,         --2011. 12. 30 hkim 추가
               EvidSeq      = B.EvidSeq                --2011. 12. 30 hkim 추가
          FROM _TPUDelvItem AS A JOIN #TPUDelvItem AS B ON ( A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl ) 
         WHERE B.WorkingTag  = 'U'     
           AND B.Status      = 0        
           AND A.CompanySeq  = @CompanySeq      
             IF @@ERROR <> 0  RETURN    
    END    
     
    -- INSERT    
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'A' AND Status = 0)      
    BEGIN      
        INSERT INTO _TPUDelvItem(CompanySeq   ,DelvSeq      ,DelvSerl     ,ItemSeq      ,UnitSeq      ,    
                                 Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq    ,    
                                 StdUnitQty   ,SMQcType     ,QcEmpSeq     ,QcDate       ,QcQty        ,    
                                 QcCurAmt     ,WHSeq        ,LOTNo        ,FromSerial   ,ToSerial     ,    
                                 SalesCustSeq ,DelvCustSeq  ,PJTSeq       ,WBSSeq       ,UMDelayType  ,    
                                 DomPrice     ,CurVAT       ,DomVAT       ,IsVAT        ,    
                                 Remark       ,IsReturn     ,LastUserSeq  ,LastDateTime, MakerSeq     ,       -- MakerSeq  추가  
                                 IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq, SupplyAmt, SupplyVAT,
                                 Memo1        ,Memo2)    
        SELECT @CompanySeq     ,DelvSeq      ,DelvSerl        ,ItemSeq         ,UnitSeq      ,    
               ISNULL(Price,0)   ,ISNULL(Qty,0)   ,ISNULL(CurAmt,0) ,ISNULL(DomAmt,0) ,StdUnitSeq   ,    
               StdUnitQty        ,SMQcType        ,QcEmpSeq         ,QcDate           ,QcQty        ,    
               QcCurAmt          ,WHSeq           ,LOTNo            ,FromSerial       ,ToSerial     ,    
               SalesCustSeq      ,DelvCustSeq     ,PJTSeq           , WBSSeq          ,UMDelayType  ,    
               ISNULL(DomPrice,0),ISNULL(CurVAT,0),ISNULL(DomVAT,0) ,IsVAT            ,    
               Remark            ,IsReturn        ,@UserSeq         ,GETDATE(),    ISNULL(MakerSeq,0),   -- MakerSeq  추가  
               ISNULL(IsFiction, '0')         ,FicRateNum      ,FicRateDen       ,EvidSeq, ISNULL(DomAmt,0), 0,--ISNULL(DomVAT,0)  -- 공급가액 컬럼에 원화 금액, 부가세 들어가도록 추가 2012. 5. 22 hkim
               SalesCustSeq      ,EndUserSeq
          FROM #TPUDelvItem AS A       
         WHERE A.WorkingTag = 'A' AND A.Status = 0        
         
         IF @@ERROR <> 0 RETURN    
    END       
     
        SELECT * FROM #TPUDelvItem       
     
    RETURN 
GO 
exec DTI_SPUDelvItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ItemName>@영업활동관리용유형</ItemName>
    <ItemNo>@영업활동관리용유형</ItemNo>
    <Spec />
    <Price>23.00000</Price>
    <Qty>24.00000</Qty>
    <CurAmt>552.00000</CurAmt>
    <DomPrice>23.00000</DomPrice>
    <DomAmt>552.00000</DomAmt>
    <WHName>(재)청주교구천주교회유지재단 프랜치스코의 집</WHName>
    <WHSeq>5</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMQcTypeName>무검사</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate xml:space="preserve">        </QcDate>
    <QCQty>0.00000</QCQty>
    <QCCurAmt>0.00000</QCCurAmt>
    <QCStdUnitQty>0.00000</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>2.40000</STDUnitQty>
    <StdConvQty>0.10000</StdConvQty>
    <STDUnitSeq>2</STDUnitSeq>
    <ItemSeq>14540</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <LotNo>P201306120003-1</LotNo>
    <FromSerial />
    <Toserial />
    <DelvSeq>133657</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <Remark />
    <LotMngYN xml:space="preserve"> </LotMngYN>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <BizUnit>1</BizUnit>
    <VATRate>0.00000</VATRate>
    <CurVAT>0.00000</CurVAT>
    <DomVAT>0.00000</DomVAT>
    <IsVAT>0</IsVAT>
    <TotCurAmt>552.00000</TotCurAmt>
    <TotDomAmt>552.00000</TotDomAmt>
    <LotNo_Old />
    <DelvNo>201306120003</DelvNo>
    <ItemSeq_Old>14541</ItemSeq_Old>
    <MakerSeq>0</MakerSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553
