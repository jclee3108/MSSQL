IF OBJECT_ID('KPXCM_SPUORDPOItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOItemCheck
GO 

-- v2015.09.24 

/*************************************************************************************************  
  FORM NAME           -       FrmPPUORDPO 
  DESCRIPTION         -     구매발주 디테일 체크
  CREAE DATE          -       2008.10.09      CREATE BY: 김현
  LAST UPDATE  DATE   -       2008.10.09         UPDATE BY: 김현
 *************************************************************************************************/  
 CREATE PROC dbo.KPXCM_SPUORDPOItemCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
      DECLARE @Count       INT,
             @Serl        INT,
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250)
      -- 서비스 마스타 등록 생성
     CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOItem' 
    
     IF @@ERROR <> 0 RETURN   
       --------------------------------------------------------------------------------------
      -- 데이터유무체크: UPDATE, DELETE 시데이터존해하지않으면에러처리
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TPUORDPOItem AS A 
                             JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TPUORDPOItem
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
             AND Status = 0
       END
    
    ------------------------------------------------------------------------
    -- MES 연동처리 되었으므로 삭제 할 수 없습니다. 
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'MES 연동처리 되었으므로 삭제 할 수 없습니다. ', 
           MessageType = 1234, 
           Status = 1234 
      FROM #TPUORDPOItem        AS A 
     WHERE EXISTS (SELECT 1 FROM IF_PUDelv_MES WHERE CompanySeq = @CompanySeq AND POSeq = A.POSeq AND POSerl = A.POSerl AND ConfirmFlag = 'Y')
       AND A.WorkingTag = 'D' 
       AND A.Status = 0 
    ------------------------------------------------------------------------
    -- MES 연동처리 되었으므로 삭제 할 수 없습니다. 
    ------------------------------------------------------------------------    
    
    
    
    
      --------------------------------------------------------------------------------------
      -- 납기일 체크 : 납기일이 발주일보다 이전 일경우 체크      -- 12.11.20 BY 김세호
      --------------------------------------------------------------------------------------
      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1150                  , -- @1는 @2보다 커야 합니다.  
                           @LanguageSeq       ,           
                           138,'',   -- 납기일  
                           166,''    -- 발주일  
      
       UPDATE #TPUORDPOItem
         SET Result        = @Results,
             MessageType   = @MessageType,
             Status        = @Status
       WHERE WorkingTag IN ('A','U')
         AND Status = 0
         AND DelvDate < PODate
  
     -- 구매납품 진행 된 건은 삭제 제한
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag IN ('U', 'D'))
     BEGIN
         -------------------
         --납품진행여부-----
         -------------------
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
           
         CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelv NCHAR(1))    
         
     
         CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
     
         CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
     
         INSERT #TMP_PROGRESSTABLE     
         SELECT 1, '_TPUDelvItem'               -- 구매납품
          -- 구매발주
         INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelv)    
         SELECT  A.POSeq, A.POSerl, '2'    
           FROM #TPUORDPOItem AS A
          WHERE A.WorkingTag IN ('U', 'D')
            AND A.Status = 0
          EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''    
        
         
         INSERT INTO #OrderTracking    
         SELECT IDX_NO,    
                SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
                SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
           FROM #TCOMProgressTracking    
          GROUP BY IDX_No    
          UPDATE #Temp_Order 
           SET IsDelv = '1'
          FROM  #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No
                                                                 AND B.Amt <> 0
                                                                 AND B.Qty <> 0
          -------------------
         --납품진행여부END------
         -------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1044               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'납품예정일'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'
         UPDATE #TPUORDPOItem
            SET Result        = @Results    ,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #TPUORDPOItem    AS A
                JOIN #Temp_Order AS B ON A.POSeq  = B.OrderSeq
          AND A.POSerl = B.OrderSerl
          WHERE B.IsDelv = '1'
            AND A.WorkingTag IN ('U', 'D')
     END    
  
      -- MAX Serl
     SELECT @Count = COUNT(*) FROM #TPUORDPOItem WHERE WorkingTag = 'A' AND Status = 0 
     IF @Count > 0
     BEGIN   
         SELECT @Serl = ISNULL(MAX(A.POSerl), 0) FROM _TPUORDPOItem AS A JOIN #TPUORDPOItem AS B ON A.POSeq = B.POSeq
                                                WHERE A.CompanySeq = @CompanySeq
         UPDATE #TPUORDPOItem SET POSerl = @Serl + DataSeq 
          WHERE WorkingTag = 'A' AND Status = 0
     END  
  
     -------------------------------------------  
     -- 내부코드0값일시에러발생
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TPUORDPOItem                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TPUORDPOItem
      WHERE Status = 0
        AND (POSeq = 0 OR POSeq IS NULL)
  
     SELECT * FROM #TPUORDPOItem
 RETURN    
 /*******************************************************************************************************************/