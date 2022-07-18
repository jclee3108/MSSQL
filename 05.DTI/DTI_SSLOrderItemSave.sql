
IF OBJECT_ID('DTI_SSLOrderItemSave') IS NOT NULL
    DROP PROC DTI_SSLOrderItemSave

GO
    /*************************************************************************************************  
   설  명 - 수주품목 저장  
   작성일 - 2008.7 : CREATED BY 김준모
   수정일 - 2009.09.21 Modify By 송경애
          :: 할증여부(IsGift) 추가
            2010.09.17 Modify By 허승남
          :: LotNo컬럼 추가     
            2010.10.01 Modify By 허승남
          :: 반품수주에서 넘어올 경우 반품수주번호 컬럼추가
  *************************************************************************************************/  
  CREATE PROC DTI_SSLOrderItemSave
      @xmlDocument    NVARCHAR(MAX),  
      @xmlFlags       INT = 0,  
      @ServiceSeq     INT = 0,  
      @WorkingTag     NVARCHAR(10)= '',  
    
      @CompanySeq     INT = 1,  
      @LanguageSeq    INT = 1,  
      @UserSeq        INT = 0,  
      @PgmSeq         INT = 0  
  AS  
      DECLARE @docHandle        INT
       -- 서비스 마스타 등록 생성  
      CREATE TABLE #TSLOrderItem (WorkingTag NCHAR(1) NULL)  
      ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLOrderItem'  
       -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
      EXEC _SCOMLog  @CompanySeq   ,  
                     @UserSeq      ,  
                     '_TSLOrderItem', -- 원테이블명  
                     '#TSLOrderItem', -- 템프테이블명  
                     'OrderSeq,OrderSerl' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq,OrderSeq,OrderSerl,OrderSubSerl,ItemSeq,UnitSeq,ItemPrice,CustPrice,Qty,IsInclusedVAT,VATRate,CurAmt,CurVAT,DomAmt,DomVAT,DVDate,DVTime,STDUnitSeq,STDQty,WHSeq,DVPlaceSeq,Remark,ModelSeq,IsStop,StopEmpSeq,StopDate,OptionSeq,UMEtcOutKind,LastUserSeq,LastDateTime,IsGift,CCtrSeq, PJTSeq, WBSSeq, Dummy1, Dummy2, Dummy3, Dummy4, Dummy5, Dummy6, Dummy7,Dummy8,Dummy9,Dummy10,LotNo,RetOrderSeq,RetOrderSerl'
       -- DELETE    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'D' AND Status = 0  )  
      BEGIN  
          DELETE _TSLOrderItem  
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND B.OrderSeq   = A.OrderSeq  
                                                      AND B.OrderSerl  = A.OrderSerl
                                                      AND (ISNULL(A.OrderSubSerl,0) = 0 OR B.OrderSubSerl = A.OrderSubSerl)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산옵션 DELETE
          DELETE _TSLOrderItemSpecOption
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpecOption AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                AND B.OrderSeq    = A.OrderSeq  
                                                                AND B.OrderSerl   = A.OrderSerl
                                                                AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산사양 DELETE
          DELETE _TSLOrderItemSpec
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpec AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                          AND B.OrderSeq    = A.OrderSeq  
                                                          AND B.OrderSerl   = A.OrderSerl
                                                          AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산사양항목 DELETE
          DELETE _TSLOrderItemSpecItem
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpecItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
        AND B.OrderSeq    = A.OrderSeq  
                                   AND B.OrderSerl   = A.OrderSerl
               AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
      END  
       -- Update    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'U' AND Status = 0  )  
      BEGIN   
          IF EXISTS (SELECT 1
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                          AND B.OrderSeq   = A.OrderSeq  
                                                          AND B.OrderSerl  = A.OrderSerl
               WHERE A.WorkingTag = 'U' AND A.Status = 0
                 AND A.ModelSeq <> B.ModelSeq)
          BEGIN
              -- 수주생산사양 DELETE
              DELETE _TSLOrderItemSpec
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItemSpec AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                              AND B.OrderSeq    = A.OrderSeq  
                                                              AND B.OrderSerl   = A.OrderSerl
               WHERE B.OrderSerl IN (SELECT A.OrderSerl
                                       FROM #TSLOrderItem AS A  
                                            JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                 AND B.OrderSeq   = A.OrderSeq  
                                                                                 AND B.OrderSerl  = A.OrderSerl
                                      WHERE A.WorkingTag = 'U' AND A.Status = 0
                                        AND A.ModelSeq <> B.ModelSeq)
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
               -- 수주생산사양항목 DELETE
              DELETE _TSLOrderItemSpecItem
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItemSpecItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                  AND B.OrderSeq    = A.OrderSeq  
                                                                  AND B.OrderSerl   = A.OrderSerl
               WHERE B.OrderSerl IN (SELECT A.OrderSerl
                                       FROM #TSLOrderItem AS A  
                                            JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                 AND B.OrderSeq   = A.OrderSeq  
                                                                                 AND B.OrderSerl  = A.OrderSerl
                                      WHERE A.WorkingTag = 'U' AND A.Status = 0
                                        AND A.ModelSeq <> B.ModelSeq)
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
           UPDATE _TSLOrderItem  
             SET  ItemSeq = ISNULL(A.ItemSeq,0),
                  UnitSeq = ISNULL(A.UnitSeq,0),
                  ItemPrice = ISNULL(A.ItemPrice,0),
                  CustPrice = ISNULL(A.CustPrice,0),
                  Qty = ISNULL(A.Qty,0),
                  IsInclusedVAT = ISNULL(A.IsInclusedVAT,''),
                  VATRate = ISNULL(A.VATRate,0),
                  CurAmt = ISNULL(A.CurAmt,0),
                  CurVAT = ISNULL(A.CurVAT,0),
                  DomAmt = ISNULL(A.DomAmt,0),
                  DomVAT = ISNULL(A.DomVAT,0),
                  DVDate = ISNULL(A.DVDate,''),
                  DVTime = ISNULL(A.DVTime,''),
                  STDUnitSeq = ISNULL(A.STDUnitSeq,0),
                  STDQty = ISNULL(A.STDQty,0),
                  WHSeq = ISNULL(A.WHSeq,0),
                  DVPlaceSeq = ISNULL(A.DVPlaceSeq,0),
                  Remark = ISNULL(A.Remark,''),
                  ModelSeq = ISNULL(A.ModelSeq,0),
                  UMEtcOutKind = ISNULL(A.UMEtcOutKind,0),
                  IsGift  = ISNULL(A.IsGift,''),
                  CCtrSeq = ISNULL(A.CCtrSeq,0),
                  PJTSeq = ISNULL(A.PJTSeq,0),
                  WBSSeq = ISNULL(A.WBSSeq,0),
                  Dummy1 = ISNULL(A.Dummy1,''),
                  Dummy2 = ISNULL(A.Dummy2,''),
                  Dummy3 = ISNULL(A.Dummy3,''),
                  Dummy4 = ISNULL(A.Dummy4,''),
                  Dummy5 = ISNULL(A.Dummy5,''),
                  Dummy6 = ISNULL(A.Dummy6,0),
                  Dummy7 = ISNULL(A.Dummy7,0),
                  Dummy8 = ISNULL(A.Dummy8,''),
                  Dummy9 = ISNULL(A.Dummy9,''),
                  Dummy10 = ISNULL(A.Dummy10,''),
                  BKCustSeq = ISNULL(A.BKCustSeq, 0),
                  LotNo   = ISNULL(A.LotNo, ''),
                  LastUserSeq  = @UserSeq,
                  LastDateTime = GETDATE()
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND B.OrderSeq   = A.OrderSeq  
                                                      AND B.OrderSerl  = A.OrderSerl
                                                      AND B.OrderSubSerl = A.OrderSubSerl
           WHERE A.WorkingTag = 'U' AND A.Status = 0
     
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
       END  
       
      -- INSERT    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'A' AND Status = 0 )  
      BEGIN  
           INSERT INTO _TSLOrderItem(  
                  CompanySeq,
                  OrderSeq,
                  OrderSerl,
                  OrderSubSerl,
                  ItemSeq,
                  UnitSeq,
                  ItemPrice,
                  CustPrice,
                  Qty,
                  IsInclusedVAT,
                  VATRate,
                  CurAmt,
                  CurVAT,
                  DomAmt,
                  DomVAT,
                  DVDate,
                  DVTime,
                  STDUnitSeq,
                  STDQty,
                  WHSeq,
                  DVPlaceSeq,
                  Remark,
                  ModelSeq,
                  IsStop,
                  StopEmpSeq,
                  StopDate,
                  UMEtcOutKind,
                  OptionSeq,
                  IsGift,
                  CCtrSeq,
                  PJTSeq, 
                  WBSSeq,
                  Dummy1,
                  Dummy2,
                  Dummy3,
                  Dummy4,
                  Dummy5,
                  Dummy6,
                  Dummy7,
                  Dummy8,
                  Dummy9,
                  Dummy10,
                  BKCustSeq,
                  LotNo,
                  RetOrderSeq,
                  RetOrderSerl,
                  LastUserSeq,
                  LastDateTime)
          SELECT  @CompanySeq,
                  OrderSeq,
                  OrderSerl,
                  ISNULL(OrderSubSerl,0),
                  ISNULL(ItemSeq,0),
                  ISNULL(UnitSeq,0),
                  ISNULL(ItemPrice,0),
                  ISNULL(CustPrice,0),
                  ISNULL(Qty,0),
                  ISNULL(IsInclusedVAT,''),
                  ISNULL(VATRate,0),
                  ISNULL(CurAmt,0),
                  ISNULL(CurVAT,0),
                  ISNULL(DomAmt,0),
                  ISNULL(DomVAT,0),
                  ISNULL(DVDate,''),
                  ISNULL(DVTime,''),
                  ISNULL(STDUnitSeq,0),
                  ISNULL(STDQty,0),
                  ISNULL(WHSeq,0),
                  ISNULL(DVPlaceSeq,0),
                  ISNULL(Remark,''),
                  ISNULL(ModelSeq,0),
                  '0',
                  ISNULL(StopEmpSeq,0),
                  ISNULL(StopDate,''),
                  ISNULL(UMEtcOutKind,0),
                  ISNULL(OptionSeq,0),
                  ISNULL(IsGift,''),
                  ISNULL(CCtrSeq,0),
                  ISNULL(PJTSeq,0),
          ISNULL(WBSSeq,0),
                  ISNULL(Dummy1,''),
          ISNULL(Dummy2,''),
                  ISNULL(Dummy3,''),
                  ISNULL(Dummy4,''),
                  ISNULL(Dummy5,''),
                  ISNULL(Dummy6,0),
                  ISNULL(Dummy7,0),
                  ISNULL(Dummy8,''),
                ISNULL(Dummy9,''),
                  ISNULL(Dummy10,''),
                  ISNULL(BKCustSeq, 0),
                  ISNULL(LotNo, ''),
                  ISNULL(RetOrderSeq, 0),
                  ISNULL(RetOrderSerl, 0),
                  @UserSeq,
                  GETDATE()
            FROM #TSLOrderItem A  
           WHERE WorkingTag = 'A' AND Status = 0
    
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END     
      END      
      
      SELECT * FROM #TSLOrderItem  
    
   RETURN
/*************************************************************************************************  
   설  명 - 수주품목 저장  
   작성일 - 2008.7 : CREATED BY 김준모
   수정일 - 2009.09.21 Modify By 송경애
          :: 할증여부(IsGift) 추가
            2010.09.17 Modify By 허승남
          :: LotNo컬럼 추가     
            2010.10.01 Modify By 허승남
          :: 반품수주에서 넘어올 경우 반품수주번호 컬럼추가
  *************************************************************************************************/  
  CREATE PROCEDURE DTI_SSLOrderItemSave
      @xmlDocument    NVARCHAR(MAX),  
      @xmlFlags       INT = 0,  
      @ServiceSeq     INT = 0,  
      @WorkingTag     NVARCHAR(10)= '',  
    
      @CompanySeq     INT = 1,  
      @LanguageSeq    INT = 1,  
      @UserSeq        INT = 0,  
      @PgmSeq         INT = 0  
  AS  
      DECLARE @docHandle        INT
       -- 서비스 마스타 등록 생성  
      CREATE TABLE #TSLOrderItem (WorkingTag NCHAR(1) NULL)  
      ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLOrderItem'  
       -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
      EXEC _SCOMLog  @CompanySeq   ,  
                     @UserSeq      ,  
                     '_TSLOrderItem', -- 원테이블명  
                     '#TSLOrderItem', -- 템프테이블명  
                     'OrderSeq,OrderSerl' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq,OrderSeq,OrderSerl,OrderSubSerl,ItemSeq,UnitSeq,ItemPrice,CustPrice,Qty,IsInclusedVAT,VATRate,CurAmt,CurVAT,DomAmt,DomVAT,DVDate,DVTime,STDUnitSeq,STDQty,WHSeq,DVPlaceSeq,Remark,ModelSeq,IsStop,StopEmpSeq,StopDate,OptionSeq,UMEtcOutKind,LastUserSeq,LastDateTime,IsGift,CCtrSeq, PJTSeq, WBSSeq, Dummy1, Dummy2, Dummy3, Dummy4, Dummy5, Dummy6, Dummy7,Dummy8,Dummy9,Dummy10,LotNo,RetOrderSeq,RetOrderSerl'
       -- DELETE    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'D' AND Status = 0  )  
      BEGIN  
          DELETE _TSLOrderItem  
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND B.OrderSeq   = A.OrderSeq  
                                                      AND B.OrderSerl  = A.OrderSerl
                                                      AND (ISNULL(A.OrderSubSerl,0) = 0 OR B.OrderSubSerl = A.OrderSubSerl)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산옵션 DELETE
          DELETE _TSLOrderItemSpecOption
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpecOption AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                AND B.OrderSeq    = A.OrderSeq  
                                                                AND B.OrderSerl   = A.OrderSerl
                                                                AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산사양 DELETE
          DELETE _TSLOrderItemSpec
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpec AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                          AND B.OrderSeq    = A.OrderSeq  
                                                          AND B.OrderSerl   = A.OrderSerl
                                                          AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           -- 수주생산사양항목 DELETE
          DELETE _TSLOrderItemSpecItem
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItemSpecItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
        AND B.OrderSeq    = A.OrderSeq  
                                   AND B.OrderSerl   = A.OrderSerl
               AND (ISNULL(A.OrderSubSerl,0) = 0)
           WHERE A.WorkingTag = 'D' AND A.Status = 0   
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
      END  
       -- Update    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'U' AND Status = 0  )  
      BEGIN   
          IF EXISTS (SELECT 1
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                          AND B.OrderSeq   = A.OrderSeq  
                                                          AND B.OrderSerl  = A.OrderSerl
               WHERE A.WorkingTag = 'U' AND A.Status = 0
                 AND A.ModelSeq <> B.ModelSeq)
          BEGIN
              -- 수주생산사양 DELETE
              DELETE _TSLOrderItemSpec
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItemSpec AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                              AND B.OrderSeq    = A.OrderSeq  
                                                              AND B.OrderSerl   = A.OrderSerl
               WHERE B.OrderSerl IN (SELECT A.OrderSerl
                                       FROM #TSLOrderItem AS A  
                                            JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                 AND B.OrderSeq   = A.OrderSeq  
                                                                                 AND B.OrderSerl  = A.OrderSerl
                                      WHERE A.WorkingTag = 'U' AND A.Status = 0
                                        AND A.ModelSeq <> B.ModelSeq)
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
               -- 수주생산사양항목 DELETE
              DELETE _TSLOrderItemSpecItem
                FROM #TSLOrderItem AS A  
                     JOIN _TSLOrderItemSpecItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                  AND B.OrderSeq    = A.OrderSeq  
                                                                  AND B.OrderSerl   = A.OrderSerl
               WHERE B.OrderSerl IN (SELECT A.OrderSerl
                                       FROM #TSLOrderItem AS A  
                                            JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                 AND B.OrderSeq   = A.OrderSeq  
                                                                                 AND B.OrderSerl  = A.OrderSerl
                                      WHERE A.WorkingTag = 'U' AND A.Status = 0
                                        AND A.ModelSeq <> B.ModelSeq)
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
           UPDATE _TSLOrderItem  
             SET  ItemSeq = ISNULL(A.ItemSeq,0),
                  UnitSeq = ISNULL(A.UnitSeq,0),
                  ItemPrice = ISNULL(A.ItemPrice,0),
                  CustPrice = ISNULL(A.CustPrice,0),
                  Qty = ISNULL(A.Qty,0),
                  IsInclusedVAT = ISNULL(A.IsInclusedVAT,''),
                  VATRate = ISNULL(A.VATRate,0),
                  CurAmt = ISNULL(A.CurAmt,0),
                  CurVAT = ISNULL(A.CurVAT,0),
                  DomAmt = ISNULL(A.DomAmt,0),
                  DomVAT = ISNULL(A.DomVAT,0),
                  DVDate = ISNULL(A.DVDate,''),
                  DVTime = ISNULL(A.DVTime,''),
                  STDUnitSeq = ISNULL(A.STDUnitSeq,0),
                  STDQty = ISNULL(A.STDQty,0),
                  WHSeq = ISNULL(A.WHSeq,0),
                  DVPlaceSeq = ISNULL(A.DVPlaceSeq,0),
                  Remark = ISNULL(A.Remark,''),
                  ModelSeq = ISNULL(A.ModelSeq,0),
                  UMEtcOutKind = ISNULL(A.UMEtcOutKind,0),
                  IsGift  = ISNULL(A.IsGift,''),
                  CCtrSeq = ISNULL(A.CCtrSeq,0),
                  PJTSeq = ISNULL(A.PJTSeq,0),
                  WBSSeq = ISNULL(A.WBSSeq,0),
                  Dummy1 = ISNULL(A.Dummy1,''),
                  Dummy2 = ISNULL(A.Dummy2,''),
                  Dummy3 = ISNULL(A.Dummy3,''),
                  Dummy4 = ISNULL(A.Dummy4,''),
                  Dummy5 = ISNULL(A.Dummy5,''),
                  Dummy6 = ISNULL(A.Dummy6,0),
                  Dummy7 = ISNULL(A.Dummy7,0),
                  Dummy8 = ISNULL(A.Dummy8,''),
                  Dummy9 = ISNULL(A.Dummy9,''),
                  Dummy10 = ISNULL(A.Dummy10,''),
                  BKCustSeq = ISNULL(A.BKCustSeq, 0),
                  LotNo   = ISNULL(A.LotNo, ''),
                  LastUserSeq  = @UserSeq,
                  LastDateTime = GETDATE()
            FROM #TSLOrderItem AS A  
                 JOIN _TSLOrderItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND B.OrderSeq   = A.OrderSeq  
                                                      AND B.OrderSerl  = A.OrderSerl
                                                      AND B.OrderSubSerl = A.OrderSubSerl
           WHERE A.WorkingTag = 'U' AND A.Status = 0
     
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
       END  
       
      -- INSERT    
      IF EXISTS (SELECT 1 FROM #TSLOrderItem WHERE WorkingTag = 'A' AND Status = 0 )  
      BEGIN  
           INSERT INTO _TSLOrderItem(  
                  CompanySeq,
                  OrderSeq,
                  OrderSerl,
                  OrderSubSerl,
                  ItemSeq,
                  UnitSeq,
                  ItemPrice,
                  CustPrice,
                  Qty,
                  IsInclusedVAT,
                  VATRate,
                  CurAmt,
                  CurVAT,
                  DomAmt,
                  DomVAT,
                  DVDate,
                  DVTime,
                  STDUnitSeq,
                  STDQty,
                  WHSeq,
                  DVPlaceSeq,
                  Remark,
                  ModelSeq,
                  IsStop,
                  StopEmpSeq,
                  StopDate,
                  UMEtcOutKind,
                  OptionSeq,
                  IsGift,
                  CCtrSeq,
                  PJTSeq, 
                  WBSSeq,
                  Dummy1,
                  Dummy2,
                  Dummy3,
                  Dummy4,
                  Dummy5,
                  Dummy6,
                  Dummy7,
                  Dummy8,
                  Dummy9,
                  Dummy10,
                  BKCustSeq,
                  LotNo,
                  RetOrderSeq,
                  RetOrderSerl,
                  LastUserSeq,
                  LastDateTime)
          SELECT  @CompanySeq,
                  OrderSeq,
                  OrderSerl,
                  ISNULL(OrderSubSerl,0),
                  ISNULL(ItemSeq,0),
                  ISNULL(UnitSeq,0),
                  ISNULL(ItemPrice,0),
                  ISNULL(CustPrice,0),
                  ISNULL(Qty,0),
                  ISNULL(IsInclusedVAT,''),
                  ISNULL(VATRate,0),
                  ISNULL(CurAmt,0),
                  ISNULL(CurVAT,0),
                  ISNULL(DomAmt,0),
                  ISNULL(DomVAT,0),
                  ISNULL(DVDate,''),
                  ISNULL(DVTime,''),
                  ISNULL(STDUnitSeq,0),
                  ISNULL(STDQty,0),
                  ISNULL(WHSeq,0),
                  ISNULL(DVPlaceSeq,0),
                  ISNULL(Remark,''),
                  ISNULL(ModelSeq,0),
                  '0',
                  ISNULL(StopEmpSeq,0),
                  ISNULL(StopDate,''),
                  ISNULL(UMEtcOutKind,0),
                  ISNULL(OptionSeq,0),
                  ISNULL(IsGift,''),
                  ISNULL(CCtrSeq,0),
                  ISNULL(PJTSeq,0),
          ISNULL(WBSSeq,0),
                  ISNULL(Dummy1,''),
          ISNULL(Dummy2,''),
                  ISNULL(Dummy3,''),
                  ISNULL(Dummy4,''),
                  ISNULL(Dummy5,''),
                  ISNULL(Dummy6,0),
                  ISNULL(Dummy7,0),
                  ISNULL(Dummy8,''),
                ISNULL(Dummy9,''),
                  ISNULL(Dummy10,''),
                  ISNULL(BKCustSeq, 0),
                  ISNULL(LotNo, ''),
                  ISNULL(RetOrderSeq, 0),
                  ISNULL(RetOrderSerl, 0),
                  @UserSeq,
                  GETDATE()
            FROM #TSLOrderItem A  
           WHERE WorkingTag = 'A' AND Status = 0
    
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END     
      END      
      
      SELECT * FROM #TSLOrderItem  
    
   RETURN