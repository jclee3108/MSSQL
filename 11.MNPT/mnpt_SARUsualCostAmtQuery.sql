IF OBJECT_ID('mnpt_SARUsualCostAmtQuery') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostAmtQuery
GO 

-- v2018.01.08 

/*********************************************************************************************************************    
    화면명 : 일반비용신청서금액 - 조회
    SP Name: _SARUsualCostAmtQuery    
    작성일 : 2010.04.20 : CREATEd by 송경애        
    수정일 : 
********************************************************************************************************************/    
CREATE PROCEDURE mnpt_SARUsualCostAmtQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle			INT    
          , @UsualCostSeq		INT         -- 일반비용신청서 내부코드
		  , @EnvValue4008		INT			-- 예산편성기준 ('예산부서' 컬럼 추가로 인해, 조회 시 예산편성기준에 따라 부서 또는 활동센터로 조회하기 위함. 2017.10.30. by sryoun.)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @UsualCostSeq   = ISNULL(UsualCostSeq, 0)  -- 일반비용신청서 내부코드
           
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (UsualCostSeq     INT
         )      
    
    SELECT @UsualCostSeq   = ISNULL(@UsualCostSeq, 0)
	-- 예산편성기준
	SELECT @EnvValue4008 = ISNULL(EnvValue, 0)
	  FROM _TCOMEnv WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 4008
    

    -- 비용항목 대중소 분류 
    SELECT C.MinorSeq AS CostSClassSeq, C.MinorName AS CostSClassName, -- '품목소분류'   
           E.MinorSeq AS CostMClassSeq, E.MinorName AS CostMClassName, -- '품목중분류'   
           G.MinorSeq AS CostLClassSeq, G.MinorName AS CostLClassName  -- '품목대분류'  
      INTO #CostClass
      FROM _TDAUMinor                 AS C WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.MinorSeq = D.MinorSeq AND D.Serl = 1000001 ) 
      -- 중분류   
      LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq )--AND E.IsUse = '1' )  
      LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND E.MinorSeq = F.MinorSeq AND F.Serl = 1000001 ) 
      -- 대분류   
      LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND F.ValueSeq = G.MinorSeq ) 
     WHERE C.CompanySeq = @CompanySeq
       AND C.MajorSeq = 1016729

/***********************************************************************************************************************************************/    
    SELECT A.UsualCostSerl  AS UsualCostSerl	-- 일반비용순번			
        , A.CostSeq         AS CostSeq			-- 비용항목코드
        , G.RemSeq          AS RemSeq			-- 관리항목코드	  
        , A.RemValSeq       AS RemValSeq		-- 상세정보코드
        , A.Amt             AS Amt				-- 금액				          
        , A.IsVat           AS IsVat			-- 부가세여부				    
        , A.SupplyAmt       AS SupplyAmt		-- 공급가액				      
        , A.VatAmt          AS VatAmt			-- 부가세 				      
        , A.CustSeq         AS CustSeq			-- 거래처				        
        , A.CustText        AS CustText			-- 카드코드 
        , M.CardNo                              -- 카드번호			  
        , A.EvidSeq         AS EvidSeq			-- 증빙				          
        , A.Remark          AS Remark			-- 비고				          
        , A.AccSeq          AS AccSeq			-- 계정과목코드				      
        , A.VatAccSeq       AS VatAccSeq		-- 부가세계정코드				
        , A.OppAccSeq       AS OppAccSeq		-- 상대계정코드	
        , G.CostName        AS CostName			-- 비용항목
        , H.RemValueName    AS RemValName		-- 상세정보
        , B.CustName        AS CustName			-- 거래처명
        , C.EvidName        AS EvidName			-- 증빙명
        , D.AccName         AS AccName			-- 계정과목
        , E.AccName         AS VatAccName		-- 부가세계정
        , F.AccName         AS OppAccName		-- 상대계정		
        , A.OppAccSeq       AS OppAccSeq		-- 상대계정코드
        , A.CostCashDate    AS CostCashDate		-- 출납예정일
        , A.CustDate        AS CustDate			-- 거래일
		, A.BgtDeptCCtrSeq	AS BgtDeptCCtrSeq	-- 예산부서내부코드
		, (CASE @EnvValue4008 WHEN 4013001 THEN I.DeptName WHEN 4013002 THEN J.CCtrName ELSE '' END) AS BgtDeptCCtrName -- '예산편성기준' 환경설정에 따라 부서/활동센터 명칭으로 조회
        , L.CostSClassSeq
        , L.CostMClassSeq
        , L.CostLClassSeq
        , L.CostSClassName
        , L.CostMClassName
        , L.CostLClassName
        
      FROM _TARUsualCostAmt         AS A WITH(NOLOCK) 
        LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq
        LEFT OUTER JOIN _TDAEvid    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EvidSeq = C.EvidSeq
        LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.AccSeq = D.AccSeq
        LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.VatAccSeq = E.AccSeq
        LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq
        LEFT OUTER JOIN _TARCostAcc AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CostSeq = G.CostSeq
        LEFT OUTER JOIN _TDAAccountRemValue AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq AND G.RemSeq = H.RemSeq AND A.RemValSeq = H.RemValueSerl
		LEFT OUTER JOIN _TDADept	AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.BgtDeptCCtrSeq = I.DeptSeq
		LEFT OUTER JOIN _TDACCtr	AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq AND A.BgtDeptCCtrSeq = J.CCtrSeq
        LEFT OUTER JOIN mnpt_TARCostAccSub  AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.CostSeq = A.CostSeq AND K.SMKindSeq = 4503004 ) 
        LEFT OUTER JOIN #CostClass          AS L              ON ( L.CostSClassSeq = K.CostSClassSeq ) 
        LEFT OUTER JOIN _TDACard        AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.CardSeq = CONVERT(INT,A.CustText) ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.UsualCostSeq = @UsualCostSeq
    RETURN


    go
    begin tran 
    exec mnpt_SARUsualCostAmtQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <UsualCostSeq>7</UsualCostSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820108
rollback 

