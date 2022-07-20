IF OBJECT_ID('mnpt_SARCostAccQuery') IS NOT NULL 
    DROP PROC mnpt_SARCostAccQuery
GO 

-- v2018.01.08 
/*********************************************************************************************************************      
    화면명 : 전자결재연동계정환경설정 - 조회  
    SP Name: _SARCostAccQuery      
    작성일 : 2010.04.19 : CREATEd by 송경애          
    수정일 : 2010.04.22 : Modify by  송경애  
                        :: 상대계정, 증빙 컬럼 추가  
********************************************************************************************************************/      
CREATE PROCEDURE mnpt_SARCostAccQuery        
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS             
    DECLARE @docHandle      INT      
          , @SMKindSeq      INT             -- 구분  
          , @CostName       NVARCHAR(100)   -- 비용구분명  
          , @AccSeq         INT             -- 계정과목코드  
          , @AccName        NVARCHAR(100)   -- 계정과목명  
          , @RemSeq         INT             -- 관리항목코드  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
      
  
    SELECT @SMKindSeq   = ISNULL(SMKindSeq, 0)  -- 구분  
         , @CostName    = ISNULL(CostName,'')   -- 비용구분명  
         , @AccSeq      = ISNULL(AccSeq,0)      -- 계정과목코드  
         , @AccName     = ISNULL(AccName,'')    -- 계정과목명  
         , @RemSeq      = ISNULL(RemSeq,0)      -- 관리항목코드  
             
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH (SMKindSeq     INT  
        , CostName      NVARCHAR(100)  
        , AccSeq        INT  
        , AccName       NVARCHAR(100)  
        , RemSeq        INT  
         )        
      
    SELECT @SMKindSeq   = ISNULL(@SMKindSeq, 0)   
        , @CostName     = ISNULL(@CostName,'')  
        , @AccSeq       = ISNULL(@AccSeq,0)  
        , @AccName      = ISNULL(@AccName,'')  
        , @RemSeq       = ISNULL(@RemSeq,0)  
  


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
    SELECT A.SMKindSeq     AS SMKindSeq    --  구분  
        , A.CostSeq         AS CostSeq      -- 비용구분내부코드  
        , A.CostName        AS CostName     -- 비용구분명  
        , A.AccSeq          AS AccSeq       -- 계정과목  
        , A.RemSeq          AS RemSeq       -- 관리항목  
        , A.RemValSeq       AS RemValSeq    -- Default관리항목  
        , A.CashDate        AS CashDate     -- 출납예정일수  
        , A.Remark          AS Remark       -- 비고  
        , B.AccName         AS AccName      -- 계정과목명  
        , C.RemName         AS RemName      -- 관리항목  
        , D.RemValueName    AS RemValueName -- Default관리항목명  
        , E.MInorName       AS SMKindName   -- 구분명  
        , A.SMKindSeq       AS OldSMKindSeq --  Old구분  
  
        , A.OppAccSeq       AS OppAccSeq    -- 상대계정코드  
        , F.AccName         AS OppAccName   -- 상대계정  
        , A.EvidSeq         AS EvidSeq      -- 증빙코드  
        , G.EvidName        AS EvidName     -- 증빙  
        , ISNULL(H.MinorName    , '') AS UMCostTypeName -- 비용구분  
        , ISNULL(A.UMCostType   ,  0) AS UMCostType     -- 비용구분코드  
/********************************************************************  
    조회시 예산과목, 순서 출력되게 수정 2011.02.07 - 김대용  
********************************************************************/  
        , ISNULL(J.BgtName      , '') AS BgtName        -- 예산과목  
        , ISNULL(A.Sort         , 0 ) AS Sort           -- 순서   
        , ISNULL(A.IsNotUse        , '') AS IsNotUse    -- 사용안함
        , L.CostSClassSeq
        , L.CostMClassSeq
        , L.CostLClassSeq
        , L.CostSClassName
        , L.CostMClassName
        , L.CostLClassName
      FROM _TARCostAcc AS A WITH(NOLOCK)  
        LEFT OUTER JOIN _TDAAccount AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq  
        LEFT OUTER JOIN _TDAAccountRem AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RemSeq = C.RemSeq  
        LEFT OUTER JOIN _TDAAccountRemValue AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.RemSeq = D.RemSeq AND A.RemValSeq = D.RemValueSerl  
        LEFT OUTER JOIN _TDASMinor AS E ON A.CompanySeq = E.CompanySEq AND A.SMKindSeq = E.MinorSeq  
        LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq  
        LEFT OUTER JOIN _TDAEvid    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.EvidSeq = G.EvidSeq  
        LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.UMCostType = H.MinorSeq AND H.MajorSeq = 4001  
        LEFT OUTER JOIN _TACBgtAcc  AS I ON A.CompanySeq = I.CompanySeq AND A.AccSeq = I.AccSeq AND A.RemSeq = I.RemSeq AND A.RemValSeq = I.RemValSeq  
        LEFT OUTER JOIN _TACBgtItem AS J ON A.CompanySeq = J.CompanySeq AND I.BgtSeq = J.BgtSeq    
        LEFT OUTER JOIN mnpt_TARCostAccSub AS K ON ( K.CompanySeq = @CompanySeq AND K.SMKindSeq = A.SMKindSeq AND K.CostSeq = A.CostSeq ) 
        LEFT OUTER JOIN #CostClass         AS L ON ( L.CostSClassSeq = K.CostSClassSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq  
       AND (@SMKindSeq = 0 OR A.SMKindSeq = @SMKindSeq)  
       AND (@CostName = '' OR A.CostName LIKE @CostName + '%')  
       AND (@AccSeq = 0 OR A.AccSeq = @AccSeq)  
       AND (@AccName = '' OR B.AccName LIKE @AccName + '%')  
       AND (@RemSeq = 0 OR C.RemSeq = @RemSeq)  
    ORDER BY A.Sort
  
    RETURN

    go
    exec mnpt_SARCostAccQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMKindSeq />
    <CostName />
    <AccSeq />
    <AccName />
    <RemSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820111,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820107