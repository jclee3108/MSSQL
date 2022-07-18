IF OBJECT_ID('hye_SPUDelvCheck') IS NOT NULL 
    DROP PROC hye_SPUDelvCheck 
GO 

-- v2016.09.29 

-- 구매납품입력_체크 by이재천 
/************************************************************  
설  명 - 구매납품체크(마스터)
작성일 - 2008년 8월 20일   
작성자 - 노영진  
************************************************************/  
  
CREATE PROC hye_SPUDelvCheck    
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
    DECLARE @Count       INT,        
            @DataSeq     INT,        
            @DelvSeq  INT,         
            @DelvNo   NVARCHAR(12),        
            @BaseDate    NVARCHAR(8),        
            @MaxNo       NVARCHAR(12),        
            @BizUnit     INT,        
            @MaxQutoRev  INT,  
            @MessageType INT,        
            @Status      INT,        
            @Results     NVARCHAR(250),
            @QCAutoIn    NCHAR(1)              
     
    
    -- 임시 테이블 생성  _TPUDelv      
    CREATE TABLE #TPUDelv (WorkingTag NCHAR(1) NULL)      
    -- 임시 테이블에 지정된 컬럼을 추가하고, xml로부터의 값을 insert한다.      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelv'         
   
    CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)    
    -- 임시 테이블에 지정된 컬럼을 추가하고, xml로부터의 값을 insert한다.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2608, 'DataBlock1', '#TPUDelvIn'       
    

    -- 확정체크 추가 by이재천 
    UPDATE A
       SET Result = '전자결재가 진행 된 구매납품 건은 수정/삭제 할 수 없습니다.(상품)', 
           Status = 1234,
           MessageType = 1234 
      FROM #TPUDelv                    AS A 
      LEFT OUTER JOIN _TPUDelv_Confirm  AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND B.IsAuto = '0' 
       AND B.CfmCode <> 0 
    -- 확정체크, END 
    
     -------------------------------------------    
     -- 필수데이터체크    
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                           @LanguageSeq       ,     
                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'            
     UPDATE #TPUDelv    
        SET Result        = @Results,    
            MessageType   = @MessageType,    
            Status        = @Status    
      WHERE DelvDate = ''    
         OR DelvDate IS NULL    
    -- 구매입고 진행 된 건은 삭제 제한
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag IN ('U', 'D') )
    BEGIN
        -------------------
        --입고진행여부-----
        -------------------
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
          
        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))    
        
    
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
    
        CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
    
        INSERT #TMP_PROGRESSTABLE     
        SELECT 1, '_TPUDelvInItem'               -- 구매입고

        -- 구매납품
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)    
        SELECT  A.DelvSeq, B.DelvSerl, '2'    
          FROM #TPUDelv     AS A WITH(NOLOCK)     
          JOIN _TPUDelvItem AS B WITH(NOLOCK) ON @CompanySeq = B.CompanySeq    
                                              AND A.DelvSeq  = B.DelvSeq  
         WHERE A.WorkingTag IN ('U', 'D')
           AND A.Status = 0

        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''    
       
        
        INSERT INTO #OrderTracking    
        SELECT IDX_NO,    
               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
          FROM #TCOMProgressTracking    
         GROUP BY IDX_No    
 
        UPDATE #Temp_Order 
           SET IsDelvIn = '1'
          FROM #Temp_Order AS A  
               JOIN #OrderTracking AS B ON A.IDX_No = B.IDX_No
        
        -- 환경설정값 가져오기  # 무검사품 자동입고 여부
        EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT  
    
        IF @QCAutoIn <> '1'    -- 무검사품 자동입고가 아닐 경우
        BEGIN
            -------------------
            --입고진행여부END------
            -------------------
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1044               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                                  @LanguageSeq       , 
                                  0,'납품예정일'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'
            UPDATE #TPUDelv
               SET Result        = @Results    ,
                   MessageType   = @MessageType,
                   Status        = @Status
              FROM #TPUDelv         AS A
                   JOIN #Temp_Order AS B ON A.DelvSeq = B.OrderSeq
                   JOIN _TPUDelv	AS C ON A.DelvSeq = C.DelvSeq
             WHERE B.IsDelvIn   IN ('1') 
               AND A.WorkingTag IN ('U')
               AND A.Status = 0
		       AND ( (A.DelvDate    <> C.DelvDate) OR (A.CustSeq   <> C.CustSeq) OR (A.SMImpType <> C.SMImpType) 
				  OR (A.CurrSeq   <> C.CurrSeq) OR (A.ExRate    <> C.ExRate) )
        END
        ELSE 
        BEGIN
            -- 전표처리건은 수정/삭제 되지 않도록 추가
            UPDATE #TPUDelvIn
               SET DelvInSeq  = (SELECT TOP 1 Seq FROM #TCOMProgressTracking),
                   DelvInDate = (SELECT TOP 1 DelvDate FROM #TPUDelv),
                   WorkingTag = (SELECT TOP 1 WorkingTag FROM #TPUDelvIn)

            EXEC _SPUDelvInCheck     @xmlDocument    = N''           ,
                                     @xmlFlags       = @xmlFlags     ,
                                     @ServiceSeq     = 2608   ,
                                     @WorkingTag     = 'AUTO'  ,
                                     @CompanySeq     = @CompanySeq   ,
                                     @LanguageSeq    = @LanguageSeq  ,
                                     @UserSeq        = @UserSeq      ,
                                     @PgmSeq         = @PgmSeq
            IF @@ERROR <> 0 RETURN    
            
            UPDATE #TPUDelv
               SET Status      = A.Status     ,
                   MessageType = A.MessageType,
                   Result      = A.Result
              FROM #TPUDelvIn AS A

            --## 자동입고 이지만 구매입고 후 검사가 처리 된 건은 수정/삭제가 되지 않도록 추가 ##
            EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                  @Status      OUTPUT,    
                                  @Results     OUTPUT,    
                                  18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                  @LanguageSeq       ,     
                                  0, '구매입고후검사로 진행된 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'            
             UPDATE #TPUDelv    
                SET Result        = @Results,    
                    MessageType   = @MessageType,    
                    Status        = @Status  
              FROM  #TPUDelv                 AS A 
                    JOIN #Temp_Order           AS B ON A.DelvSeq   = B.OrderSeq
                    JOIN #TCOMProgressTracking AS C ON B.IDX_No = C.IDX_No
                    JOIN _TPDQCTestReport      AS D ON C.Seq  = D.SourceSeq
              WHERE A.WorkingTag IN ('U', 'D')
                AND A.Status     = 0
                AND D.CompanySeq = @CompanySeq
                AND D.SourceType = '7'
        END

    END  
     -- 인수검사가 완료된 건은 삭제/수정 제한
     IF EXISTS (SELECT 1 FROM _TPDQCTestReport AS A
                              JOIN #TPUDelv    AS B ON A.SourceSeq = B.DelvSeq 
                        WHERE A.CompanySeq = @CompanySeq AND A.SourceType = '1' AND B.WorkingTag IN ('D') AND B.Status = 0)
     BEGIN
             EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                   @Status      OUTPUT,    
                                   @Results     OUTPUT,    
                                   18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                   @LanguageSeq       ,     
                                   0, '구매인수검사로 진행된 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'            
              UPDATE #TPUDelv    
                 SET Result        = @Results,    
                     MessageType   = @MessageType,    
                     Status        = @Status  
               FROM  #TPUDelv      
     END    
    
  
    --순번update---------------------------------------------------------------------------------------------------------------        
    SELECT   @DataSeq = 0        
      
    WHILE ( 1 = 1 )         
    BEGIN        
        SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = DelvDate        
        FROM #TPUDelv        
         WHERE WorkingTag = 'A'        
           AND Status = 0        
           AND DataSeq > @DataSeq        
         ORDER BY DataSeq        
            
        IF @@ROWCOUNT = 0 BREAK     

        -- DelvNo 생성        
        EXEC _SCOMCreateNo 'PU', '_TPUDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT        
        
    
        SELECT @count = COUNT(*)          
          FROM #TPUDelv          
         WHERE WorkingTag = 'A' AND Status = 0            
            
        IF @count > 0        
        BEGIN     
            EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TPUDelv', 'DelvSeq', 1    
        END        
        
        UPDATE #TPUDelv        
           SET DelvSeq = @DelvSeq + 1,--DataSeq, :: 루프로 한건씩 처리되므로 일괄처리시 사용하면 1씩 증가되어야 하므로 20120828 by 천경민
               DelvNo  = @DelvNo        
         WHERE WorkingTag = 'A'        
           AND Status = 0        
           AND DataSeq = @DataSeq        
    END        
    
    UPDATE #TPUDelv
       SET SMImpType = 8008001
     WHERE ISNULL(SMIMPType,0) = 0
     
    SELECT * FROM #TPUDelv        
          
      
RETURN      
/***********************************************************************************************************************/