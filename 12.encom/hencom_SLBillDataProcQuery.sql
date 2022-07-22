IF OBJECT_ID('hencom_SLBillDataProcQuery') IS NOT NULL 
    DROP PROC hencom_SLBillDataProcQuery
GO 

-- v2017.03.20 
/************************************************************
 설  명 - 데이터-세금계산서일괄생성_hencom : 합계조회
 작성일 - 20170125
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SLBillDataProcQuery                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle      INT,
		    @DeptSeq        INT ,
            @CustSeq        INT ,
            @StdYM          NCHAR(6)  ,
			@PJTSeq         int,
			@UMDataKind     int
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq        = DeptSeq         ,
            @CustSeq        = CustSeq         ,
            @StdYM          = StdYM           ,
			@PJTSeq         = PJTSeq          ,
			@UMDataKind     = UMDataKind
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (DeptSeq         INT ,
            CustSeq         INT ,
            StdYM           NCHAR(6),
			PJTSeq          int ,
			UMDataKind      int)

        DECLARE @EmpSeq INT
        SELECT @EmpSeq = EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq and UserSeq = @UserSeq

	
				 SELECT a.Remark,
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
                        case when PreBillExceptRegSeq is null then '0' else '1' end as UMDataKind,
						isnull(PreBillExceptRegSeq,0) as PreBillExceptRegSeq, 
                        (select empname from _tdaemp where companyseq = @CompanySeq and empseq = case isnull(inv.EmpSeq,0) when 0 then @EmpSeq else inv.EmpSeq end) as EmpName,
                        (case isnull(inv.EmpSeq,0) when 0 then @EmpSeq else inv.EmpSeq end) as EmpSeq
                        
                   into #tempresult
                   FROM hencom_VInvoiceReplaceItem    AS A  WITH(NOLOCK)         
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
		                                                  and eb.StdYM = @StdYM
														  and eb.TableSeq = a.SourceTableSeq
														  and eb.Seq = case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSeq else a.ReplaceRegSeq end
														  and eb.Serl = case a.SourceTableSeq when 1000057 then a.SumMesKey when 1268 then a.InvoiceSerl else a.ReplaceRegSerl end
         left outer join _tslinvoice as inv on inv.companyseq = @CompanySeq
		                                   and inv.InvoiceSeq = a.InvoiceSeq
                   WHERE A.CompanySeq = @CompanySeq                                       
                     AND (@CustSeq = 0 OR A.CustSeq = @CustSeq )                            
                     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )                
                     AND A.CloseCfmCode = '1'    --확정건만 조회          
                     AND (CASE WHEN A.IsBill = '1' OR ISNULL(PSM.FromSeq,0) <> 0 THEN '1' ELSE A.IsBill END) = '0'   -- 선매출연결건 제외
					 and ( @UMDataKind = 9 or case when PreBillExceptRegSeq is null then '0' else '1' end = @UMDataKind )
					 --and isnull(a.InvoiceSeq,0) <> 0
					 --and isnull(a.salesseq,0) <> 0            -- 매출발생건
					 and isnull(a.itemseq,0) <> 0
					 and a.BalCurAmt > 0
                ORDER BY AD.DispSeq ,A.WorkDate DESC  ,A.CustSeq ,A.PJTSeq,A.ItemSeq             
				--select * from #tempresult
		if @WorkingTag = 'SS1' 
        begin 
				  select CustName,
						 CustSeq,
				         BizNo,
						 PJTName,
						 PJTSeq,
                         sum(Qty) AS Qty,
						 sum(CurVAT) as CurVAT,
						 sum(CurAmt) as CurAmt,
						 sum(TotAmt) as TotAmt,
						 '1' as IsTaxPJT,
						 max(UMDataKind) as UMDataKind, 
                         max(EmpSeq) as EmpSeq
                    into #Result
				    from #tempresult 
				   where IsTaxPJT = '1'
                group by CustName,
						 CustSeq,
				         BizNo,
						 PJTName,
						 PJTSeq
				union all	
				  select CustName,
						 CustSeq,
				         BizNo,
						 null,
						 0,
                         sum(Qty) AS Qty,
						 sum(CurVAT) as CurVAT,
						 sum(CurAmt) as CurAmt,
						 sum(TotAmt) as TotAmt,
						 '0' as IsTaxPJT,
						 max(UMDataKind) as UMDataKind, 
                         max(EmpSeq) as EmpSeq
				    from #tempresult 
				   where IsTaxPJT = '0'
                group by CustName,
						 CustSeq,
				         BizNo
                
                SELECT A.*, B.EmpName
                  FROM #Result AS A 
                  LEFT OUTER JOIN _TDAEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq )
        end 
		else
        begin
				 select *
				   from #tempresult	
                  where (@PJTSeq = 0 OR PJTSeq = @PJTSeq )
			   order by custname, PJTName  , InvoiceDate                          
        end 
		
RETURN
go
exec hencom_SLBillDataProcQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>49</DeptSeq>
    <CustSeq>62366</CustSeq>
    <StdYM>201702</StdYM>
    <UMDataKind>9</UMDataKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511045,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032706