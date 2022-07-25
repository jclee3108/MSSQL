
IF OBJECT_ID('amoerp_SLGInOutDailyItemMergeCheck') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemMergeCheck
GO 

-- v2013.11.22 

-- 위탁출고입력_amoerp by이재천
CREATE PROC amoerp_SLGInOutDailyItemMergeCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250), 
            @LotNoQty   DECIMAL(19,5), 
            @Qty        DECIMAL(19,5)
  
    CREATE TABLE #amoerp_TLGInOutDailyItemMergeSub (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#amoerp_TLGInOutDailyItemMergeSub'
    
    ALTER TABLE #amoerp_TLGInOutDailyItemMergeSub ADD InOutSubSerl   INT
    
    UPDATE A 
       SET A.InOutSubSerl = B.InOutSubSerl 
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A
      JOIN amoerp_TLGInOutDailyItemMergeSub  AS B ON ( B.CompanySeq = @CompanySeq 
                                                   AND B.InOutSeq = A.InOutSeq 
                                                   AND B.InOutSerl = A.InOutSerl 
                                                     ) 
    

    CREATE TABLE #TMP_ProgressTable 
                 (IDOrder   INT, 
                  TableName NVARCHAR(100)) 

    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
         SELECT 1, '_TSLInvoiceItem'   -- 데이터 찾을 테이블
         
    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TLGInOutDailyItem',    -- 기준이 되는 테이블
            @TempTableName = '#amoerp_TLGInOutDailyItemMergeSub',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'InOutSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'InOutSubSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
    SELECT A.InOutSeq, A.InOutSerl, C.InvoiceSeq, C.InvoiceSerl, C.Qty AS InvoiceQty
      INTO #TSLInvoiceItem  
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
      JOIN #TCOMProgressTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN _TSLInvoiceItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.InvoiceSeq = B.Seq AND C.InvoiceSerl = B.Serl )  
    
    -- 체크1, 진행된 데이터는 수정, 삭제를 할 수 없습니다. 
    
    UPDATE A 
       SET Status = 5513, 
           Result = N'진행된 데이터는 수정, 삭제를 할 수 없습니다.', 
           MessageType = 1234 
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A
     WHERE EXISTS ( SELECT 1 FROM #TSLInvoiceItem )
       --AND A.WorkingTag IN ('U', 'D')
       AND A.Status = 0  
    
    -- 체크1, END
    
    -- 체크2, 등록된 Lot품목수량과 Lot분할 수량이 같지 않습니다.
    
    SELECT @LotNoQty = SUM(A.LotNoQty) FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
                                       JOIN amoerp_TLGInOutDailyItemMerge     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
                                      GROUP BY A.InOutSeq
                                      HAVING SUM(A.LotNoQty) <> MAX(B.Qty)
    SELECT @Qty = MAX(B.Qty) FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
                             JOIN amoerp_TLGInOutDailyItemMerge     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
                            GROUP BY A.InOutSeq
                           HAVING SUM(A.LotNoQty) <> MAX(B.Qty)
    
    UPDATE A 
       SET Status = 5513, 
           Result = N'등록된 Lot품목수량과 Lot분할 수량이 같지 않습니다.', 
           MessageType = 1234 
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
     WHERE @LotNoQty <> @Qty
       AND A.Status = 0
       
    -- 체크2, END

    -- 체크3, Lot No별 수량은 필수입력 항목 입니다.
    
    UPDATE A 
       SET A.Result = N'Lot No별 수량은 필수입력 항목 입니다.',
           A.Status = 1234,
           A.MessageType = 1234 
           
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
     WHERE A.Status = 0 
       AND ISNULL(A.LotNo,'') <> '' 
       AND ISNULL(A.LotNoQty,0) = 0 
    
    -- 체크3, END

    -- 체크4, Lot No는 필수입력 항목 입니다.
    
    UPDATE A 
       SET A.Result = N'Lot No는 필수입력 항목 입니다.',
           A.Status = 1234,
           A.MessageType = 1234 
           
      FROM #amoerp_TLGInOutDailyItemMergeSub AS A 
     WHERE A.Status = 0 
       AND ISNULL(A.LotNo,'') = '' 
       AND ISNULL(A.LotNoQty,0) <> 0 
    
    -- 체크4, END
       
    SELECT * FROM #amoerp_TLGInOutDailyItemMergeSub 
    
    RETURN    
GO
begin tran
exec amoerp_SLGInOutDailyItemMergeCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <LotNo />
    <LotNoQty>0</LotNoQty>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <InOutSeq>1001256</InOutSeq>
    <InOutSerl>1</InOutSerl>
    <ItemSeq>27375</ItemSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <LotNo>lot_test_2</LotNo>
    <LotNoQty>3</LotNoQty>
    <InOutSeq>1001256</InOutSeq>
    <InOutSerl>1</InOutSerl>
    <ItemSeq>27375</ItemSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <LotNo>lot_test_3</LotNo>
    <LotNoQty>5</LotNoQty>
    <InOutSeq>1001256</InOutSeq>
    <InOutSerl>1</InOutSerl>
    <ItemSeq>27375</ItemSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426
rollback tran 