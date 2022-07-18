IF OBJECT_ID('KPXLS_SACJournalQueryPrt') IS NOT NULL 
    DROP PROC KPXLS_SACJournalQueryPrt
GO 

-- v2016.02.24 

/************************************************************
설  명 - 전표연속출력(분개장 형식)
작성일 - 2009년 9월 10일
작성자 - 민형준
************************************************************/
CREATE PROCEDURE KPXLS_SACJournalQueryPrt
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10) = '',
    @CompanySeq     INT = 0,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
        
    
    DECLARE @docHandle          INT,    
            @AccUnit            INT,     
            @SlipUnit           INT,
            @AccDate            NCHAR(8),
            @AccDateTo          NCHAR(8),
            @CNT                INT,
            @Seq                INT,
            @SMAccStd           INT,  
            @BitCnt             INT     ,
            @CompanyName		NVARCHAR(200),
            @CurrDate			NCHAR(8),
            @IsSet				NCHAR(1)   
   
                    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
          

    SELECT  @AccUnit            =  AccUnit           ,  
            @SlipUnit           =  SlipUnit,
            @AccDate            =  AccDate          ,
            @AccDateTo          =  AccDateTo,
            @SMAccStd           =  SMAccStd,
            @IsSet			    = CASE IsSet WHEN 1016001 THEN '0'	-- 미승인
                                             WHEN 1016002 THEN '1'    -- 승인
                                             ELSE '' END 

    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (  AccUnit            INT,             
            SlipUnit           INT,
            AccDate            NCHAR(8),
            AccDateTo          NCHAR(8),
            SMAccStd           INT,
            IsSet			   INT 
            )   

    
    SELECT
           @SMAccStd    = ISNULL(LTRIM(RTRIM(@SMAccStd       )), 0),  
           @BitCnt = 2  



    --================================================================================================================================  
    -- 컬럼 정보 생성
    --================================================================================================================================  


    SELECT @CompanyName = CompanyName FROM _TCACompany WHERE CompanySeq = @CompanySeq
    SELECT @CurrDate    = CONVERT(NCHAR(8), GETDATE(), 112)

    --================================================================================================================================  
    -- 고정컬럼값 조회
    --================================================================================================================================  
    SELECT C.SlipMstSeq
     INTO #ACSlipRowjournalTypePrt
      FROM _TACSlipRow AS A WITH(NOLOCK)
                           JOIN _TDAAccount AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq
                LEFT OUTER JOIN _TACSlip    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND  A.SlipMstSeq = C.SlipMstSeq 
--                LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.AccSeq = D.AccSeq 
--                LEFT OUTER JOIN _TDACurr    AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.CurrSeq = E.CurrSeq  
--                LEFT OUTER JOIN _TDAEvid    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.EvidSeq = F.EvidSeq  
--                LEFT OUTER JOIN _TDAEmp     AS G WITH(NOLOCK) ON C.CompanySeq = G.CompanySeq AND C.RegEmpSeq = G.EmpSeq 
--                LEFT OUTER JOIN _TDAAccUnit AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq AND A.AccUnit    = J.AccUnit 
 
                LEFT OUTER JOIN _TACSlipKind AS H ON C.CompanySeq = H.CompanySeq AND C.SlipKind = H.SlipKind
                           JOIN  dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS I ON H.SMAccStd = I.Val  
     WHERE A.CompanySeq = @CompanySeq
       
       AND (@AccUnit = 0 OR A.AccUnit = @AccUnit)
       AND A.AccDate BETWEEN @AccDate AND RTRIM(@AccDateTo) + '99999999'
       AND (@SlipUnit = '' OR A.SlipUnit = @SlipUnit)
--       AND A.SlipMstSeq IN (SELECT SlipMstSeq FROM #ACSlipRowjournalTypePrt)


      SELECT 
      IDENTITY(INT, 0, 1)  AS RowIDX,
           A.SlipID,
           C.AccUnitName,
           A.SlipMstSeq,
           A.SlipSeq,
           A.SlipNo,
           A.RowNo,
           A.AccDate,
           A.DrAmt,
           A.CrAmt,
           A.Summary,
           B.AccName,
           B.AccSeq,
           B.AccNo,
           D.SetSlipID,
         (SELECT DISTINCT   STUFF((SELECT ', ' + LTRIM(CONVERT(NVARCHAR(100), B1.DeptName)) AS [text()]      
                               FROM _TACSlipCost AS A1 WITH(NOLOCK)      
                                       LEFT OUTER JOIN _TDADept AS B1 WITH(NOLOCK) ON A1.CompanySeq = B1.CompanySeq AND A1.CostDeptSeq = B1.DeptSeq     
                              WHERE A1.CompanySeq = @CompanySeq       
                                AND A1.SlipSeq = A.SlipSeq         
                                AND 1=1 FOR XML path('')   ),1,1,'')) AS CostDeptName,      
         (SELECT DISTINCT   STUFF((SELECT ', ' + LTRIM(CONVERT(NVARCHAR(100), B1.CCtrName)) AS [text()]      
                               FROM _TACSlipCost AS A1 WITH(NOLOCK)      
                                         LEFT OUTER JOIN _TDACCtr AS B1 WITH(NOLOCK) ON A1.CompanySeq = B1.CompanySeq AND A1.CostCCtrSeq = B1.CCtrSeq           
                              WHERE A1.CompanySeq = @CompanySeq       
                                AND A1.SlipSeq = A.SlipSeq      
                                AND 1=1 FOR XML path('')   ),1,1,'')) AS CostCCtrName
      INTO #TempFixedCol  
      FROM _TACSlipRow AS A WITH (NOLOCK)
                 JOIN  _TACSlip AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.SlipMstSeq = D.SlipMstSeq
           LEFT  JOIN _TDAAccount AS B WITH (NOLOCK)
                   ON A.CompanySeq  = B.CompanySeq
                  AND A.AccSeq      = B.AccSeq
           LEFT OUTER JOIN _TDAAccUnit AS C WITH (NOLOCK) 
                        ON A.CompanySeq = C.CompanySeq
                       AND A.AccUnit    = C.AccUnit
     WHERE A.CompanySeq = @CompanySeq  
       AND A.SlipMstSeq IN (SELECT SlipMstSeq FROM #ACSlipRowjournalTypePrt)
       AND (@IsSet = '' OR A.IsSet = @IsSet) 
     ORDER BY A.SlipID, A.RowNo



    --================================================================================================================================  
    -- 변동컬럼값 조회(관리항목)
    --================================================================================================================================
    -- 코드헬프의 명칭을 가져오기 위한 임시테이블 생성
    CREATE TABLE #tmp_SlipRemValue
    (
        SlipMstSeq      INT,
        SlipSeq         INT,
        RemSeq          INT,
        Seq             INT,
        RemValText      NVARCHAR(100),
        Sort            INT
    )

    -- 임시테이블에 명칭을 가져오기 위한 키값을 넣어주고
    INSERT INTO #tmp_SlipRemValue
        SELECT A.SlipMstSeq,
               A.SlipSeq,
               B.RemSeq,
               B.RemValSeq,
               B.RemValText,
               C.Sort
          FROM #TempFixedCol AS A
               INNER JOIN _TACSlipRem AS B WITH (NOLOCK)
                       ON B.CompanySeq  = @CompanySeq
                      AND B.SlipSeq     = A.SlipSeq
               INNER JOIN _TDAAccountSub AS C WITH (NOLOCK)
                       ON C.CompanySeq  = B.CompanySeq
                      AND C.AccSeq      = A.AccSeq
                      AND C.RemSeq      = B.RemSeq


    -- 명칭을 가져온다.
 -- 실행 후에는 ValueName 컬럼이 자동생성되어 진다.
    EXEC _SUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue'

    SELECT *, @CurrDate AS CurrDate
      FROM (
        SELECT  CASE WHEN @AccUnit = 0 THEN '' ELSE A.AccUnitName END AS AccUnitName,
                A.SlipMstSeq, @CompanyName AS CompanyName, A.AccDate , A.SlipNo, A.RowNo, A.AccNo, A.AccName, A.DrAmt, A.CrAmt, A.Summary, A.SlipID,
                B.RemValue AS RemValue1 , C.RemValue AS RemValue2, D.RemValue AS RemCust, A.CostDeptName, A.CostCCtrName, G.SetSlipNo AS SetSlipID,
                F.MinorName AS UMCostTypeName
        FROM #TempFixedCol AS A 
        LEFT OUTER JOIN #tmp_SlipRemValue AS B ON A.SlipSeq = B.SlipSeq AND B.Sort = 1 
        LEFT OUTER JOIN #tmp_SlipRemValue AS C ON A.SlipSeq = C.SlipSeq AND C.Sort = 2
        LEFT OUTER JOIN #tmp_SlipRemValue AS D ON A.SlipSeq = D.SlipSeq AND D.RemSEq = 1017 -- 거래처
        LEFT OUTER JOIN _TACSlipRow AS E ON E.CompanySeq = @CompanySeq AND A.SlipSeq = E.SlipSeq 
        LEFT OUTER JOIN _TDAUMinor AS F ON F.CompanySeq = @CompanySeq AND E.UMCostType = F.MinorSeq 
        LEFT OUTER JOIN _TACSlip    AS G ON G.CompanySeq = @CompanySeq AND G.SlipMstSeq = E.SlipMstSeq 
--        UNION ALL
--        SELECT AccUnitName, SlipMstSeq, @CompanyName AS CompanyName,   AccDate AS AccDate, NULL AS SlipNo, '999' AS RowNo, '전표계' AS AccNo, NULL AS AccName, 
--               SUM(DrAmt) AS DrAmt, SUM(CrAmt) AS CrAmt, NULL AS Summary, NULL RemValue1, NULL RemValue2
--         FROM #TempFixedCol
--        GROUP BY AccUnitName, SlipMstSeq, AccDate
--        UNION ALL
--        SELECT AccUnitName, MAX(SlipMstSeq) AS SlipMstSeq, @CompanyName AS CompanyName,   AccDate AS AccDate, NULL AS SlipNo, '9999' AS RowNo, '소 계' AS AccNo, NULL AS AccName, 
--               SUM(DrAmt) AS DrAmt, SUM(CrAmt) AS CrAmt, NULL AS Summary, NULL RemValue1, NULL RemValue2
--         FROM #TempFixedCol
--        GROUP BY AccUnitName, AccDate
        
            ) AS A
      ORDER BY A.AccDate, A.SetSlipID, A.RowNo



    RETURN
/*******************************************************************************************************************/
GO


EXEC KPXLS_SACJournalQueryPrt @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccUnit />
    <SlipUnit />
    <AccDate>20160224</AccDate>
    <AccDateTo>20160224</AccDateTo>
    <IsSet />
    <SMAccStd>1</SMAccStd>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1035317, @WorkingTag = N'', @CompanySeq = 3, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 300181
