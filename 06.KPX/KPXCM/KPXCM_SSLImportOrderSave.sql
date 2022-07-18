IF OBJECT_ID('KPXCM_SSLImportOrderSave') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderSave
GO 

-- v2015.10.06 

-- PONo 수정될수있도록 by이재천 
/*************************************************************************************************    
      Ver. 121004
      화면명 : 수입Order저장   
     SP Name: _SSLImportOrderSave    
     작성일 : 2009.01.05 : CREATEd by 천혜연        
     수정일 : 2009.07.29 : 수입Order차수관련필드추가 (snheo)
              2010.02.23 : 수입Order테이블에 결제자금계정, 결제예정일, 결제은행, 금회결제금액 추가 Modify by 허승남
 *************************************************************************************************/   
 CREATE PROCEDURE KPXCM_SSLImportOrderSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
     DECLARE @docHandle          INT,  
             @Count              INT,  
             @POSeq              INT,  
             @PODate             NVARCHAR(8),  
             @PONo               NVARCHAR(50)  
   
     -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPO'
      IF @@ERROR <> 0 RETURN       
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq,    
                    @UserSeq,    
                    '_TPUORDPO',     
                    '#TPUORDPO',    
                    'POSeq',    
                    'CompanySeq,POSeq,PoNo,SMImpType,PoDate,DeptSeq,EmpSeq,CustSeq,CurrSeq,ExRate,Payment,Remark,IsCustAccept,POAmd,IsDirectDelv,UnitAssySeq,IsConfirm,ConfirmDate,ConfirmEmpSeq,B2BTranCnt,IsPJT,PoMngNo,SMProgStatus,ERP,PORev,PORevEmpSeq,PORevDate,LastUserSeq,LastDateTime'
  
     EXEC _SCOMLog  @CompanySeq,    
                    @UserSeq,    
                    '_TSLImpOrder',     
                    '#TPUORDPO',    
                    'POSeq',    
                    'CompanySeq,POSeq,BizUnit,POAmd,PORefNo,BKCustSeq,UMPriceTerms,UMPayment1,UMPayment2,Payment3,UMShipVia,Packing,LoadingPort,ETD,DischargingPort,ETA,Destination,CountryOfOrigin,Validity,Remark,LastUserSeq,LastDateTime,Memo,IsPJT,FundAccSeq,PrePaymentDate,PaymentBankSeq,PaymentAmt,FileSeq'
  
     -- DELETE    
     IF EXISTS (SELECT TOP 1 1 FROM #TPUORDPO WHERE WorkingTag = 'D' AND Status = 0  )  
     BEGIN  
         DELETE _TPUORDPO  
           FROM _TPUORDPO AS A JOIN #TPUORDPO AS B ON A.POSeq = B.POSeq --AND A.POAmd = B.POAmd)  
          WHERE B.WorkingTag = 'D' AND B.Status = 0    
            AND A.CompanySeq = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN    
  
         DELETE _TSLImpOrder  
           FROM _TSLImpOrder AS A JOIN #TPUORDPO AS B ON A.POSeq = B.POSeq --AND A.POAmd = B.POAmd)  
          WHERE B.WorkingTag = 'D' AND B.Status = 0    
            AND A.CompanySeq = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN  
   
         DELETE _TPUORDPOItem  
           FROM _TPUORDPOItem AS A JOIN #TPUORDPO AS B ON A.POSeq = B.POSeq --AND A.POAmd = B.POAmd)  
          WHERE B.WorkingTag = 'D' AND B.Status = 0    
            AND A.CompanySeq = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN    
     END      
     -- Update    
     IF EXISTS (SELECT 1 FROM #TPUORDPO WHERE WorkingTag = 'U' AND Status = 0  )  
     BEGIN   
         UPDATE _TPUORDPO SET  
                 PONo         = ISNULL(B.PONo,''), 
                 SMImpType    = ISNULL(B.SMImpType, 0) ,  
                 PODate       = ISNULL(B.PODate, '')    ,  
                 DeptSeq      = ISNULL(B.DeptSeq, 0)   ,  
                 EmpSeq       = ISNULL(B.EmpSeq, 0)    ,  
                 CustSeq      = ISNULL(B.CustSeq, 0)   ,        
                 CurrSeq      = ISNULL(B.CurrSeq, 0)   ,  
                 ExRate       = ISNULL(B.ExRate, 0)    ,  
                 Remark       = ISNULL(B.Remark, '')    ,  
                 POAmd        = 0     ,        
     POMngNo   = ISNULL(B.PORefNo, '')   ,
                 PORev        = ISNULL(B.PORev, 0)     ,
  PORevEmpSeq  = ISNULL(B.PORevEmpSeq, 0),
                 PORevDate    = ISNULL(B.PORevDate, '')  ,
             LastUserSeq  = @UserSeq    ,   
                 LastDateTime = GETDATE()  
           FROM _TPUORDPO AS A JOIN #TPUORDPO AS B ON (A.POSeq = B.POSeq)  
          WHERE B.WorkingTag = 'U' AND B.Status = 0    
            AND A.CompanySeq  = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN  
    UPDATE _TSLImpOrder SET 
     BizUnit   = ISNULL(B.BizUnit, 0),
     PORefNo   = ISNULL(B.PORefNo, '') ,
     BKCustSeq  = ISNULL(B.BKCustSeq, 0),
     UMPriceTerms = ISNULL(B.UMPriceTerms, 0),
     UMPayment1  = ISNULL(B.UMPayment1, 0),
     UMPayment2  = ISNULL(B.UMPayment2, 0),
     Payment3  = ISNULL(B.Payment3, ''),
     UMShipVia  = ISNULL(B.UMShipVia, 0),
     LoadingPort  = ISNULL(B.LoadingPort, ''),
     ETD    = ISNULL(B.ETD, ''),
     DischargingPort = ISNULL(B.DischargingPort, 0),
     ETA    = ISNULL(B.ETA, ''),
     Destination  = ISNULL(B.Destination, ''),
     CountryofOrigin = ISNULL(B.CountryofOrigin, ''),
     Validity  = ISNULL(B.Validity, ''),
     Remark   = ISNULL(B.Remark2, ''),
                 POAmd   = 0,
                 Memo            = ISNULL(B.Memo, ''),
                 Packing         = ISNULL(B.Packing, ''),  
                 FundAccSeq      = ISNULL(B.FundAccSeq, 0),
                 PrePaymentDate  = ISNULL(B.PrePaymentDate, ''),
                 PaymentBankSeq  = ISNULL(B.PaymentBankSeq, 0),
                 PaymentAmt      = ISNULL(B.PaymentAmt, 0),      
                 LastUserSeq  = @UserSeq,   
                 LastDateTime = GETDATE(),
                 FileSeq         = ISNULL(B.FileSeq, 0)
           FROM _TSLImpOrder AS A JOIN #TPUORDPO AS B ON (A.POSeq = B.POSeq)  
          WHERE B.WorkingTag = 'U' AND B.Status = 0    
            AND A.CompanySeq  = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN 
   
     END   
      -- INSERT    
     IF EXISTS (SELECT 1 FROM #TPUORDPO WHERE WorkingTag = 'A' AND Status = 0  )  
     BEGIN  
          -- 서비스 INSERT  
          INSERT INTO _TPUORDPO(CompanySeq    , POSeq        , PONo        , SMImpType    , PODate       ,   
                                DeptSeq       , EmpSeq       , CustSeq     , CurrSeq      , ExRate       ,  
                                Payment       , Remark       , POAmd       , IsCustAccept , IsDirectDelv ,  
                                UnitAssySeq  , IsConfirm   , ConfirmDate  , ConfirmEmpSeq,  
                                B2BTranCnt    , IsPJT        , POMngNo     , SMProgStatus , ERP          , 
                                PORev         , PORevEmpSeq  , PORevDate   ,
                                LastUserSeq   , LastDateTime )   
          SELECT @CompanySeq                 , B.POSeq                   , ISNULL(B.PONo, '')        , ISNULL(B.SMImpType, 0)  , ISNULL(B.PODate, '')    ,  
                    ISNULL(B.DeptSeq, 0)     , ISNULL(B.EmpSeq, 0)       , ISNULL(B.CustSeq, 0)      , ISNULL(B.CurrSeq, 0)    , ISNULL(B.ExRate, 0)    ,  
                    ''                       , ISNULL(B.Remark, '')      , 0                         , ''                      , '' ,  
                    ''                        , ''          , ''          , ''                      ,  
                    ''                       , B.IsPJT                       , ISNULL(B.PORefNo, '')     , ''                      , ''  , 
                    ISNULL(B.PORev, 0)       , ISNULL(B.PORevEmpSeq, 0)  , ISNULL(B.PORevDate, '')   ,
                    @UserSeq                 , GETDATE()   
            FROM #TPUORDPO AS B   
           WHERE B.WorkingTag = 'A' AND B.Status = 0   
                
          IF @@ERROR <> 0 RETURN    
     
          INSERT INTO _TSLImpOrder(CompanySeq, POSeq,    BizUnit, POAmd,          PORefNo, 
                                   BKCustSeq,    UMPriceTerms,     UMPayment1, UMPayment2,         Payment3, 
                                   UMShipVia, LoadingPort,        ETD,  DischargingPort, ETA,  
                                   Destination,  CountryofOrigin,    Validity, Remark,    Packing, 
                                   Memo,         IsPJT,              FundAccSeq, PrePaymentDate,     PaymentBankSeq,
                                   PaymentAmt,   LastUserSeq,     LastDateTime,FileSeq )   
                  SELECT @CompanySeq,                   B.POSeq,                     ISNULL(B.BizUnit, 0),      ISNULL(B.POAmd, 0),     ISNULL(B.PORefNo, ''), 
                         ISNULL(B.BKCustSeq, 0),        ISNULL(B.UMPriceTerms, 0),   ISNULL(B.UMPayment1, 0),     ISNULL(B.UMPayment2, 0),   ISNULL(B.Payment3, ''),
                         ISNULL(B.UMShipVia, 0),        ISNULL(B.LoadingPort, ''),   ISNULL(B.ETD, ''),          ISNULL(B.DischargingPort, 0),  ISNULL(B.ETA, ''),
                         ISNULL(B.Destination, ''),     ISNULL(B.CountryofOrigin, 0),ISNULL(B.Validity, ''),      ISNULL(B.Remark2, ''),      ISNULL(B.Packing, ''),
                         ISNULL(B.Memo, ''),            B.IsPJT,                     ISNULL(B.FundAccSeq, 0),     ISNULL(B.PrePaymentDate, ''),  ISNULL(B.PaymentBankSeq, 0),
                         ISNULL(B.PaymentAmt, 0),       @UserSeq,                    GETDATE(),                   ISNULL(B.FileSeq,0)
                    FROM #TPUORDPO AS B   
                   WHERE B.WorkingTag = 'A' AND B.Status = 0   
            
          IF @@ERROR <> 0 RETURN  
      END   
   
     SELECT * FROM #TPUORDPO  
   
 RETURN  
 /****************************************************************************************/