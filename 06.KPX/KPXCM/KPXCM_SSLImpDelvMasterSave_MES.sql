IF OBJECT_ID('KPXCM_SSLImpDelvMasterSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SSLImpDelvMasterSave_MES
GO 

-- v2015.09.23 KPXCM MES 용


/*********************************************************************************************************************  
     화면명 : 수입면장마스터저장
     SP Name: _SSLImpDelvMasterSave  
     작성일 : 
     수정일 :   
 ********************************************************************************************************************/  
   
 CREATE PROCEDURE KPXCM_SSLImpDelvMasterSave_MES
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',   
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS         
     DECLARE @docHandle  INT,   
             @DelvSeq      INT,   
             @count      INT,   
             @BizUnit    INT,   
             @CurrDate   NCHAR(8),  
             @InvoiceNo  NCHAR(12)  
       
     -- 서비스 마스타 등록 생성    
     CREATE TABLE #TUIImpDelv (WorkingTag NCHAR(1) NULL)    
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpDelv'   
    
     SELECT @DelvSeq   = DelvSeq,
            @BizUnit = BizUnit  
       FROM #TUIImpDelv
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TUIImpDelv', -- 원테이블명
                    '#TUIImpDelv', -- 템프테이블명  
                    'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    'CompanySeq,DelvSeq,BizUnit,DelvDate,CustSeq,DelvNo,PermitSeq,BLSeq,InvoiceSeq,PaymentSeq,POSeq,
      EmpSeq,DeptSeq,CurrSeq,ExRate,Remark,SMImpKind,IsPJT,LastUserSeq,LastDateTime'
   
 -- DELETE
     IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag = 'D' AND Status = 0 )    
     BEGIN    
         DELETE _TUIImpDelv    
           FROM _TUIImpDelv AS A  
                  JOIN #TUIImpDelv AS B ON  A.DelvSeq = B.DelvSeq AND A.CompanySeq = @CompanySeq  
          WHERE B.WorkingTag = 'D'   
            AND B.Status = 0  
     
     END     
   
 -- Update                                                                                       
     IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag = 'U' AND Status = 0 )    
     BEGIN     
         UPDATE _TUIImpDelv     
            SET  BizUnit   = B.BizUnit,
                 SMImpKind       = B.SMImpKind,
     DelvDate  = B.DelvDate,
     CustSeq   = B.CustSeq,
     DelvNo   = B.DelvNo,
     PermitSeq  = B.PermitSeq,
     BLSeq   = B.BLSeq,
     InvoiceSeq  = B.InvoiceSeq,
     PaymentSeq  = B.PaymentSeq,
     POSeq   = B.POSeq,
     EmpSeq   = B.EmpSeq,
     DeptSeq   = B.DeptSeq,
     CurrSeq   = B.CurrSeq,
     ExRate   = B.ExRate,
     Remark   = B.Remark,
     LastUserSeq     = @UserSeq,
                 LastDateTime    = GETDATE()  
           FROM _TUIImpDelv AS A   
                  JOIN #TUIImpDelv AS B ON A.DelvSeq = B.DelvSeq AND A.CompanySeq = @CompanySeq   
          WHERE B.WorkingTag = 'U'   
            AND B.Status = 0  
     
         IF @@ERROR <> 0 RETURN
         
     END   
  -- INSERT                                                                                               
     IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag = 'A' AND Status = 0 )    
     BEGIN    
   
         -- 서비스 INSERT    
         INSERT INTO _TUIImpDelv(CompanySeq,  DelvSeq, BizUnit, DelvDate, CustSeq,
         DelvNo,   PermitSeq, BLSeq,  InvoiceSeq, PaymentSeq,
         POSeq,   EmpSeq,  DeptSeq, CurrSeq, ExRate,
         Remark,   SMImpKind,  IsPJT,      LastUserSeq,LastDateTime)
             SELECT @CompanySeq   , DelvSeq, BizUnit, DelvDate, CustSeq,
      DelvNo,   PermitSeq, BLSeq,  InvoiceSeq, PaymentSeq,
      POSeq,   EmpSeq,  DeptSeq, CurrSeq, ExRate,
      Remark,   SMImpKind,  IsPJT,      @UserSeq,          GETDATE()  
               FROM #TUIImpDelv    
              WHERE WorkingTag = 'A' AND Status = 0
          
         IF @@ERROR <> 0 RETURN
      END     
      
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TUIImpDelv )  
      
    RETURN @Status  