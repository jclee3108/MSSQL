IF OBJECT_ID('KPXLS_SSLImpDelvDelete') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvDelete
GO 

-- v2016.02.26 

-- LotNo Master 삭제 추가 by이재천 

/*********************************************************************************************************************  
    화면명 : 전체삭제
    SP Name: _SSLImpDelvDelete  
    작성일 :     
    수정일 :   
********************************************************************************************************************/  
  
CREATE PROCEDURE KPXLS_SSLImpDelvDelete
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE @docHandle  INT  
  
  
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #TUIImpDelv (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpDelv'    
  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TUIImpDelv', -- 원테이블명
                   '#TUIImpDelv', -- 템프테이블명  
                   'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq,DelvSeq,BizUnit,DelvDate,CustSeq,DelvNo,PermitSeq,BLSeq,InvoiceSeq,PaymentSeq,POSeq,EmpSeq,DeptSeq,
                    CurrSeq,ExRate,Remark,LastUserSeq,LastDateTime,SMImpKind'

                    
    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvItem', -- 원테이블명
                         '#TUIImpDelv', -- 템프테이블명  
                         'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                         'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,DomAmt,WHSeq,LotNo,FromSerl,ToSerl,ProdDate,STDUnitSeq,
                          STDQty,LastUserSeq,LastDateTime,OKCurAmt,OKDomAmt,AccSeq,VATAccSeq,OppAccSeq,SlipSeq,IsCostCalc,PJTSeq,WBSSeq,MakerSeq,Remark'
                    
    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvCostDiv', -- 원테이블명
                         '#TUIImpDelv', -- 템프테이블명  
                         'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                         'CompanySeq,DelvCostSeq,DelvCostDate,DelvSeq,AccDeptSeq,AccEmpSeq,Remark,SlipSeq,LastUserSeq,LastDateTime'


    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvCostDivItem', -- 원테이블명
                         '#TUIImpDelv', -- 템프테이블명  
                         'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                         'CompanySeq,DelvCostSeq,DelvSeq,DelvSerl,ExpenseSeq,ExpenseSerl,CurrSeq,ExRate,CurAmt,DomAmt,Remark,LastUserSeq,LastDateTime'

    

    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        -- LotNo Master 삭제 
        DELETE Z 
          FROM _TLGLotMaster AS Z 
          JOIN ( 
                SELECT B.ItemSeq, B.LotNo 
                  FROM #TUIImpDelv AS A 
                  JOIN _TUIImpDelvItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
                 WHERE A.WorkingTag = 'D' 
                   AND A.Status = 0 
               ) AS Y ON ( Y.LotNo = Z.LotNo AND Y.ItemSeq = Z.ItemSeq ) 
         WHERE Z.CompanySeq = @CompanySeq 
        
        -- Delv마스터
        DELETE _TUIImpDelv    
          FROM _TUIImpDelv AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
  
        IF @@ERROR <> 0 RETURN  
  
        -- Delv디테일
        DELETE _TUIImpDelvItem   
          FROM _TUIImpDelvItem AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  


        DELETE _TUIImpDelvCostDiv   
          FROM _TUIImpDelvCostDiv AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  


        DELETE _TUIImpDelvCostDivItem   
          FROM _TUIImpDelvCostDivItem AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  
        
    END    
        
    SELECT * FROM #TUIImpDelv
    
    RETURN
GO


