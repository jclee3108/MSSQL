drop proc test_jclee1 
go
create proc test_jclee1 
	@IN_SITECODE int ,
	@IN_ITEMID	int
as 


    CREATE TABLE #tmpWH_LOT_STOCK
    (
      WHSEQ     INT,
      ITEMSEQ   INT,
      LOTNO     NVARCHAR(100),
      WHNAME    NVARCHAR(100),
      ITEMNO    NVARCHAR(100),
      ITEMNAME  NVARCHAR(100),
      SPEC      NVARCHAR(100),
      QTY       DECIMAL(19, 2),
    )


    EXEC  KPXCM.KPX_SLGWHLotStockList_Item
          @CompanySeq = @IN_SITECODE,
          @ItemID = @IN_ITEMID
    
	select * from #tmpWH_LOT_STOCK  order by qty 

return 
go
--begin tran 
exec test_jclee1 2, 353

--rollback 

