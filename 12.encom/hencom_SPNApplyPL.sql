IF OBJECT_ID('hencom_SPNApplyPL') IS NOT NULL 
    DROP PROC hencom_SPNApplyPL
GO 

-- v2017.04.25
/************************************************************
 설  명 - 데이터-손익반영사업계획_hencom : 손익적용
 작성일 - 20161114
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SPNApplyPL
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	DECLARE @MessageType	INT,
					@Status				INT,
					@Results			NVARCHAR(250),
					@IsClose nchar(1),
					@SlipUnit int,
					@PlanSeq int,
					@DeptSeq int  
  					
  CREATE TABLE #hencom_TPNPLPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLPlan'


	select @DeptSeq = DeptSeq, @PlanSeq = PlanSeq from #hencom_TPNPLPlan

	create table #tempresult (
				rownum int,
				PLPlanRegSeq int,
				SlipUnit int,
				FSItemTypeSeq int,
				FSItemSeq int,
				PlanAmt01 decimal(19,5),
				PlanAmt02 decimal(19,5),
				PlanAmt03 decimal(19,5),
				PlanAmt04 decimal(19,5),
				PlanAmt05 decimal(19,5),
				PlanAmt06 decimal(19,5),
				PlanAmt07 decimal(19,5),
				PlanAmt08 decimal(19,5),
				PlanAmt09 decimal(19,5),
				PlanAmt10 decimal(19,5),
				PlanAmt11 decimal(19,5),
				PlanAmt12 decimal(19,5),
				Remark    nvarchar(1000),
				PlanSeq   int
			)		


	--------- 차수마감체크
	select @IsClose = isnull(IsClose,'0')
	  from hencom_TPNPlan 
	 where companyseq = @CompanySeq
	   and PlanSeq = @PlanSeq

	select @IsClose = isnull(@IsClose,'0')

	if @IsClose = '1'
	begin
		UPDATE #hencom_TPNPLPlan	
		   set Result = '차수가 마감되어 수정 삭제 불가합니다.',
		       Status = 999
         where status = 0

	end
	------------------------ 차수마감체크끝
	select @SlipUnit = SlipUnit from _TDADept where CompanySeq = @CompanySeq and DeptSeq = @DeptSeq
	---------------------------------------------------------------------------------------------------   공통 처리부분

	if @PgmSeq=1031766 -- 수선비
	begin
		insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
		select row_number() over (order by accseq),
		       0,
			   @SlipUnit,
			   2,
			   accseq,
			   sum(case right(BPYm,2) when '01' then curamt else 0 end) as PlanAmt01,
			   sum(case right(BPYm,2) when '02' then curamt else 0 end) as PlanAmt02,
			   sum(case right(BPYm,2) when '03' then curamt else 0 end) as PlanAmt03,
			   sum(case right(BPYm,2) when '04' then curamt else 0 end) as PlanAmt04,
			   sum(case right(BPYm,2) when '05' then curamt else 0 end) as PlanAmt05,
			   sum(case right(BPYm,2) when '06' then curamt else 0 end) as PlanAmt06,
			   sum(case right(BPYm,2) when '07' then curamt else 0 end) as PlanAmt07,
			   sum(case right(BPYm,2) when '08' then curamt else 0 end) as PlanAmt08,
			   sum(case right(BPYm,2) when '09' then curamt else 0 end) as PlanAmt09,
			   sum(case right(BPYm,2) when '10' then curamt else 0 end) as PlanAmt10,
			   sum(case right(BPYm,2) when '11' then curamt else 0 end) as PlanAmt11,
			   sum(case right(BPYm,2) when '12' then curamt else 0 end) as PlanAmt12,
			   max(remark),
			   @PlanSeq
		  from hencom_TPNRepairInvest
         where CompanySeq = @CompanySeq
		   and DeptSeq = @DeptSeq
		   and PlanSeq = @PlanSeq
      group by accseq

  		  DELETE hencom_TPNPLPlan   --- 수선비반영분을 모두 삭제한다.
			FROM hencom_TPNPLPlan 
		   where CompanySeq  = @CompanySeq
			 and SlipUnit = @SlipUnit
			 and FSItemTypeSeq = '2' -- 계정
			 and FSItemSeq in (select accseq from _TDAAccount where CompanySeq = @CompanySeq and accno in (select minorname from _TDAUMinor where companyseq = @CompanySeq and majorseq = 1013989 ))

		IF @@ERROR <> 0  
		begin
			UPDATE #hencom_TPNPLPlan	
		       set Result = '기존 반영자료 삭제시 에러발생.',
		           Status = 999
			select * from #hencom_TPNPLPlan
			RETURN
		end



	end --------------------- 수선비 끝



	if @PgmSeq=1031856 -- 감가상각비
	begin

		insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
		select row_number() over (order by accseq),
		       0,
			   @SlipUnit,
			   2,
			   a.AccSeq,
			   sum(A.PlanAmt01 + NewPlanAmt01) as  PlanAmt01,
			   sum(A.PlanAmt02 + NewPlanAmt02) as  PlanAmt02,
			   sum(A.PlanAmt03 + NewPlanAmt03) as  PlanAmt03,
			   sum(A.PlanAmt04 + NewPlanAmt04) as  PlanAmt04,
			   sum(A.PlanAmt05 + NewPlanAmt05) as  PlanAmt05,
			   sum(A.PlanAmt06 + NewPlanAmt06) as  PlanAmt06,
			   sum(A.PlanAmt07 + NewPlanAmt07) as  PlanAmt07,
			   sum(A.PlanAmt08 + NewPlanAmt08) as  PlanAmt08,
			   sum(A.PlanAmt09 + NewPlanAmt09) as  PlanAmt09,
			   sum(A.PlanAmt10 + NewPlanAmt10) as  PlanAmt10,
			   sum(A.PlanAmt11 + NewPlanAmt11) as  PlanAmt11,
			   sum(A.PlanAmt12 + NewPlanAmt12) as  PlanAmt12,
			   max(a.Remark),
			   @PlanSeq
          from (
		        		SELECT  A.AccSeq,
								A.PlanAmt01,A.PlanAmt02,A.PlanAmt03,A.PlanAmt04,A.PlanAmt05,A.PlanAmt06,A.PlanAmt07,A.PlanAmt08,A.PlanAmt09,A.PlanAmt10,A.PlanAmt11,A.PlanAmt12,
								0 as NewPlanAmt01,0 as NewPlanAmt02,0 as NewPlanAmt03,0 as NewPlanAmt04,0 as NewPlanAmt05,0 as NewPlanAmt06,0 as NewPlanAmt07,0 as NewPlanAmt08,0 as NewPlanAmt09,0 as NewPlanAmt10,0 as NewPlanAmt11,0 as NewPlanAmt12,
								A.Remark
						  FROM  hencom_TPNDepreciation AS A WITH (NOLOCK) 
						 WHERE  A.CompanySeq = @CompanySeq
						   AND  A.PlanSeq    = @PlanSeq   
						   AND  A.DeptSeq    = @DeptSeq   
					 union all
						select  A.AccSeq,
								0 as PlanAmt01,0 as PlanAmt02,0 as PlanAmt03,0 as PlanAmt04,0 as PlanAmt05,0 as PlanAmt06,0 as PlanAmt07,0 as PlanAmt08,0 as PlanAmt09,0 as PlanAmt10,0 as PlanAmt11,0 as PlanAmt12,
								sum(case when right(BPYm,2) between '01' and '01' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12 as NewPlanAmt01,
								sum(case when right(BPYm,2) between '01' and '02' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt02,
								sum(case when right(BPYm,2) between '01' and '03' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt03,
								sum(case when right(BPYm,2) between '01' and '04' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt04,
								sum(case when right(BPYm,2) between '01' and '05' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt05,
								sum(case when right(BPYm,2) between '01' and '06' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt06,
								sum(case when right(BPYm,2) between '01' and '07' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt07,
								sum(case when right(BPYm,2) between '01' and '08' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt08,
								sum(case when right(BPYm,2) between '01' and '09' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt09,
								sum(case when right(BPYm,2) between '01' and '10' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt10,
								sum(case when right(BPYm,2) between '01' and '11' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt11,
								sum(case when right(BPYm,2) between '01' and '12' then  a.curamt else 0 end) / max(convert(int, v.ValueText)) / 12  as NewPlanAmt12,
								max(A.Remark) as Remark
						  FROM  hencom_TPNRepairInvest AS A WITH (NOLOCK) 
			   left outer join  _TDAAccount as c on c.CompanySeq = a.CompanySeq
												and c.accseq = a.accseq
			   left outer join _tdauminor as m on m.CompanySeq = a.CompanySeq
											  and m.MajorSeq = 	1014019
											  and m.MinorName = c.accno
			   left outer join _TDAUMinorValue as v on v.CompanySeq = a.CompanySeq
												   and v.MinorSeq = m.MinorSeq
												   and v.serl = 1000001
						 WHERE  A.CompanySeq = @CompanySeq
						   AND  A.PlanSeq    = @PlanSeq   
						   AND  A.DeptSeq    = @DeptSeq  
						   and  a.IsInvest = '1'  --- 투자
						   and  a.UMInvestKind = 1014021001 -- 유형투자
					  group by  A.AccSeq
                ) as a  
		group by a.AccSeq		                                           
			
  		  DELETE hencom_TPNPLPlan   --- 기존 감가상각비 반영분 모두 삭제한다.
			FROM hencom_TPNPLPlan 
		   where CompanySeq  = @CompanySeq
			 and SlipUnit = @SlipUnit
			 and FSItemTypeSeq = '2' -- 계정
			 and FSItemSeq in (select accseq from _TDAAccount where CompanySeq = @CompanySeq and accno in (select minorname from _TDAUMinor where companyseq = @CompanySeq and majorseq = 1014019 ))

		IF @@ERROR <> 0  
		begin
			UPDATE #hencom_TPNPLPlan	
		       set Result = '기존 반영자료 삭제시 에러발생.',
		           Status = 999
			select * from #hencom_TPNPLPlan
			RETURN
		end
	end ------------------- 감가상각비 끝


	if @PgmSeq=1031795 -- 제품매출수량
	begin

			declare @SalesQtySeq int,@SalesQtyTypeSeq int,  @SalesAmtSeq int, @SalesAmtTypeSeq int

			select @SalesQtySeq = MinorSort,
				   @SalesQtyTypeSeq = case remark when '계정과목' then 2 else 1 end
			  from _TDAUMinor
			 where CompanySeq = @CompanySeq
			   and minorseq = (
								select a.minorseq
								  from _TDAUMinorValue as a
								  join _TDAUMinorValue b on b.CompanySeq = a.CompanySeq
														and b.MajorSeq = a.MajorSeq
														and b.minorseq = a.MinorSeq
														and b.Serl = 1000004 
														and b.ValueSeq = 1031795   
								 where a.CompanySeq = @CompanySeq
								   and a.majorseq = 1013755
								   and a.Serl = 1000002          
								   and a.ValueText = '1'     ) 

			select @SalesAmtSeq = MinorSort,
				   @SalesAmtTypeSeq = case remark when '계정과목' then 2 else 1 end
			  from _TDAUMinor
			 where CompanySeq = @CompanySeq
			   and minorseq = (
								select a.minorseq
								  from _TDAUMinorValue as a
								  join _TDAUMinorValue b on b.CompanySeq = a.CompanySeq
														and b.MajorSeq = a.MajorSeq
														and b.minorseq = a.MinorSeq
														and b.Serl = 1000004 
														and b.ValueSeq = 1031795   
								 where a.CompanySeq = @CompanySeq
								   and a.majorseq = 1013755
								   and a.Serl = 1000002          
								   and isnull(a.ValueText,0) = '0'     ) 


			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
			select 1,
				   0,
				   @SlipUnit,
				   @SalesQtyTypeSeq,
				   @SalesQtySeq,
				   sum(case right(BPYm,2) when '01' then SalesQty else 0 end) as PlanAmt01,
				   sum(case right(BPYm,2) when '02' then SalesQty else 0 end) as PlanAmt02,
				   sum(case right(BPYm,2) when '03' then SalesQty else 0 end) as PlanAmt03,
				   sum(case right(BPYm,2) when '04' then SalesQty else 0 end) as PlanAmt04,
				   sum(case right(BPYm,2) when '05' then SalesQty else 0 end) as PlanAmt05,
				   sum(case right(BPYm,2) when '06' then SalesQty else 0 end) as PlanAmt06,
				   sum(case right(BPYm,2) when '07' then SalesQty else 0 end) as PlanAmt07,
				   sum(case right(BPYm,2) when '08' then SalesQty else 0 end) as PlanAmt08,
				   sum(case right(BPYm,2) when '09' then SalesQty else 0 end) as PlanAmt09,
				   sum(case right(BPYm,2) when '10' then SalesQty else 0 end) as PlanAmt10,
				   sum(case right(BPYm,2) when '11' then SalesQty else 0 end) as PlanAmt11,
				   sum(case right(BPYm,2) when '12' then SalesQty else 0 end) as PlanAmt12,
				   max(a.remark),
				   @PlanSeq
			  from hencom_TPNPSalesPlan as a 
			  join hencom_TPNPSalesPland as b on b.CompanySeq = a.CompanySeq
			                                 and b.PSalesRegSeq = a.PSalesRegSeq
             where A.CompanySeq = @CompanySeq
			   AND A.PlanSeq    = @PlanSeq   
			   AND A.DeptSeq    = @DeptSeq  
			   and isnull(a.itemseq ,0) <> 0

			   union all

			select 2,
				   0,
				   @SlipUnit,
				   @SalesAmtTypeSeq,
				   @SalesAmtSeq,
				   sum(case right(BPYm,2) when '01' then SalesAmt else 0 end) as PlanAmt01,
				   sum(case right(BPYm,2) when '02' then SalesAmt else 0 end) as PlanAmt02,
				   sum(case right(BPYm,2) when '03' then SalesAmt else 0 end) as PlanAmt03,
				   sum(case right(BPYm,2) when '04' then SalesAmt else 0 end) as PlanAmt04,
				   sum(case right(BPYm,2) when '05' then SalesAmt else 0 end) as PlanAmt05,
				   sum(case right(BPYm,2) when '06' then SalesAmt else 0 end) as PlanAmt06,
				   sum(case right(BPYm,2) when '07' then SalesAmt else 0 end) as PlanAmt07,
				   sum(case right(BPYm,2) when '08' then SalesAmt else 0 end) as PlanAmt08,
				   sum(case right(BPYm,2) when '09' then SalesAmt else 0 end) as PlanAmt09,
				   sum(case right(BPYm,2) when '10' then SalesAmt else 0 end) as PlanAmt10,
				   sum(case right(BPYm,2) when '11' then SalesAmt else 0 end) as PlanAmt11,
				   sum(case right(BPYm,2) when '12' then SalesAmt else 0 end) as PlanAmt12,
				   max(a.remark),
				   @PlanSeq
			  from hencom_TPNPSalesPlan as a 
			  join hencom_TPNPSalesPland as b on b.CompanySeq = a.CompanySeq
			                                 and b.PSalesRegSeq = a.PSalesRegSeq
             where A.CompanySeq = @CompanySeq
			   AND A.PlanSeq    = @PlanSeq   
			   AND A.DeptSeq    = @DeptSeq  
			   and isnull(a.itemseq ,0) <> 0

  			DELETE hencom_TPNPLPlan   --- 기존 감가상각비 반영분 모두 삭제한다.
			  FROM hencom_TPNPLPlan 
			 where CompanySeq  = @CompanySeq
			   and SlipUnit = @SlipUnit
			   and FSItemTypeSeq = @SalesQtyTypeSeq
			   and FSItemSeq = @SalesQtySeq

			IF @@ERROR <> 0  
			begin
				UPDATE #hencom_TPNPLPlan	
				   set Result = '기존 반영자료 삭제시 에러발생.',
					   Status = 999
				select * from #hencom_TPNPLPlan
				RETURN
			end

  			DELETE hencom_TPNPLPlan   --- 기존 감가상각비 반영분 모두 삭제한다.
			  FROM hencom_TPNPLPlan 
			 where CompanySeq  = @CompanySeq
			   and SlipUnit = @SlipUnit
			   and FSItemTypeSeq = @SalesAmtTypeSeq
			   and FSItemSeq = @SalesAmtSeq

			IF @@ERROR <> 0  
			begin
				UPDATE #hencom_TPNPLPlan	
				   set Result = '기존 반영자료 삭제시 에러발생.',
					   Status = 999
				select * from #hencom_TPNPLPlan
				RETURN
			end
	end  ---- 제품매출수량 끝



	if @PgmSeq=1031840 -- 상품매출수량
	begin

			declare @GoodQtySeq int,@GoodQtyTypeSeq int

			select @GoodQtySeq = MinorSort,
				   @GoodQtyTypeSeq = case remark when '계정과목' then 2 else 1 end
			  from _TDAUMinor
			 where CompanySeq = @CompanySeq
			   and minorseq = (
								select a.minorseq
								  from _TDAUMinorValue as a
								  join _TDAUMinorValue b on b.CompanySeq = a.CompanySeq
														and b.MajorSeq = a.MajorSeq
														and b.minorseq = a.MinorSeq
														and b.Serl = 1000004 
														and b.ValueSeq = 1031840   
								 where a.CompanySeq = @CompanySeq
								   and a.majorseq = 1013755
								   and a.Serl = 1000002          
								   and a.ValueText = '1'     ) 


			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
			select 1,
				   0,
				   @SlipUnit,
				   @GoodQtyTypeSeq,
				   @GoodQtySeq,
				   sum(case right(BPYm,2) when '01' then SalesQty else 0 end) as PlanAmt01,
				   sum(case right(BPYm,2) when '02' then SalesQty else 0 end) as PlanAmt02,
				   sum(case right(BPYm,2) when '03' then SalesQty else 0 end) as PlanAmt03,
				   sum(case right(BPYm,2) when '04' then SalesQty else 0 end) as PlanAmt04,
				   sum(case right(BPYm,2) when '05' then SalesQty else 0 end) as PlanAmt05,
				   sum(case right(BPYm,2) when '06' then SalesQty else 0 end) as PlanAmt06,
				   sum(case right(BPYm,2) when '07' then SalesQty else 0 end) as PlanAmt07,
				   sum(case right(BPYm,2) when '08' then SalesQty else 0 end) as PlanAmt08,
				   sum(case right(BPYm,2) when '09' then SalesQty else 0 end) as PlanAmt09,
				   sum(case right(BPYm,2) when '10' then SalesQty else 0 end) as PlanAmt10,
				   sum(case right(BPYm,2) when '11' then SalesQty else 0 end) as PlanAmt11,
				   sum(case right(BPYm,2) when '12' then SalesQty else 0 end) as PlanAmt12,
				   max(a.remark),
				   @PlanSeq
			  from hencom_TPNPSalesPlan as a 
			  join hencom_TPNPSalesPland as b on b.CompanySeq = a.CompanySeq
			                                 and b.PSalesRegSeq = a.PSalesRegSeq
             where A.CompanySeq = @CompanySeq
			   AND A.PlanSeq    = @PlanSeq   
			   AND A.DeptSeq    = @DeptSeq  
			   and isnull(a.itemseq ,0) = 0

			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
			select ROW_NUMBER() over (order by MinorSort) + (select max(rownum)from #tempresult),
				   0,
				   @SlipUnit,
				   case m1.Remark when '계정과목' then 2 else 1 end,
				   m1.MinorSort,
				   sum(case right(BPYm,2) when '01' then SalesAmt else 0 end) as PlanAmt01,
				   sum(case right(BPYm,2) when '02' then SalesAmt else 0 end) as PlanAmt02,
				   sum(case right(BPYm,2) when '03' then SalesAmt else 0 end) as PlanAmt03,
				   sum(case right(BPYm,2) when '04' then SalesAmt else 0 end) as PlanAmt04,
				   sum(case right(BPYm,2) when '05' then SalesAmt else 0 end) as PlanAmt05,
				   sum(case right(BPYm,2) when '06' then SalesAmt else 0 end) as PlanAmt06,
				   sum(case right(BPYm,2) when '07' then SalesAmt else 0 end) as PlanAmt07,
				   sum(case right(BPYm,2) when '08' then SalesAmt else 0 end) as PlanAmt08,
				   sum(case right(BPYm,2) when '09' then SalesAmt else 0 end) as PlanAmt09,
				   sum(case right(BPYm,2) when '10' then SalesAmt else 0 end) as PlanAmt10,
				   sum(case right(BPYm,2) when '11' then SalesAmt else 0 end) as PlanAmt11,
				   sum(case right(BPYm,2) when '12' then SalesAmt else 0 end) as PlanAmt12,
				   max(a.remark),
				   @PlanSeq
			  from hencom_TPNPSalesPlan as a 
			  join hencom_TPNPSalesPland as b on b.CompanySeq = a.CompanySeq
			                                 and b.PSalesRegSeq = a.PSalesRegSeq
              join _TDAUMinorValue as v1 on v1.CompanySeq = a.CompanySeq
			                            and v1.MinorSeq = a.UMSalesKind
									    and v1.serl = 1000001
              join _TDAUMinor      as m1 on m1.CompanySeq = a.CompanySeq
			                            and m1.MinorSeq = v1.ValueSeq
             where A.CompanySeq = @CompanySeq
			   AND A.PlanSeq    = @PlanSeq   
			   AND A.DeptSeq    = @DeptSeq  
			   and isnull(a.itemseq ,0) = 0
          group by case m1.Remark when '계정과목' then 2 else 1 end,
				   m1.MinorSort


			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
			select ROW_NUMBER() over (order by MinorSort) + (select max(rownum)from #tempresult),
				   0,
				   @SlipUnit,
				   case m1.Remark when '계정과목' then 2 else 1 end,
				   m1.MinorSort,
				   sum(case right(BPYm,2) when '01' then b.PurAmt else 0 end) as PlanAmt01,
				   sum(case right(BPYm,2) when '02' then b.PurAmt else 0 end) as PlanAmt02,
				   sum(case right(BPYm,2) when '03' then b.PurAmt else 0 end) as PlanAmt03,
				   sum(case right(BPYm,2) when '04' then b.PurAmt else 0 end) as PlanAmt04,
				   sum(case right(BPYm,2) when '05' then b.PurAmt else 0 end) as PlanAmt05,
				   sum(case right(BPYm,2) when '06' then b.PurAmt else 0 end) as PlanAmt06,
				   sum(case right(BPYm,2) when '07' then b.PurAmt else 0 end) as PlanAmt07,
				   sum(case right(BPYm,2) when '08' then b.PurAmt else 0 end) as PlanAmt08,
				   sum(case right(BPYm,2) when '09' then b.PurAmt else 0 end) as PlanAmt09,
				   sum(case right(BPYm,2) when '10' then b.PurAmt else 0 end) as PlanAmt10,
				   sum(case right(BPYm,2) when '11' then b.PurAmt else 0 end) as PlanAmt11,
				   sum(case right(BPYm,2) when '12' then b.PurAmt else 0 end) as PlanAmt12,
				   max(a.remark),
				   @PlanSeq
			  from hencom_TPNPSalesPlan as a 
			  join hencom_TPNPSalesPland as b on b.CompanySeq = a.CompanySeq
			                                 and b.PSalesRegSeq = a.PSalesRegSeq
              join _TDAUMinorValue as v1 on v1.CompanySeq = a.CompanySeq
			                            and v1.MinorSeq = a.UMSalesKind
									    and v1.serl = 1000002
              join _TDAUMinor      as m1 on m1.CompanySeq = a.CompanySeq
			                            and m1.MinorSeq = v1.ValueSeq
             where A.CompanySeq = @CompanySeq
			   AND A.PlanSeq    = @PlanSeq   
			   AND A.DeptSeq    = @DeptSeq  
			   and isnull(a.itemseq ,0) = 0
          group by case m1.Remark when '계정과목' then 2 else 1 end,
				   m1.MinorSort


  				  DELETE hencom_TPNPLPlan   --- 기존 상품매출수량 반영분 모두 삭제한다.
					FROM hencom_TPNPLPlan 
				   where CompanySeq  = @CompanySeq
					 and SlipUnit = @SlipUnit
					 and FSItemTypeSeq = @GoodQtyTypeSeq -- 계정
					 and FSItemSeq = @GoodQtySeq

				IF @@ERROR <> 0  
				begin
					UPDATE #hencom_TPNPLPlan	
					   set Result = '기존 반영자료 삭제시 에러발생.',
						   Status = 999
					select * from #hencom_TPNPLPlan
					RETURN
				end

  				  DELETE a   --- 기존 상품매출수량 반영분 모두 삭제한다.
					FROM hencom_TPNPLPlan as a 
				    join _TDAUMinorValue as v1 on v1.CompanySeq = a.CompanySeq
											  and v1.MajorSeq = 1013992
											  and v1.serl = 1000002
					join _TDAUMinor      as m1 on m1.CompanySeq = a.CompanySeq
											  and m1.MinorSeq = v1.ValueSeq
											  and m1.MinorSort = a.FSItemSeq
											  and case m1.Remark when '계정과목' then 2 else 1 end = a.FSItemTypeSeq   
				   where a.CompanySeq  = @CompanySeq
					 and SlipUnit = @SlipUnit

				IF @@ERROR <> 0  
				begin
					UPDATE #hencom_TPNPLPlan	
					   set Result = '기존 반영자료 삭제시 에러발생.',
						   Status = 999
					select * from #hencom_TPNPLPlan
					RETURN
				end


  				  DELETE a   --- 기존 상품매출수량 반영분 모두 삭제한다.
					FROM hencom_TPNPLPlan as a 
				    join _TDAUMinorValue as v1 on v1.CompanySeq = a.CompanySeq
											  and v1.MajorSeq = 1013992
											  and v1.serl = 1000001
					join _TDAUMinor      as m1 on m1.CompanySeq = a.CompanySeq
											  and m1.MinorSeq = v1.ValueSeq
											  and m1.MinorSort = a.FSItemSeq
											  and case m1.Remark when '계정과목' then 2 else 1 end = a.FSItemTypeSeq   
				   where a.CompanySeq  = @CompanySeq
					 and SlipUnit = @SlipUnit

				IF @@ERROR <> 0  
				begin
					UPDATE #hencom_TPNPLPlan	
					   set Result = '기존 반영자료 삭제시 에러발생.',
						   Status = 999
					select * from #hencom_TPNPLPlan
					RETURN
				end
	end

	if @PgmSeq=1031857 -- 치환율(재료비)
	begin
			create table #tmepresult2 (
				ItemSeq int null,ItemName nvarchar(200) null,ItemNo nvarchar(200) null,Spec nvarchar(200) null,ItemClassLName nvarchar(200) null,ItemClassLSeq int null,
				PrevQty decimal(19,5) null,PrevAmt decimal(19,5) null,PrevPrice decimal(19,5) null,MatItemSeq int null,PrevTotQty decimal(19,5) null,PrevTotAmt decimal(19,5) null,
				PrevAvgPrice decimal(19,5) null,Qty1 decimal(19,5) null,Amt1 decimal(19,5) null,Price1 decimal(19,5) null,
                Qty2 decimal(19,5) null,Amt2 decimal(19,5) null,Price2 decimal(19,5) null,Qty3 decimal(19,5) null,Amt3 decimal(19,5) null,Price3 decimal(19,5) null,Qty4 decimal(19,5) null,
				Amt4 decimal(19,5) null,Price4 decimal(19,5) null,Qty5 decimal(19,5) null,Amt5 decimal(19,5) null,Price5 decimal(19,5) null,Qty6 decimal(19,5) null,Amt6 decimal(19,5) null,
				Price6 decimal(19,5) null,Qty7 decimal(19,5) null,Amt7 decimal(19,5) null,Price7 decimal(19,5) null,Qty8 decimal(19,5) null,Amt8 decimal(19,5) null,Price8 decimal(19,5) null,
				Qty9 decimal(19,5) null,Amt9 decimal(19,5) null,Price9 decimal(19,5) null,Qty10 decimal(19,5) null,Amt10 decimal(19,5) null,
                Price10 decimal(19,5) null,Qty11 decimal(19,5) null,Amt11 decimal(19,5) null,Price11 decimal(19,5) null,Qty12 decimal(19,5) null,Amt12 decimal(19,5) null,Price12 decimal(19,5) null,
				TotQty decimal(19,5) null,TotAmt decimal(19,5) null,AvgPrice  decimal(19,5) null
				)

				 alter table #tmepresult2 add 
						PrevM3Qty decimal(19,5) null,
						PrevM3TotQty decimal(19,5) null,
						TotM3Qty decimal(19,5) null,
						M3Qty1 decimal(19,5) null,
						M3Qty2 decimal(19,5) null,
						M3Qty3 decimal(19,5) null,
						M3Qty4 decimal(19,5) null,
						M3Qty5 decimal(19,5) null,
						M3Qty6 decimal(19,5) null,
						M3Qty7 decimal(19,5) null,
						M3Qty8 decimal(19,5) null,
						M3Qty9 decimal(19,5) null,
						M3Qty10 decimal(19,5) null,
						M3Qty11 decimal(19,5) null,
						M3Qty12 decimal(19,5) null

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
				<DeptSeq>' + convert(nvarchar(100),@DeptSeq) + '</DeptSeq>
				<PlanSeq>' + convert(nvarchar(100),@PlanSeq) + '</PlanSeq>
			  </DataBlock1>
			</ROOT>'

			insert #tmepresult2
			exec hencom_SPNQCReplaceRatePlanResultQuery @xmlDocument=@test,@xmlFlags=2,@ServiceSeq=1510198,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031857

			delete from #tmepresult2 where itemseq = -1






			declare @MatAmtSeq int,@MatAmtTypeSeq int

			select @MatAmtSeq = MinorSort,
				   @MatAmtTypeSeq = case remark when '계정과목' then 2 else 1 end
			  from _TDAUMinor
			 where CompanySeq = @CompanySeq
			   and minorseq = (
								select a.minorseq
								  from _TDAUMinorValue as a
								 where a.CompanySeq = @CompanySeq
								    and a.majorseq = 1013755
								   and a.Serl = 1000004          
								   and a.ValueSeq = 1031857     ) 



			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)
			select 1,
				   0,
				   @SlipUnit,
				   @MatAmtTypeSeq,
				   @MatAmtSeq,
				   sum(amt1) as PlanAmt01,
				   sum(Amt2) as PlanAmt02,
				   sum(amt3) as PlanAmt03,
				   sum(amt4) as PlanAmt04,
				   sum(amt5) as PlanAmt05,
				   sum(amt6) as PlanAmt06,
				   sum(amt7) as PlanAmt07,
				   sum(amt8) as PlanAmt08,
				   sum(amt9) as PlanAmt09,
				   sum(amt10) as PlanAmt10,
				   sum(amt11) as PlanAmt11,
				   sum(amt12) as PlanAmt12,
				   '',
				   @PlanSeq
              from #tmepresult2

  		  DELETE hencom_TPNPLPlan   --- 기존 재료비 반영분 모두 삭제한다.
			FROM hencom_TPNPLPlan 
		   where CompanySeq  = @CompanySeq
			 and SlipUnit = @SlipUnit
			 and FSItemTypeSeq = @MatAmtTypeSeq -- 계정
			 and FSItemSeq = @MatAmtSeq

		IF @@ERROR <> 0  
		begin
			UPDATE #hencom_TPNPLPlan	
		       set Result = '기존 반영자료 삭제시 에러발생.',
		           Status = 999
			select * from #hencom_TPNPLPlan
			RETURN
		end
	end

	if @PgmSeq=1031995 -- 운송비변수등록(도급비)
	begin
			
			create table #tempresultTC 
            (    
                Gubun       INT, 
                ColumnA     NVARCHAR(100), 
                ColumnB     NVARCHAR(100), 
                ColumnC     NVARCHAR(100), 
                PrevPlan    DECIMAL(19,5),
                PrevSales   DECIMAL(19,5),
                PrevRate    DECIMAL(19,5),
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
				<DeptSeq>' + convert(nvarchar(100),@DeptSeq) + '</DeptSeq>
				<PlanSeq>' + convert(nvarchar(100),@PlanSeq) + '</PlanSeq>
			  </DataBlock2>
			</ROOT>'

			insert #tempresultTC
			exec hencom_SPNCostOfTransportVarSubContQueryNew @xmlDocument=@test,@xmlFlags=2,@ServiceSeq=1510143,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031995
            
			select @MatAmtSeq = MinorSort,
				   @MatAmtTypeSeq = case remark when '계정과목' then 2 else 1 end
			  from _TDAUMinor
			 where CompanySeq = @CompanySeq
			   and minorseq = (
								select a.minorseq
								  from _TDAUMinorValue as a
								 where a.CompanySeq = @CompanySeq
								    and a.majorseq = 1013755
								   and a.Serl = 1000004          
								   and a.ValueSeq = 1031995     ) 

			insert #tempresult (rownum, PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,PlanSeq)

			select 1,
				   0,
				   @SlipUnit,
				   @MatAmtTypeSeq,
				   @MatAmtSeq,
				   Mth1 as PlanAmt01,
				   Mth2 as PlanAmt02,
				   Mth3 as PlanAmt03,
				   Mth4 as PlanAmt04,
				   Mth5 as PlanAmt05,
				   Mth6 as PlanAmt06,
				   Mth7 as PlanAmt07,
				   Mth8 as PlanAmt08,
				   Mth9 as PlanAmt09,
				   Mth10 as PlanAmt10,
				   Mth11 as PlanAmt11,
				   Mth12 as PlanAmt12,
				   '',
				   @PlanSeq
			  from #tempresultTC
			 where gubun = 11

  		  DELETE hencom_TPNPLPlan   --- 기존 도급비반영분 모두 삭제한다.
			FROM hencom_TPNPLPlan 
		   where CompanySeq  = @CompanySeq
			 and SlipUnit = @SlipUnit
			 and FSItemTypeSeq = @MatAmtTypeSeq -- 계정
			 and FSItemSeq = @MatAmtSeq

		IF @@ERROR <> 0  
		begin
			UPDATE #hencom_TPNPLPlan	
		       set Result = '기존 반영자료 삭제시 에러발생.',
		           Status = 999
			select * from #hencom_TPNPLPlan
			RETURN
		end

	end






	----------------------------------------------------------  공통 반영부분
	 DECLARE @MaxSeq INT,  
			 @Count  INT   
    SELECT @Count = Count(1) FROM #tempresult   
    IF @Count >0   
    BEGIN  
		EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TPNPLPlan ','PLPlanRegSeq',@Count --rowcount

		update #tempresult
		   set PLPlanRegSeq = @MaxSeq + rownum

	end


	INSERT INTO hencom_TPNPLPlan ( CompanySeq,PLPlanRegSeq,SlipUnit,FSItemTypeSeq,FSItemSeq,PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,LastUserSeq,LastDateTime,PlanSeq) 
	SELECT @CompanySeq,PLPlanRegSeq,SlipUnit, FSItemTypeSeq, FSItemSeq, PlanAmt01,PlanAmt02,PlanAmt03,PlanAmt04,PlanAmt05,PlanAmt06,PlanAmt07,
								PlanAmt08,PlanAmt09,PlanAmt10,PlanAmt11,PlanAmt12,Remark,@UserSeq,GETDATE(),PlanSeq
		FROM #tempresult AS A   

		IF @@ERROR <> 0  
		begin
			UPDATE #hencom_TPNPLPlan	
		       set Result = '신규데이터 생성시 에러발생.',
		           Status = 999
			select * from #hencom_TPNPLPlan
			RETURN
		end




		
	SELECT * FROM #hencom_TPNPLPlan 
RETURN
go
begin tran 
exec hencom_SPNApplyPL @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>44</DeptSeq>
    <PlanSeq>3</PlanSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510197,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031995
rollback 