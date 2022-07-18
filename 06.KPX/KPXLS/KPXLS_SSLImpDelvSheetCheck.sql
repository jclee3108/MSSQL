IF OBJECT_ID('KPXLS_SSLImpDelvSheetCheck') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvSheetCheck
GO 

-- v2015.12.18 

-- KPXLS용 수입입고품목체크 By이재천 
/*********************************************************************************************************************
    화면명 : 수입입고_품목체크
    SP Name: _SUIImpDelvItemCheck
    작성일 : 2008.10.15 : 
    수정일 : 
********************************************************************************************************************/
CREATE PROCEDURE KPXLS_SSLImpDelvSheetCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
     DECLARE @Count              INT,
            @DelvSeq            INT, 
            @MaxDelvSerl        INT,
            @MessageType        INT,
            @Status             INT,
            @Results            NVARCHAR(250),
            @MinorSeq           INT, 
            @BizUnit            INT
        
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #TUIImpDelvItem (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TUIImpDelvItem' 
    
    ------------------------------------------------------------------------------------------------------------
    -- 체크0, 검사의뢰가 생성되어있어 수정/삭제를 할 수 없습니다. 
    ------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '검사의뢰가 생성되어있어 수정/삭제를 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TUIImpDelvItem AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM KPXLS_TQCRequest WHERE CompanySeq = @CompanySeq AND SMSourceType = 1000522007 AND SourceSeq = A.DelvSeq) 
    ------------------------------------------------------------------------------------------------------------
    -- 체크0, END 
    ------------------------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------------
    -- 체크1, Lot관리 품목은 MakerLotNo가 필수입니다. 
    ------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'Lot관리 품목은 MakerLotNo, 유효일자, 제조일자가 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TUIImpDelvItem          AS A 
      LEFT OUTER JOIN _TDAItemStock AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND B.IsLotMng = '1' 
       AND (ISNULL(A.Memo1,'') = '' OR ISNULL(A.Memo2,'') = '' OR ISNULL(A.ProdDate,'') = '')
    ------------------------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------------------------
    
    SELECT @DelvSeq = DelvSeq, 
           @BizUnit = BizUnit   -- 창고 체크를 위해 필요
      FROM #TUIImpDelvItem                                
      -------------------------------------------
     -- 필수데이터체크
     -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)
                               @LanguageSeq       , 
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'        
 
         UPDATE #TUIImpDelvItem
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
          WHERE DelvSeq IS NULL
    --------------------------------------------------------------------------------------
    -- 데이터유무체크: UPDATE, DELETE 시데이터존해하지않으면에러처리
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 
                      FROM #TUIImpDelvItem AS A 
                            JOIN _TUIImpDelvItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq
                     WHERE A.WorkingTag IN ('U', 'D'))
     BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                               @LanguageSeq       , 
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
          UPDATE #TUIImpDelvItem
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
          WHERE WorkingTag IN ('U','D')
    END
      -------------------------------------------  
     -- 비용데이터체크  
     -------------------------------------------  
         SELECT @MinorSeq = ISNULL(MinorSeq, 0)
          FROM _TDAUMinorValue WITH (NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND MajorSeq   = 8212
           AND Serl       = 1003
           AND ValueText  = '1'
          EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               102                , -- @1 데이터가 존재합니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                               @LanguageSeq       ,   
                               0,'비용처리'   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'          
   
         UPDATE #TUIImpDelvItem   
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TUIImpDelvItem AS A
                JOIN _TSLExpExpense AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND B.SMSourceType = 8215006
                                                      AND A.DelvSeq   = B.SourceSeq
                JOIN _TSLExpExpenseDesc AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
                                                          AND B.ExpenseSeq = C.ExpenseSeq
          WHERE ((A.WorkingTag = 'D')
             OR (A.WorkingTag = 'U' AND C.UMExpenseItem = @MinorSeq))
            AND  A.Status = 0
     -------------------------------------------
    -- 중복여부체크 
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,'수입Delv'      
    UPDATE #TUIImpDelvItem    
       SET Result        = REPLACE(@Results,'@2',RTRIM(B.DelvSeq)),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #TUIImpDelvItem AS A JOIN ( SELECT S.DelvSeq, S.DelvSerl  
                                            FROM (SELECT A1.DelvSeq, A1.DelvSerl  
                                                    FROM #TUIImpDelvItem AS A1    
                                                   WHERE A1.WorkingTag IN ('U')    
                                                     AND A1.Status = 0    
                                                   UNION ALL    
                                                  SELECT A1.DelvSeq, A1.DelvSerl  
                                                    FROM _TUIImpDelvItem AS A1    
                                                   WHERE A1.DelvSeq  NOT IN (SELECT DelvSeq    
                                                                                  FROM #TUIImpDelvItem     
                                                                                 WHERE WorkingTag IN ('U','D')     
                                                                                   AND Status = 0)    
                                                    AND A1.DelvSerl  NOT IN (SELECT DelvSerl    
                                                                                  FROM #TUIImpDelvItem     
                                                                                 WHERE WorkingTag IN ('U','D')     
                                                                                   AND Status = 0)    
                                                    AND A1.CompanySeq = @CompanySeq    
                                          ) AS S    
                                    GROUP BY S.DelvSeq, S.DelvSerl  
                                    HAVING COUNT(1) > 1    
                                  ) AS B ON A.DelvSeq  = B.DelvSeq    
                                        AND A.DelvSerl = B.DelvSerl  
 
     -------------------------------------------    
     -- 수정여부체크                                
     -------------------------------------------   
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           5                , -- 이미 @1가(이) 완료된 @2입니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                           @LanguageSeq       ,   
                           0,'원가계산'   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'          
      UPDATE #TUIImpDelvItem  
        SET Result        = REPLACE(@Results,'@2','입고'),  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TUIImpDelvItem AS A
            JOIN _TUIImpDelvCostDiv AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND A.DelvSeq    = B.DelvSeq
      WHERE A.WorkingTag IN ('A','U')
        AND A.Status = 0
     --------------------------------------------------------------------------------------
    -- 창고체크 - 사업부문의 창고가 아니면 에러 메시지 발생                               
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          11                , -- 해당 @1의  @2 가 아닙니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 11)  
                          @LanguageSeq       ,   
                          2,'', 
                          584, ''   -- SELECT * FROM _TCADictionary WHERE Word like '%창고%'          
                           
    UPDATE #TUIImpDelvItem  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status                             
      FROM #TUIImpDelvItem AS A
            LEFT OUTER JOIN _TDAWH AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                    AND B.BizUnit    = @BizUnit
                                                    AND A.WHSeq      = B.WHSeq
      WHERE B.WHSeq IS NULL
        AND (A.WorkingTag = 'A' OR A.WorkingTag = 'U')   
     
    -- 순번update---------------------------------------------------------------------------------------------------------------
     SELECT @Count = COUNT(1) FROM #TUIImpDelvItem WHERE WorkingTag = 'A' AND Status = 0    
       
    IF @Count > 0    
    BEGIN    
        SELECT @MaxDelvSerl = ISNULL(MAX(DelvSerl), 0)
          FROM _TUIImpDelvItem 
         WHERE DelvSeq = @DelvSeq
         UPDATE #TUIImpDelvItem
           SET DelvSerl = @MaxDelvSerl + IDX_NO
          FROM #TUIImpDelvItem
         WHERE WorkingTag = 'A' 
           AND Status = 0
               
        IF @WorkingTag = 'D'
            UPDATE #TUIImpDelvItem
               SET WorkingTag = 'D'
    END
     -------------------------------------------  
    -- 내부코드0값일시에러발생
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                          @LanguageSeq       
     UPDATE #TUIImpDelvItem                               
       SET Result        = @Results     ,    
           MessageType   = @MessageType ,    
           Status        = @Status    
      FROM #TUIImpDelvItem
     WHERE Status = 0
       AND (DelvSeq = 0 OR DelvSeq IS NULL)
 
    --------------------------------------
    -- LotNo 자동생성 :: 20150102 박성호
    --------------------------------------
     IF NOT EXISTS ( SELECT 1 FROM #TUIImpDelvItem WHERE Status <> 0 )
    BEGIN
    
        SELECT A.WorkingTag  AS WorkingTag             
             , A.IDX_NO      AS IDX_NO                 
             , A.DataSeq     AS DataSeq                
             , A.MessageType AS MessageType            
             , A.Status      AS Status                 
             , A.Result      AS Result                 
             , A.BizUnit     AS FirstInitialUnitValue  
             , A.DelvDate    AS date                  
             , A.DelvSeq     AS KeySeq
             , A.DelvSerl    AS KeySerl
             , A.ItemSeq     AS ItemSeq
             , A.LotNo       AS LotNo
          INTO #TUIImpDelvItemCreateLotNo 
          FROM #TUIImpDelvItem    AS A
               JOIN _TDAItemStock AS B WITH(NOLOCK) ON B.ItemSeq    = A.ItemSeq
                                                   AND B.CompanySeq = @CompanySeq
         WHERE A.WorkingTag = 'A'
           AND B.IsLotMng   = '1'
          -- XmlData 생성
        DECLARE @XmlData NVARCHAR(MAX)
        
        SELECT @XmlData = CONVERT( NVARCHAR(MAX), ( SELECT DataSeq AS IDX_NO, *
                                                      FROM #TUIImpDelvItemCreateLotNo 
                                                     WHERE Status = 0
                                                       FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS ))
                                              
        CREATE TABLE #TLGMakingLotNo(WorkingTag NCHAR(1) NULL)
        EXEC dbo._SCAOpenXmlToTemp @XmlData, 2, @CompanySeq, 4219, 'DataBlock1', '#TLGMakingLotNo'
          
        TRUNCATE TABLE #TLGMakingLotNo
         -- LotNo 자동생성
        INSERT INTO #TLGMakingLotNo
        EXEC _SLGLotSerialENVMakeLotNo @xmlDocument = @XmlData     ,  
                                       @xmlFlags    = 2            ,
                                       @ServiceSeq  = 4219         ,
                                       @WorkingTag  = N''          ,
                                       @CompanySeq  = @CompanySeq  ,
                                       @LanguageSeq = @LanguageSeq ,
                                       @UserSeq     = @UserSeq     ,
                                       @PgmSeq      = @PgmSeq
         -- 생성 LotNo UPDATE
        UPDATE A
           SET A.LotNo = B.LotNo
          FROM #TUIImpDelvItem      AS A
               JOIN #TLGMakingLotNo AS B ON B.KeySeq  = A.DelvSeq
                                        AND B.KeySerl = A.DelvSerl
    END
    
    SELECT * FROM #TUIImpDelvItem
    RETURN
go
begin tran
exec KPXLS_SSLImpDelvSheetCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTSeq>0</PJTSeq>
    <WBSSeq>0</WBSSeq>
    <ItemName>Lot테스트_이재천</ItemName>
    <ItemNo>Lot테스트_이재천</ItemNo>
    <Spec />
    <MakerName />
    <MakerSeq />
    <UnitName>Kg</UnitName>
    <Qty>171</Qty>
    <Price>0</Price>
    <CurAmt>0</CurAmt>
    <DomAmt>0</DomAmt>
    <WHName>T일반창고1_이재천</WHName>
    <LotNo>550725-005</LotNo>
    <Memo1 />
    <Memo2 />
    <Memo3>0</Memo3>
    <FromSerlNo />
    <ToSerlNo />
    <ProdDate />
    <STDUnitName>Kg</STDUnitName>
    <STDQty>171</STDQty>
    <DelvSerl>5</DelvSerl>
    <ItemSeq>27375</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <STDUnitSeq>2</STDUnitSeq>
    <AccName />
    <OppAccName />
    <WHSeq>7534</WHSeq>
    <IsQtyChange>0</IsQtyChange>
    <Remark>MES연동실적건</Remark>
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <BizUnit>2</BizUnit>
    <DelvDate>20150828</DelvDate>
    <DelvSeq>1000182</DelvSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033909,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028083
rollback 