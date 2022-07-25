
IF OBJECT_ID('amoerp_SLGInOutDailyItemMergeSave') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemMergeSave
GO 

-- v2013.11.26 

-- 困殴免绊涝仿_amoerp by捞犁玫
CREATE PROC amoerp_SLGInOutDailyItemMergeSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TLGInOutDailyItem'     
    IF @@ERROR <> 0 RETURN  
    
    UPDATE A 
       SET A.InOutType = 50, 
           A.ItemSeq = B.ItemSeq
      FROM #TLGInOutDailyItem AS A 
      JOIN amoerp_TLGInOutDailyItemMerge AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl )
       
    --select * from #TLGInOutDailyItem
    --return
    
    --SELECT A.WorkIngTag, A.IDX_NO, A.DataSeq, A.Selected, A.Status, ISNULL(A.LotNo,'') AS LotNo, 
    --       B.CompanySeq, B.InOutType, B.InOutSeq, A.InOutSerl*100000+(ROW_NUMBER() OVER (ORDER BY A.InOutSeq)) AS InOutSerl, B.ItemSeq, B.CCtrSeq, 
    --       B.DVPlaceSeq, B.InWHSeq, B.OutWHSeq, B.UnitSeq, ISNULL(A.LotNoQty,0) AS Qty, ISNULL(A.LotNoQty,0) AS STDQty, B.Amt, B.EtcOutAmt, 
    --       B.EtcOutVAT, B.InOutKind, B.InOutDetailKind, B.SerialNo, B.IsStockSales, B.OriUnitSeq, 
    --       B.OriItemSeq, B.OriQty, B.OriSTDQty, B.PgmSeq, NULL AS InOutDataSerl, NULL AS DataKind, A.InOutSerl AS InOutSerlSub
    --  INTO #TLGInOutDailyItem
    --  FROM #TLGInOutDailyItem AS A 
    --  JOIN amoerp_TLGInOutDailyItemMerge AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
      
     --Create Table #TLGInOutMinusCheck  
     --(    
     --    WHSeq           INT,  
     --    FunctionWHSeq   INT,  
     --    ItemSeq         INT
     --)  
    
    CREATE TABLE #TLGInOutMonth
    (  
        InOut           INT,
        InOutYM         NCHAR(6),
        WHSeq           INT,
        FunctionWHSeq   INT,
        ItemSeq         INT,
        UnitSeq         INT,
        Qty             DECIMAL(19, 5),
        StdQty          DECIMAL(19, 5),      
        ADD_DEL         INT      
    )
    
    CREATE TABLE #TLGInOutMonthLot
    (  
        InOut           INT,
        InOutYM         NCHAR(6),
        WHSeq           INT,
        FunctionWHSeq   INT,
        LotNo           NVARCHAR(30),
        ItemSeq         INT,
        UnitSeq         INT,
        Qty             DECIMAL(19, 5),
        StdQty          DECIMAL(19, 5),      
        ADD_DEL         INT      
    )
    
    -- [0] 
    INSERT #TLGInOutMonth              
    (        
        InOut, InOutYM, WHSeq, FunctionWHSeq,              
        ItemSeq, UnitSeq, Qty, StdQty,              
        ADD_DEL
    )
    SELECT 0 AS InOut, LEFT(C.InOutDate,6) AS InOutYM, A.InWHSeq, 0 AS FunctionWHSeq, 
           A.ItemSeq, 0 AS UnitSeq, 0 AS Qty, 0 AS StdQty,              
           1 AS ADD_DEL 
      FROM #TLGInOutDailyItem AS B 
      JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
      JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
      
    UNION ALL 
    
    SELECT 0, LEFT(C.InOutDate,6), A.OutWHSeq, 0,               
           A.ItemSeq, 0, 0, 0,              
           1              
      FROM #TLGInOutDailyItem AS B 
      JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
      JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
    
    INSERT INTO #TLGInOutMonthLot                
    ( 
        InOut, InOutYM, WHSeq, FunctionWHSeq, LotNo,              
        ItemSeq, UnitSeq, Qty, StdQty,                
        ADD_DEL
    ) 
    SELECT A.* 
      FROM (SELECT 0 AS InOut, LEFT(C.InOutDate,6) AS InOutYM, A.InWHSeq, 0 AS FunctionWHSeq, B.LotNo, 
                   A.ItemSeq, 0 AS UnitSeq, 0 AS Qty, 0 AS StdQty,              
                   1 AS ADD_DEL 
              FROM #TLGInOutDailyItem AS B 
              JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
              JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
              
            UNION ALL 
            
            SELECT 0, LEFT(C.InOutDate,6), A.OutWHSeq, 0, B.LotNo,                
                   A.ItemSeq, 0, 0, 0,              
                   1              
              FROM #TLGInOutDailyItem AS B 
              JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
              JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
           ) AS A 
    
    UNION 
    
    SELECT A.* 
      FROM (SELECT 0 AS InOut, LEFT(C.InOutDate,6) AS InOutYM, A.InWHSeq, 0 AS FunctionWHSeq, D.LotNo, 
                   A.ItemSeq, 0 AS UnitSeq, 0 AS Qty, 0 AS StdQty,              
                   1 AS ADD_DEL 
              FROM #TLGInOutDailyItem AS B 
              JOIN amoerp_TLGInOutDailyItemMergeSub  AS D ON ( D.CompanySeq = @CompanySeq AND D.InOutSeq = B.InOutSeq AND D.InOutSerl = B.InOutSerl ) 
              JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
              JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
              
            UNION ALL 
            
            SELECT 0, LEFT(C.InOutDate,6), A.OutWHSeq, 0, D.LotNo, 
                   A.ItemSeq, 0, 0, 0,              
                   1              
              FROM #TLGInOutDailyItem AS B 
              JOIN amoerp_TLGInOutDailyItemMergeSub  AS D ON ( D.CompanySeq = @CompanySeq AND D.InOutSeq = B.InOutSeq AND D.InOutSerl = B.InOutSerl ) 
              JOIN amoerp_TLGInOutDailyItemMerge     AS A ON ( A.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl ) 
              JOIN _TLGInOutDaily                    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = B.InOutSeq ) 
           ) AS A 
    
    -- [1]
    DELETE B
      FROM #TLGInOutDailyItem AS A 
      JOIN amoerp_TLGInOutDailyItemMergeSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
     WHERE A.Status = 0 
    
    INSERT INTO amoerp_TLGInOutDailyItemMergeSub 
    (
        CompanySeq, InOutSeq, InOutSerl, InOutSubSerl, LotNo, 
        Qty, LastUserSeq, LastDateTime, PgmSeq
    ) 
    SELECT @CompanySeq, A.InOutSeq, A.InOutSerl, A.InOutSerl*100000+(ROW_NUMBER() OVER (ORDER BY A.InOutSeq)), A.LotNo,            
           A.LotNoQty, @UserSeq ,GETDATE(), @PgmSeq 
           
      FROM #TLGInOutDailyItem AS A   
     WHERE ISNULL(A.LotNo,'') <> '' 
       AND ISNULL(A.LotNoQty,0) <> 0
       AND A.Status = 0 
    
    -- [2]
    DELETE A
      FROM _TLGInOutDailyItem AS A 
      JOIN _TDAItemStock AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 
    
    INSERT INTO _TLGInOutDailyItem 
    (
        CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq,
        InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq,
        UnitSeq, Qty, STDQty, Amt, EtcOutAmt,
        EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo,
        IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty,
        LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq,
        ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
    )
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, B.InOutSubSerl, A.ItemSeq,
           A.InOutRemark, A.CCtrSeq, A.DVPlaceSeq, A.InWHSeq, A.OutWHSeq,
           A.UnitSeq, B.Qty, B.Qty, A.Amt, A.EtcOutAmt,
           A.EtcOutVAT, A.InOutKind, A.InOutDetailKind, B.LotNo, A.SerialNo,
           A.IsStockSales, A.OriUnitSeq, A.OriItemSeq, A.OriQty, A.OriSTDQty,
           A.LastUserSeq, A.LastDateTime, A.PJTSeq, A.OriLotNo, A.ProgFromSeq,
           A.ProgFromSerl, A.ProgFromSubSerl, A.ProgFromTableSeq, A.PgmSeq
           
      FROM amoerp_TLGInOutDailyItemMerge    AS A 
      JOIN amoerp_TLGInOutDailyItemMergeSub AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 
    
    -- [3]   
    DELETE A
      FROM _TLGInOutLotSub AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 )
    
    INSERT INTO _TLGInOutLotSub 
    (
        CompanySeq,InOutType,InOutSeq,InOutSerl,DataKind,
        InOutDataSerl,InOutLotSerl,LotNo,ItemSeq,UnitSeq,
        Qty,STDQty,InWHSeq,OutWHSeq,LastUserSeq,
        LastDateTime,Amt,OriItemSeq,OriUnitSeq,OriLotNo,
        OriQty,OriSTDQty,PgmSeq
    )
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, B.InOutSubSerl, 0,
           0, 1, B.LotNo, A.ItemSeq, A.UnitSeq,
           B.Qty, B.Qty, A.InWHSeq, A.OutWHSeq, A.LastUserSeq,
           A.LastDateTime, A.Amt, A.OriItemSeq, A.OriUnitSeq, A.OriLotNo,
           A.OriQty, A.OriSTDQty, @PgmSeq
           
      FROM amoerp_TLGInOutDailyItemMerge    AS A 
      JOIN amoerp_TLGInOutDailyItemMergeSub AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = A.InOutSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 )
    
    -- [4]
    DELETE A
      FROM _TLGInOutStock AS A 
      JOIN _TDAItemStock AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 

    INSERT INTO _TLGInOutStock  
    (
        CompanySeq,InOutType,InOutSeq,InOutSerl,DataKind,
        InOutDataSerl,InOutSubSerl,InOut,InOutYM,InOutDate,
        WHSeq,FunctionWHSeq,ItemSeq,UnitSeq,Qty,
        StdQty,Amt,InOutKind,InOutDetailKind
    )
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, A.InOutSerl, 0,
           1, 0, -1, LEFT(B.InOutDate,6), B.InOutDate,
           
           (CASE WHEN ISNULL(A.OutWHSeq,0) <> 0 THEN A.OutWHSeq ELSE B.OutWHSeq END), 
           0, A.ItemSeq, A.UnitSeq, A.Qty,
           
           A.StdQty, A.Amt, A.InOutKind, A.InOutDetailKind
           
      FROM _TLGInOutDailyItem AS A 
      JOIN _TLGInOutDaily     AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 50 ) 
      JOIN _TDAItemStock      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 
    
    UNION ALL 
    
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, A.InOutSerl, 0,
           2, 0, 1, LEFT(B.InOutDate,6), B.InOutDate,
           
           (CASE WHEN ISNULL(A.InWHSeq,0) <> 0 THEN A.InWHSeq ELSE B.InWHSeq END), 
           0, A.ItemSeq, A.UnitSeq, A.Qty,
           
           A.StdQty, A.Amt, A.InOutKind, A.InOutDetailKind
           
      FROM _TLGInOutDailyItem AS A 
      JOIN _TLGInOutDaily     AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 50 ) 
      JOIN _TDAItemStock      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 
    
    -- [5]
    DELETE A
      FROM _TLGInOutLotStock AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 )
    
    INSERT INTO _TLGInOutLotStock 
    (
        CompanySeq, InOutType, InOutSeq, InOutSerl, DataKind,
        InOutDataSerl, InOutSubSerl, InOutLotSerl, InOut, InOutYM,
        InOutDate, WHSeq, FunctionWHSeq, LotNo, ItemSeq,
        UnitSeq, Qty, StdQty, InOutKind, InOutDetailKind, 
        Amt
    )
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, A.InOutSerl, 0,
           1, 0, 1, -1, LEFT(B.InOutDate,6), 
           
           B.InOutDate,
           (CASE WHEN ISNULL(A.OutWHSeq,0) <> 0 THEN A.OutWHSeq ELSE B.OutWHSeq END), 
           0, A.LotNo, A.ItemSeq, 
           
           A.UnitSeq, A.Qty, A.StdQty, A.InOutKind, A.InOutDetailKind, 
           A.Amt 
           
      FROM _TLGInOutDailyItem AS A 
      JOIN _TLGInOutDaily     AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 50 ) 
      JOIN _TDAItemStock      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 ) 
    
    UNION ALL 
    
    SELECT @CompanySeq, A.InOutType, A.InOutSeq, A.InOutSerl, 0,
           2, 0, 1, 1, LEFT(B.InOutDate,6), 
           
           B.InOutDate,
           (CASE WHEN ISNULL(A.InWHSeq,0) <> 0 THEN A.InWHSeq ELSE B.InWHSeq END), 
           0, A.LotNo, A.ItemSeq, 
           
           A.UnitSeq, A.Qty, A.StdQty, A.InOutKind, A.InOutDetailKind, 
           A.Amt 
           
      FROM _TLGInOutDailyItem AS A 
      JOIN _TLGInOutDaily     AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 50 ) 
      JOIN _TDAItemStock      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.IsLotMng = '1' ) -- Lot包府前格父...
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutType = 50 
       AND A.InOutSeq IN ( SELECT InOutSeq FROM #TLGInOutDailyItem WHERE Status = 0 )
    
    -- 芒绊犁绊 岿笼拌
    EXEC _SLGWHStockUPDATE @CompanySeq  
    EXEC _SLGLOTStockUPDATE @CompanySeq  
    
    -- (-) 犁绊眉农 
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq
    
    DELETE FROM _TCOMSourceDaily 
     WHERE CompanySeq = @CompanySeq 
       AND ToTableSeq = 14 
       AND ToSeq IN (SELECT InOutSeq FROM #TLGInOutDailyItem) 
       
    
    INSERT INTO _TCOMSourceDaily 
    (
        CompanySeq,ToTableSeq,ToSeq,ToSerl,ToSubSerl,
        FromTableSeq,FromSeq,FromSerl,FromSubSerl,ToQty,
        ToSTDQty,ToAmt,ToVAT,FromQty,FromSTDQty,
        FromAmt,FromVAT,ADD_DEL,PrevFromTableSeq,LastUserSeq,
        LastDateTime,PgmSeq
    )
    SELECT @CompanySeq, 14, A.InOutSeq, A.InOutSerl, 0,
           A.ProgFromTableSeq, A.ProgFromSeq, A.ProgFromSerl, 0, A.Qty,
           A.STDQty, A.Amt, 0, C.Qty, C.STDQty,
           C.CurAmt, C.CurVAT, 1, 0, @UserSeq,
           GETDATE(), @PgmSeq
    
      FROM _TLGInOutDailyItem AS A 
      LEFT OUTER JOIN _TSLDVReqItem AS C ON ( A.ProgFromTableSeq = 16 AND A.ProgFromSeq = C.DVReqSeq AND A.ProgFromSerl = C.DVReqSerl )
    
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InOutSeq = (SELECT TOP 1 InOutSeq FROM #TLGInOutDailyItem)
       AND ISNULL(A.ProgFromSeq,0) <> 0 

    SELECT * FROM #TLGInOutDailyItem 
    
    RETURN 
    
GO
begin tran 
exec amoerp_SLGInOutDailyItemMergeSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InOutSeq>1001260</InOutSeq>
    <InOutSerl>1</InOutSerl>
    <ItemSeq>27375</ItemSeq>
    <LotNo>lot_test_3</LotNo>
    <LotNoQty>30.00000</LotNoQty>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InOutSeq>1001260</InOutSeq>
    <InOutSerl>1</InOutSerl>
    <ItemSeq>27375</ItemSeq>
    <LotNo>lot_test_4</LotNo>
    <LotNoQty>70.00000</LotNoQty>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426
rollback