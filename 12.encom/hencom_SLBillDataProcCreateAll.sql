IF OBJECT_ID('hencom_SLBillDataProcCreateAll') IS NOT NULL 
    DROP PROC hencom_SLBillDataProcCreateAll
GO 

-- v2017.03.21 
/************************************************************
 설  명 - 데이터-세금계산서일괄생성_hencom : 세금계산서일괄생성
 작성일 - 20170202
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SLBillDataProcCreateAll
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
    DECLARE @MessageType    INT,
            @Status         INT,
            @Results        NVARCHAR(250),
            @IDX            int, 
            @BillDate       nchar(8), 
            @BillNo         nvarchar(200), 
            @BillSeq        int, 
            @TotCnt         int
  					
    CREATE TABLE #CreateAllBills (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#CreateAllBills'
    
        DECLARE @EmpSeq INT
        SELECT @EmpSeq = EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq and UserSeq = @UserSeq

				 SELECT cb.DataSeq as idx,
						row_number() over (partition by cb.DataSeq order by cb.DataSeq,a.pjtseq,a.workdate) as idxserl,
						a.IsReplace,
						a.Remark,
						a.PJTSeq,
						a.WorkDate AS InvoiceDate,
						a.ItemSeq,
						a.Qty,
						a.Price,
						a.CurAmt,
						a.CurVAT,
						a.TotAmt,
						a.IsInclusedVAT,
						a.CustSeq,
						a.CustName,
						a.PJTName,
						a.GoodItemName,
						a.DeptSeq,
						a.DeptName,
						a.InvoiceSeq,
						a.InvoiceSerl,
						a.SalesSeq,
						a.SalesSerl,
						a.SumMesKey,
						a.IsBill,
						a.BizNo,
						a.ProdQty,
						a.OutQty,
						a.IsPreSales,
						a.SourceTableSeq as TableSeq,
						case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSeq else a.ReplaceRegSeq end as Seq,
						case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSerl else a.ReplaceRegSerl end as Serl,
						a.AttachDate,
		                IT.AssetSeq ,
				        IA.AssetName,
		                PJTADD.UMPayType    AS UMPayType , 
	                    PJTADD.ClaimPeriod  AS ClaimPeriod ,
						(SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = PJTADD.UMPayType) AS UMPayTypeName ,
						a.ItemSeq as GoodItemSeq,
						isnull(ca.IsTaxPJT,'0') as IsTaxPJT,
                        case when eb.PreBillExceptRegSeq is null then '0' else '1' end as UMDataKind,
						isnull(eb.PreBillExceptRegSeq,0) as PreBillExceptRegSeq,
						CASE WHEN ISNULL(PJTADD.ClaimPeriod,0) <> 0 THEN CONVERT(NCHAR(8),DATEADD(DAY,PJTADD.ClaimPeriod,  convert(datetime,cb.BillDate)  ),112) ELSE cb.BillDate END as FundArrangeDate,
						case isnull(inv.EmpSeq,0) when 0 then @EmpSeq else inv.EmpSeq end as EmpSeq,
						(select empname from _tdaemp where companyseq = @CompanySeq and empseq = case isnull(inv.EmpSeq,0) when 0 then @EmpSeq else inv.EmpSeq end) as EmpName,
						inv.BizUnit,
						( select BizUnitName from _TDABizUnit where companyseq = @CompanySeq and bizUnit = inv.BizUnit ) as BizUnitName,
						inv.CurrSeq,
						( select CurrName from _TDACurr where companyseq = @CompanySeq and CurrSeq = inv.CurrSeq ) as CurrName,
						inv.ExRate,
						inv.SMExpKind,
						si.AccSeq,
						( select accname from _TDAAccount where companyseq = @CompanySeq and AccSeq = si.AccSeq ) as AccName,
			            cb.OppAccSeq,           
						( select accname from _TDAAccount where companyseq = @CompanySeq and AccSeq =  cb.OppAccSeq ) as OppAccName,
						cb.BillDate,
						cb.UMBillKind,
						cb.SMBillType,
						cb.SMBilling,
						cb.VatAccSeq,
						cb.EvidSeq    ,
						dept.TaxUnit        
                   into #tempresult
                   FROM hencom_VInvoiceReplaceItem    AS A  WITH(NOLOCK)         
                   join #CreateAllBills as cb on cb.deptseq = a.deptseq
				                             and cb.custseq = a.CustSeq
											 and a.pjtseq = case cb.istaxpjt when '0' then a.pjtseq else cb.pjtseq end
        LEFT OUTER JOIN hencom_TDADeptAdd AS AD WITH(NOLOCK) ON AD.CompanySeq = @CompanySeq AND AD.DeptSeq = A.DeptSeq         
        LEFT OUTER JOIN hencom_TPJTProjectAdd AS PJTADD WITH(NOLOCK) ON PJTADD.CompanySeq = @CompanySeq AND PJTADD.PJTSeq = A.PJTSeq        
        LEFT OUTER JOIN _TDAItem AS IT WITH(NOLOCK) ON IT.CompanySeq = A.CompanySeq AND IT.ItemSeq = A.ItemSeq        
        LEFT OUTER JOIN _TDAItemAsset AS IA WITH(NOLOCK) ON IA.CompanySeq = IT.CompanySeq AND IA.AssetSeq = IT.AssetSeq        
        LEFT OUTER JOIN _TSLBill AS BL WITH(NOLOCK) ON BL.CompanySeq = @CompanySeq AND BL.BillSeq = A.BillSeq     
        LEFT OUTER JOIN hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK) ON PSM.ToTableSeq = A.SourceTableSeq     
                                                                     AND PSM.ToSeq =     
                                                                         (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSeq     
                                                                         WHEN 1000057 THEN A.SumMesKey    
                                                                         WHEN 1000075 THEN A.ReplaceRegSeq    
            END  )    
                                                                     AND PSM.ToSerl =     
                                                                    (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSerl     
                                                               WHEN 1000057 THEN 0    
                                     WHEN 1000075 THEN A.ReplaceRegSerl    
                                        END  )    
                                                                             
         LEFT OUTER JOIN hencom_ViewPreSalesSource AS VPS ON VPS.FromTableSeq = PSM.FromTableSeq     
                                                         AND VPS.FromSeq = PSM.FromSeq     
                                                         AND VPS.FromSerl = PSM.FromSerl    
         LEFT OUTER JOIN hencom_TSLPrePublicSales AS PPS WITH(NOLOCK) ON PPS.CompanySeq = @CompanySeq AND PPS.PPSRegSeq = PSM.PPSRegSeq    
		 left outer join hemcom_TDADeptCustAddInfo as ca on ca.companyseq = a.companyseq
		                                                and ca.deptseq = a.deptseq
														and ca.custseq = a.custseq
         left outer join hencom_TSLPreBillExceptData as eb on eb.companyseq = a.companyseq
		                                                  and eb.StdYM = cb.StdYM
														  and eb.TableSeq = a.SourceTableSeq
														  and eb.Seq = case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSeq else a.ReplaceRegSeq end
														  and eb.Serl = case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSerl else a.ReplaceRegSerl end
         left outer join _tslinvoice as inv on inv.companyseq = @CompanySeq
		                                   and inv.InvoiceSeq = a.InvoiceSeq
         left outer join _tslsalesitem as si on si.companyseq = @CompanySeq
		                                    and si.salesseq = a.salesseq
											and si.salesserl = a.salesserl
        LEFT OUTER JOIN _TDADept AS dept WITH(NOLOCK) ON dept.CompanySeq = @CompanySeq AND dept.DeptSeq = A.DeptSeq
												            
                   WHERE A.CompanySeq = @CompanySeq                                       
                     AND A.CloseCfmCode = '1'    --확정건만 조회          
                     AND (CASE WHEN A.IsBill = '1' OR ISNULL(PSM.FromSeq,0) <> 0 THEN '1' ELSE A.IsBill END) = '0'   
					 and  case when eb.PreBillExceptRegSeq is null then '0' else '1' end = '0'
					 --and isnull(a.InvoiceSeq,0) > 0
					 --and isnull(a.salesseq,0) > 0            -- 매출발생건
					 and isnull(a.itemseq,0) > 0
					 and a.BalCurAmt > 0
                ORDER BY cb.DataSeq,a.pjtseq,a.workdate
			
    
    --SELECT * FROM #tempresult 
    --return 
            
            
            
    IF (select count(*) from #tempresult) = 0
    BEGIN                                  
								 
        UPDATE #CreateAllBills                                             
           SET Result = '처리할 자료가 없습니다. 확인 후 작업하세요'   ,                                           
               Status = 999                                                                      
         WHERE Status = 0                                  
                 
        SELECT * FROM #CreateAllBills   
        
        RETURN                              
    END		  

    ------------------------------------------------------------------------------------------------
    -- 체크1, 매출이 발생되지 않은 건이 존재합니다.
    ------------------------------------------------------------------------------------------------
    UPDATE #CreateAllBills
       SET Result = '매출이 발생되지 않은 건이 존재합니다.'   ,                                           
           Status = 1234, 
           MessageType = 1234
      FROM #tempresult                              AS A 
      LEFT OUTER JOIN hencom_VInvoiceReplaceItem    AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND (case when B.SourceTableSeq = 1000057 then B.SumMesKey 
                                                                    when B.SourceTableSeq = 1268 then B.InvoiceSeq 
                                                                    else B.ReplaceRegSeq 
                                                                    end
                                                              ) = A.Seq
                                                          AND (case when B.SourceTableSeq = 1000057 then B.SumMesKey 
                                                                    when B.SourceTableSeq = 1268 then B.InvoiceSerl 
                                                                    else B.ReplaceRegSerl 
                                                                    end 
                                                              ) = A.Serl 
                                                          AND B.SourceTableSeq = A.TableSeq ) 
     WHERE ( ISNULL(B.SalesSeq,0) = 0 OR ISNULL(B.InvoiceSeq,0) = 0 ) 

    IF EXISTS (SELECT 1 FROM #CreateAllBills WHERE Status <> 0)
    BEGIN 
        SELECT * FROM #CreateAllBills   
        RETURN                              
    END		  

    ------------------------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------------------------ 
    

				            
	CREATE TABLE #TSLBill (
			idx int null, 
			[CompanySeq] [int] NULL,
			[BillSeq] [int]  NULL,
			[BizUnit] [int]  NULL,
			[SMExpKind] [int]  NULL,
			[BillNo] [nvarchar](20) NULL,
			[BillDate] [nchar](8)  NULL,
			[SMBillType] [int]  NULL,
			[UMBillKind] [int]  NULL,
			[DeptSeq] [int]  NULL,
			[EmpSeq] [int]  NULL,
			[CustSeq] [int]  NULL,
			[CurrSeq] [int]  NULL,
			[ExRate] [decimal](19, 6)  NULL,
			[Gwon] [nvarchar](5) NOT NULL,
			[Ho] [nvarchar](5) NOT NULL,
			[FundArrangeDate] [nchar](8) NOT NULL,
			[PrnReqDate] [nchar](8) NOT NULL,
			[SMBilling] [int] NOT NULL,
			[IsPrint] [nchar](1) NOT NULL,
			[IsDate] [nchar](1) NOT NULL,
			[IsCust] [nchar](1) NOT NULL,
			[TaxNo] [nvarchar](20) NULL,
			[EvidSeq] [int] NOT NULL,
			[Remark] [nvarchar](1000) NOT NULL,
			[AccSeq] [int] NOT NULL,
			[VatAccSeq] [int] NOT NULL,
			[OppAccSeq] [int] NOT NULL,
			[SlipSeq] [int] NULL,
			[LastUserSeq] [int] NOT NULL,
			[LastDateTime] [datetime] NOT NULL,
			[BillID] [int] NULL,
			[UMPriceTerms] [int] NULL,
			[CondSerl] [int] NULL,
			[SMSalesCrtKind] [int] NULL,
			[TaxUnit] [int] NULL,
			[DtiProcType] [nchar](1) NULL,
			[IsPJT] [nchar](1) NULL,
			[Email] [nvarchar](100) NULL,
			[PgmSeq] [int] NULL,
			[FileSeq] [int] NULL)
    CREATE TABLE #TSLBillItem(
			[CompanySeq] [int] NOT NULL,
			[BillSeq] [int] NOT NULL,
			[BillSerl] [int] NOT NULL,
			[BillPrtDate] [nchar](8) NOT NULL,
			[ItemName] [nvarchar](200) NULL,
			[Spec] [nvarchar](100) NULL,
			[Qty] [decimal](19, 5) NOT NULL,
			[Price] [decimal](19, 5) NOT NULL,
			[CurAmt] [decimal](19, 5) NOT NULL,
			[CurVAT] [decimal](19, 5) NOT NULL,
			[KorPrice] [decimal](19, 5) NOT NULL,
			[DomAmt] [decimal](19, 5) NOT NULL,
			[DomVAT] [decimal](19, 5) NOT NULL,
			[Remark] [nvarchar](500) NOT NULL,
			[LastUserSeq] [int] NOT NULL,
			[LastDateTime] [datetime] NOT NULL,
			[PgmSeq] [int] NULL)

	CREATE TABLE #TSLSalesBillRelation(
			[CompanySeq] [int] NOT NULL,
			[BillSeq] [int] NOT NULL,
			[SalesSeq] [int] NOT NULL,
			[SalesSerl] [int] NOT NULL,
			[CurAmt] [decimal](19, 5) NOT NULL,
			[CurVAT] [decimal](19, 5) NOT NULL,
			[DomAmt] [decimal](19, 5) NOT NULL,
			[DomVAT] [decimal](19, 5) NOT NULL,
			[SlipSeq] [int] NULL,
			[IsSlip] [nchar](1) NOT NULL,
			[LastUserSeq] [int] NOT NULL,
			[LastDateTime] [datetime] NOT NULL,
			[PgmSeq] [int] NULL)
	CREATE TABLE #hemcom_TSLBillReplaceRelation (
			[CompanySeq] [int] NOT NULL,
			[BillSeq] [int] NOT NULL,
			[ReplaceRegSeq] [int] NOT NULL,
			[ReplaceRegSerl] [int] NOT NULL,
			[ReplaceCurAmt] [decimal](19, 5) NULL,
			[ReplaceCurVAT] [decimal](19, 5) NULL,
			[ReplaceDomAmt] [decimal](19, 5) NULL,
			[ReplaceDomVat] [decimal](19, 5) NULL )
		insert #tslbill ( idx,companyseq, billseq, bizunit, smexpkind, billno, billdate, smbilltype, umbillkind, deptseq, EmpSeq, custseq, currseq, exrate, gwon, ho, fundarrangedate,prnreqdate, smbilling, isprint,
		                  isdate, iscust, taxno, EvidSeq, remark, accseq, vataccseq, oppaccseq, lastuserseq, lastdatetime, billid, 
						  umpriceterms,condserl,taxunit, pgmseq )
		select          idx,@CompanySeq,0,      max(BizUnit),  max(SMExpKind), ''    , billdate, smbilltype, umbillkind, max(DeptSeq), max(empseq), max(custseq), max(CurrSeq), max(ExRate), '',   '', max(FundArrangeDate),'',         smbilling, '',
		                  '',     '',     '',    evidseq, ''    , 0     , max(vataccseq), max(oppaccseq), @UserSeq,     getdate(),   ( select case envvalue when 8017001 then 3 else 2 end from _TCOMEnv where envseq = 8054  )   , 
						  0,           0,       max(taxunit), @PgmSeq 
		 from #tempresult
		  group by idx ,  billdate, smbilltype, umbillkind, smbilling, evidseq
		  -- BillSeq 생성  
		select @TotCnt     = count(*) from #tslbill
        EXEC @BillSeq = _SCOMCreateSeq @CompanySeq, '_TSLBill', 'BillSeq', @TotCnt   
		
		update   #tslbill
		  set BillSeq = @BillSeq + idx
	
   SELECT   @IDX = 0    
        
    WHILE ( 1 = 1 )     
    BEGIN    
        SELECT @BillNo   = ''    
    
        SELECT TOP 1 @IDX = IDX, @BillDate = BillDate
          FROM #tslbill    
         WHERE IDX > @IDX    
         ORDER BY IDX    
    
        IF @@ROWCOUNT = 0 BREAK    
    
        -- BillNo 생성    
        EXEC _SCOMCreateNo 'SL', '_TSLBill', @CompanySeq, '', @BillDate, @BillNo OUTPUT    
    
        UPDATE #tslbill    
           SET BillNo   = @BillNo    
         WHERE IDX   = @IDX    
    END    

		  
		  insert #hemcom_TSLBillReplaceRelation (CompanySeq, BillSeq, ReplaceRegSeq, ReplaceRegSerl, ReplaceCurAmt, ReplaceCurVAT,ReplaceDomAmt, ReplaceDomVat)
		  select @CompanySeq, b.BillSeq, a.Seq, a.Serl, CurAmt, CurVAT, curamt, curvat
		    from #tempresult as a
 left outer join #tslbill as b on b.idx = a.idx
           where a.isreplace = '1'


		   insert #TSLSalesBillRelation (CompanySeq, BillSeq, SalesSeq, SalesSerl, CurAmt, CurVAT, DomAmt, DomVAT, SlipSeq, IsSlip, LastUserSeq, LastDateTime, PgmSeq)
		   select @CompanySeq, b.BillSeq, a.SalesSeq, a.SalesSerl, CurAmt, CurVAT, curamt, curvat, 0, 0, @UserSeq, GETDATE(), @PgmSeq
		     from #tempresult as a
  left outer join #tslbill as b on b.idx = a.idx
            where a.isreplace = '0'
			union all
		  select @CompanySeq, b.BillSeq, s.salesseq, 1 as SalesSerl, sum(m.CurAmt), sum(m.CurVat), sum(m.DomAmt), sum(m.DomVat), 0, 0,  @UserSeq, GETDATE(), @PgmSeq
			from #tempresult as a
          	join hencom_TSLCloseSumReplaceMapping as m on m.CompanySeq = @CompanySeq
			                                          and m.ReplaceRegSeq = a.seq
													  and m.ReplaceRegSerl = a.serl
            join hencom_TIFProdWorkReportCloseSum as s on s.CompanySeq = @CompanySeq
			                                          and s.SumMesKey = m.SumMesKey
 left outer join #tslbill as b on b.idx = a.idx
           where a.isreplace = '1'
        group by b.BillSeq, s.salesseq
	
	      insert #TSLBillItem (CompanySeq,BillSeq,BillSerl,BillPrtDate,ItemName,Spec,Qty,Price,CurAmt,CurVAT,KorPrice,DomAmt,DomVAT,Remark,LastUserSeq,LastDateTime,PgmSeq)
		  select @CompanySeq,  
				 b.BillSeq,
				 1 as BillSerl,
				 a.BillDate,
				 '레미콘' as ItemName,
				 min(GoodItemName) + ' 외' as Spec,
				 sum(a.qty) as Qty,
				 0 as Price,
				 sum(a.curamt) as CurAmt,
				 sum(a.curvat) as CurVat,
				 0 as KorPrice,
				 sum(a.curamt) as DomAmt,
				 sum(a.curvat) as DomVat,
				 '' as Remark,
				 @UserSeq,
				 getdate(),
				 @PgmSeq
		    from #tempresult as a
 left outer join #tslbill as b on b.idx = a.idx
        group by a.idx, a.billdate,b.BillSeq



	if exists ( select 1 from #tslbill)
	begin
		begin tran
		  insert _TSLBill (companyseq, billseq, bizunit, smexpkind, billno, billdate, smbilltype, umbillkind, deptseq, EmpSeq, custseq, currseq, exrate, gwon, ho, fundarrangedate,prnreqdate, smbilling, isprint,
		                  isdate, iscust, taxno, EvidSeq, remark, accseq, vataccseq, oppaccseq, lastuserseq, lastdatetime, billid, 
						  umpriceterms,condserl,taxunit, pgmseq )
		  select companyseq, billseq, bizunit, smexpkind, billno, billdate, smbilltype, umbillkind, deptseq, EmpSeq, custseq, currseq, exrate, gwon, ho, fundarrangedate,prnreqdate, smbilling, isprint,
		                  isdate, iscust, taxno, EvidSeq, remark, accseq, vataccseq, oppaccseq, lastuserseq, lastdatetime, billid, 
						  umpriceterms,condserl,taxunit, pgmseq 
		    from #tslbill
			IF @@ERROR <> 0
			BEGIN                                  
								 
				UPDATE #CreateAllBills                                             
					SET Result        = '세금계산서 마스터 생성시 오류발생'   ,                                           
						Status        = 999                                                                               
				WHERE Status     = 0                                  
            
				SELECT * FROM #CreateAllBills   
				ROLLBACK TRAN                                 
				RETURN                              
			END		  
		  
			
			insert hemcom_TSLBillReplaceRelation (CompanySeq, BillSeq, ReplaceRegSeq, ReplaceRegSerl, ReplaceCurAmt, ReplaceCurVAT,ReplaceDomAmt, ReplaceDomVat)
            select CompanySeq, BillSeq, ReplaceRegSeq, ReplaceRegSerl, ReplaceCurAmt, ReplaceCurVAT,ReplaceDomAmt, ReplaceDomVat from  #hemcom_TSLBillReplaceRelation   
			IF @@ERROR <> 0
			BEGIN                                  
								 
				UPDATE #CreateAllBills                                             
					SET Result        = '규격대체관계 생성시 오류발생'   ,                                           
						Status        = 999                                                                               
				WHERE Status     = 0                                  
                                            
				SELECT * FROM #CreateAllBills   
				ROLLBACK TRAN                                 
				RETURN                              
			END		  

			insert _TSLSalesBillRelation (CompanySeq, BillSeq, SalesSeq, SalesSerl, CurAmt, CurVAT, DomAmt, DomVAT, SlipSeq, IsSlip, LastUserSeq, LastDateTime, PgmSeq)
			select CompanySeq, BillSeq, SalesSeq, SalesSerl, CurAmt, CurVAT, DomAmt, DomVAT, SlipSeq, IsSlip, LastUserSeq, LastDateTime, PgmSeq from #TSLSalesBillRelation
			IF @@ERROR <> 0
			BEGIN                                  
								 
				UPDATE #CreateAllBills                                             
					SET Result        = '외상매출상계 생성시 오류발생'   ,                                           
						Status        = 999                                                                               
				WHERE Status     = 0                                  
                                            
				SELECT * FROM #CreateAllBills   
				ROLLBACK TRAN                                 
				RETURN                              
			END		  

			insert _TSLBillItem (CompanySeq,BillSeq,BillSerl,BillPrtDate,ItemName,Spec,Qty,Price,CurAmt,CurVAT,KorPrice,DomAmt,DomVAT,Remark,LastUserSeq,LastDateTime,PgmSeq)
			select CompanySeq,BillSeq,BillSerl,BillPrtDate,ItemName,Spec,Qty,Price,CurAmt,CurVAT,KorPrice,DomAmt,DomVAT,Remark,LastUserSeq,LastDateTime,PgmSeq from #TSLBillItem
			IF @@ERROR <> 0
			BEGIN                                  
								 
				UPDATE #CreateAllBills                                             
					SET Result        = '세금계산서품목 생성시 오류발생'   ,                                           
						Status        = 999                                                                               
				WHERE Status     = 0                                  
                                            
				SELECT * FROM #CreateAllBills   
				ROLLBACK TRAN                                 
				RETURN                              
			END		  

---------------------- 생성데이터 확인
		 -- select m.* 
		 --   from _TSLBill as m
   --         join #tslbill as b on b.BillSeq = m.billseq
			--select m.* 
		 --   from hemcom_TSLBillReplaceRelation as m
   --         join #tslbill as b on b.BillSeq = m.billseq
			--select m.* 
		 --   from _TSLSalesBillRelation as m
   --         join #tslbill as b on b.BillSeq = m.billseq
			--select m.* 
		 --   from _TSLBillItem as m
   --         join #tslbill as b on b.BillSeq = m.billseq
-----------------------------------------
---------- 실적재집계      
		   CREATE TABLE #SSLBillSeq        
		   (   SumSeq    INT)        
      
		   INSERT  #SSLBillSeq   
		   SELECT  DISTINCT BillSeq      
			 FROM  #tslbill      
		   EXEC _SSLBillSum 'A', @CompanySeq   
---------- 실적재집계      

		commit tran
	end
---------------------------------
	select * from #CreateAllBills
RETURN
go
begin tran 
exec hencom_SLBillDataProcCreateAll @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <CustSeq>62366</CustSeq>
    <PJTSeq>0</PJTSeq>
    <IsTaxPJT>0</IsTaxPJT>
    <UMDataKind>0</UMDataKind>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <StdYM>201702</StdYM>
    <DeptSeq>49</DeptSeq>
    <BillDate>20170321</BillDate>
    <UMBillKind>8027001</UMBillKind>
    <SMBillType>8026001</SMBillType>
    <SMBilling>8027002</SMBilling>
    <VatAccSeq>115</VatAccSeq>
    <EvidSeq>10</EvidSeq>
    <OppAccSeq>18</OppAccSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511045,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032706
rollback 