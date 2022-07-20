IF OBJECT_ID('mnpt_SCACodeHelpARCostAcc') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpARCostAcc
GO 

-- v2018.01.08 

/*************************************************************************************************                    
ROCEDURE    - _SCACodeHelpARCostAcc                    
DESCRIPTION - 전자결재연동비용 CodeHelp
작  성  일  - 2010년 04월 07일                    
작  성  자  - 송경애 
*************************************************************************************************/             
CREATE PROCEDURE mnpt_SCACodeHelpARCostAcc                       
    @WorkingTag     NVARCHAR(1),                  
    @LanguageSeq    INT,                  
    @CodeHelpSeq    INT,                  
    @DefQueryOption INT, -- 2: direct search                  
    @CodeHelpType   TINYINT,                  
    @PageCount      INT = 20,       
    @CompanySeq     INT = 1,                 
    @Keyword        NVARCHAR(200) = '',    -- 경조사명   -- 입력된 키워드를 정상적으로 가져오지 못해 풀네임으로 조회 시 조회되지 않아 수정함. (서비스요청번호 : 201605300174) 2016.05.31 by sryoun          
    @Param1         NVARCHAR(50) = '',    -- 사원코드
    @Param2         NVARCHAR(50) = '',    -- 
    @Param3         NVARCHAR(50) = '',      
    @Param4         NVARCHAR(50) = ''      
AS  
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
    
    SET ROWCOUNT @PageCount
    
    SELECT A.SMKindSeq	    AS SMKindSeq    --  구분
        , A.CostSeq         AS CostSeq      -- 비용구분내부코드
        , A.CostName        AS CostName     -- 비용구분명
        , A.AccSeq          AS AccSeq       -- 계정과목
        , A.RemSeq          AS RemSeq       -- 관리항목
        , A.RemValSeq       AS RemValSeq    -- Default관리항목
        , A.CashDate        AS CashDate     -- 출납예정일수
        , B.AccName         AS AccName      -- 계정과목명
        , C.RemName         AS RemName      -- 관리항목
        , D.RemValueName    AS RemValName   -- Default관리항목명
        , E.MInorName       AS SMKindName   -- 구분명
        , A.OppAccSeq       AS OppAccSeq    -- 상대계정
        , A.EvidSeq         AS EvidSeq      -- 증빙
        , F.AccName         AS OppAccName   -- 상대계정명
        , G.EvidName        AS EvidName     -- 증빙명
        , I.CostSClassSeq
        , I.CostMClassSeq
        , I.CostLClassSeq
        , I.CostSClassName
        , I.CostMClassName
        , I.CostLClassName
        
      FROM _TARCostAcc                          AS A WITH(NOLOCK)
        LEFT OUTER JOIN _TDAAccount             AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq
        LEFT OUTER JOIN _TDAAccountRem          AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RemSeq = C.RemSeq
        LEFT OUTER JOIN _TDAAccountRemValue     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.RemSeq = D.RemSeq AND A.RemValSeq = D.RemValueSerl
        LEFT OUTER JOIN _TDASMinor              AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySEq AND A.SMKindSeq = E.MinorSeq
        LEFT OUTER JOIN _TDAAccount             AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq
        LEFT OUTER JOIN _TDAEvid                AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.EvidSeq = G.EvidSeq
        LEFT OUTER JOIN mnpt_TARCostAccSub      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CostSeq = A.CostSeq AND H.SMKindSeq = A.SMKindSeq ) 
        LEFT OUTER JOIN #CostClass              AS I              ON ( I.CostSClassSeq = H.CostSClassSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.CostName LIKE @Keyword) 
       AND (@Param1 = 0 OR A.SMKindSeq = @Param1)
       AND ISNULL(A.IsNotUse,'') <> '1'
     ORDER BY A.Sort
    SET ROWCOUNT 0
RETURN

go

exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'13820036',@Keyword=N'%회식비%',@Param1=N'4503004',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=1,@WkDeptSeq=18,@EmpSeq=64,@UserSeq=167