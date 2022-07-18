IF OBJECT_ID('KPXCM_SSLImpDelvSheetSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SSLImpDelvSheetSave_MES
GO 

-- v2015.09.23 KPXCM MES 용

/*********************************************************************************************************************  
     화면명 : 수입면장시트저장
     SP Name: _SSLImpDelvSheetSave  
     작성일 : 
     수정일 : 2013.11.28 Memo컬럼 조회추가    by 서보영   
 ********************************************************************************************************************/  
 CREATE PROCEDURE KPXCM_SSLImpDelvSheetSave_MES
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
      CREATE TABLE #TUIImpDelvItem (WorkingTag NCHAR(1) NULL)    
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TUIImpDelvItem'   
  
  
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TUIImpDelvItem', -- 원테이블명  
                    '#TUIImpDelvItem', -- 템프테이블명  
                    'DelvSeq, DelvSerl' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,DomAmt,WHSeq,LotNo,FromSerl,ToSerl,ProdDate,STDUnitSeq,
                     STDQty,LastUserSeq,LastDateTime,OKCurAmt,OKDomAmt,AccSeq,VATAccSeq,OppAccSeq,SlipSeq,IsCostCalc,PJTSeq,WBSSeq,MakerSeq,Remark,
                     Memo1,Memo2,Memo3,Memo4,Memo5,Memo6,Memo7,Memo8'
   
 -- DELETE                                                                                                  
     IF EXISTS (SELECT 1 FROM #TUIImpDelvItem WHERE WorkingTag = 'D' AND Status = 0 )    
     BEGIN
         DELETE _TUIImpDelvItem
           FROM _TUIImpDelvItem AS A
                  JOIN #TUIImpDelvItem AS B ON  A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl  
          WHERE A.CompanySeq = @CompanySeq  
            AND B.WorkingTag = 'D'   
            AND B.Status = 0      
             
     END     
   
 -- Update    원화판매단가 추가 2009.01.14 by snheo                                                                                               
     IF EXISTS (SELECT 1 FROM #TUIImpDelvItem WHERE WorkingTag = 'U' AND Status = 0 )    
     BEGIN     
         UPDATE _TUIImpDelvItem     
            SET  ItemSeq = B.ItemSeq,
     UnitSeq = B.UnitSeq,
     Qty  = B.Qty,
     Price = B.Price,
     CurAmt = B.CurAmt,
     DomAmt = B.DomAmt,
     WHSeq = B.WHSeq,
     LotNo = B.LotNo,
     FromSerl = B.FromSerlNo,
     ToSerl  = B.ToSerlNo,
     ProdDate = B.ProdDate,
     STDUnitSeq = B.STDUnitSeq,
     STDQty  = B.STDQty, 
                 PJTSeq      = B.PJTSeq,
                 WBSSeq      = B.WBSSeq,
     MakerSeq = B.MakerSeq,
     LastUserSeq   = @UserSeq,
     LastDateTime  = GETDATE(), 
     Remark        = B.Remark,
                 Memo1         = B.Memo1,  -- by 서보영 2013.11.28
                 Memo2         = B.Memo2,
                 Memo3         = B.Memo3,
                 Memo4         = B.Memo4,
                 Memo5         = B.Memo5,
                 Memo6         = B.Memo6,
                 Memo7         = B.Memo7,
                 Memo8         = B.Memo8
   
           FROM _TUIImpDelvItem AS A   
                  JOIN #TUIImpDelvItem AS B ON A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl  
          WHERE B.WorkingTag = 'U'   
            AND B.Status = 0  
            AND A.CompanySeq = @CompanySeq  
      
          IF @@ERROR <> 0 RETURN     
         
     END   
   
 -- INSERT     원화판매단가 추가 2009.01.14 by snheo                                                                                              
     IF EXISTS (SELECT 1 FROM #TUIImpDelvItem WHERE WorkingTag = 'A' AND Status = 0 )    
     BEGIN         
     
         -- 서비스 INSERT    
         INSERT INTO _TUIImpDelvItem(
                     CompanySeq, DelvSeq, DelvSerl, ItemSeq, UnitSeq,
      Qty,  Price,  CurAmt,  DomAmt,  WHSeq,
      LotNo,  FromSerl, ToSerl,  ProdDate,
      STDUnitSeq, STDQty,  PJTSeq,     WBSSeq,     MakerSeq, 
      LastUserSeq,LastDateTime, Remark,
                     Memo1,      Memo2,      Memo3,      Memo4,      Memo5,
                     Memo6,      Memo7,      Memo8)
               SELECT @CompanySeq, DelvSeq, DelvSerl, ItemSeq, UnitSeq,
      Qty,  Price,  CurAmt,  DomAmt,  WHSeq,
      LotNo,  FromSerlNo, ToSerlNo, ProdDate,
      STDUnitSeq, STDQty,  PJTSeq,     WBSSeq,     MakerSeq, 
      @UserSeq,   GETDATE(),  Remark,
                     Memo1,      Memo2,      Memo3,      Memo4,      Memo5,     -- by 서보영 2013.11.28
                     Memo6,      Memo7,      Memo8
                 FROM #TUIImpDelvItem
               WHERE WorkingTag = 'A' AND Status = 0
   
         IF @@ERROR <> 0 RETURN
   
     END     
     
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TUIImpDelvItem )  
      
    RETURN @Status  