IF OBJECT_ID('hencom_SPNMarginalProfitsItemQuery_AllDept') IS NOT NULL 
    DROP PROC hencom_SPNMarginalProfitsItemQuery_AllDept
GO 

-- v2017.05.24 
/************************************************************  
 설  명 - 데이터-제품단위당한계이익사업계획_hencom : 제품단위당이익조회  
 hencom_SPNMarginalProfitsItemQuery과 동일한 결과를 사용하기 위함.
 매출수량및함계이익 그래프화면에서 사용. 
 작성일 - 20161128
 작성자 - 박수영  
************************************************************/  
create PROC dbo.hencom_SPNMarginalProfitsItemQuery_AllDept
    @CompanySeq     INT  = 1,              
    @PlanSeq        INT   
    AS          
    
    
    --create table #tmepresult2 
    --(  
    --    DeptSeq int null, 
    --    ItemSeq int null,
    --    ItemName nvarchar(200) null,
    --    ItemNo nvarchar(200) null,
    --    Spec nvarchar(200) null,
    --    ItemClassLName nvarchar(200) null,
    --    ItemClassLSeq int null,  
    --    --PrevQty decimal(19,5) null,
    --    --PrevAmt decimal(19,5) null,
    --    --PrevPrice decimal(19,5) null,
    --    --MatItemSeq int null,
    --    --PrevTotQty decimal(19,5) null,
    --    --PrevTotAmt decimal(19,5) null,  
    --    --PrevAvgPrice decimal(19,5) null,
    --    Qty1 decimal(19,5) null,
    --    Amt1 decimal(19,5) null,
    --    Price1 decimal(19,5) null,  
    --    Qty2 decimal(19,5) null,
    --    Amt2 decimal(19,5) null,
    --    Price2 decimal(19,5) null,
    --    Qty3 decimal(19,5) null,
    --    Amt3 decimal(19,5) null,
    --    Price3 decimal(19,5) null,
    --    Qty4 decimal(19,5) null,  
    --    Amt4 decimal(19,5) null,
    --    Price4 decimal(19,5) null,
    --    Qty5 decimal(19,5) null,
    --    Amt5 decimal(19,5) null,
    --    Price5 decimal(19,5) null,
    --    Qty6 decimal(19,5) null,
    --    Amt6 decimal(19,5) null,  
    --    Price6 decimal(19,5) null,
    --    Qty7 decimal(19,5) null,
    --    Amt7 decimal(19,5) null,
    --    Price7 decimal(19,5) null,
    --    Qty8 decimal(19,5) null,
    --    Amt8 decimal(19,5) null,
    --    Price8 decimal(19,5) null,  
    --    Qty9 decimal(19,5) null,
    --    Amt9 decimal(19,5) null,
    --    Price9 decimal(19,5) null,
    --    Qty10 decimal(19,5) null,
    --    Amt10 decimal(19,5) null,  
    --    Price10 decimal(19,5) null,
    --    Qty11 decimal(19,5) null,
    --    Amt11 decimal(19,5) null,
    --    Price11 decimal(19,5) null,
    --    Qty12 decimal(19,5) null,
    --    Amt12 decimal(19,5) null,
    --    Price12 decimal(19,5) null,  
    --    TotQty decimal(19,5) null,
    --    TotAmt decimal(19,5) null,
    --    AvgPrice  decimal(19,5) null  
    --)  
    -- alter table #tmepresult2 add   
    --  TotM3Qty decimal(19,5) null,  
    --  M3Qty1 decimal(19,5) null,  
    --  M3Qty2 decimal(19,5) null,  
    --  M3Qty3 decimal(19,5) null,  
    --  M3Qty4 decimal(19,5) null,  
    --  M3Qty5 decimal(19,5) null,  
    --  M3Qty6 decimal(19,5) null,  
    --  M3Qty7 decimal(19,5) null,  
    --  M3Qty8 decimal(19,5) null,  
    --  M3Qty9 decimal(19,5) null,  
    --  M3Qty10 decimal(19,5) null,  
    --  M3Qty11 decimal(19,5) null,  
    --  M3Qty12 decimal(19,5) null  



    CREATE TABLE #tmepresult2   
    (    
        DeptSeq INT, 
        ItemSeq INT ,    
        ItemName NVARCHAR(200),    
        ItemNo NVARCHAR(200),    
        Spec NVARCHAR(200),    
        ITemClassLName NVARCHAR(200),    
        ITemClassLSeq INT  ,    
        PrevQty DECIMAL(19,5),    
        PrevAmt  DECIMAL(19,5),    
        PrevPrice  DECIMAL(19,5),    
        MatitemSeq INT ,    
        PrevTotQty  DECIMAL(19,5) ,    
        PrevTotAmt  DECIMAL(19,5),    
        PrevAvgPrice  DECIMAL(19,5),    
        Qty1  DECIMAL(19,5),    
        Amt1  DECIMAL(19,5),    
        Price1  DECIMAL(19,5),    
        Qty2  DECIMAL(19,5),    
        Amt2  DECIMAL(19,5),    
        Price2  DECIMAL(19,5),    
        Qty3  DECIMAL(19,5),    
        Amt3  DECIMAL(19,5),     
        Price3  DECIMAL(19,5),     
        Qty4  DECIMAL(19,5),     
        Amt4  DECIMAL(19,5),     
        Price4  DECIMAL(19,5),     
        Qty5  DECIMAL(19,5),    
        Amt5  DECIMAL(19,5),    
        Price5  DECIMAL(19,5),    
        Qty6  DECIMAL(19,5),    
        Amt6  DECIMAL(19,5),    
        Price6  DECIMAL(19,5) ,    
        Qty7  DECIMAL(19,5),    
        Amt7  DECIMAL(19,5),    
        Price7  DECIMAL(19,5),    
        Qty8  DECIMAL(19,5),    
        Amt8 DECIMAL(19,5),     
        Price8  DECIMAL(19,5),    
        Qty9  DECIMAL(19,5),    
        Amt9  DECIMAL(19,5),    
        Price9  DECIMAL(19,5),    
        Qty10  DECIMAL(19,5),    
        Amt10  DECIMAL(19,5),     
        Price10  DECIMAL(19,5),    
        Qty11  DECIMAL(19,5),    
        Amt11  DECIMAL(19,5),    
        Price11  DECIMAL(19,5),     
        Qty12  DECIMAL(19,5),     
        Amt12  DECIMAL(19,5),    
        Price12  DECIMAL(19,5),    
        TotQty  DECIMAL(19,5),    
        TotAmt  DECIMAL(19,5),    
        AvgPrice  DECIMAL(19,5),    
        PrevM3Qty  DECIMAL(19,5),    
        PrevM3TotQty  DECIMAL(19,5),    
        TotM3Qty  DECIMAL(19,5),    
        M3Qty1  DECIMAL(19,5),    
        M3Qty2  DECIMAL(19,5),    
        M3Qty3  DECIMAL(19,5) ,    
        M3Qty4  DECIMAL(19,5),     
        M3Qty5  DECIMAL(19,5),     
        M3Qty6 DECIMAL(19,5),     
        M3Qty7  DECIMAL(19,5),     
        M3Qty8  DECIMAL(19,5),     
        M3Qty9  DECIMAL(19,5),     
        M3Qty10  DECIMAL(19,5),     
        M3Qty11 DECIMAL(19,5),     
        M3Qty12  DECIMAL(19,5)    
    )    


   declare @test nvarchar(1000)   
    set @test = '<ROOT>  
     <DataBlock1>  
    <WorkingTag>A</WorkingTag>  
    <IDX_NO>1</IDX_NO>  
    <Status>0</Status>  
    <DataSeq>1</DataSeq>  
    <Selected>1</Selected>  
    <TABLE_NAME>DataBlock1</TABLE_NAME>  
    <IsChangedMst>1</IsChangedMst>  
    <PlanSeq>' + convert(nvarchar(100),@PlanSeq) + '</PlanSeq>  
     </DataBlock1>  
   </ROOT>'  
   --insert #tmepresult2  
   exec hencom_SPNQCReplaceRatePlanResultQuery_AllDept @xmlDocument=@test,@xmlFlags=2,@ServiceSeq=1510198,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031857  
  

  
    CREATE TABLE #tempresultTC
    (    
        DeptSeq     INT, 
        Gubun       INT, 
        ColumnA     NVARCHAR(100), 
        ColumnB     NVARCHAR(100), 
        ColumnC     NVARCHAR(100), 
        Sales       DECIMAL(19,5),
        Mth1        DECIMAL(19,5),
        Mth2        DECIMAL(19,5),
        Mth3        DECIMAL(19,5),
        Mth4        DECIMAL(19,5),
        Mth5        DECIMAL(19,5),
        Mth6        DECIMAL(19,5),
        Mth7        DECIMAL(19,5),
        Mth8        DECIMAL(19,5),
        Mth9        DECIMAL(19,5),
        Mth10       DECIMAL(19,5),
        Mth11       DECIMAL(19,5),
        Mth12       DECIMAL(19,5),
        Total       DECIMAL(19,5)
    )    
  
    set @test = '<ROOT>  
      <DataBlock2>  
     <WorkingTag>A</WorkingTag>  
     <IDX_NO>1</IDX_NO>  
     <Status>0</Status>  
     <DataSeq>1</DataSeq>  
     <Selected>1</Selected>  
     <TABLE_NAME>DataBlock2</TABLE_NAME>  
    <IsChangedMst>1</IsChangedMst>  
    <PlanSeq>' + convert(nvarchar(100),@PlanSeq) + '</PlanSeq>  
     </DataBlock2>  
   </ROOT>'  
  
  --select * from #tempresultTC 

   INSERT INTO #tempresultTC  
   EXEC hencom_SPNCostOfTransportVarSubContQueryNew_AllDept @xmlDocument=@test,@xmlFlags=2,@ServiceSeq=1510143,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031995  
  



  
   insert #tmepresult2 (DeptSeq, ItemSeq,itemname,Amt1, Amt2, Amt3, Amt4,Amt5, Amt6, Amt7, Amt8, Amt9, Amt10, Amt11, Amt12, TotAmt,   
                          Price1, Price2, Price3, Price4, Price5, Price6, Price7, Price8, Price9, Price10, Price11, Price12, AvgPrice   )  
   select A.DeptSeq, 
          77777771,  
          '소계',  
       --sum(a.PrevAmt),   
       --sum(a.PrevTotAmt),   
       sum(a.Amt1),   
       sum(a.Amt2),   
       sum(a.Amt3),   
       sum(a.Amt4),   
       sum(a.Amt5),   
       sum(a.Amt6),   
       sum(a.Amt7),   
       sum(a.Amt8),   
          sum(a.Amt9),   
       sum(a.Amt10),   
       sum(a.Amt11),   
       sum(a.Amt12),   
       sum(a.TotAmt),  
     --  PrevPrice = sum(a.PrevAmt) / max(b.PrevQty) ,  
     --PrevAvgPrice = sum(a.PrevTotAmt) /max(b.PrevTotQty),  
     Price1 = sum(a.Amt1)  / max(b.Qty1) ,  
     Price2 = sum(a.Amt2)  / max(b.Qty2),  
     Price3 = sum(a.Amt3)   / max(b.Qty3),  
     Price4 = sum(a.Amt4)   / max(b.Qty4),  
     Price5 = sum(a.Amt5)   / max(b.Qty5),  
     Price6 = sum(a.Amt6)   / max(b.Qty6),  
     Price7 = sum(a.Amt7)   / max(b.Qty7),  
     Price8 = sum(a.Amt8)   / max(b.Qty8),  
     Price9 = sum(a.Amt9)   / max(b.Qty9),  
     Price10 = sum(a.Amt10)   / max(b.Qty10),  
     Price11 = sum(a.Amt11)   / max(b.Qty11),  
     Price12 = sum(a.Amt12)   / max(b.Qty12),  
     AvgPrice = sum(a.TotAmt) / max(b.TotQty)  
     from #tmepresult2 as a  
     join #tmepresult2 as b on ( b.DeptSeq = A.DeptSeq AND b.ItemSeq = -1 ) 
    where a.ItemSeq <> -1  
     GROUP BY A.DeptSeq 
   
  
   insert #tmepresult2 (DeptSeq, ItemSeq,itemname,  Amt1, Amt2, Amt3, Amt4, Amt5, Amt6, Amt7, Amt8, Amt9, Amt10, Amt11, Amt12, TotAmt,   
                          Price1, Price2, Price3, Price4, Price5, Price6, Price7, Price8, Price9, Price10, Price11, Price12, AvgPrice   )  
   select A.DeptSeq, 
          77777772,  
          '도급비',  
       --a.prevsales,  
       --a.prevplan,  
       a.Mth1 as PlanAmt01,  
       a.Mth2 as PlanAmt02,  
       a.Mth3 as PlanAmt03,  
       a.Mth4 as PlanAmt04,  
       a.Mth5 as PlanAmt05,  
       a.Mth6 as PlanAmt06,  
       a.Mth7 as PlanAmt07,  
       a.Mth8 as PlanAmt08,  
       a.Mth9 as PlanAmt09,  
       a.Mth10 as PlanAmt10,  
       a.Mth11 as PlanAmt11,  
       a.Mth12 as PlanAmt12,  
       a.Total,   
  
     --  a.prevsales /  b.PrevQty ,  
     --a.prevplan / b.PrevTotQty,  
     a.Mth1 / b.Qty1,  
     a.Mth2 / b.Qty2,  
     a.Mth3 / b.Qty3,  
     a.Mth4 / b.Qty4,  
     a.Mth5 / b.Qty5,  
     a.Mth6 / b.Qty6,  
     a.Mth7 / b.Qty7,  
     a.Mth8 / b.Qty8,  
     a.Mth9 / b.Qty9,  
     a.Mth10 / b.Qty10,  
     a.Mth11 / b.Qty11,  
     a.Mth12 / b.Qty12,  
     a.Total / b.TotQty  
     from #tempresultTC as a  
     join #tmepresult2 as b on ( B.DeptSeq = A.DeptSeq AND b.ItemSeq = -1 ) 
          where gubun = 11  
   
   
   insert #tmepresult2 (DeptSeq, ItemSeq,itemname,Amt1, Amt2, Amt3, Amt4,Amt5, Amt6, Amt7, Amt8, Amt9, Amt10, Amt11, Amt12, TotAmt,   
                            Price1, Price2, Price3, Price4, Price5, Price6, Price7, Price8, Price9, Price10, Price11, Price12, AvgPrice   )  
   select A.DeptSeq, 
          77777773,  
          '합계',  
       --sum(a.PrevAmt),   
       --sum(a.PrevTotAmt),   
       sum(a.Amt1),   
       sum(a.Amt2),   
       sum(a.Amt3),   
       sum(a.Amt4),   
       sum(a.Amt5),   
       sum(a.Amt6),   
       sum(a.Amt7),   
       sum(a.Amt8),   
          sum(a.Amt9),   
       sum(a.Amt10),   
       sum(a.Amt11),   
       sum(a.Amt12),   
       sum(a.TotAmt),  
     --  PrevPrice = sum(a.PrevAmt) / max(b.PrevQty) ,  
     --PrevAvgPrice = sum(a.PrevTotAmt) /max(b.PrevTotQty),  
     Price1 = sum(a.Amt1)  / max(b.Qty1) ,  
     Price2 = sum(a.Amt2)  / max(b.Qty2),  
     Price3 = sum(a.Amt3)   / max(b.Qty3),  
     Price4 = sum(a.Amt4)   / max(b.Qty4),  
     Price5 = sum(a.Amt5)   / max(b.Qty5),  
     Price6 = sum(a.Amt6)   / max(b.Qty6),  
     Price7 = sum(a.Amt7)   / max(b.Qty7),  
     Price8 = sum(a.Amt8)   / max(b.Qty8),  
     Price9 = sum(a.Amt9)   / max(b.Qty9),  
     Price10 = sum(a.Amt10)   / max(b.Qty10),  
     Price11 = sum(a.Amt11)   / max(b.Qty11),  
     Price12 = sum(a.Amt12)   / max(b.Qty12),  
     AvgPrice = sum(a.TotAmt) / max(b.TotQty)  
     from #tmepresult2 as a  
     join #tmepresult2 as b on ( B.DeptSeq = A.DeptSeq AND b.ItemSeq = -1 ) 
    where a.ItemSeq in (77777771,77777772)  
     GROUP BY A.DeptSeq 
   
  
  
   insert #tmepresult2 (DeptSeq, ItemSeq,itemname,  Price1, Price2, Price3, Price4, Price5, Price6, Price7, Price8, Price9, Price10, Price11, Price12, AvgPrice   )  
   select A.DeptSeq, 
          77777774,  
          '한계이익',  
       --sum(case itemseq when -1 then a.PrevPrice else -a.PrevPrice end),   
       --sum(case itemseq when -1 then a.PrevAvgPrice else -a.PrevAvgPrice end),   
       sum(case itemseq when -1 then a.Price1 else -a.Price1 end),   
       sum(case itemseq when -1 then a.Price2 else -a.Price2 end),   
       sum(case itemseq when -1 then a.Price3 else -a.Price3 end),   
       sum(case itemseq when -1 then a.Price4 else -a.Price4 end),   
       sum(case itemseq when -1 then a.Price5 else -a.Price5 end),   
       sum(case itemseq when -1 then a.Price6 else -a.Price6 end),   
       sum(case itemseq when -1 then a.Price7 else -a.Price7 end),   
       sum(case itemseq when -1 then a.Price8 else -a.Price8 end),   
          sum(case itemseq when -1 then a.Price9 else -a.Price9 end),   
       sum(case itemseq when -1 then a.Price10 else -a.Price10 end),   
       sum(case itemseq when -1 then a.Price11 else -a.Price11 end),   
       sum(case itemseq when -1 then a.Price12 else -a.Price12 end),   
       sum(case itemseq when -1 then a.AvgPrice else -a.AvgPrice end)  
     from #tmepresult2 as a  
    where a.ItemSeq in (-1,77777773)  
     GROUP BY A.DeptSeq 
    --*/
   
    INSERT INTO #TMP_Result_Graph
    SELECT * FROM #tmepresult2  
RETURN
--go
--begin tran 
--exec hencom_SPNMarginalProfitsItemQuery_AllDept 1, 3 
--rollback 