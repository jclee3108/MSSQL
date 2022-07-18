

select * from KPX_TDAItem           where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemClass      where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemDefUnit    where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemSales      where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemFile       where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemUserDefine where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemRemark     where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemUnit       where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemUnitModule where companyseq = 1 and itemseq =1518
select * from KPX_TDAItemUnitSpec   where companyseq = 1 and itemseq =1518

select * from KPX_TDAItem_Confirm where cfmseq = 1518


select * from _TDAItem           where companyseq = 1 and itemseq =1518
select * from _TDAItemClass      where companyseq = 1 and itemseq =1518
select * from _TDAItemDefUnit    where companyseq = 1 and itemseq =1518
select * from _TDAItemSales      where companyseq = 1 and itemseq =1518
select * from _TDAItemFile       where companyseq = 1 and itemseq =1518
select * from _TDAItemUserDefine where companyseq = 1 and itemseq =1518
select * from _TDAItemRemark     where companyseq = 1 and itemseq =1518
select * from _TDAItemUnit       where companyseq = 1 and itemseq =1518
select * from _TDAItemUnitModule where companyseq = 1 and itemseq =1518
select * from _TDAItemUnitSpec   where companyseq = 1 and itemseq =1518



select * from _TDAItemProduct where companyseq = 1 and itemseq =  1518
select * from _TDAItemPurchase where companyseq = 1 and itemseq =  1518 
select * from _TDAItemStock where companyseq =1 and itemseq =  1518 



select * from _TDAItemLog           where companyseq = 1 and itemseq = 1051550
select * from _TDAItemClassLog      where companyseq = 1 and itemseq = 1051550
select * from _TDAItemDefUnitLog    where companyseq = 1 and itemseq = 1051550
select * from _TDAItemSalesLog      where companyseq = 1 and itemseq = 1051550
select * from _TDAItemFileLog       where companyseq = 1 and itemseq = 1051550
select * from _TDAItemUserDefineLog where companyseq = 1 and itemseq = 1051550
select * from _TDAItemRemarkLog     where companyseq = 1 and itemseq = 1051550
select * from _TDAItemUnitLog       where companyseq = 1 and itemseq = 1051550
select * from _TDAItemUnitModuleLog where companyseq = 1 and itemseq = 1051550
select * from _TDAItemUnitSpecLog   where companyseq = 1 and itemseq = 1051550





select * from _TDAItemProductLog where companyseq = 1 and itemseq =  1051549 and pgmseq = 1021312
select * from _TDAItemPurchaseLog where companyseq = 1 and itemseq =  1051549 
select * from _TDAItemStockLog where companyseq =1 and itemseq =  1051549 

--drop table #temp_Pur

        create table #temp_Prod
        (
            ItemSeq         INT, 
            --PgmSeq          INT,
            LastDateTime    DATETIME
        )
        INSERT INTO #temp_Prod (ItemSeq, LastDateTime)
select ItemSeq,  LastDateTime 
  from _TDAItemProduct 
 where companyseq = 1 
   and itemseq =  1051549 
   and pgmseq = 1021312
union all 
select ItemSeq,  LastDateTime 
  from _TDAItemProductLog 
 where companyseq = 1 and itemseq =  1051549 and pgmseq = 1021312
 



select itemseq, pgmseq, max(lastdatetime)
  from (
            
            
        create table #temp_Pur
        (
            ItemSeq         INT, 
            --PgmSeq          INT,
            LastDateTime    DATETIME
        )
        INSERT INTO #temp_Pur (ItemSeq,  LastDateTime)
        select ItemSeq,  LastDateTime 
          from _TDAItemPurchase 
         where companyseq = 1 
           and itemseq =  1051549 
           and pgmseq = 1021313
        union all 
        select ItemSeq,  LastDateTime 
          from _TDAItemPurchaseLog 
         where companyseq = 1 
           and itemseq =  1051549 
           and pgmseq = 1021313
         
   ) 
   group by itemseq, pgmseq 
--order by LastDateTime desc 

select itemseq, max(lastdatetime) as lastdatetime from #temp_Prod group by itemseq
select itemseq, max(lastdatetime) as lastdatetime from #temp_Pur group by itemseq