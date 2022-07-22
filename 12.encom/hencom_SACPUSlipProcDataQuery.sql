IF OBJECT_ID('hencom_SACPUSlipProcDataQuery') IS NOT NULL 
    DROP PROC hencom_SACPUSlipProcDataQuery
GO 

/************************************************************            
  설  명 - 데이터-전자결재_매입전표조회_hencom : 조회            
  작성일 - 20160727            
  작성자 - 박수영            
 ************************************************************/            
CREATE PROC hencom_SACPUSlipProcDataQuery
  @xmlDocument    NVARCHAR(MAX) ,                        
  @xmlFlags     INT  = 0,                        
  @ServiceSeq     INT  = 0,                        
  @WorkingTag     NVARCHAR(10)= '',                              
  @CompanySeq     INT  = 1,                        
  @LanguageSeq INT  = 1,                        
  @UserSeq     INT  = 0,                        
  @PgmSeq         INT  = 0                     
                 
 AS                    
              
    DECLARE @docHandle  INT,            
            @SlipUnit   INT ,            
            @DateTo     NCHAR(8) ,            
            @DateFr     NCHAR(8)              
        
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                         
   SELECT  @SlipUnit   = SlipUnit    ,            
             @DateTo     = DateTo      ,            
             @DateFr     = DateFr                  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)            
    WITH (SlipUnit    INT ,            
             DateTo      NCHAR(8) ,            
             DateFr      NCHAR(8) )            
            
     CREATE TABLE #TMPResultData            
     (            
	    SortSeq         INT,            -- 순번
        OppAccSeq       INT,            -- 상대계정코드              
        OppAccName      NVARCHAR(1000),  -- 상대계정              
        CustSeq         INT,            -- 거래처                
        CustName        NVARCHAR(1000),    -- 거래처명              
        Remark          NVARCHAR(1000),      -- 비고                                               
        SupplyAmt       DECIMAL(19,5),   -- 공급가액                        
        VatAmt          DECIMAL(19,5),      -- 부가세                          
        Amt             DECIMAL(19,5),      -- 금액                
        AccSeq          INT,    -- 계정과목코드                        
        VatAccSeq       INT,    -- 부가세계정코드                   
        AccName         NVARCHAR(1000),     -- 계정과목             
        SlipSeq INT  ,        
        SlipUnit INT  ,        
        SlipUnitName    NVARCHAR(1000)         
    )            
       
      
    SELECT   SM.SlipMstSeq ,    
        CASE  WHEN SR.AccSeq IN (761,762) THEN SR.AccSeq ELSE 0 END   AS AccSeq ,--도급비(제)_지입운송,도급비(제)_용차운송      
        SR.DrAmt ,      
        CASE  WHEN SR.AccSeq IN (580) THEN SR.AccSeq ELSE 0 END   AS OppAccSeq ,      
        (SELECT RemValSeq FROM _TACSlipRem WHERE CompanySeq = 1 AND SlipSeq = SR.SlipSeq AND RemSeq = 1017) AS CustSeq ,  --관리항목_거래처      
        CASE  WHEN SR.AccSeq IN (32) THEN SR.AccSeq ELSE 0 END   AS VatAccSeq ,      
        SR.SlipUnit,      
        SR.Summary,      
        SR.SlipSeq      
    INTO #TMPSlip      
    FROM _TACSlipRow AS SR WITH(NOLOCK)       
     JOIN _TACSlip AS SM WITH(NOLOCK) ON SM.CompanySeq = SR.CompanySeq       
                                        AND SM.SlipMstSeq = SR.SlipMstSeq           
      WHERE SR.CompanySeq = @CompanySeq       
        AND (SM.AccDate BETWEEN CASE WHEN @DateFr = '' THEN SM.AccDate ELSE @DateFr END        
                   AND CASE WHEN @DateTo = '' THEN SM.AccDate ELSE @DateTo END )      
    AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
    AND SM.SlipKind = 1000004 --도급운반비정산현황_hencom     
   
 --SELECT * FROM #TMPSlip   
      
--계정과목      
    SELECT 2 as sort_seq,
	       B.OppAccSeq,      
           F.AccName AS OppAccName,      
           A.CustSeq,      
           (SELECT CustName FROM _TDACust AS B WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq =A.CustSeq ) AS CustName ,      
           A.Summary AS Remark,        
           A.DrAmt AS SupplyAmt,      
           C.DrAmt AS VatAmt, --부가세금액      
           ISNULL(A.DrAmt,0) + ISNULL(C.DrAmt,0)  AS Amt,       
           A.AccSeq,      
           C.VatAccSeq ,      
           D.AccName,      
           A.SlipSeq ,      
           A.SlipUnit,      
           (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit )AS SlipUnitName      
    INTO #TMP_PUSubContrCalc      
    FROM (      
        SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(AccSeq,0) <> 0       
        ) AS A      
    LEFT OUTER JOIN     --상대계정      
        (SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(OppAccSeq,0) <> 0      
        ) AS B ON B.CustSeq = A.CustSeq  AND B.SlipMstSeq = A.SlipMstSeq    
    LEFT OUTER JOIN     --부가세계정      
        (SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(VatAccSeq,0) <> 0      
        ) AS C ON C.CustSeq = A.CustSeq  AND C.SlipMstSeq = A.SlipMstSeq    
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON F.CompanySeq = @CompanySeq AND F.AccSeq = B.OppAccSeq      
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.AccSeq = A.AccSeq        
          
  
    CREATE TABLE #TMP_ACC_DATA            
    (            
        IDX_NO         INT IDENTITY,              
        SourceSeq      INT,              
        SourceSerl     INT,              
        SourceType     NCHAR(1)          
    )    
      
    INSERT INTO #TMP_ACC_DATA   
    SELECT  DISTINCT              
            A.SourceSeq         AS SourceSeq   , -- 원천순번              
            A.SourceSerl        AS SourceSerl  ,              
            A.SourceType        AS SourceType               
  
    FROM _TPUBuyingAcc AS A WITH(NOLOCK)           
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
    JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
    LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.CustSeq = A.CustSeq              
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq     
             
    WHERE A.CompanySeq = @CompanySeq            
    AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
    AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
    AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )      
--and A.BuyingAccSeq = 37974  
--  
--select * from #TMP_ACC_DATA  
--return  
   -- Payment 원천담기      
     -- PaymentNo를 가져오기 위한 로직 추가               
    CREATE TABLE #Tmp_Payment              
    (              
        IDX_NO         INT ,              
        SourceSeq      INT,              
        SourceSerl     INT,              
        SourceType     NCHAR(1),              
          PaymentNo      NVARCHAR(100),               
        PaymentSeq     INT              
    )              
    CREATE TABLE #TMP_SOURCETABLE             
    (            
        IDOrder INT,             
        TABLENAME   NVARCHAR(100)            
    )       
   -- 원천 데이터 테이블                  
    CREATE TABLE #TCOMSourceTracking             
    (            
        IDX_NO INT,                         
          IDOrder INT,                         
      Seq  INT,                        
        Serl  INT,                    
        SubSerl     INT,                          
        Qty    DECIMAL(19, 5),              
        STDQty  DECIMAL(19, 5),             
        Amt  DECIMAL(19, 5),             
        VAT   DECIMAL(19, 5)            
    )  
      
    INSERT INTO #Tmp_Payment            
    SELECT IDX_NO    ,       
            SourceSeq ,             
   SourceSerl ,            
            SourceType ,            
            '', 0            
    FROM #TMP_ACC_DATA            
    WHERE SourceType = '1'    
     
--   select * from #Tmp_Payment  
   -------납품 원천 담기---------------          
            
  INSERT #TMP_SOURCETABLE                 
  SELECT 1, '_TPUDelvItem'                    
                     
  EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#Tmp_Payment','SourceSeq', 'SourceSerl',''                
           
    SELECT A.IDX_NO ,                 
           I.DelvSeq,          
           I.DelvSerl,          
           I.MakerSeq          
      INTO #TMP_DelvItem          
      FROM #TCOMSourceTracking AS A                 
            JOIN _TPUDelv      AS C WITH(NOLOCK) ON C.CompanySeq  =@CompanySeq AND A.Seq  = C.DelvSeq                 
           JOIN _TPUDelvItem  AS I WITH(NOLOCK) ON I.CompanySeq  =@CompanySeq AND A.Seq = I.DelvSeq AND A.Serl = I.DelvSerl            
     WHERE ISNULL(C.IsReturn, '') <> '1' -- 2011. 3. 3 hkim 추가 ; 반품건은 중복해서 납품 코드를 가져올수 있다.           
  
--select * from #TMP_DelvItem  
--return  
    --select * from #TMP_PUSubContrCalc      
    --return      

    INSERT #TMPResultData (SortSeq, OppAccSeq , OppAccName, CustSeq ,CustName ,Remark ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName,SlipSeq ,SlipUnit,SlipUnitName)            
     SELECT     
	     A.OppAccSeq        As SortSeq,            
         A.OppAccSeq        AS OppAccSeq,   -- 상대계정코드              
         F.AccName          AS OppAccName,  -- 상대계정              
         A.CustSeq          AS CustSeq,     -- 거래처                
         CASE WHEN ISNULL(A.CustSeq,0) = 0 THEN A.CustText ELSE B.CustName  END  AS CustName,    -- 거래처명                      
         SR.Summary ,                                           
         A.SupplyAmt        AS SupplyAmt,   -- 공급가액                        
         A.VatAmt           AS VatAmt,      -- 부가세                          
        ISNULL(A.SupplyAmt,0) + ISNULL(A.VatAmt,0)  AS Amt,         -- 금액                
         A.AccSeq           AS AccSeq,      -- 계정과목코드                        
         A.VatAccSeq        AS VatAccSeq,   -- 부가세계정코드                   
         D.AccName          AS AccName,     -- 계정과목              
         AA.SlipSeq    ,        
         SR.SlipUnit,        
           (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --전표관리단위             
    FROM _TARUsualCostAmt         AS A WITH(NOLOCK)               
    LEFT OUTER JOIN _TARUsualCost AS AA WITH(NOLOCK) ON A.CompanySeq = AA.CompanySeq         
                                    AND A.UsualCostSeq = AA.UsualCostSeq         
                                    AND AA.SlipSeq IS NOT NULL            
    JOIN _TACSlipRow AS SR WITH(NOLOCK) ON AA.SlipSeq = SR.SlipSeq         
                        AND AA.CompanySeq = SR.CompanySeq            
    LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq              
      LEFT OUTER JOIN _TDAEvid    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EvidSeq = C.EvidSeq              
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.AccSeq = D.AccSeq              
      LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.VatAccSeq = E.AccSeq              
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq              
        LEFT  OUTER JOIN _TARCostAcc AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  AND A.CostSeq = G.CostSeq              
    LEFT OUTER JOIN _TDAAccountRemValue AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq AND G.RemSeq = H.RemSeq AND A.RemValSeq = H.RemValueSerl            
    LEFT OUTER JOIN _TDAEmp AS I WITH(NOLOCK) ON A.CompanySeq =  I.CompanySeq AND A.EmpSeq = I.EmpSeq            
	LEFT OUTER JOIN _TDADept AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq AND A.DeptSeq = J.DeptSeq            
    LEFT OUTER JOIN _TDACCtr AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CCtrSeq = K.CCtrSeq            
    WHERE  (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)            
    AND ( AA.RegDate BETWEEN CASE WHEN @DateFr = '' THEN AA.RegDate ELSE @DateFr END              
    AND CASE WHEN @DateTo = '' THEN AA.RegDate ELSE @DateTo END  )       
        
	UNION ALL    

	SELECT	1 as SortSeq
	,       A.OppAccSeq
	,		A.OppAccName
	,		A.CustSeq
	,		A.CustName
	,		A.Summary
	,		sum(a.PuAmt) as PuAmt
	,		sum(a.PuVat) as PuVat
	,		sum(a.TotPuAmt) as TotPuAmt
	,		a.accseq
	,		a.vataccseq
	,		a.accname
	,		a.SlipSeq
	,		A.SlipUnit
	,		A.SlipUnitName
	FROM	(
		SELECT	A.AntiAccSeq       AS OppAccSeq    -- 상대계정코드
		,		F.AccName          AS OppAccName   -- 상대계정
		,		A.CustSeq          AS CustSeq      -- 거래처
		,		BC.CustName        AS CustName     -- 거래처명
		,		PDS.ProdDistirct   AS Summary
		,		DVA.PuAmt as PuAmt
		,		DVA.PuVat as PuVat
		,		DVA.PuAmt + DVA.PuVat As TotPuAmt,
				A.AccSeq           AS AccSeq,    -- 계정과목코드                        
				A.VatAccSeq        AS VatAccSeq  -- 부가세계정코드                   
		,       CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' 
					ELSE ( SELECT ISNULL(MinorName,'') 
							 FROM _TDAUMinor WITH(NOLOCK)   
							WHERE CompanySeq = L.CompanySeq AND MinorSeq = L.ValueSeq ) END + '(' +   -- 품목대분류  
		--        CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' 
					--ELSE ( SELECT ISNULL(MinorName,'')   
		--                     FROM _TDAUMinor WITH(NOLOCK)   
		--                    WHERE CompanySeq = K.CompanySeq AND MinorSeq = K.ValueSeq ) END AS ItemClassMName,  -- 품목중분류
			   ISNULL(H.MinorName,'') + ')'      AS AccName, -- 품목소분류
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --전표관리단위       
		FROM	_TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS BC WITH(NOLOCK) ON BC.CompanySeq = A.CompanySeq AND BC.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl
		LEFT OUTER JOIN hencom_TPUPurchaseArea AS PDS WITH(NOLOCK) ON DVA.ProdDistrictSeq = PDS.ProdDistrictSeq
		  LEFT OUTER JOIN _TDAItemClass		AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND  B.UMajorItemClass IN (2001,2004) ) 
		  LEFT OUTER JOIN _TDAUMinor	    AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq )
		  LEFT OUTER JOIN _TDAUMinorValue	AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
		  LEFT OUTER JOIN _TDAUMinorValue	AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )
		WHERE A.CompanySeq = @CompanySeq
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )

		  UNION ALL

		SELECT	A.AntiAccSeq       AS OppAccSeq    -- 상대계정코드
		,		F.AccName          AS OppAccName   -- 상대계정
		,		A.CustSeq          AS CustSeq      -- 거래처
		,		BC.CustName        AS CustName     -- 거래처명
		,		PDS.ProdDistirct   AS Summary
		,		DVA.DeliChargeAmt as PuAmt
		,		DVA.DeliChargeVat as PuVat
		,		DVA.DeliChargeAmt + DVA.DeliChargeVat As TotPuAmt,
				A.AccSeq           AS AccSeq,    -- 계정과목코드                        
				A.VatAccSeq        AS VatAccSeq  -- 부가세계정코드                   
		,       CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' 
					ELSE ( SELECT ISNULL(MinorName,'') 
							 FROM _TDAUMinor WITH(NOLOCK)   
							WHERE CompanySeq = L.CompanySeq AND MinorSeq = L.ValueSeq ) END + '(' +   -- 품목대분류  
		--        CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' 
					--ELSE ( SELECT ISNULL(MinorName,'')   
		--                     FROM _TDAUMinor WITH(NOLOCK)   
		--                    WHERE CompanySeq = K.CompanySeq AND MinorSeq = K.ValueSeq ) END AS ItemClassMName,  -- 품목중분류
			   ISNULL(H.MinorName,'') + ')'      AS AccName, -- 품목소분류
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --전표관리단위       
		FROM	_TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS BC WITH(NOLOCK) ON BC.CompanySeq = A.CompanySeq AND BC.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl
		LEFT OUTER JOIN hencom_TPUPurchaseArea AS PDS WITH(NOLOCK) ON DVA.ProdDistrictSeq = PDS.ProdDistrictSeq
		  LEFT OUTER JOIN _TDAItemClass		AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND  B.UMajorItemClass IN (2001,2004) ) 
		  LEFT OUTER JOIN _TDAUMinor	    AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq )
		  LEFT OUTER JOIN _TDAUMinorValue	AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
		  LEFT OUTER JOIN _TDAUMinorValue	AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )
		WHERE A.CompanySeq = @CompanySeq
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )
		  AND DVA.DeliCustSeq <> 0

		UNION ALL

		SELECT  A.AntiAccSeq       AS OppAccSeq,  -- 상대계정코드              
				F.AccName          AS OppAccName,  -- 상대계정              
				A.CustSeq          AS CustSeq,   -- 거래처                
				B.CustName         AS CustName,  -- 거래처명     
				SR.Summary ,        
				-- 1.구매외주입고정산처리 표준납품프로세스 --> 상품의 전표처리   
				-- 2.구매외주입고정산처리_HNCOM 사이트납품프로세스-- 상품이외 전표처리   
				-- 전자결재에서는 모두 조회되어야 하기 때문에 사이트테이블(hencom_TPUDelvItemAdd) 데이터 존재유무로 금액을 구분해서 조회한다.                       
				case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end  AS PuAmt,        -- 매입금액                          
				case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end AS PuVat,        -- 매입부가세     
				ISNULL(case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end,0)  + ISNULL(case when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end ,0)  AS TotPuAmt,                
				A.AccSeq           AS AccSeq,   -- 계정과목코드                        
				A.VatAccSeq        AS VatAccSeq,  -- 부가세계정코드                   
				'감액'          AS AccName,   -- 계정과목(D.AccName)
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --전표관리단위         
		FROM _TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		LEFT OUTER JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl              
		WHERE A.CompanySeq = @CompanySeq            
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )
		  AND DVA.DelvSeq is Null AND A.AccSeq = 47
	) as a
	GROUP BY A.OppAccSeq
	,		A.OppAccName
	,		A.CustSeq
	,		A.CustName
	,		A.Summary
	,		a.accseq
	,		a.vataccseq
	,		a.accname
	,		a.slipseq
	,		A.SlipUnit
	,		A.SlipUnitName
  
	UNION ALL --WL사용등록(정산처리)    

		SELECT  2 as SortSeq,
		        A.OppAccSeq     AS OppAccSeq,   -- 상대계정코드              
				F.AccName       AS OppAccName,  -- 상대계정              
				CAR.CustSeq,      
				CAR.CustName,                
				  SR.Summary ,                                             
				ISNULL(M.ContrAmt,0) + ISNULL(M.OTAmt,0) + ISNULL(M.AddPayAmt,0) - ISNULL(M.DeductionAmt,0)    AS SupplyAmt, -- 공급가액                        
				M.CurVAT              AS VatAmt,      -- 부가세                          
				ISNULL(M.ContrAmt,0) + ISNULL(M.OTAmt,0) + ISNULL(M.AddPayAmt,0) - ISNULL(M.DeductionAmt,0) + ISNULL(M.CurVAT ,0)  AS Amt,-- 금액                
				A.AccSeq           AS AccSeq,      -- 계정과목코드                        
				11090501        AS VatAccSeq,   -- 부가세계정코드                   
				B.AccName          AS AccName,     -- 계정과목              
				M.SlipSeq    ,        
				SR.SlipUnit,        
				(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = SR.CompanySeq AND SlipUnit = SR.SlipUnit ) AS SlipUnitName --전표관리단위      
		   FROM hencom_TPUSubContrWL  AS M WITH (NOLOCK)       
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = M.CompanySeq       
											AND SR.SlipSeq = M.SlipSeq       
		LEFT OUTER JOIN _TARCostAcc AS A WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq       
										 AND A.CostSeq = M.CostSeq      
		LEFT OUTER JOIN _TDAAccount AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq       
									 AND A.AccSeq = B.AccSeq        
		  LEFT OUTER JOIN _TDAAccountRem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq       
										 AND A.RemSeq =  C.RemSeq          
		LEFT OUTER JOIN _TDAAccountRemValue AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq       
											 AND A.RemSeq = D.RemSeq        
											 AND A.RemValSeq = D.RemValueSerl        
		LEFT OUTER JOIN _TDASMinor AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySEq       
									 AND A.SMKindSeq = E.MinorSeq        
		LEFT OUTER JOIN _TDAAccount AS F WITH (NOLOCK) ON A.CompanySeq = F.CompanySeq       
										 AND A.OppAccSeq = F.AccSeq        
		LEFT OUTER JOIN hencom_VPUContrCarInfo AS CAR WITH (NOLOCK) ON CAR.CompanySeq = M.CompanySeq      
													AND CAR.SubContrCarSeq = M.SubContrCarSeq       
													AND M.WLDate BETWEEN CAR.StartDate AND CAR.EndDate      
      
		WHERE M.CompanySeq= @CompanySeq      
		AND (M.WLDate BETWEEN CASE WHEN @DateFr = '' THEN M.WLDate ELSE @DateFr END        
					 AND CASE WHEN @DateTo = '' THEN M.WLDate ELSE @DateTo END )      
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)
      
	UNION ALL --도급운반비정산현황_hencom      

    SELECT  2 as SortSeq,
	        A.OppAccSeq,      
            A.OppAccName,      
            A.Accseq AS CustSeq,      
            (case when A.Accseq = 761 then '자차' when A.Accseq = 762 Then '용차' End) as CustName ,      
            (case when A.Accseq = 761 then '믹서자차운송비(자차)' when A.Accseq = 762 Then '믹서자차운송비(용차)' End) as Remark,      
            sum(A.SupplyAmt) as SupplyAmt,      
            sum(A.VatAmt) as VatAmt, --부가세금액      
            sum(A.Amt) as Amt,       
            A.AccSeq,      
            A.VatAccSeq ,      
            A.AccName,      
            A.Accseq as SlipSeq ,      
            A.SlipUnit,      
            A.SlipUnitName      
    FROM	#TMP_PUSubContrCalc AS A
	Group by A.OppAccSeq,      
            A.OppAccName,      
            A.Accseq,
			A.VatAccSeq,
			A.AccName,
            A.SlipUnit,
            A.SlipUnitName
    
    /*
	UNION ALL

	--SELECT	a.OppAccSeq as SortSeq
	--,		a.OppAccSeq
	--,		a.OppAccName
	SELECT	107 as SortSeq
	,		107 as OppAccSeq
	,		'미지급금_업체' as OppAccName
	,		0 as CustSeq
	,		(CASE a.IsOwn WHEN '0' THEN '자가주유소' ELSE '' END) as CustName
	,		a.UmCarClassName as Remark
	,		sum(a.TotalOutAmt) as SupplyAmt
	,		sum(a.TotalOutVat) as VatAmt
	,		sum(a.TotalOutSumAmt) as Amt
	,		a.CalAccSeq as AccSeq
	,		0 as VatAccSeq
	,		a.CalAccName as AccName
	,		a.SlipSeq
	,		a.SlipUnit as SlipUnit
	,		(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit ) AS SlipUnitName
	FROM	(
		  SELECT   A.FuelCalcYM
				  ,A.DeptSeq
				  ,B.DeptName
				  ,A.SubContrCarSeq   
				  ,ISNULL(A.IsOwn, '0') AS IsOwn          
				  ,E.MinorName AS UMCarClassName
				  ,D.CarNo
				  ,CASE WHEN ISNULL(A.SlipSeq, 0) = 0 THEN '0' ELSE '1' END AS IsSlip    --전표처리여부 
				  ,A.TotalRealDistance
				  ,A.TotalOutQty
				  ,A.TotalOutAmt
				  ,A.ApplyPrice AS RealPrice                  -- 실단가(ℓ)
				  ,A.ApplyPrice                               -- 적용단가(공제)
				  ,A.RealMileage                              -- 실적연비
				  ,A.StdMileage                               -- 기준연비
				  ,A.RefStdMileage
				  ,A.CurAmt
				  ,I.AccName         AS OppAccName   -- 상대계정              
				  ,H.AccName         AS VatAccName
				  ,G.AccName         AS CalAccName
				  ,F.EvidName        AS EvidName
				  ,A.OppAccSeq
				  ,A.VatAccSeq
				  ,A.CalAccSeq
				  ,A.EvidSeq
				  ,A.SlipSeq
				  ,S.SlipID               AS SlipID    -- 전표번호
				   -- 2016.02.03   추가
				  ,A.TotalOutAmt * 0.1 AS TotalOutVat                         -- 주유부가세
				  ,A.TotalOutAmt + (A.TotalOutAmt * 0.1) AS TotalOutSumAmt    -- 주유합계금액
				  --------------추가컬럼by박수영2016.04.29
				 ,A.STDTotOutQty
				 ,A.SubStdMileage
				 ,A.SubOilAmt
				 ,A.DiffQty
				 ,A.RefTotAmt
				 ,A.RefOppAccSeq
				 ,A.RefVatAccSeq
				 ,A.RefCalAccSeq
				 ,A.RefEvidSeq
				 ,A.Remark
				 ,A.RefStdPrice
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefOppAccSeq) AS RefOppAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefVatAccSeq) AS RefVatAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefCalAccSeq) AS RefCalAccName
				 ,(SELECT EvidName FROM _TDAEvid   WHERE CompanySeq = @CompanySeq AND EvidSeq = A.RefEvidSeq) AS RefEvidName
				 ,A.RetroAmt AS RetroAmt -- 소급적용(유류)
				 ,S.SlipUnit
			 FROM hencom_TPUFuelCalc AS A WITH (NOLOCK) 
			LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 
													  AND B.DeptSeq = A.DeptSeq
			LEFT OUTER JOIN hencom_TPUSubContrCar AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq 
																   AND D.SubContrCarSeq = A.SubContrCarSeq
			LEFT OUTER JOIN _TDAUMinor AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq 
									  AND E.MinorSeq = D.UMCarClass
			   AND E.MajorSeq = 8030   
			JOIN _TACSlipRow AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq AND A.SlipSeq = S.SlipSeq AND S.SlipUnit = @SlipUnit
			 LEFT OUTER JOIN _TDAEvid    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.EvidSeq = F.EvidSeq    
			LEFT OUTER JOIN _TDAAccount AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CalAccSeq = G.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.VatAccSeq = H.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.OppAccSeq = I.AccSeq   
			WHERE A.CompanySeq   = @CompanySeq
			 --AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
			AND (A.FuelCalcYM = SUBSTRING(@DateFr, 1, 6)) 
			AND ISNULL(A.SlipSeq,0) <> 0
	) A
	Group by (CASE a.IsOwn WHEN '0' THEN 3 ELSE a.OppAccSeq END)
	,		a.OppAccSeq
	,		a.OppAccName
	,		(CASE a.IsOwn WHEN '0' THEN '자가주유소' ELSE '' END)
	,		a.UmCarClassName
	,		a.CalAccSeq
	,		a.CalAccName
	,		a.SlipSeq
	,		a.SlipUnit
    */
	UNION ALL

	SELECT	a.RefOppAccSeq SortSeq
	,		a.RefOppAccSeq
	,		a.RefOppAccName
	,		0 as CustSeq
	,		(CASE SIGN(sum(a.RefTotAmt)) WHEN 1 THEN '유류환급' WHEN -1 THEN '유류공제' END) as CustName
	,		A.FuelCalcYM + (CASE SIGN(sum(a.RefTotAmt)) WHEN 1 THEN ' 유류환급' WHEN -1 THEN ' 유류공제' END) as Remark
	,		sum(a.RefTotAmt) as SupplyAmt
	,		sum(0) as VatAmt
	,		sum(a.RefTotAmt) as Amt
	,		a.RefCalAccSeq as AccSeq
	,		0 as VatAccSeq
	,		a.RefCalAccName as AccName
	,		a.SlipSeq
	,		a.SlipUnit as SlipUnit
	,		(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit ) AS SlipUnitName
	FROM	(
		  SELECT   A.FuelCalcYM
				  ,A.DeptSeq
				  ,B.DeptName
				  ,A.SubContrCarSeq   
				  ,ISNULL(A.IsOwn, '0') AS IsOwn          
				  ,E.MinorName AS UMCarClassName
				  ,D.CarNo
				  ,CASE WHEN ISNULL(A.SlipSeq, 0) = 0 THEN '0' ELSE '1' END AS IsSlip    --전표처리여부 
				  ,A.TotalRealDistance
				  ,A.TotalOutQty
				  ,A.TotalOutAmt
				  ,A.ApplyPrice AS RealPrice                  -- 실단가(ℓ)
				  ,A.ApplyPrice                               -- 적용단가(공제)
				  ,A.RealMileage                              -- 실적연비
				  ,A.StdMileage                               -- 기준연비
				  ,A.RefStdMileage
				  ,A.CurAmt
				  ,I.AccName         AS OppAccName   -- 상대계정              
				  ,H.AccName         AS VatAccName
				  ,G.AccName         AS CalAccName
				  ,F.EvidName        AS EvidName
				  ,A.OppAccSeq
				  ,A.VatAccSeq
				  ,A.CalAccSeq
				  ,A.EvidSeq
				  ,A.SlipSeq
				  ,S.SlipID               AS SlipID    -- 전표번호
				   -- 2016.02.03   추가
				  ,A.TotalOutAmt * 0.1 AS TotalOutVat                         -- 주유부가세
				  ,A.TotalOutAmt + (A.TotalOutAmt * 0.1) AS TotalOutSumAmt    -- 주유합계금액
				  --------------추가컬럼by박수영2016.04.29
				 ,A.STDTotOutQty
				 ,A.SubStdMileage
				 ,A.SubOilAmt
				 ,A.DiffQty
				 ,A.RefTotAmt
				 ,A.RefOppAccSeq
				 ,A.RefVatAccSeq
				 ,A.RefCalAccSeq
				 ,A.RefEvidSeq
				 ,A.Remark
				 ,A.RefStdPrice
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND  AccSeq = A.RefOppAccSeq) AS RefOppAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefVatAccSeq) AS RefVatAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefCalAccSeq) AS RefCalAccName
				 ,(SELECT EvidName FROM _TDAEvid   WHERE CompanySeq = @CompanySeq AND EvidSeq = A.RefEvidSeq) AS RefEvidName
				 ,A.RetroAmt AS RetroAmt -- 소급적용(유류)
				 ,S.SlipUnit
			 FROM hencom_TPUFuelCalc AS A WITH (NOLOCK) 
			LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 
													  AND B.DeptSeq = A.DeptSeq
			LEFT OUTER JOIN hencom_TPUSubContrCar AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq 
																   AND D.SubContrCarSeq = A.SubContrCarSeq
			LEFT OUTER JOIN _TDAUMinor AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq 
									  AND E.MinorSeq = D.UMCarClass
			   AND E.MajorSeq = 8030   
			JOIN _TACSlipRow AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq AND A.SlipSeq = S.SlipSeq AND S.SlipUnit = @SlipUnit
			 LEFT OUTER JOIN _TDAEvid    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.EvidSeq = F.EvidSeq    
			LEFT OUTER JOIN _TDAAccount AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CalAccSeq = G.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.VatAccSeq = H.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.OppAccSeq = I.AccSeq   
			WHERE A.CompanySeq   = @CompanySeq
			 --AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
			AND (A.FuelCalcYM = SUBSTRING(@DateFr, 1, 6)) 
			AND ISNULL(A.RefCalAccSeq,0) <> 0
	) A
	Group by (CASE a.IsOwn WHEN '0' THEN 2 ELSE 9 END)
	,		a.RefOppAccSeq
	,		a.RefOppAccName
	,		(CASE a.IsOwn WHEN '0' THEN '' ELSE '' END)
	,		A.FuelCalcYM
	,		a.RefCalAccSeq
	,		a.RefCalAccName
	,		a.SlipSeq
	,		a.SlipUnit

	UPDATE #TMPResultData SET SortSeq = 2 WHERE OppAccSeq = 580 -- 미지급금_도급비 순서 변경

    --select * from #TMPResultData return  
--대체전표일괄처리_hncom 화면 조회결과를 담을 임시테이블 생성.
    CREATE TABLE #TMPBSSlipData 
    (        
        SlipKind INT  --전표분개유형내부코드        
        ,SlipKindName NVARCHAR(200)  --전표분개유형(마스터)        
        ,SlipMstID NVARCHAR(200) --기표번호(전표마스터번호)        
        ,SetSlipNo NVARCHAR(200)--전표번호(마스터 승인일련번호)        
        ,RegEmpName NVARCHAR(200)--기표자(마스터)        
        ,RegAccDate NVARCHAR(8) --기표일(마스터)        
        ,SlipUnitName NVARCHAR(200)--전표관리단위        
        ,SlipMstSeq INT--전표마스터내부코드        
        ,SlipUnit INT--전표관리단위코드        
        ,RowNo NVARCHAR(200) --행번호        
        ,SlipID NVARCHAR(200)--전표기표번호        
        ,AccName NVARCHAR(200)--계정과목        
        ,AccSeq INT       
        ,DrAmt DECIMAL(19,5) --차변금액        
        ,SlipSeq INT --전표내부코드        
        ,CrAccName NVARCHAR(200)        
        ,CrAmt    DECIMAL(19,5)    
        ---------------------1        
 ,RemSeq1   INT           
        ,IsDrEss1   NCHAR(1)      
        ,IsCrEss1        NCHAR(1)
        ,RemName1    NVARCHAR(100)    
        ,CellType1      NVARCHAR(100)  
        ,CodeHelpSeq1       INT
        ,CodeHelpParams1   NVARCHAR(100)   
        ,RemValue1     NVARCHAR(200) 
        ,RemValSeq1  INT
        ---------------------2         
        ,RemSeq2  INT           
        ,IsDrEss2 NCHAR(1)        
        ,IsCrEss2   NCHAR(1)     
        ,RemName2 NVARCHAR(100)       
        ,CellType2  NVARCHAR(100)      
        ,CodeHelpSeq2   INT     
        ,CodeHelpParams2 NVARCHAR(100)     
        ,RemValue2 NVARCHAR(200)     
        ,RemValSeq2  INT
        ---------------------3        
        ,RemSeq3  INT            
        ,IsDrEss3  NCHAR(1)      
        ,IsCrEss3     NCHAR(1)   
        ,RemName3    NVARCHAR(100)       
        ,CellType3 NVARCHAR(100)       
        ,CodeHelpSeq3  INT
        ,CodeHelpParams3    NVARCHAR(100)  
        ,RemValue3    NVARCHAR(200)   
    ,RemValSeq3  INT
        ---------------------4        
 ,RemSeq4   INT            
        ,IsDrEss4 NCHAR(1)       
        ,IsCrEss4  NCHAR(1)      
        ,RemName4 NVARCHAR(100)        
        ,CellType4 NVARCHAR(100)       
        ,CodeHelpSeq4  INT      
        ,CodeHelpParams4  NVARCHAR(100)    
        ,RemValue4   NVARCHAR(200)  
        ,RemValSeq4  INT
        ---------------------5        
        ,RemSeq5 INT            
        ,IsDrEss5  NCHAR(1)      
        ,IsCrEss5  NCHAR(1)      
        ,RemName5  NVARCHAR(100)      
        ,CellType5   NVARCHAR(100)     
        ,CodeHelpSeq5  INT      
        ,CodeHelpParams5 NVARCHAR(100)     
        ,RemValue5    NVARCHAR(100)
        ,RemValSeq5 INT 
        ---------------------6        
        ,RemSeq6  INT             
        ,IsDrEss6 NCHAR(1)       
        ,IsCrEss6    NCHAR(1)    
        ,RemName6  NVARCHAR(100)      
        ,CellType6 NVARCHAR(100)        
        ,CodeHelpSeq6 INT       
        ,CodeHelpParams6 NVARCHAR(100)      
        ,RemValue6    NVARCHAR(200)  
        ,RemValSeq6  INT
        ---------------------7        
        ,RemSeq7   INT           
        ,IsDrEss7   NCHAR(1)     
        ,IsCrEss7     NCHAR(1)   
        ,RemName7 NVARCHAR(100)       
        ,CellType7  NVARCHAR(100)      
        ,CodeHelpSeq7 INT       
        ,CodeHelpParams7   NVARCHAR(100)  
        ,RemValue7  NVARCHAR(200)    
        ,RemValSeq7  INT
        ---------------------8        
        ,RemSeq8  INT          
        ,IsDrEss8 NCHAR(1)       
        ,IsCrEss8 NCHAR(1)       
        ,RemName8 NVARCHAR(100)       
        ,CellType8  NVARCHAR(100)      
        ,CodeHelpSeq8 INT       
        ,CodeHelpParams8   NVARCHAR(100)   
        ,RemValue8   NVARCHAR(200)   
        ,RemValSeq8  INT
        ---------------------9      
        ,RemSeq9 INT           
        ,IsDrEss9 NCHAR(1)        
        ,IsCrEss9 NCHAR(1)       
        ,RemName9  NVARCHAR(100)      
        ,CellType9  NVARCHAR(100)      
        ,CodeHelpSeq9 INT        
        ,CodeHelpParams9  NVARCHAR(100)    
        ,RemValue9 NVARCHAR(200)     
        ,RemValSeq9 INT  
        ---------------------10        
        ,RemSeq10 INT              
        ,IsDrEss10  NCHAR(1)      
        ,IsCrEss10 NCHAR(1)       
        ,RemName10 NVARCHAR(100)       
        ,CellType10 NVARCHAR(100)       
        ,CodeHelpSeq10  INT      
        ,CodeHelpParams10 NVARCHAR(100)   
        ,RemValue10  NVARCHAR(200)    
        ,RemValSeq10 INT 
        ------------------------------------        
        ,DrRemValue INT--본지점계정(차변)관리항목코드 : 생성될 전표의 차변계정에 사용됨.     
        ,DrRemName NVARCHAR(200) --본지점계정(차변)관리항목      
        ,CrRemValue INT  --본지점계정(대변)관리항목 : 생성될 전표의 대변계정에 사용됨.     
        ,CrRemName NVARCHAR(200)--본지점계정(대변)관리항목      
        ,ProcSlipSeq INT--생성된 전표내부코드    
        ,Sort1Remseq INT -- 본지점계정의 관리항목1번  
        ,Sort2Remseq INT -- 본지점계정의 관리항목2번  
        ,Sort3Remseq INT -- 본지점계정의 관리항목3번  
        ,AccDate NCHAR(8) --회계일  
        ,Summary  NVARCHAR(1000)
        ,CostDeptSeq INT--귀속부서         
        ,CostCCtrSeq INT--활동센터         
        ,CostDeptName  NVARCHAR(200)
        ,CostCCtrName  NVARCHAR(200) 
        ,AccUnit    INT--회계단위  
        ,CrtSlipUnit INT --전표단위  
        ,CrtBgtDeptSeq INT--예산부서  
        ,DrUMCostType INT --본지점계정(차변)관리항목 계정의 비용구분    
        ,CrUMCostType INT --본지점계정(대변)관리항목 : 생성될 전표의 대변계정의 비용구분  
    )
    --BS대체전표일괄처리데이터 조회   
    INSERT #TMPBSSlipData         
    EXEC hencom_SACBalanceSubProcQuery @CompanySeq,@DateFr,@DateTo,@SlipUnit            
    

    INSERT #TMPResultData (SortSeq, OppAccSeq, OppAccName, CustSeq ,CustName ,Remark  ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName, SlipSeq )            
    SELECT
	CrRemValue      AS SortSeq  ,   -- 상대계정코드              
    CrRemValue      AS OppAccSeq,   -- 상대계정코드                
    CrRemName       AS OppAccName,  -- 상대계정
	0               AS CustSeq,     -- 거래처                
    ''              AS CustName,    -- 거래처명
    Summary         AS Remark,      -- 비고                                               
    DrAmt           AS SupplyAmt,   -- 공급가액
    0               AS VatAmt,      -- 부가세                   
    DrAmt           AS Amt,         -- 금액                       
    DrRemValue      AS AccSeq,      -- 계정과목코드                        
    0               AS VatAccSeq,   -- 부가세계정코드                   
    DrRemName       AS AccName,      -- 계정과목                
    ProcSlipSeq     AS SlipSeq            
    FROM #TMPBSSlipData            
    WHERE ISNULL(ProcSlipSeq,0) <> 0            

  
  SELECT 1 AS Gubun, SortSeq, OppAccSeq , OppAccName, CustSeq ,CustName ,Remark ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName,SlipSeq            
  INTO #TMPQuery            
  FROM #TMPResultData            
UNION ALL            
  SELECT  2 AS Gubun,           
          ISNULL(SortSeq,0) AS SortSeq ,  
          ISNULL(OppAccSeq,0) AS OppAccSeq ,             
          ' 소계' AS OppAccName,             
          0 CustSeq ,            
          '' CustName ,            
          ISNULL(OppAccName,'')+  ' 소계' Remark ,            
          SUM(ISNULL(SupplyAmt,0)) AS  SupplyAmt ,            
          SUM(ISNULL(VatAmt,0)) AS VatAmt,            
          SUM(ISNULL(Amt,0)) AS Amt,              
          0 AccSeq ,            
          0 VatAccSeq ,             
          '' AccName ,            
          0 SlipSeq            
  FROM #TMPResultData            
    GROUP BY ISNULL(SortSeq,0), ISNULL(OppAccSeq,0),ISNULL(OppAccName,'')            
  UNION ALL            
  SELECT  3 AS Gubun,     
          9999 as SortSeq,
          MAX(OppAccSeq) +1  AS OppAccSeq ,             
          ' 총계' AS OppAccName,             
          0 CustSeq ,            
          '' CustName ,            
          ' 총계' Remark ,            
          SUM(ISNULL(SupplyAmt,0)) AS  SupplyAmt ,            
          SUM(ISNULL(VatAmt,0)) AS VatAmt,            
          SUM(ISNULL(Amt,0)) AS Amt,             
          0 AS AccSeq ,            
            0 AS VatAccSeq ,             
          '' AS AccName ,            
          0  AS SlipSeq            
  FROM #TMPResultData            
    
  
  --SELECT * FROM #TMPQuery RETURN  
  
  SELECT *  ,          
        ----------------전자결재용          
        LEFT(@DateFr,4)+'-'+SUBSTRING(@DateFr,5,2)+'-'+SUBSTRING(@DateFr,7,2) AS DateFr_GW,          
        LEFT(@DateTo,4)+'-'+SUBSTRING(@DateTo,5,2)+'-'+SUBSTRING(@DateTo,7,2) AS DateTo_GW,          
         (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = @SlipUnit) AS SlipUnitName  
  FROM #TMPQuery  
  ORDER by SortSeq, OppAccSeq, Gubun ,CustName

  RETURN  
  go
begin tran 
EXEC hencom_SACPUSlipProcDataQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DateFr>20170501</DateFr>
    <DateTo>20170531</DateTo>
    <SlipUnit>20</SlipUnit>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1038078, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 1031103

rollback 