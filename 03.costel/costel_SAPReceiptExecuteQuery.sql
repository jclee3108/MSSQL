
IF OBJECT_ID('costel_SAPReceiptExecuteQuery') IS NOT NULL 
    DROP PROC costel_SAPReceiptExecuteQuery
GO

-- v2013.04.26 
       
 -- 일일자금집행_fnb 조회 by서보영 Copy이재천 2013.11.15
    CREATE PROC costel_SAPReceiptExecuteQuery                   
    @xmlDocument    NVARCHAR(MAX) ,                
    @xmlFlags       INT  = 0,                
    @ServiceSeq     INT  = 0,                
    @WorkingTag     NVARCHAR(10)= '',                      
    @CompanySeq     INT  = 1,                
    @LanguageSeq    INT  = 1,                
    @UserSeq        INT  = 0,                
    @PgmSeq         INT  = 0             
       
   AS            
        
    DECLARE @docHandle       INT,    
            @AccUnit         INT ,    
            @ExecuteDateFr   NVARCHAR(8),  
            @ExecuteDateTo   NVARCHAR(8),
            @SlipKind        NVARCHAR(10)
        
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
       
    SELECT  @AccUnit        = ISNULL(AccUnit,0)     ,    
            @ExecuteDateFr  = ISNULL(ExecuteDateFr, ''),  
            @ExecuteDateTo  = ISNULL(ExecuteDateTo, ''),
            @SlipKind       = SlipKind       
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (AccUnit     INT ,    
            ExecuteDateFr   NVARCHAR(8),  
            ExecuteDateTo   NVARCHAR(8),     
            SlipKind        NVARCHAR(10) )
         CREATE TABLE #APCashExecute  
           (  
               SilpKindNM  NVARCHAR(2),  
               AccName   NVARCHAR(100),  
               Summary   NVARCHAR(200),  
               CrAmt     DECIMAL(19,5),  
               CustName  NVARCHAR(100),  
               SlipID    NVARCHAR(40),  
               AccDate   NCHAR(8),  
               ExecuteDate NCHAR(8),  
               IsSet     NVARCHAR(2),
               SlipKind  NVARCHAR(10)  
           ) 
                
      CREATE TABLE #tmp_SlipRemValue            
      (            
          SlipSeq         INT,            
          RemSeq          INT,                       
          Seq             INT,            
          RemValText      NVARCHAR(100),            
          CellType        NVARCHAR(50),            
          IsDrEss         NCHAR(1),            
          IsCrEss         NCHAR(1),            
          Sort            INT            
      )  
    
      -- 임시테이블에 명칭을 가져오기 위한 키값을 넣어주고            
      INSERT INTO #tmp_SlipRemValue            
          SELECT A.SlipSeq,            
                 B.RemSeq,              
                 B.RemValSeq,            
                 B.RemValText,            
                 CASE D.SMInputType            
                WHEN 4016001 THEN 'enText'            
                      WHEN 4016002 THEN 'enCodeHelp'            
                      WHEN 4016003 THEN 'enFloat'            
                      WHEN 4016004 THEN 'enFloat'            
                      WHEN 4016005 THEN 'enDate'            
                      WHEN 4016006 THEN 'enText'            
                      WHEN 4016007 THEN 'enFloat'            
                      ELSE 'enText'            
                 END AS CellType,       -- 입력형태            
                 C.IsDrEss,            
                 C.IsCrEss,            
                 C.Sort            
            FROM _TACSlipRow AS A            
                 INNER JOIN _TACSlipRem AS B WITH (NOLOCK)            
                         ON B.CompanySeq  = @CompanySeq            
                        AND B.SlipSeq     = A.SlipSeq            
                 INNER JOIN _TDAAccountSub AS C WITH (NOLOCK)            
                         ON C.CompanySeq  = @CompanySeq            
                        AND C.AccSeq      = A.AccSeq            
                        AND C.RemSeq      = B.RemSeq       
                 INNER JOIN _TDAAccountRem AS D WITH (NOLOCK)            
                         ON D.CompanySeq  = @CompanySeq            
                        AND D.RemSeq      = B.RemSeq     
       EXEC _SUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue'
  
 --SELECT * FROM #tmp_SlipRemValue
          --================================================================================================================================                   
        -- 환경설정(출납입력(잔액기준))설정에 따른 출납예정일 출력을 위한 임시테이블 생성 (2012.02.01 mypark)       
        --================================================================================================================================         
   
         CREATE TABLE #tempCash    
        (    
            CompanySeq      INT,     
            SlipSeq         INT,     
            Amt             DECIMAL(19,5),    
            ForAmt          DECIMAL(19,5),     
            CashDate        NCHAR(8),    
            Serl            INT,  
            SMInOrOut       INT  
       
        )    
         CREATE TABLE #tempCashOff    
        (    
            CompanySeq      INT,     
            SlipSeq         INT,     
            OffSlipSeq      INT,    
            OffAmt          DECIMAL(19,5),  
            Serl            INT    
       
        )                
       
        IF EXISTS (SELECT * FROM _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 4040 AND EnvValue = '0')    
        BEGIN  --출납(통합)  
            INSERT INTO #tempCash (CompanySeq, SlipSeq,Amt, ForAmt, CashDate, Serl, SMInOrOut)    
                SELECT A.CompanySeq, A.SlipSeq, A.Amt, A.ForAmt, A.CashDate, A.Serl, B.SMInOrOut    
                  FROM _TAPCashOn AS A LEFT OUTER JOIN _TAPCash AS B WITH(NOLOCK)  
                                           ON A.CompanySeq = B.CompanySeq   
                                          AND A.SlipSeq    = B.SlipSeq   
                 WHERE A.CompanySeq = @CompanySeq  
             INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq, OffAmt, Serl)    
                SELECT A.CompanySeq, A.SlipSeq, A.OffSlipSeq, B.CrAmt + B.DrAmt, A.Serl    
                  FROM _TAPCashOff AS A JOIN _TACSlipRow AS B ON A.CompanySeq  = B.CompanySeq  
                                                             AND A.OffSlipSeq  = B.SlipSeq   
                 WHERE A.CompanySeq = @CompanySeq   
        END     
        ELSE    
        BEGIN  --출납(잔액기준)  
            INSERT INTO #tempCash (CompanySeq, SlipSeq, Amt, ForAmt, CashDate, Serl, SMInOrOut)    
                SELECT CompanySeq, SlipSeq, OnAmt, OnForAmt, CashDate, 1,SMInOrOut   
                  FROM _TACCashOn   
                 WHERE CompanySeq = @CompanySeq    
              
            INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq,OffAmt, Serl)    
                  SELECT CompanySeq, OnSlipSeq, MAX(SlipSeq) AS SlipSeq, SUM(OffAmt) AS OffAmt,  1    
                  FROM _TACCashOff   
                 WHERE CompanySeq = @CompanySeq   
                 GROUP BY CompanySeq, OnSlipSeq  
        END    
       
        --================================================================================================================================                  
       -- 환경설정(출납입력(잔액기준))설정에 따른 출납예정일 출력을 위한 임시테이블 생성 끝     
       --================================================================================================================================  
       -- 집행여부로 관련하여 출납예정일을 기준으로 조회 한다.  
       -- 승인여부는 출납데이터 발생 전표의 승인여부  
       -- 출납데이터 #tempCash과 off는 반드시 1:1 로 처리되므로 off가 있으면 집행이 된것으로 본다.  
       INSERT INTO #APCashExecute ( SilpKindNM  , AccName          ,Summary    ,CrAmt,  
                                   CustName   ,SlipID     ,AccDate    , ExecuteDate, IsSet, SlipKind )                 
     SELECT '입금' AS SilpKindNM,     
            F.AccName,   
            G.Summary,   
            ISNULL(G.DrAmt,0)  AS CrAmt,  
            B.CustName,  
            G.SlipId,   
            G.AccDate,   
            AB.FundArrangeDate,  
            G.IsSet , '1008899001' 
            --,*  
       FROM _TSLSales AS A WITH (NOLOCK)  
            JOIN (SELECT BillSeq, SalesSeq  
                      FROM _TSLSalesBillRelation WITH(NOLOCK)  
                      WHERE CompanySeq = @CompanySeq  
                      GROUP BY BillSeq, SalesSeq) AS AA  ON A.SalesSeq    = AA.SalesSeq  
                                     --AND I.SalesSerl = AA.SalesSerl  
            JOIN _TSLBill    AS AB WITH(NOLOCK) ON @CompanySeq = AB.CompanySeq  
                                                   AND AA.BillSeq    = AB.BillSeq  
     LEFT OUTER JOIN _TACSlipRow AS TT WITH(NOLOCK) ON AB.CompanySeq = TT.CompanySeq    
                                                   AND AB.SlipSeq    = TT.SlipSeq    
     LEFT OUTER JOIN _TACSlipRow AS G WITH(NOLOCK)  ON TT.CompanySeq = G.CompanySeq    
                                                   AND TT.SlipMstSeq = G.SlipMstSeq  
     LEFT OUTER JOIN _TACSlip    AS GG WITH(NOLOCK) ON TT.SlipMstSeq = GG.SlipMstSeq  
                                                   AND TT.CompanySeq = GG.CompanySeq    
     LEFT OUTER JOIN _TACSlipRem AS BT WITH(NOLOCK) ON G.CompanySeq  = BT.CompanySeq    
                                                   AND G.SlipSeq     = BT.SlipSeq    
                                                   AND BT.RemSeq     = 1017    
     LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK)     ON BT.CompanySeq = B.CompanySeq     
                                                   AND BT.RemValSeq  = B.CustSeq    
     LEFT OUTER JOIN _TACSlipAutoEnvRow AS C WITH (NOLOCK) ON G.CompanySeq = C.CompanySeq    
                                                          AND G.AccSeq     = C.AccSeq    
     LEFT OUTER JOIN _TACSlipAutoEnv    AS D WITH (NOLOCK) ON C.CompanySeq = D.CompanySeq    
                                                          AND C.SlipAutoEnvSeq = D.SlipAutoEnvSeq    
     LEFT OUTER JOIN _TACSlipKind       AS E WITH (NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                          AND D.SlipKindNo = E.SlipKindNo     
     LEFT OUTER JOIN _TDAAccount        AS F WITH (NOLOCK) ON G.CompanySeq = F.CompanySeq    
                                                          AND G.AccSeq     = F.AccSeq 
    WHERE  A.CompanySeq = @CompanySeq  
      AND E.SlipKind IN (10018)  
      AND C.IsAnti = 1  
      AND (@AccUnit = 0 OR G.AccUnit = @AccUnit)   
      AND (AB.FundArrangeDate BETWEEN @ExecuteDateFr AND @ExecuteDateTo)    
      AND D.SlipAutoEnvSeq = 33  
      AND  G.IsSet <> 0  
          
 UNION
          
      
      SELECT   C.MinorName AS SilpKindNM,  
               D.AccName,  
               B.Summary,  
               ISNULL(E.Amt, 0) AS CrAmt,
               R1.RemValue,  
               B.SlipId,  
               B.AccDate,  
               E.CashDate,B.IsSet , '1008899002'
                 
      FROM  _TACSlipRow AS B   
                LEFT OUTER JOIN _TACSlipRem AS R WITH(NOLOCK) ON B.CompanySeq = R.CompanySeq AND B.SlipSeq = R.SlipSeq AND R.RemSeq = 1017  
                         JOIN #tempCash  AS E WITH(NOLOCK) ON B.CompanySeq = E.CompanySeq AND B.SlipSeq = E.SlipSeq  
              LEFT OUTER JOIN _TDASMinor  AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq AND E.SMInOrOut = C.MinorSeq  
              LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON B.CompanySeq = D.CompanySeq AND B.AccSeq = D.AccSeq  
              LEFT OUTER JOIN _TDACust    AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq AND R.RemValSeq = F.CustSeq  
              --LEFT OUTER JOIN #tempCashOff AS I ON B.CompanySeq = I.CompanySeq AND E.SlipSeq = I.SlipSeq AND E.Serl = I.Serl  
              --LEFT OUTER JOIN _TACSlipRow AS J ON B.CompanySeq = J.CompanySeq AND I.OffSlipSeq = J.SlipSeq   
              LEFT OUTER JOIN #tmp_SlipRemValue AS R1 ON B.SlipSeq = R1.SlipSeq AND R1.Sort  = 1  
        WHERE B.CompanySeq = @CompanySeq  
         AND C.MinorSeq   = 4003002  
         AND (@AccUnit = 0 OR B.AccUnit    = @AccUnit)  
         AND B.IsSet <> '0'  
         AND (E.CashDate BETWEEN @ExecuteDateFr AND @ExecuteDateTo)  
      
         SELECT A.*  
     FROM #APCashExecute AS A   
          WHERE A.SlipKind = @SlipKind
        ORDER BY SilpKindNM, SlipId  
        
       
   RETURN 
   