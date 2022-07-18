IF OBJECT_ID('KPXCM_SPUDelvItemSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SPUDelvItemSave_MES
GO 

-- v2015.09.23 KPXCM MES 용

/************************************************************      
 설  명 - 구매견적 상세 저장      
 작성일 - 2008년 8월 20일       
 작성자 - 노영진      
 수정일 - 2009년 9월 2일      
 수정자 - 김현(무검사품 자동입고 추가)      
 수정일 - 2010년 10월 21일    
 수정자 - 이용춘( MakerSeq 추가)    
 수정일 - 2011. 12. 30 hkim (의제매입 관련 저장, 업데이트 되도록 수정)  
        - 2013.  7. 10 천경민 (Memo1~8 컬럼 추가)  
 ************************************************************/      
     
 CREATE PROC dbo.KPXCM_SPUDelvItemSave_MES
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
       
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
       
     -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정)   
     IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
     BEGIN  
            ALTER TABLE _TPUDelvItem ADD PgmSeq INT NULL  
     END   
   
     IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItemLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
     BEGIN  
            ALTER TABLE _TPUDelvItemLog ADD PgmSeq INT NULL  
     END    
       
       
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)      
     EXEC _SCOMLog  @CompanySeq   ,      
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
                     IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl,IsFiction,FicRateNum,  
                     FicRateDen,EvidSeq,Memo1,Memo2,Memo3,Memo4,Memo5,Memo6,Memo7,Memo8,SMPriceType,PgmSeq'      
                     ,'',@PgmSeq  
       
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvItem WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN        
       
             DELETE _TPUDelvItem      
               FROM _TPUDelvItem A WITH(NOLOCK)
                   JOIN #TPUDelvItem B WITH(NOLOCK) ON A.DelvSeq = B.DelvSeq       
                                                   AND A.DelvSerl = B.DelvSerl      
              WHERE B.WorkingTag = 'D' AND B.Status = 0          
                AND A.CompanySeq  = @CompanySeq      
             IF @@ERROR <> 0  RETURN      
       
     END        
       
     -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'U' AND Status = 0)        
     BEGIN      
       
             UPDATE _TPUDelvItem      
                SET        
                     ItemSeq      = B.ItemSeq      ,      
                     UnitSeq      = B.UnitSeq      ,      
                     Price        = ISNULL(B.Price        , 0),      
                     DomPrice     = ISNULL(B.DomPrice     , 0),      
   Qty          = ISNULL(B.Qty          , 0),      
                     CurAmt       = ISNULL(B.CurAmt        , 0),      
                     DomAmt       = ISNULL(B.DomAmt       , 0),      
                       CurVAT       = ISNULL(B.CurVAT       , 0),      
                     DomVAT       = ISNULL(B.DomVAT       , 0),      
                     IsVAT        = B.IsVAT        ,      
                     StdUnitSeq   = B.StdUnitSeq   ,      
                     StdUnitQty   = B.StdUnitQty   ,      
                     --SMQcType     = B.SMQcType     ,    -- 2014.03.04 김용현 검사 구분은 이미 구매검사의뢰에서 처리해주므로  
                                                          -- 두번 처리 할 필요 없어서 주석처리  
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
                     EvidSeq      = B.EvidSeq      ,         --2011. 12. 30 hkim 추가  
                     Memo1        = B.Memo1,  
                     Memo2        = B.Memo2,  
                     Memo3        = B.Memo3,  
                     Memo4        = B.Memo4,  
                     Memo5        = B.Memo5,  
                     Memo6        = B.Memo6,  
                     Memo7        = B.Memo7,  
                     Memo8        = B.Memo8,  
                     SMPriceType  = B.SMPriceType,  
                     PgmSeq       = @PgmSeq  
               FROM _TPUDelvItem AS A WITH(NOLOCK) 
                    JOIN #TPUDelvItem AS B WITH(NOLOCK) ON A.DelvSeq = B.DelvSeq       
                                                       AND A.DelvSerl = B.DelvSerl      
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
                                 Memo1        ,Memo2        ,Memo3        ,Memo4        ,Memo5        ,  
                        Memo6        ,Memo7        ,Memo8        ,SMPriceType  ,PgmSeq)  
         SELECT  @CompanySeq     ,DelvSeq      ,DelvSerl        ,ItemSeq         ,UnitSeq      ,      
                   ISNULL(Price,0)   ,ISNULL(Qty,0)   ,ISNULL(CurAmt,0) ,ISNULL(DomAmt,0) ,StdUnitSeq   ,      
                 StdUnitQty        ,SMQcType        ,QcEmpSeq         ,QcDate           ,QcQty        ,      
                 QcCurAmt          ,WHSeq           ,LOTNo            ,FromSerial       ,ToSerial     ,      
                 SalesCustSeq      ,DelvCustSeq     ,PJTSeq           , WBSSeq          ,UMDelayType  ,      
                 ISNULL(DomPrice,0),ISNULL(CurVAT,0),ISNULL(DomVAT,0) ,IsVAT            ,      
                 Remark            ,IsReturn        ,@UserSeq         ,GETDATE(),    ISNULL(MakerSeq,0),   -- MakerSeq  추가    
                 ISNULL(IsFiction, '0')         ,FicRateNum      ,FicRateDen       ,EvidSeq, ISNULL(DomAmt,0), 0, --ISNULL(DomVAT,0)  -- 공급가액 컬럼에 원화 금액, 부가세 들어가도록 추가 2012. 5. 22 hkim  
                 Memo1        ,Memo2        ,Memo3        ,Memo4        ,Memo5        ,  
                 Memo6        ,Memo7        ,Memo8        ,SMPriceType  ,@PgmSeq  
           FROM #TPUDelvItem AS A WITH(NOLOCK)        
          WHERE A.WorkingTag = 'A' AND A.Status = 0          
         IF @@ERROR <> 0 RETURN      
     END         
       
           
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TPUDelvItem )  
      
    RETURN @Status  
    