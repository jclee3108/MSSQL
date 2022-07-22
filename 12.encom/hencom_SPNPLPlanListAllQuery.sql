IF OBJECT_ID('hencom_SPNPLPlanListAllQuery') IS NOT NULL 
    DROP PROC hencom_SPNPLPlanListAllQuery
GO 

-- v2017.05.29 

/************************************************************
 설  명 - 데이터-사업계획조회_hencom : 조회
 작성일 - 20161108
 작성자 - 영림원
 참조sp - hencom_SACPLAdjRealListQuery  hencom_SACPLAdjGetData   hencom_SCOMFSFormMakeRawData
************************************************************/

CREATE PROC dbo.hencom_SPNPLPlanListAllQuery              
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
		    @PlanAmd        INT ,
            @PlanYear       NCHAR(4) ,
            @PlanSeq        INT ,
            @FormatSeq      INT ,
            @SlipUnit       INT ,
            @AccUnit        INT,
			@IsUseUMCostType nchar(1), 
            @BizUnit        INT 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

	SELECT  @PlanAmd        = ISNULL(PlanAmd   ,0)     ,
            @PlanYear       = ISNULL(PlanYear  ,0)     ,
            @PlanSeq        = ISNULL(PlanSeq   ,0)     ,
            @FormatSeq      = ISNULL(FormatSeq ,0)     ,
            @SlipUnit       = ISNULL(SlipUnit  ,0)     ,
            @AccUnit        = ISNULL(AccUnit   ,0)     , 
            @BizUnit        = ISNULL(BizUnit   ,0) 
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (PlanAmd         INT ,
            PlanYear        NCHAR(4) ,
            PlanSeq         INT ,
            FormatSeq       INT ,
            SlipUnit        INT ,
            AccUnit         INT ,
            BizUnit         INT )




    SELECT @IsUseUMCostType = B.IsUseUMCostType  -- 비용구분 사용여부
      FROM _TCOMFSForm AS A WITH (NOLOCK)
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq 
     where a.CompanySeq = @CompanySeq
       and a.FormatSeq = @FormatSeq 


	create table #hencom_TACPLAdj(
	    rownum int,
		companyseq int,
		AdjRegSeq int,
		StdYM nchar(6),
		--SlipUnit int,
  --      BizUnit int, 
		FSItemTypeSeq int,
		FSItemSeq int,
		AdjAmt decimal(19,5),
		OrgAmt decimal(19,5),
		Remark nvarchar(1000),
		LastUserSeq int,
		LastDateTime datetime )
    --- 여러 사업소일경우 아래 테이블에 모두 입력하고 위 테이블에 sum해서 넣는다

	create table #hencom_TACPLAdjSum(
	    rownum int,
		companyseq int,
		AdjRegSeq int,
		StdYM nchar(6),
		--SlipUnit int,
  --      BizUnit  int, 
		FSItemTypeSeq int,
		FSItemSeq int,
		AdjAmt decimal(19,5),
		OrgAmt decimal(19,5),
		Remark nvarchar(1000),
		LastUserSeq int,
		LastDateTime datetime )

------------------------------------- 실적금액처리
                                                       --------    여기를 루프돌려야 한다 다른테이블 만든 후에 그리고 합산하여 원래테이블에 넣으면 됨
    
    -- 사업소, 사업부문 조회조건 만족시키기 위한 조건 
    SELECT DISTINCT D.DSlipUnit, 1 AS Cnt
        INTO #SlipUnit_Cnt
        FROM _TDADept                     AS A WITH(NOLOCK) 
        JOIN _TACSlipUnit                 AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
        JOIN hencom_TACPLAdjSubSlipUnit   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MSlipUnit = C.SlipUnit ) 
        WHERE A.CompanySeq = @CompanySeq 
        AND ( @SlipUnit = 0 OR A.SlipUnit = @SlipUnit ) 
    
    UNION ALL 

    SELECT DISTINCT D.DSlipUnit, 1 AS Cnt
        FROM _TDADept                     AS A WITH(NOLOCK) 
        JOIN _TACSlipUnit                 AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
        JOIN hencom_TACPLAdjSubSlipUnit   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MSlipUnit = C.SlipUnit ) 
        WHERE A.CompanySeq = @CompanySeq 
        AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
          
    SELECT DSlipUnit
      INTO #SlipUnit
      FROM #SlipUnit_Cnt 
     GROUP BY DSlipUnit 
     HAVING SUM(Cnt) > 1 
    -- 사업소, 사업부문 조회조건 만족시키기 위한 조건, END 

    --select * from #SlipUnit 
    --return 


    DECLARE @PlanYearFr nchar(6), @PlanYearTo nchar(6)

	select @PlanYearFr = convert(nchar(4),convert(int,@PlanYear) - 1) + '01', @PlanYearTo = convert(nchar(4),convert(int,@PlanYear) - 1) + '12'

	

    CREATE TABLE #tmpFinancialStatement
	(
        RowNum      INT IDENTITY(0, 1),
        ThisTermItemAmt       DECIMAL(19, 5),
        ThisTermAmt           DECIMAL(19, 5),
        PrevTermItemAmt       DECIMAL(19, 5),
        PrevTermAmt           DECIMAL(19, 5),
        PrevChildAmt          DECIMAL(19, 5),
        ThisChildAmt          DECIMAL(19, 5),
        ThisReplaceFormula    NVARCHAR(1000),
        PrevReplaceFormula    NVARCHAR(1000)
	)	
	    
	EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, 0, '#tmpFinancialStatement'
	IF @@ERROR <> 0  RETURN
    

    --select * from #tmpFinancialStatement 
    --return 

    EXEC hencom_SCOMFSFormMakeRawData_AllDept @CompanySeq, @FormatSeq, @IsUseUMCostType, @AccUnit, @PlanYearFr , @PlanYearTo, '', '', '', '#tmpFinancialStatement','1', '0', '0', 0
	
    --return 
    IF @@ERROR <> 0  RETURN

    --select * from #tmpFinancialStatement
    --return 
  
    INSERT INTO #hencom_TACPLAdjSum
    SELECT ROW_NUMBER() OVER (ORDER BY a.FSItemSort) as rownum,
           @CompanySeq,
           0 as AjhRegSeq,
           @PlanYear+'12' as StdYM,
           A.FSItemTypeSeq,
           A.FSItemSeq,
           round(A.termitemamt,0) as AdjAmt,
           round(A.termitemamt,0) as OrgAmt,
           '' as Remark,
           @UserSeq,
           getdate()
      FROM #tmpFinancialStatement       AS A  
      LEFT OUTER JOIN _TCOMFSFormItem   AS C ON ( C.CompanySeq = @CompanySeq 
                                              AND A.FSItemTypeSeq = C.FSItemTypeSeq 
                                              AND A.FSItemSeq = C.FSItemSeq 
                                              AND A.UMCostType = C.UMCostType 
                                              AND C.FormatSeq = @FormatSeq 
                                                ) 
      LEFT OUTER JOIN _TDASMinor AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MajorSeq = 1035 AND C.SMFormulaCalcKind = G.MinorSeq ) 
     WHERE A.FSItemLevel in (1,2)
       and a.FSItemSeq in ( select MinorSort  from _tdauminor where CompanySeq = @CompanySeq and MajorSeq = 1013755 )
     ORDER BY a.FSItemSort
---------------------------------------------    여기를 루프돌려야 한다 끝
    
    --select* from #hencom_TACPLAdjSum 
    --return 

	INSERT INTO #hencom_TACPLAdj (rownum, CompanySeq,AdjRegSeq,StdYM,FSItemTypeSeq,FSItemSeq,AdjAmt,OrgAmt,Remark,LastUserSeq,LastDateTime)
	SELECT ROW_NUMBER() OVER (ORDER BY FSItemSeq) as rownum,
		   @CompanySeq,
		   0 as AdjRegSeq,
		   StdYM,
		   FSItemTypeSeq,
		   FSItemSeq,
		   sum(adjamt),
		   sum(orgamt),
		   '' as remark,
		   @UserSeq,
		   getdate() 
      FROM #hencom_TACPLAdjSum
     GROUP BY StdYM, FSItemTypeSeq, FSItemSeq



--------------------------------------   계획금액처리

    CREATE TABLE #tmpFinancialStatement2
    (
        RowNum      INT IDENTITY(0, 1),
        ThisTermItemAmt       DECIMAL(19, 5),
        ThisTermAmt           DECIMAL(19, 5),
        PrevTermItemAmt       DECIMAL(19, 5),
        PrevTermAmt           DECIMAL(19, 5),
        PrevChildAmt          DECIMAL(19, 5),
        ThisChildAmt          DECIMAL(19, 5),
        ThisReplaceFormula    NVARCHAR(1000),
        PrevReplaceFormula    NVARCHAR(1000)
    )	
    
    EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, 0, '#tmpFinancialStatement2'
    
    IF @@ERROR <> 0  RETURN

	alter table #tmpFinancialStatement2 add PrePlanAmt decimal(19,5) null , 
		                                    PreAmt decimal(19,5) null ,
											TotPlanAmt  decimal(19,5) null , 
                                            PlanAmt01 decimal(19,5) null , 
                                            PlanAmt02 decimal(19,5) null , 
                                            PlanAmt03 decimal(19,5) null , 
                                            PlanAmt04 decimal(19,5) null , 
                                            PlanAmt05 decimal(19,5) null , 
                                            PlanAmt06 decimal(19,5) null , 
                                            PlanAmt07 decimal(19,5) null , 
                                            PlanAmt08 decimal(19,5) null , 
                                            PlanAmt09 decimal(19,5) null , 
                                            PlanAmt10 decimal(19,5) null , 
                                            PlanAmt11 decimal(19,5) null , 
                                            PlanAmt12 decimal(19,5) null , 
											SMFormulaCalcKind int,
											Formula nvarchar(100),
											FormulaName nvarchar(1000)

    update #tmpFinancialStatement2
       set PrePlanAmt = 0,
           PreAmt = 0,
           TotPlanAmt = 0,
           PlanAmt01 = 0,
           PlanAmt02 = 0,
           PlanAmt03 = 0,
           PlanAmt04 = 0,
           PlanAmt05 = 0,
           PlanAmt06 = 0,
           PlanAmt07 = 0,
           PlanAmt08 = 0,
           PlanAmt09 = 0,
           PlanAmt10 = 0,
           PlanAmt11 = 0,
           PlanAmt12 = 0,
           SMFormulaCalcKind    = 0,
           Formula = '',
           FormulaName = ''


    UPDATE a
       SET SMFormulaCalcKind = b.SMFormulaCalcKind,
           Formula  = b.Formula,
           FormulaName  = b.FormulaName
      FROM  #tmpFinancialStatement2 as a
      JOIN  _TCOMFSFormItem         as b ON b.CompanySeq = @CompanySeq
                                        AND b.FormatSeq = @FormatSeq
                                        AND b.FSItemTypeSeq = a.FSItemTypeSeq
                                        AND b.FSItemSeq = a.FSItemSeq
                                        AND b.UMCostType = a.UMCostType
        


        SELECT A.PlanSeq, 
               A.FSItemTypeSeq, 
               A.FSItemSeq, 
               SUM(PlanAmt01) AS PlanAmt01, 
               SUM(PlanAmt02) AS PlanAmt02, 
               SUM(PlanAmt03) AS PlanAmt03, 
               SUM(PlanAmt04) AS PlanAmt04, 
               SUM(PlanAmt05) AS PlanAmt05, 
               SUM(PlanAmt06) AS PlanAmt06, 
               SUM(PlanAmt07) AS PlanAmt07, 
               SUM(PlanAmt08) AS PlanAmt08, 
               SUM(PlanAmt09) AS PlanAmt09, 
               SUM(PlanAmt10) AS PlanAmt10, 
               SUM(PlanAmt11) AS PlanAmt11, 
               SUM(PlanAmt12) AS PlanAmt12
          INTO #hencom_TPNPLPlan_Sum
          FROM hencom_TPNPLPlan AS A 
          JOIN #SlipUnit        AS B ON ( B.DSlipUnit = A.SlipUnit ) 
         WHERE A.CompanySeq = @CompanySeq 
         GROUP BY A.PlanSeq, A.FSItemTypeSeq, FSItemSeq 
         

		update  a
		   set  PlanAmt01 = b.PlanAmt01,
				PlanAmt02 = b.PlanAmt02,
				PlanAmt03 = b.PlanAmt03,
				PlanAmt04 = b.PlanAmt04,
				PlanAmt05 = b.PlanAmt05,
				PlanAmt06 = b.PlanAmt06,
				PlanAmt07 = b.PlanAmt07,
				PlanAmt08 = b.PlanAmt08,
				PlanAmt09 = b.PlanAmt09,
				PlanAmt10 = b.PlanAmt10,
				PlanAmt11 = b.PlanAmt11,
				PlanAmt12 = b.PlanAmt12,
				TotPlanAmt = b.PlanAmt01 + b.PlanAmt02 + b.PlanAmt03 + b.PlanAmt04 + b.PlanAmt05 + b.PlanAmt06 + b.PlanAmt07 + b.PlanAmt08 + b.PlanAmt09 + b.PlanAmt10 + b.PlanAmt11 + b.PlanAmt12
           from #tmpFinancialStatement2 as a 
		   join #hencom_TPNPLPlan_Sum as b on b.PlanSeq = @PlanSeq
									      and b.FSItemTypeSeq = a.FSItemTypeSeq
									      and b.FSItemSeq = a.FSItemSeq
    
        --select * From #tmpFinancialStatement2 

        --return 

		update  a
		   set  PrePlanAmt = isnull(b.PlanAmt01 + b.PlanAmt02 + b.PlanAmt03 + b.PlanAmt04 + b.PlanAmt05 + b.PlanAmt06 + b.PlanAmt07 + b.PlanAmt08 + b.PlanAmt09 + b.PlanAmt10 + b.PlanAmt11 + b.PlanAmt12,0)
           from #tmpFinancialStatement2 as a 
		   join #hencom_TPNPLPlan_Sum as b on b.PlanSeq = (select planseq from hencom_TPNPlan where CompanySeq = @CompanySeq and PlanYear = convert(nchar(4),convert(int,@PlanYear) - 1) and IsCfm = '1')
									      and b.FSItemTypeSeq = a.FSItemTypeSeq
									      and b.FSItemSeq = a.FSItemSeq


		update  a
		   set  PreAmt = b.adjamt
           from #tmpFinancialStatement2 as a 
		   join #hencom_TACPLAdj as b on b.FSItemTypeSeq = a.FSItemTypeSeq
									 and b.FSItemSeq = a.FSItemSeq


	    update #tmpFinancialStatement2
		   set smformulacalckind = 1035002 -- 트리하위합계
		  from #tmpFinancialStatement2
		 where childcnt > 0
		   and isnull(smformulacalckind,0) = 0
		   and isslip = '0'
		   and fsitemtypeseq = 2


		   



	 declare @frlevel int, @tolevel int ---------------------------------------- 트리하위집계처리 시작
     SELECT @frlevel = (SELECT max( fsitemlevel) FROM #tmpFinancialStatement2)                        
     SELECT @tolevel = 1  
     
     WHILE @frlevel > @tolevel                      
     BEGIN                        
				UPDATE #tmpFinancialStatement2                        
				   SET PlanAmt01 = case when isnull(a.PlanAmt01,0) = 0 then  b.PlanAmt01 else isnull(a.PlanAmt01,0) end,
						PlanAmt02 = case when isnull(a.PlanAmt02,0) = 0 then  b.PlanAmt02 else isnull(a.PlanAmt02,0) end,
						PlanAmt03 = case when isnull(a.PlanAmt03,0) = 0 then  b.PlanAmt03 else isnull(a.PlanAmt03,0) end,
						PlanAmt04 = case when isnull(a.PlanAmt04,0) = 0 then  b.PlanAmt04 else isnull(a.PlanAmt04,0) end,
						PlanAmt05 = case when isnull(a.PlanAmt05,0) = 0 then  b.PlanAmt05 else isnull(a.PlanAmt05,0) end,
						PlanAmt06 = case when isnull(a.PlanAmt06,0) = 0 then  b.PlanAmt06 else isnull(a.PlanAmt06,0) end,
						PlanAmt07 = case when isnull(a.PlanAmt07,0) = 0 then  b.PlanAmt07 else isnull(a.PlanAmt07,0) end,
						PlanAmt08 = case when isnull(a.PlanAmt08,0) = 0 then  b.PlanAmt08 else isnull(a.PlanAmt08,0) end,
						PlanAmt09 = case when isnull(a.PlanAmt09,0) = 0 then  b.PlanAmt09 else isnull(a.PlanAmt09,0) end,
						PlanAmt10 = case when isnull(a.PlanAmt10,0) = 0 then  b.PlanAmt10 else isnull(a.PlanAmt10,0) end,
						PlanAmt11 = case when isnull(a.PlanAmt11,0) = 0 then  b.PlanAmt11 else isnull(a.PlanAmt11,0) end,
						PlanAmt12 = case when isnull(a.PlanAmt12,0) = 0 then  b.PlanAmt12 else isnull(a.PlanAmt12,0) end,
						TotPlanAmt = case when isnull(a.TotPlanAmt,0) = 0 then  b.TotPlanAmt else isnull(a.TotPlanAmt,0) end,
						PrePlanAmt = case when isnull(a.PrePlanAmt,0) = 0 then  b.PrePlanAmt else isnull(a.PrePlanAmt,0) end,
						PreAmt     = case when isnull(a.PreAmt,0) = 0 then   b.PreAmt else isnull(a.PreAmt,0) end
					                        
				  FROM #tmpFinancialStatement2 as a,                        
				  ( SELECT parenttype, parentseq, parentumcosttype,                         
						   SUM(PlanAmt01) as PlanAmt01 ,
						   SUM(PlanAmt02) as PlanAmt02 ,
						   SUM(PlanAmt03) as PlanAmt03 ,
						   SUM(PlanAmt04) as PlanAmt04 ,
						   SUM(PlanAmt05) as PlanAmt05 ,
						   SUM(PlanAmt06) as PlanAmt06 ,
						   SUM(PlanAmt07) as PlanAmt07 ,
						   SUM(PlanAmt08) as PlanAmt08 ,
						   SUM(PlanAmt09) as PlanAmt09 ,
						   SUM(PlanAmt10) as PlanAmt10 ,
						   SUM(PlanAmt11) as PlanAmt11 ,
						   SUM(PlanAmt12) as PlanAmt12 ,
						   SUM(TotPlanAmt) as TotPlanAmt ,
						   SUM(PrePlanAmt) as PrePlanAmt,
						   sum(PreAmt) as PreAmt
					 FROM #tmpFinancialStatement2                         
					 WHERE fsitemlevel = @frlevel             
					 GROUP BY parenttype, parentseq, parentumcosttype                           
		                          
			   ) as b                        
				WHERE a.fsitemlevel = @frlevel -1                        
				  AND a.SMFormulaCalcKind = 1035002     -- 산식종류가 하위트리 합계인경우만 적용                      
				  AND a.fsitemtypeseq = b.parenttype                        
				  AND a.fsitemseq = b.parentseq 
				  AND A.umcosttype = B.parentumcosttype  
				  
				 
		                          
				SELECT @frlevel = @frlevel - 1                        
      END -------------------------------------------------------------------------------------- 트리하위집계처리 끝

	  --select 1111, fsitemtypeseq,
			--   fsitemtypename,
		 --      fsitemseq,
			--   fsitemnameprt as fsitemname,
			--   fsitemsort,
			--   smformulacalckind,
			--   formula,
			--   formulaname,
			--   fsitemlevel,
			--   preplanamt,
			--   preamt,
			--   totplanamt,
			--   planamt01,
			--   planamt02,
			--   planamt03,
			--   planamt04,
			--   planamt05,
			--   planamt06,
			--   planamt07,
			--   planamt08,
			--   planamt09,
			--   planamt10,
			--   planamt11,
			--   planamt12 from #tmpFinancialStatement2 
		 --  return



  --=====================================================================================================================
     -- :: 산식적용    START         
     --===================================================================================================================== 
	 
	 --- 산식적용전에 사용자정의코드 손익조정제외재무제표항목의 값을 1로 설정해 준다 제조원가와 매출원가 보정산식을 건너 뛰려고...
	 UPDATE #tmpFinancialStatement2                        
				   SET PlanAmt01 = 1,
						PlanAmt02 = 1,
						PlanAmt03 = 1,
						PlanAmt04 = 1,
						PlanAmt05 = 1,
						PlanAmt06 = 1,
						PlanAmt07 = 1,
						PlanAmt08 = 1,
						PlanAmt09 = 1,
						PlanAmt10 = 1,
						PlanAmt11 = 1,
						PlanAmt12 = 1,
						TotPlanAmt = 1,
						PrePlanAmt = 1
					                        
				  FROM #tmpFinancialStatement2  as a
				  join _tdauminor as b on b.CompanySeq = @CompanySeq
				                      and b.MajorSeq = 1013756
									  and b.MinorSort = a.fsitemseq
									  and case b.Remark when '계정과목' then 2 else 1 end  = a.fsitemtypeseq
				      
	           
       
     DECLARE @FSItemSeq     NVARCHAR(200),          
             @Formula       NVARCHAR(4000),          
             @CalcFSItemSeq NVARCHAR(200),          
             @Variable      NVARCHAR(200),          
             @TempAmt       DECIMAL(19,5),          
             @TempDirectAmt DECIMAL(19,5),          
             @sql           NVARCHAR(MAX)  ,			 
             @FSItemTypeSeq int,
			 @UMCostType int  ,    
			 @CalcFSItemTypeSeq int,
			 @CalcUMCostType int   ,

			 @PlanAmt01 decimal(19,5),
			 @PlanAmt02 decimal(19,5),
			 @PlanAmt03 decimal(19,5),
			 @PlanAmt04 decimal(19,5),
			 @PlanAmt05 decimal(19,5),
			 @PlanAmt06 decimal(19,5),
			 @PlanAmt07 decimal(19,5),
			 @PlanAmt08 decimal(19,5),
			 @PlanAmt09 decimal(19,5),
			 @PlanAmt10 decimal(19,5),
			 @PlanAmt11 decimal(19,5),
			 @PlanAmt12 decimal(19,5),
			 @TotPlanAmt decimal(19,5),
			 @PrePlanAmt decimal(19,5),
			 @PreAmt decimal(19,5),

			 @FormulaPlanAmt01 NVARCHAR(4000),
			 @FormulaPlanAmt02 NVARCHAR(4000),
			 @FormulaPlanAmt03 NVARCHAR(4000),
			 @FormulaPlanAmt04 NVARCHAR(4000),
			 @FormulaPlanAmt05 NVARCHAR(4000),
			 @FormulaPlanAmt06 NVARCHAR(4000),
			 @FormulaPlanAmt07 NVARCHAR(4000),
			 @FormulaPlanAmt08 NVARCHAR(4000),
			 @FormulaPlanAmt09 NVARCHAR(4000),
			 @FormulaPlanAmt10 NVARCHAR(4000),
			 @FormulaPlanAmt11 NVARCHAR(4000),
			 @FormulaPlanAmt12 NVARCHAR(4000),
			 @FormulaTotPlanAmt NVARCHAR(4000),
			 @FormulaPrePlanAmt NVARCHAR(4000),
			 @FormulaPreAmt NVARCHAR(4000)
       
    DECLARE c_Fomul CURSOR FOR           
    SELECT a.FSItemTypeSeq, a.UMCostType,  a.FSItemSeq, a.Formula 
      FROM _TCOMFSFormItem as a
      join #tmpFinancialStatement2 as b on b.fsitemtypeseq  = a.FSItemTypeSeq
		                               and b.FSItemSeq      = a.FSItemSeq
                                       and b.UMCostType     = a.UMCostType
     WHERE a.FormatSeq = @FormatSeq           
       AND a.SMFormulaCalcKind = 1035001           
       AND a.CompanySeq = @CompanySeq          
     order by b.fsitemlevel desc,  b.fsitemsort
		    
        OPEN c_Fomul          
            
        FETCH NEXT FROM c_Fomul INTO @FSItemTypeSeq,@UMCostType, @FSItemSeq, @Formula
            
        WHILE @@FETCH_status = 0          
        BEGIN        

		select @FormulaPlanAmt01 = @Formula,
				 @FormulaPlanAmt02 = @Formula,
				 @FormulaPlanAmt03 = @Formula,
				 @FormulaPlanAmt04 = @Formula,
				 @FormulaPlanAmt05 = @Formula,
				 @FormulaPlanAmt06 = @Formula,
				 @FormulaPlanAmt07 = @Formula,
				 @FormulaPlanAmt08 = @Formula,
				 @FormulaPlanAmt09 = @Formula,
				 @FormulaPlanAmt10 = @Formula,
				 @FormulaPlanAmt11 = @Formula,
				 @FormulaPlanAmt12 = @Formula,
				 @FormulaTotPlanAmt = @Formula,
				 @FormulaPrePlanAmt = @Formula,
				 @FormulaPreAmt = @Formula

		
		if isnull(@Formula,'') = ''
		begin
			FETCH NEXT FROM c_Fomul INTO @FSItemTypeSeq,@UMCostType, @FSItemSeq, @Formula 
			continue  
		end
             
        DECLARE c_Fomulin CURSOR for           
				SELECT CalcFSItemTypeSeq, CalcUMCostType,  CalcFSItemSeq, Variable           
				  FROM _TCOMFSFormItemCalc           
				 WHERE FormatSeq = @FormatSeq           
				   AND FSItemSeq = @FSItemSeq   
				   and FSItemTypeSeq = @FSItemTypeSeq
				   and UMCostType = @UMCostType        
				   AND CompanySeq = @CompanySeq  
				        
             
   		   OPEN c_Fomulin          
           
           FETCH NEXT FROM c_Fomulin INTO @CalcFSItemTypeSeq, @CalcUMCostType, @CalcFSItemSeq, @Variable          

             WHILE @@FETCH_status = 0          
             BEGIN          
				 SELECT  @PlanAmt01  = sum(PlanAmt01),
						 @PlanAmt02  = sum(PlanAmt02),
						 @PlanAmt03  = sum(PlanAmt03),
						 @PlanAmt04  = sum(PlanAmt04),
						 @PlanAmt05  = sum(PlanAmt05),
						 @PlanAmt06  = sum(PlanAmt06),
						 @PlanAmt07  = sum(PlanAmt07),
						 @PlanAmt08  = sum(PlanAmt08),
						 @PlanAmt09  = sum(PlanAmt09),
						 @PlanAmt10  = sum(PlanAmt10),
						 @PlanAmt11  = sum(PlanAmt11),
						 @PlanAmt12  = sum(PlanAmt12),
						 @TotPlanAmt  = sum(TotPlanAmt),
						 @PrePlanAmt  = sum(PrePlanAmt),
						 @PreAmt  = sum(PreAmt)
				   FROM #tmpFinancialStatement2 
				  WHERE fsitemseq = @CalcFSItemSeq 
				    and fsitemtypeseq  = @CalcFSItemTypeSeq 
                    and UMCostType = @CalcUMCostType

					 SELECT  @PlanAmt01  = isnull(@PlanAmt01,0),
						 @PlanAmt02  = isnull(@PlanAmt02,0),
						 @PlanAmt03  = isnull(@PlanAmt03,0),
						 @PlanAmt04  = isnull(@PlanAmt04,0),
						 @PlanAmt05  = isnull(@PlanAmt05,0),
						 @PlanAmt06  = isnull(@PlanAmt06,0),
						 @PlanAmt07  = isnull(@PlanAmt07,0),
						 @PlanAmt08  = isnull(@PlanAmt08,0),
						 @PlanAmt09  = isnull(@PlanAmt09,0),
						 @PlanAmt10  = isnull(@PlanAmt10,0),
						 @PlanAmt11  = isnull(@PlanAmt11,0),
						 @PlanAmt12  = isnull(@PlanAmt12,0),
						 @TotPlanAmt  = isnull(@TotPlanAmt,0),
						 @PrePlanAmt = isnull( @PrePlanAmt,0) ,  
						 @PreAmt = isnull( @PreAmt,0)


				select @FormulaPlanAmt01  = replace(@FormulaPlanAmt01,@Variable,@PlanAmt01 ),
						 @FormulaPlanAmt02  = replace(@FormulaPlanAmt02,@Variable,@PlanAmt02 ),
						 @FormulaPlanAmt03  = replace(@FormulaPlanAmt03,@Variable,@PlanAmt03 ),
						 @FormulaPlanAmt04  = replace(@FormulaPlanAmt04,@Variable,@PlanAmt04 ),
						 @FormulaPlanAmt05  = replace(@FormulaPlanAmt05,@Variable,@PlanAmt05 ),
						 @FormulaPlanAmt06  = replace(@FormulaPlanAmt06,@Variable,@PlanAmt06 ),
						 @FormulaPlanAmt07  = replace(@FormulaPlanAmt07,@Variable,@PlanAmt07 ),
						 @FormulaPlanAmt08  = replace(@FormulaPlanAmt08,@Variable,@PlanAmt08 ),
						 @FormulaPlanAmt09  = replace(@FormulaPlanAmt09,@Variable,@PlanAmt09 ),
						 @FormulaPlanAmt10  = replace(@FormulaPlanAmt10,@Variable,@PlanAmt10 ),
						 @FormulaPlanAmt11  = replace(@FormulaPlanAmt11,@Variable,@PlanAmt11 ),
						 @FormulaPlanAmt12  = replace(@FormulaPlanAmt12,@Variable,@PlanAmt12 ),
						 @FormulaTotPlanAmt  = replace(@FormulaTotPlanAmt,@Variable,@TotPlanAmt ),
						 @FormulaPrePlanAmt  = replace(@FormulaPrePlanAmt,@Variable,@PrePlanAmt ),
						 @FormulaPreAmt  = replace(@FormulaPreAmt,@Variable,@PreAmt )
				 
			 select    	 @FormulaPlanAmt01   = replace(@FormulaPlanAmt01,'--','+' ),
						 @FormulaPlanAmt02   = replace(@FormulaPlanAmt02,'--','+' ),
						 @FormulaPlanAmt03   = replace(@FormulaPlanAmt03,'--','+' ),
						 @FormulaPlanAmt04   = replace(@FormulaPlanAmt04,'--','+' ),
						 @FormulaPlanAmt05   = replace(@FormulaPlanAmt05,'--','+' ),
						 @FormulaPlanAmt06   = replace(@FormulaPlanAmt06,'--','+' ),
						 @FormulaPlanAmt07   = replace(@FormulaPlanAmt07,'--','+' ),
						 @FormulaPlanAmt08   = replace(@FormulaPlanAmt08,'--','+' ),
						 @FormulaPlanAmt09   = replace(@FormulaPlanAmt09,'--','+' ),
						 @FormulaPlanAmt10   = replace(@FormulaPlanAmt10,'--','+' ),
						 @FormulaPlanAmt11   = replace(@FormulaPlanAmt11,'--','+' ),
						 @FormulaPlanAmt12   = replace(@FormulaPlanAmt12,'--','+' ),
						 @FormulaTotPlanAmt  = replace(@FormulaTotPlanAmt,'--','+' ),
						 @FormulaPrePlanAmt  = replace(@FormulaPrePlanAmt,'--','+' ),
						 @FormulaPreAmt  = replace(@FormulaPreAmt,'--','+' )


						 
	              
			  FETCH NEXT FROM c_Fomulin INTO @CalcFSItemTypeSeq, @CalcUMCostType, @CalcFSItemSeq, @Variable            
               
         END          
             
        CLOSE c_Fomulin          
        DEALLOCATE c_Fomulin          
     ---------------------       
       
	 --   if @FSItemSeq = 708
		--begin
		--	select 1111, @FormulaPlanAmt01 ,
		--				 @FormulaPlanAmt02 ,
		--				 @FormulaPlanAmt03 ,
		--				 @FormulaPlanAmt04 ,
		--				 @FormulaPlanAmt05 ,
		--				 @FormulaPlanAmt06 ,
		--				 @FormulaPlanAmt07 ,
		--				 @FormulaPlanAmt08 ,
		--				 @FormulaPlanAmt09 ,
		--				 @FormulaPlanAmt10 ,
		--				 @FormulaPlanAmt11 ,
		--				 @FormulaPlanAmt12 ,
		--				 @FormulaTotPlanAmt,
		--				 @FormulaPrePlanAmt,
		--				 @FormulaPreAmt   
		--	select 222, * from #tmpFinancialStatement2 where fsitemtypeseq = @FSItemTypeSeq and umcosttype = @UMCostType and fsitemseq = @FSItemSeq
  --      end

      SELECT @Sql = N'UPDATE #tmpFinancialStatement2' + CHAR(13)          
     SELECT @Sql = @Sql + N'SET PlanAmt01 = case when isnull(PlanAmt01,0) = 0 then ' + @FormulaPlanAmt01 + ' else PlanAmt01 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt02 = case when isnull(PlanAmt02,0) = 0 then ' + @FormulaPlanAmt02 + ' else PlanAmt02 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt03 = case when isnull(PlanAmt03,0) = 0 then ' + @FormulaPlanAmt03 + ' else PlanAmt03 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt04 = case when isnull(PlanAmt04,0) = 0 then ' + @FormulaPlanAmt04 + ' else PlanAmt04 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt05 = case when isnull(PlanAmt05,0) = 0 then ' + @FormulaPlanAmt05 + ' else PlanAmt05 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt06 = case when isnull(PlanAmt06,0) = 0 then ' + @FormulaPlanAmt06 + ' else PlanAmt06 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt07 = case when isnull(PlanAmt07,0) = 0 then ' + @FormulaPlanAmt07 + ' else PlanAmt07 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt08 = case when isnull(PlanAmt08,0) = 0 then ' + @FormulaPlanAmt08 + ' else PlanAmt08 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt09 = case when isnull(PlanAmt09,0) = 0 then ' + @FormulaPlanAmt09 + ' else PlanAmt09 end,' + CHAR(13)          
     SELECT @Sql = @Sql + N' PlanAmt10 = case when isnull(PlanAmt10,0) = 0 then ' + @FormulaPlanAmt10 + ' else PlanAmt10 end,' + CHAR(13)      
     SELECT @Sql = @Sql + N' PlanAmt11 = case when isnull(PlanAmt11,0) = 0 then ' + @FormulaPlanAmt11 + ' else PlanAmt11 end,' + CHAR(13)      
     SELECT @Sql = @Sql + N' PlanAmt12 = case when isnull(PlanAmt12,0) = 0 then ' + @FormulaPlanAmt12 + ' else PlanAmt12 end,' + CHAR(13)      
     SELECT @Sql = @Sql + N' TotPlanAmt = case when isnull(TotPlanAmt,0) = 0 then ' + @FormulaTotPlanAmt + ' else TotPlanAmt end,' + CHAR(13)      
     SELECT @Sql = @Sql + N' PrePlanAmt = case when isnull(PrePlanAmt,0) = 0 then ' + @FormulaPrePlanAmt + ' else PrePlanAmt end,' + CHAR(13)      
     SELECT @Sql = @Sql + N' PreAmt = case when isnull(PreAmt,0) = 0 then ' + @FormulaPreAmt + ' else PreAmt end' + CHAR(13)      
     SELECT @Sql = @Sql + N' WHERE  fsitemtypeseq = ' + CONVERT(NVARCHAR(100),@FSItemTypeSeq) + CHAR(13)          
     SELECT @Sql = @Sql + N' AND UMCostType = ' + CONVERT(NVARCHAR(100),@UMCostType)    
     SELECT @Sql = @Sql + N' AND fsitemseq = ' + CONVERT(NVARCHAR(100),@FSItemSeq)         
	 
	 SET ANSI_WARNINGS OFF
	 SET ARITHIGNORE ON
	 SET ARITHABORT OFF

	

     if  isnull(@Sql,'') <> ''              
     EXEC SP_EXECUTESQL @Sql            
     --------------------          
            
      FETCH NEXT FROM c_Fomul INTO @FSItemTypeSeq,@UMCostType, @FSItemSeq, @Formula          
      END          
    CLOSE c_Fomul          
    DEALLOCATE c_Fomul         
	------------------------------------------------------------------------------   산식적용 끝


--select *
--		  from #tmpFinancialStatement


		delete from #tmpFinancialStatement2 where fsitemlevel > 2

		delete a
		  from #tmpFinancialStatement2 as a
		  join _tdauminor as b on b.CompanySeq = @CompanySeq
		                      and b.majorseq = 1013756
						 	  and b.MinorSort = a.fsitemseq
							  and case b.Remark when '계정과목' then 2 else 1 end = a.fsitemtypeseq



		EXEC _SCOMFSFormApplyStyle @CompanySeq, @FormatSeq, '#tmpFinancialStatement2', '0', '1'
		IF @@ERROR <> 0  RETURN

	
		select fsitemtypeseq,
			   fsitemtypename,
		       fsitemseq,
			   fsitemnameprt as fsitemname,
			   fsitemsort,
			   smformulacalckind,
			   formula,
			   formulaname,
			   fsitemlevel,
			   preplanamt,
			   preamt,
			   totplanamt,
			   planamt01,
			   planamt02,
			   planamt03,
			   planamt04,
			   planamt05,
			   planamt06,
			   planamt07,
			   planamt08,
			   planamt09,
			   planamt10,
			   planamt11,
			   planamt12
		  from #tmpFinancialStatement2
	order by fsitemsort



		

RETURN

go
begin tran 
exec hencom_SPNPLPlanListAllQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SlipUnit>0</SlipUnit>
    <BizUnit>3</BizUnit>
    <PlanSeq>3</PlanSeq>
    <PlanYear>2017</PlanYear>
    <PlanAmd>1</PlanAmd>
    <FormatSeq>52</FormatSeq>
    <AccUnit>1</AccUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510103,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031967
rollback 


--select *from _TDABizUnit 