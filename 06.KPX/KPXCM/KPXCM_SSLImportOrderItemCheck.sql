IF OBJECT_ID('KPXCM_SSLImportOrderItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderItemCheck
GO 

-- v2015.09.25 

-- MES 연동된 데이터 삭제체크 추가 by이재천 
/*************************************************************************************************    
     화면명 : 수입Order품목저장체크    
     SP Name: _SSLImportOrderItemCheck    
     작성일 : 2009.01.05 : CREATEd by 천혜연        
     수정일 : 
 *************************************************************************************************/    
 CREATE PROC KPXCM_SSLImportOrderItemCheck  
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
             @Results     NVARCHAR(250),
             @PODate      NCHAR(8)     ,  
             @PONo        NCHAR(12)    ,  
             @POSeq       INT, 
             @TableSeq    INT,
             @GoodQtyDecLength INT
      EXEC @GoodQtyDecLength    = dbo._SCOMEnvR @CompanySeq, 5, @UserSeq, @@PROCID -- 구매/자재 소수점자리수
   
     -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOItem'   
      
     IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------
    -- 체크, MES 연동처리 되었으므로 삭제 할 수 없습니다. 
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
    -- 체크, MES 연동처리 되었으므로 삭제 할 수 없습니다. END 
    ------------------------------------------------------------------------    
    
     -------------------------------------------  
     -- 중복여부체크  
     -------------------------------------------  
 --     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
 --                           @Status      OUTPUT,  
 --                           @Results     OUTPUT,  
 --                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
 --                           @LanguageSeq       ,   
 --                           0,'납품예정일'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
 --     UPDATE #TPUORDPODelvDate  
 --        SET Result        = REPLACE(@Results,'@2', A.PODelvDate),  
 --            MessageType   = @MessageType,  
 --            Status        = @Status  
 --       FROM #TPUORDPODelvDate AS A JOIN ( SELECT S.PODelvDate  
 --                                   FROM (  
 --                                          SELECT A1.PODelvDate  
 --                                            FROM #TPUORDPODelvDate AS A1  
 --                                           WHERE A1.WorkingTag IN ('A','U')  
 --                                             AND A1.Status = 0  
 --                                           UNION ALL  
 --                                          SELECT A1.PODelvDate  
 --                                            FROM _TPUORDPODelvDate AS A1  
 --                                           WHERE A1.POSeq IN (SELECT POSeq   
 --                                                                       FROM #TPUORDPODelvDate   
 --                                                                      WHERE WorkingTag NOT IN ('U','D')   
 --                                                                        AND Status = 0)  
 --                                             AND A1.POSerl IN (SELECT POSerl   
 --                                                                       FROM #TPUORDPODelvDate   
 --                                                                      WHERE WorkingTag NOT IN ('U','D')   
 --                                                                        AND Status = 0)  
 --                                         ) AS S  
 --                                    GROUP BY S.PODelvDate  
 --                                    HAVING COUNT(1) > 1  
 --                                  ) AS B ON (A.PODelvDate = B.PODelvDate)  
   
     -------------------------------------------  
     -- 진행여부체크  
     -------------------------------------------  
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag IN ('U', 'D') )  
     BEGIN  
         -- 진행체크할 테이블값 테이블
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))      
         
         -- 진행체크할 데이터 테이블
         CREATE TABLE #Temp_ORDPO(IDX_NO INT IDENTITY, POSeq INT, POSerl INT, IsNext NCHAR(1)) 
         
         -- 진행된 내역 테이블
         CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,
                                            Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))
       
         SELECT @TableSeq = ProgTableSeq
           FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블
          WHERE ProgTableName = '_TPUORDPOItem'
          INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)
         SELECT B.ProgTableName
           FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --진행테이블관계
                 JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq
  
         
         INSERT INTO #Temp_ORDPO(POSeq, POSerl, IsNext) -- IsNext=1(진행), 0(미진행)
         SELECT  A.POSeq, B.POSerl, '0'
           FROM #TPUORDPOItem  AS A WITH(NOLOCK)       
                 JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                     AND A.POSeq        = B.POSeq
                                                     AND A.POSerl       = B.POSerl
          WHERE A.WorkingTag IN ('U', 'D')  
            AND A.Status = 0  
   
         EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_ORDPO', 'POSeq', 'POSerl', ''    
   
   
         UPDATE #Temp_ORDPO   
           SET IsNext = '1'  
          FROM  #Temp_ORDPO AS A  
                 JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  
   
         --ERR Message
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1045)  
                               @LanguageSeq       ,   
                               0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
         UPDATE #TPUORDPOItem  
            SET Result        = @Results    ,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TPUORDPOItem   AS A  
                JOIN #Temp_ORDPO AS B ON A.POSeq  = B.POSeq  
                                     AND A.POSerl = B.POSerl
          WHERE B.IsNext = '1' 
     END  
      --기준단위수량 계산 2010.02.05 by 허승남
     UPDATE #TPUORDPOItem  
        SET STDUnitQty = ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END),@GoodQtyDecLength)  
       FROM #TPUORDPOItem AS A  
            JOIN _TDAItemUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                               AND A.ItemSeq    = B.ItemSeq  
                                               AND A.UnitSeq    = B.UnitSeq  
            JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                AND A.ItemSeq    = C.ItemSeq  
      WHERE A.Status = 0  
        AND ISNULL(A.Qty,0) <> 0  
        AND ISNULL(C.IsQtyChange,'') <> '1'  
   
  
     -- MAX Serl  
     SELECT @Count = COUNT(*) FROM #TPUORDPOItem WHERE WorkingTag = 'A' AND Status = 0   
     IF @Count > 0  
     BEGIN     
         SELECT @Serl = ISNULL(MAX(A.POSerl), 0) FROM _TPUORDPOItem AS A JOIN #TPUORDPOItem AS B ON A.POSeq = B.POSeq  
                                                WHERE A.CompanySeq = @CompanySeq  
         UPDATE #TPUORDPOItem SET POSerl = @Serl + DataSeq   
          WHERE WorkingTag = 'A' AND Status = 0  
     END    
   
     SELECT * FROM #TPUORDPOItem  
 RETURN      
 /*******************************************************************************************************************/