IF OBJECT_ID('hye_SPUDelvSave') IS NOT NULL 
    DROP PROC hye_SPUDelvSave
GO 

-- v2016.09.29 

-- 구매납품입력_저장 by이재천 
/************************************************************  
설  명 - 구매납품저장
작성일 - 2008년 8월 20일   
작성자 - 노영진  
UPDATE :: 구매납품마스터 '납품관리번호(DelvMngNo)' 항목 추가 :: 11.04.25 BY 김세호
UPDATE :: 삭제시 품목정보도 함께 삭제해되므로 구매납품품목테이블 관련 로그를 남기도록 수정 :: 12.07.25 BY 허승남
************************************************************/     
CREATE PROC hye_SPUDelvSave     
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10) = '',      
    @CompanySeq     INT = 0,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS      
      
    -- 변수 선언      
    DECLARE  @docHandle     INT,      
             @LotSeq        INT,      
             @count         INT,
             @QCAutoIn      NCHAR(1)      
            
  
    -- 임시 테이블 생성      
    CREATE TABLE #TPUDelv (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelv'      
  
    -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정) 
    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelv' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelv ADD PgmSeq INT NULL
    END 

    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelvLog ADD PgmSeq INT NULL
    END  
    
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
    EXEC _SCOMLog   @CompanySeq       ,      
                    @UserSeq          ,      
                    '_TPUDelv', -- 원테이블명      
                    '#TPUDelv'    , -- 템프테이블명      
                    'DelvSeq'    , -- 키가 여러개일 경우는 , 로 연결한다.       
                    'CompanySeq,DelvSeq,BizUnit,DelvNo,SMImpType,
                     DelvDate,DeptSeq,EmpSeq,CustSeq,CurrSeq,
                     ExRate,SMDelvType,Remark,IsPJT,SMStkType,
                     IsReturn,LastUserSeq,LastDateTime,PgmSeq'
                     ,'',@PgmSeq    
     
--    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT
  
--    IF @QCAutoIn = '1'
--    BEGIN
--        -------------------
--        --입고진행여부-----
--        -------------------
--        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
--          
--        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))            
--    
--        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
--    
--        CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
--    
--        INSERT #TMP_PROGRESSTABLE     
--        SELECT 1, '_TPUDelvInItem'               -- 구매입고
--
--        -- 구매납품
--        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)    
--        SELECT  A.DelvSeq, A.DelvSerl, '2'    
--          FROM #TPUDelv AS A WITH(NOLOCK)  
--               JOIN _TPUDelvItem AS B ON A.DelvSeq    = B.DelvSeq
--                                     AND B.CompanySeq = @CompanySeq   
--         WHERE A.WorkingTag IN ('U')
--           AND A.Status = 0
--           AND B.SMQCType NOT IN( '6035002', '6035003', '6035004', '6035005', '6035006' ) 
--
--        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', '', ''           
--        
--        INSERT INTO #OrderTracking    
--        SELECT IDX_NO,    
--               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
--               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
--          FROM #TCOMProgressTracking    
--         GROUP BY IDX_No    
--
--        UPDATE #Temp_Order 
--          SET IsDelvIn = '1'
--         FROM  #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No
--        -----------------------
--        --입고진행여부END------
--        -----------------------
--    END  
    -- DELETE                                                                                                      
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'D' AND Status = 0 )        
    BEGIN  

  -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMDeleteLog  @CompanySeq   ,
                   @UserSeq      ,
                   '_TPUDelvItem', -- 원테이블명    
                   '#TPUDelv', -- 템프테이블명    
                   'DelvSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,    
                    Price,Qty,CurAmt,CurVAT,DomPrice,    
                    DomAmt,DomVAT,IsVAT,StdUnitSeq,StdUnitQty,    
                    SMQcType,QcEmpSeq,QcDate,QcQty,QcCurAmt,    
                    WHSeq,LOTNo,FromSerial,ToSerial,SalesCustSeq,    
                    DelvCustSeq,PJTSeq,WBSSeq,UMDelayType,Remark,    
                    IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl, PgmSeq'    
                    ,'', @PgmSeq

      
        DELETE _TPUDelv        
          FROM _TPUDelv       AS A WITH(NOLOCK)      
                JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq  = @CompanySeq     
                                                  AND A.DelvSeq     = B.DelvSeq       
         WHERE B.WorkingTag = 'D'       
           AND B.Status = 0        
               
        IF @@ERROR <> 0 RETURN      
    
        DELETE _TPUDelvItem        
          FROM _TPUDelvItem   AS A WITH(NOLOCK)      
                JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq = @CompanySeq     
                                                   AND A.DelvSeq  = B.DelvSeq       
         WHERE B.WorkingTag = 'D'       
           AND B.Status = 0        
               
        IF @@ERROR <> 0 RETURN  
        
        DELETE _TPUDelv_Confirm        
          FROM _TPUDelv_Confirm   AS A WITH(NOLOCK)      
                JOIN #TPUDelv    AS B ON A.CompanySeq = @CompanySeq     
                                     AND A.CfmSeq  = B.DelvSeq       
         WHERE B.WorkingTag = 'D'       
           AND B.Status = 0        
               
        IF @@ERROR <> 0 RETURN      
       
    
    END        
        
    -- Update                                                                                                       
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'U' AND Status = 0 )        
    BEGIN         
  
  
        UPDATE _TPUDelv        
           SET  BizUnit      = B.BizUnit      ,
                DelvNo       = B.DelvNo       ,
                SMImpType    = B.SMImpType    ,
                DelvDate     = B.DelvDate     ,
                DeptSeq      = B.DeptSeq      ,
                EmpSeq       = B.EmpSeq       ,
                CustSeq      = B.CustSeq      ,
                CurrSeq      = B.CurrSeq      ,
                ExRate       = B.ExRate       ,
                SMDelvType   = B.SMDelvType   ,
                Remark       = B.Remark       ,
--                IsPJT        = B.IsPJT        ,
                SMStkType    = B.SMStkType    ,
                IsReturn     = B.IsReturn     ,
                LastUserSeq   =  @UserSeq       ,  
                LastDateTime  =  GETDATE()    ,  
                DelvMngNo     = B.DelvMngNo   ,          -- 11.04.25 김세호 추가
                PgmSeq        = @PgmSeq
         FROM _TPUDelv      AS A WITH(NOLOCK)       
              JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq  = @CompanySeq     
                    AND A.DelvSeq     = B.DelvSeq       
        
         WHERE B.WorkingTag = 'U'       
           AND B.Status = 0      
               
        IF @@ERROR <> 0 RETURN   
    END         
    
    -- INSERT                             
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'A' AND Status = 0 )        
    BEGIN        
        INSERT INTO _TPUDelv(CompanySeq    ,DelvSeq       ,BizUnit       ,DelvNo        ,SMImpType     ,
                             DelvDate      ,DeptSeq       ,EmpSeq        ,CustSeq       ,CurrSeq       ,
                             ExRate        ,SMDelvType    ,Remark        ,IsPJT         ,SMStkType     ,
                             IsReturn      ,LastUserSeq   ,LastDateTime  ,DelvMngNo     ,PgmSeq                   -- 11.04.25 김세호 추가
                                )    
        SELECT  @CompanySeq   ,DelvSeq       ,BizUnit       ,DelvNo        ,SMImpType     ,
                DelvDate      ,DeptSeq       ,EmpSeq        ,CustSeq       ,CurrSeq       ,
                ExRate        ,SMDelvType    ,Remark        ,IsPJT         ,SMStkType     ,
                IsReturn      ,@UserSeq    ,   GETDATE()    ,DelvMngNo     ,@PgmSeq                          -- 11.04.25 김세호 추가
              FROM #TPUDelv        
             WHERE WorkingTag = 'A' AND Status = 0        
                   
        IF @@ERROR <> 0 RETURN      
    END      
            
     
    
    Select * FROM #TPUDelv      
      
RETURN