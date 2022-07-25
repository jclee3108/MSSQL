select * from _TLGInOutDaily where companyseq = 1 and InOutType = 50 and InOutSeq = 1001292
select * from _TLGInOutDailyItem where companyseq = 1 and InOutType = 50 and InOutSeq = 1001292
select * from _TLGInOutLotSub where companyseq = 1 and InOutType = 50 and InOutSeq = 1001292

select * from _TLGInOutStock where companyseq = 1 and inouttype = 50 and InOutSeq = 1001292
select * from _TLGInOutLotStock where companyseq = 1 and inouttype = 50 and InOutSeq = 1001292

select * from _TLGWHStock where companyseq = 1 and stkym = '201311' and itemseq IN (27375) and whseq in (2,6) 
select * from _TLGLotStock where companyseq = 1 and stkym = '201311' and itemseq IN (27375)and whseq in (2,6) 

select * from _TLGInOutDaily where companyseq = 1 and InOutType = 50 and InOutSeq = 1001292
select * from amoerp_TLGInOutDailyItemMerge where companyseq = 1 and InOutType = 50 and InOutSeq = 1001292
select * from amoerp_TLGInOutDailyItemMergeSub where companyseq = 1 and InOutSeq = 1001292


select * from _TCOMsourcedaily where companyseq = 1 and toseq = 1001325


select * from _TLGInOutDaily where companyseq = 1 and inoutno = '201311260002'

select * from _TLGInOutLotSub where inoutseq = 1001240



select * from _TLGInOutDaily where companyseq = 1 and InOutType = 50 and InOutno = '201312110001'