
IF OBJECT_ID('amoerp_SACAsstDeptAccDepreListQuery') IS NOT NULL 
    DROP PROC amoerp_SACAsstDeptAccDepreListQuery
GO 

-- v2013.12.31 

-- 관리부서별 계정별 상각조회_amoerp by이재천

/************************************************************
 작성일 - 2008년 11월 23일
 수정일 - 2011년 11월 3일    민형준  자산별 상각조회와 동일한 로직으로 변경, 마지막 조회만 계정별로 조회되게 한다. 
 작성자 - 박근수
 ************************************************************/
 CREATE PROCEDURE amoerp_SACAsstDeptAccDepreListQuery
  @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 0,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
      DECLARE @docHandle      INT,          
             @BizUnit        INT,          
             @QueryYMFr      NCHAR(6),          
             @QueryYMTo      NCHAR(6),          
             @AccSeq         INT,          
             @DeptSeq        INT,        
             @SMAccStd       INT,  
             @SMAccType      INT,         
             @AsstName       NVARCHAR(100),        
             @AsstNo         NVARCHAR(100),        
             @LastDate       NVARCHAR(8),        
             @BitCnt         INT,        
             @DepreCpt       INT,        
             @DispoFin       NVARCHAR(1),        
             @DepreAccSeq    INT      
           
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
         
     SELECT  @BizUnit    = ISNULL(BizUnit        , 0),        
             @AccSeq     = ISNULL(AccSeq         , 0),        
             @DeptSeq    = ISNULL(DeptSeq        , 0),        
             @QueryYMFr  = ISNULL(QueryYMFr      , ''),        
             @QueryYMTo  = ISNULL(QueryYMTo      , '299912'),        
             @SMAccStd   = ISNULL(SMAccStd       , 0),  
             @SMAccType  = ISNULL(SMAccType      , 0),         
             @AsstName   = ISNULL(AsstName       , ''),        
             @AsstNo     = ISNULL(AsstNo         , ''),        
             @DepreCpt   = ISNULL(DepreCpt       , 0 ),        
             @DispoFin   = ISNULL(DispoFin       , ''),        
             @DepreAccSeq = ISNULL(DepreAccSeq    , 0)         
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
     WITH (  BizUnit         INT         ,        
             AccSeq          INT         ,        
             DeptSeq         INT         ,        
             QueryYMFr       NCHAR(6)    ,        
             QueryYMTo       NCHAR(6)    ,        
             SMAccStd        INT         ,  
             SMAccType       INT         ,        
             AsstName        NVARCHAR(100),        
             AsstNo          NVARCHAR(100),        
             DepreCpt        INT          ,        
             DispoFin        NCHAR(1),        
             DepreAccSeq     INT)       
         
     SELECT @BitCnt = 2        
         
     CREATE TABLE #Asst (        
         AsstSeq             INT)        
             
     IF @QueryYMTo = '' SELECT @QueryYMTo = '299912'        
             
     INSERT INTO #Asst (AsstSeq)        
         SELECT A.AsstSeq        
           FROM _TACAsst AS A WITH (NOLOCK) JOIN _TACAsstDefault AS de WITH (NOLOCK)        
                                              ON A.CompanySeq        = de.CompanySeq        
                                             AND A.AsstTypeSeq       = de.AsstTypeSeq        
                                            JOIN _TACAsstAccSet AS ac WITH (NOLOCK)        
                                              ON A.CompanySeq        = ac.CompanySeq        
                                             AND de.AsstAccTypeSeq   = ac.AsstAccTypeSeq        
          WHERE A.CompanySeq     = @CompanySeq        
            AND (@BizUnit        = 0 OR A.BizUnit        = @BizUnit      )        
            AND (@DeptSeq        = 0 OR A.DeptSeq        = @DeptSeq      )        
            AND (@AccSeq         = 0 OR ac.GainAccSeq    = @AccSeq       )      
            AND A.AsstNo     LIKE @AsstNo + '%'        
            AND A.AsstName   LIKE @AsstName + '%'        
            AND A.GainDate       <= @QueryYMTo + '31'         
       
     --================================================================================================================        
     -- 기간이전 처분완료된 자산포함에 체크되지 않은 경우 100%처분자산 제외 -- 2010.12.04 by bgKeum START        
     --================================================================================================================        
     IF @DispoFin <> '1'        
     BEGIN        
         CREATE TABLE #DispoFin (        
             AsstSeq         INT,        
             GainDrAmt       DECIMAL(19,5),        
             GainCrAmt       DECIMAL(19,5),        
             RemAmt          DECIMAL(19,5))        
         INSERT INTO #DispoFin (AsstSeq, GainDrAmt, GainCrAmt, RemAmt)        
             SELECT A.AsstSeq, SUM(A.GainDrAmt), SUM(A.GainCrAmt), SUM(A.GainDrAmt) - SUM(A.GainCrAmt)        
               FROM _TACAsstInOut AS A JOIN dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS val        
                                         ON A.SMAccStd       = val.Val        
              WHERE A.CompanySeq     = @CompanySeq        
                AND A.AsstSeq       IN (SELECT A.AsstSeq        
                                          FROM _TACAsstInOut AS A JOIN dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS val        
                                                                    ON A.SMAccStd    = val.Val        
                                         WHERE A.CompanySeq      = @CompanySeq        
                                           AND A.SMDepreType     = 4118002               -- 처분이 있는 자산        
                                           AND A.ChgDate         < @QueryYMFr + '01')    -- 조회시작일 이전
                AND A.ChgDate         < @QueryYMFr + '01'  
              GROUP BY A.AsstSeq        
              HAVING SUM(A.GainDrAmt) - SUM(A.GainCrAmt) = 0 -- 잔액이 0인 자산은 100% 처분자산으로 인식함        
         
         -- 대상에서 제외        
         DELETE #Asst WHERE AsstSeq IN (SELECT AsstSeq FROM #DispoFin)         
     END        
     --================================================================================================================        
     -- 기간이전 처분완료된 자산포함에 체크되지 않은 경우 100%처분자산 제외 -- 2010.12.04 by bgKeum END        
     --================================================================================================================        
         
     CREATE TABLE #TempBfr (        
         AsstSeq             INT             , -- 자산코드        
         GainAmt             DECIMAL(19,5)   , -- 기초취득가액        
         TermAddAmt          DECIMAL(19,5)   , -- 당기자산증가액(취득)        
         TermDecAmt          DECIMAL(19,5)   , -- 당기자산감소액(취득)        
         EndGainAmt          DECIMAL(19,5)   , -- 기말취득가액        
         BasicDepreAmt       DECIMAL(19,5)   , -- 기초상각누계액        
         TermAddDepreAmt     DECIMAL(19,5)   , -- 당기상각증가액        
         TermDecDepreAmt     DECIMAL(19,5)   , -- 당기상각감소액        
         EndDepreAmt         DECIMAL(19,5)   , -- 기말상각누계액        
         ToMonDepreAmt       DECIMAL(19,5)   , -- 당월상각액         -- 우선 Temp에는 두지만, 화면에서는 제외시킴        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- 기초미상각잔액        
         EndNotDepreAmt      DECIMAL(19,5)   , -- 기말미상각잔액        
   TermAddEstAmt       DECIMAL(19,5)   , -- 당기자산증가액(자본적지출)        
   TermDecEstAmt       DECIMAL(19,5)   , -- 당기자산증가액(자본적지출)        
         DepreCptAmt         DECIMAL(19,5)   )         
         
    
     CREATE TABLE #TACAsstInOut (        
         AsstSeq             INT             , -- 자산코드        
         GainAmt             DECIMAL(19,5)   , -- 기초취득가액        
         TermAddAmt          DECIMAL(19,5)   , -- 당기자산증가액(취득)        
         TermDecAmt          DECIMAL(19,5)   , -- 당기자산감소액(취득)        
         EndGainAmt          DECIMAL(19,5)   , -- 기말취득가액        
         BasicDepreAmt       DECIMAL(19,5)   , -- 기초상각누계액        
         TermAddDepreAmt     DECIMAL(19,5)   , -- 당기상각증가액       
         TermDecDepreAmt     DECIMAL(19,5)   , -- 당기상각감소액        
         EndDepreAmt         DECIMAL(19,5)   , -- 기말상각누계액        
   ToMonDepreAmt       DECIMAL(19,5)   , -- 당월상각액         -- 우선 Temp에는 두지만, 화면에서는 제외시킴        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- 기초미상각잔액        
         EndNotDepreAmt      DECIMAL(19,5)   , -- 기말미상각잔액        
         TermAddEstAmt       DECIMAL(19,5)   , -- 당기자산증가액(자본적지출)        
         TermDecEstAmt       DECIMAL(19,5)   , -- 당기자산증가액(자본적지출)        
         DepreCptAmt         DECIMAL(19,5)   )         
         
     -- 기초취득가액, 기초상각누계액, 기초미상각잔액        
     INSERT INTO #TempBfr (AsstSeq, GainAmt, TermAddAmt, TermDecAmt, EndGainAmt,        
                           BasicDepreAmt, TermAddDepreAmt, TermDecDepreAmt, EndDepreAmt,        
                           ToMonDepreAmt, BasicNotDepreAmt, EndNotDepreAmt,         
                           TermAddEstAmt, TermDecEstAmt, DepreCptAmt)        
         SELECT a.AsstSeq, ISNULL(SUM(a.GainDrAmt - a.GainCrAmt), 0), 0, 0, 0,         
                           ISNULL(SUM(a.DepreCrAmt - a.DepreDrAmt), 0) + ISNULL(SUM(a.ImpairCrAmt - a.ImpairDrAmt), 0), 0, 0, 0,       
                           0, ISNULL(SUM(( a.GainDrAmt - a.GainCrAmt ) - ( a.DepreCrAmt - a.DepreDrAmt ) - ( a.ImpairCrAmt - a.ImpairDrAmt )), 0), 0,        
                           0, 0, 0        
           FROM _TACAsstInOut AS a WITH (NOLOCK) JOIN #Asst AS t        
                                                   ON a.AsstSeq      = t.AsstSeq        
                                                 JOIN dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS val        
                                                   ON a.SMAccStd     = val.Val        
          WHERE a.CompanySeq     = @CompanySeq        
            AND a.ChgDate        < @QueryYMFr + '01'        
          GROUP BY a.AsstSeq        
         
     -- 당기자산증가액(취득), 당기자산감소액(취득), 당기상각증가액, 당기상각감소액, 당기자산증가액(자본적지출), 당기자산감소액(자본적지출)        
     INSERT INTO #TempBfr (AsstSeq, GainAmt, TermAddAmt, TermDecAmt, EndGainAmt,        
                           BasicDepreAmt, TermAddDepreAmt, TermDecDepreAmt, EndDepreAmt,        
                           ToMonDepreAmt, BasicNotDepreAmt, EndNotDepreAmt,         
                           TermAddEstAmt,         
                           TermDecEstAmt,         
                           DepreCptAmt)        
         SELECT a.AsstSeq, 0, ISNULL(SUM(CASE WHEN a.SMGainType = 4117001 THEN a.GainDrAmt ELSE 0 END), 0), ISNULL(SUM(CASE WHEN a.SMGainType = 4117001 THEN a.GainCrAmt ELSE 0 END), 0), 0,         
                           0, ISNULL(SUM(a.DepreCrAmt + a.ImpairCrAmt), 0), ISNULL(SUM(a.DepreDrAmt + a.ImpairDrAmt), 0), 0,        
                           0, 0, 0,        
                           ISNULL(SUM(CASE WHEN a.SMGainType = 4117002 THEN a.GainDrAmt ELSE 0 END), 0), ISNULL(SUM(CASE WHEN a.SMGainType = 4117002 THEN a.GainCrAmt ELSE 0 END), 0),        
                           ISNULL(SUM(( a.GainDrAmt - a.GainCrAmt ) - ( a.DepreCrAmt - a.DepreDrAmt ) - ( a.ImpairCrAmt - a.ImpairDrAmt )), 0)        
           FROM _TACAsstInOut AS a WITH (NOLOCK) JOIN #Asst AS t        
                                                   ON a.AsstSeq      = t.AsstSeq        
                                                 JOIN dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS val        
                                                   ON a.SMAccStd     = val.Val        
          WHERE a.CompanySeq     = @CompanySeq        
            AND a.ChgDate       >= @QueryYMFr + '01'        
            AND a.ChgDate       <= @QueryYMTo + '31'        
          GROUP BY a.AsstSeq        
         
     -- 기말취득가액, 기말상각누계액, 기말미상각잔액        
     INSERT INTO #TempBfr (AsstSeq, GainAmt, TermAddAmt, TermDecAmt, EndGainAmt,        
                           BasicDepreAmt, TermAddDepreAmt, TermDecDepreAmt, EndDepreAmt,        
                           ToMonDepreAmt, BasicNotDepreAmt, EndNotDepreAmt,         
                           TermAddEstAmt, TermDecEstAmt, DepreCptAmt)        
         SELECT a.AsstSeq, 0, 0, 0, ISNULL(SUM(a.GainDrAmt - a.GainCrAmt), 0),         
                           0, 0, 0, ISNULL(SUM(a.DepreCrAmt - a.DepreDrAmt), 0) + ISNULL(SUM(a.ImpairCrAmt - a.ImpairDrAmt), 0),        
                           0, 0, ISNULL(SUM(( a.GainDrAmt - a.GainCrAmt ) - ( a.DepreCrAmt - a.DepreDrAmt ) - ( a.ImpairCrAmt - a.ImpairDrAmt )), 0),        
                           0, 0, 0        
           FROM _TACAsstInOut AS a WITH (NOLOCK) JOIN #Asst AS t        
                                                   ON a.AsstSeq      = t.AsstSeq        
                                                 JOIN dbo._FCOMBitMask(@BitCnt, @SMAccStd) AS val        
                                                   ON a.SMAccStd  = val.Val        
          WHERE a.CompanySeq     = @CompanySeq        
            AND a.ChgDate       <= @QueryYMTo + '31'        
          GROUP BY a.AsstSeq        
         
     --------------------------------------------------------------------------------------------------------------        
     -- 당월상각액 (ToDate기준) 화면에서 삭제함        
     -- 화면상 DataFieldName = ToMonDepreAmt 였음        
     -- 오해의 소지만 생길 뿐 필요없는 컬럼으로 판단됨 (화면상 Column Delete)        
     -- 더군다나 손상누계액까지 있기때문에, 순수한 감가상만만을 보여줄지도 의문임..        
     --------------------------------------------------------------------------------------------------------------        
         
     -- 정리        
     INSERT INTO #TACAsstInOut (AsstSeq, GainAmt, TermAddAmt, TermDecAmt, EndGainAmt,        
                                BasicDepreAmt, TermAddDepreAmt, TermDecDepreAmt, EndDepreAmt,        
            ToMonDepreAmt, BasicNotDepreAmt, EndNotDepreAmt, TermAddEstAmt, TermDecEstAmt, DepreCptAmt)        
         SELECT a.AsstSeq, ISNULL(SUM(a.GainAmt), 0), ISNULL(SUM(a.TermAddAmt), 0), ISNULL(SUM(a.TermDecAmt), 0), ISNULL(SUM(a.EndGainAmt), 0),        
                           ISNULL(SUM(a.BasicDepreAmt), 0), ISNULL(SUM(a.TermAddDepreAmt), 0), ISNULL(SUM(a.TermDecDepreAmt), 0), ISNULL(SUM(a.EndDepreAmt), 0),        
                           ISNULL(SUM(a.ToMonDepreAmt), 0), ISNULL(SUM(a.BasicNotDepreAmt), 0), ISNULL(SUM(a.EndNotDepreAmt), 0),        
                           ISNULL(SUM(a.TermAddEstAmt), 0), ISNULL(SUM(a.TermDecEstAmt), 0), ISNULL(SUM(a.DepreCptAmt),0)        
           FROM #TempBfr AS a        
          GROUP BY a.AsstSeq        
  
     --자산계정별 현황을 위한 최종테이블
     CREATE TABLE #TACAsstAccList
     (
         BizUnitName         NVARCHAR(200),
         AsstName            NVARCHAR(200),
         AsstNo              NVARCHAR(200),
         GainDate            NCHAR(8),
         AccName             NVARCHAR(200),
         GainQty             DECIMAL(19,5),
         GainAmt             DECIMAL(19,5),
         GainCustName        NVARCHAR(200),
         DeptName            NVARCHAR(200),
         DepreAccName        NVARCHAR(200),
         SrtDepreYM          NCHAR(6),
         EndDepreYM          NCHAR(6),
         UseYear             INT   , -- 내용년수        
         DepreRate           DECIMAL(19,5)   , -- 상각률        
         IsRemAmtCheck       NCHAR(1)   , -- 잔액기준상각
         IsRemUseMonDepre    NCHAR(1)   , -- 잔존내용연수기준정액상각 2011.04.22 추가           
         BasicGainAmt        DECIMAL(19,5)   , -- 기초취득가액        
         TermAddAmt          DECIMAL(19,5)   , -- 당기자산증가액(취득)        
         TermDecAmt          DECIMAL(19,5)   , -- 당기자산감소액(취득)        
         EndGainAmt          DECIMAL(19,5)   , -- 기말취득가액        
         BasicDepreAmt       DECIMAL(19,5)   , -- 기초상각누계액        
         TermAddDepreAmt     DECIMAL(19,5)   , -- 당기상각증가액        
         TermDecDepreAmt     DECIMAL(19,5)   , -- 당기상각감소액        
         EndDepreAmt         DECIMAL(19,5)   , -- 기말상각누계액        
         ToMonDepreAmt       DECIMAL(19,5)   , -- 당월상각액        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- 기초미상각잔액        
         EndNotDepreAmt      DECIMAL(19,5)   , -- 기말미상각잔액        
         AsstSeq             INT   , -- 자산번호내부코드        
         TermAddEstAmt       DECIMAL(19,5)   , -- 당기자산증가액(자본적지출)        
         TermDecEstAmt       DECIMAL(19,5)    , -- 당기자산감소액(자본적지출)        
         RemainAmt           DECIMAL(19,5)   , -- 최종잔존가액 
         CCtrName            NVARCHAR(200), -- 활동센터명
         CCtrSeq             INT     -- 활동센터코드             
     )
          
     IF @SMAccStd = 2        
     BEGIN        
         
         INSERT INTO #TACAsstAccList (
                                     BizUnitName         ,
                                     AsstName            ,
                                     AsstNo              ,
                                     GainDate            ,
                                     AccName             ,
                                     GainQty             ,
                                     GainAmt             ,
                                     GainCustName        ,
                                     DeptName            ,
                                     DepreAccName        ,
                                     SrtDepreYM          ,
                                     EndDepreYM          ,
                                     UseYear             ,
                                     DepreRate           ,
                                     IsRemAmtCheck       ,
                                     IsRemUseMonDepre    ,  
                                     BasicGainAmt        ,
                                     TermAddAmt          ,
                                     TermDecAmt          ,
                                     EndGainAmt          ,
                                     BasicDepreAmt       ,
                                     TermAddDepreAmt     ,
                                     TermDecDepreAmt     ,
                                     EndDepreAmt         ,
                                     ToMonDepreAmt       ,
                                     BasicNotDepreAmt    ,
                                     EndNotDepreAmt      ,
                                     AsstSeq             ,
                                     TermAddEstAmt       ,
                                     TermDecEstAmt       ,
                                     RemainAmt           ,
                                     CCtrName            ,
                                     CCtrSeq              
                                     )
         SELECT  ISNULL(Biz.BizUnitName          , '') AS BizUnitName            , -- 사업부문        
                 ISNULL(asst.AsstName            , '') AS AsstName               , -- 자산명        
                 ISNULL(asst.AsstNo              , '') AS AsstNo                 , -- 자산번호        
                 ISNULL(asst.GainDate            , '') AS GainDate               , -- 취득일        
                 ISNULL(acc.AccName              , '') AS AccName                , -- 취득계정        
                 ISNULL(asst.GainQty             ,  0) AS GainQty                , -- 취득수량        
                 ISNULL(asst.GainAmt             ,  0) AS GainAmt                , -- 취득가액        
                 ISNULL(Cust.CustName            , '') AS GainCustName           , -- 취득처        
                 ISNULL(Dept.DeptName            , '') AS DeptName               , -- 관리부서        
 --                ISNULL(Dacc.AccName             , '') AS DepreAccName           , -- 상각계정        
                 CASE WHEN ISNULL(E.AccName, '') > '' THEN ISNULL(E.AccName, '')
                      ELSE ISNULL(Dacc.AccName, '') END AS DepreAccName          , -- 상각계정 2011.08.16 -- E.Accname이 없으면 기존처럼...
 --                ISNULL(E.AccName                , '') AS DepreAccName           , -- 상각계정 2011.02.24 사용부서관리의 상각계정으로 변경        
                 ISNULL(hist.SrtDepreYM          , '') AS SrtDepreYM             , -- 상각시작년월        
                 ISNULL(hist.EndDepreYM          , '') AS EndDepreYM             , -- 상각완료년월        
                 ISNULL(hist.UseYear             , '') AS UseYear                , -- 내용년수        
                 ISNULL(hist.DepreRate           , '') AS DepreRate              , -- 상각률        
                 ISNULL(hist.IsRemAmtCheck       , '') AS IsRemAmtCheck          , -- 잔액기준상각
                 ISNULL(asst.IsRemUseMonDepre    ,'0') AS IsRemUseMonDepre       , -- 잔존내용연수기준정액상각 2011.04.22 추가           
                 ISNULL(t.GainAmt                ,  0) AS BasicGainAmt           , -- 기초취득가액        
                 ISNULL(t.TermAddAmt             ,  0) AS TermAddAmt             , -- 당기자산증가액(취득)        
                 ISNULL(t.TermDecAmt             ,  0) AS TermDecAmt             , -- 당기자산감소액(취득)        
                 ISNULL(t.EndGainAmt             ,  0) AS EndGainAmt             , -- 기말취득가액        
                 ISNULL(t.BasicDepreAmt          ,  0) AS BasicDepreAmt          , -- 기초상각누계액        
                 ISNULL(t.TermAddDepreAmt        ,  0) AS TermAddDepreAmt        , -- 당기상각증가액        
                 ISNULL(t.TermDecDepreAmt        ,  0) AS TermDecDepreAmt        , -- 당기상각감소액        
                 ISNULL(t.EndDepreAmt            ,  0) AS EndDepreAmt            , -- 기말상각누계액        
                 ISNULL(t.ToMonDepreAmt          ,  0) AS ToMonDepreAmt          , -- 당월상각액        
                 ISNULL(t.BasicNotDepreAmt       ,  0) AS BasicNotDepreAmt       , -- 기초미상각잔액        
                 ISNULL(t.EndNotDepreAmt         ,  0) AS EndNotDepreAmt         , -- 기말미상각잔액        
                 ISNULL(asst.AsstSeq             ,  0) AS AsstSeq                , -- 자산번호내부코드        
                 ISNULL(t.TermAddEstAmt          ,  0) AS TermAddEstAmt          , -- 당기자산증가액(자본적지출)        
                 ISNULL(t.TermDecEstAmt          ,  0) AS TermDecEstAmt          , -- 당기자산감소액(자본적지출)        
                 ISNULL(hist.RemainAmt           ,  0) AS RemainAmt              , -- 최종잔존가액 
                 ISNULL(CCtr.CCtrName            , '') AS CCtrName               , -- 활동센터명
                 ISNULL(CCtr.CCtrSeq             ,  0) AS CCtrSeq                  -- 활동센터코드
                 
            FROM _TACAsst AS asst WITH (NOLOCK) LEFT OUTER JOIN _TDABizUnit AS Biz WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Biz.CompanySeq        
                                                 AND asst.BizUnit        = Biz.BizUnit        
                                                JOIN _TACAsstText AS info WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = info.CompanySeq        
                                                 AND asst.AsstSeq        = info.AsstSeq        
                     JOIN _TACAsstDepreStdHist AS hist ON hist.CompanySeq   = asst.CompanySeq        
                                                         AND asst.AsstSeq         = hist.AsstSeq        
                        JOIN (SELECT AsstSeq, MAX(HistSerl) AS HistSerl        
                               FROM _TACAsstDepreStdHist        
                              WHERE CompanySeq     = @CompanySeq        
                                --AND @FromEndYM  >= EffectiveYM        
                              GROUP BY AsstSeq) AS sub    ON asst.AsstSeq         = sub.AsstSeq        
                                                         AND hist.HistSerl     = sub.HistSerl                                                          
                                                JOIN _TACAsstDefault AS de WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = de.CompanySeq        
                                                 AND asst.AsstTypeSeq    = de.AsstTypeSeq        
                                                JOIN _TACAsstAccSet AS accset WITH (NOLOCK)        
                          ON asst.CompanySeq     = accset.CompanySeq        
                                                 AND de.AsstAccTypeSeq   = accset.AsstAccTypeSeq        
                                                LEFT OUTER JOIN _TDAAccount AS acc WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = acc.CompanySeq        
                                                AND accset.GainAccSeq   = acc.AccSeq        
                                                LEFT OUTER JOIN _TDAAccount AS Dacc WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Dacc.CompanySeq        
                                                 AND de.DepreAccSeq      = Dacc.AccSeq        
                                                LEFT OUTER JOIN _TDACust AS Cust WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Cust.CompanySeq        
                                                 AND asst.GainCustSeq    = Cust.CustSeq        
                                                LEFT OUTER JOIN _TDADept AS Dept WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Dept.CompanySeq        
                                                 AND asst.DeptSeq        = Dept.DeptSeq        
                                                LEFT OUTER JOIN #TACAsstInOut AS t        
                                                  ON asst.AsstSeq        = t.AsstSeq        
                                                LEFT OUTER JOIN _TACAsstDept AS D WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = D.CompanySeq        
                                                 AND asst.AsstSeq        = D.AsstSeq        
                                                 AND D.DeptSerl          = 1        
                                                LEFT OUTER JOIN _TDAAccount AS E WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = E.CompanySeq        
                                                 AND D.AccSeq            = E.AccSeq 
                                                LEFT OUTER JOIN _TDACCtr      AS CCtr
                                                  ON asst.CompanySeq     = CCtr.CompanySeq
                                                 AND D.CCtrSeq           = CCtr.CCtrSeq 
                                                --LEFT OUTER JOIN _TDASMinor AS minor ON asst.CompanySeq = minor.CompanySeq   
                                                -- AND acc.SMAccType = minor.MinorSeq        
           WHERE 1 = 1        
             AND asst.CompanySeq         = @CompanySeq        
             AND asst.AsstSeq           IN (SELECT AsstSeq FROM #Asst)        
             --AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (T.BasicNotDepreAmt <= info.RemainAmt))   --수정 EndNotDepreAmt -> BasicNotDepreAmt      
             --                   OR (@DepreCpt = 4518002 AND (T.BasicNotDepreAmt > info.RemainAmt)) )  --수정 EndNotDepreAmt -> BasicNotDepreAmt  
             AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (ISNULL(T.BasicNotDepreAmt,0) = 0 
                                                             AND ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))= 0
                                                                     OR ISNULL(T.EndNotDepreAmt,0) = 0)
                                                                     )
                                   )  
                                      --기초미상각잔액이 0이고 (당기자산증가액 - 당기자산감소액이 0이거나 기말미상각잔액이 0인것을 상각완료로 판단.
                                OR (@DepreCpt = 4518002 AND (ISNULL(T.BasicNotDepreAmt,0) <> 0 
                                                             OR ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))<> 0
                                                                     AND ISNULL(T.EndNotDepreAmt,0) <> 0)
                                                                     )
                                    )
                 )     
             AND ((@DepreAccSeq   = 0     OR de.DepreAccSeq   = @DepreAccSeq) OR (@DepreAccSeq = 0 OR d.AccSeq = @DepreAccSeq))  --2011.04.19 허광호 수정  
             AND (@SMAccType     = 0     OR acc.SMAccType    = @SMAccType)       
         
     END        
     ELSE        
     BEGIN      
         INSERT INTO #TACAsstAccList (
                                     BizUnitName         ,
                                     AsstName            ,
                                     AsstNo              ,
                                     GainDate            ,
                                     AccName             ,
                                     GainQty             ,
                                     GainAmt             ,
                                     GainCustName        ,
                                     DeptName            ,
                                     DepreAccName        ,
                                     SrtDepreYM          ,
                                     EndDepreYM          ,
                                     UseYear             ,
                                     DepreRate           ,
                                     IsRemAmtCheck       ,
                                     IsRemUseMonDepre    ,  
                                     BasicGainAmt        ,
                                     TermAddAmt          ,
                                     TermDecAmt          ,
                                     EndGainAmt          ,
                                     BasicDepreAmt       ,
                                     TermAddDepreAmt     ,
                                     TermDecDepreAmt     ,
                                     EndDepreAmt         ,
                                     ToMonDepreAmt       ,
                                     BasicNotDepreAmt    ,
                                     EndNotDepreAmt      ,
                                     AsstSeq             ,
                                     TermAddEstAmt       ,
                                     TermDecEstAmt       ,
                                     RemainAmt           ,
                                     CCtrName            ,
                                     CCtrSeq                           
                                     )    
         SELECT  ISNULL(Biz.BizUnitName          , '') AS BizUnitName            , -- 사업부문        
                 ISNULL(asst.AsstName            , '') AS AsstName               , -- 자산명        
                 ISNULL(asst.AsstNo              , '') AS AsstNo                 , -- 자산번호        
                 ISNULL(asst.GainDate            , '') AS GainDate               , -- 취득일        
                 ISNULL(acc.AccName              , '') AS AccName                , -- 취득계정        
                 ISNULL(asst.GainQty             ,  0) AS GainQty                , -- 취득수량        
                 ISNULL(asst.GainAmt             ,  0) AS GainAmt                , -- 취득가액        
                 ISNULL(Cust.CustName            , '') AS GainCustName           , -- 취득처        
                 ISNULL(Dept.DeptName            , '') AS DeptName               , -- 관리부서        
 --                ISNULL(Dacc.AccName             , '') AS DepreAccName           , -- 상각계정    
                 CASE WHEN ISNULL(E.AccName, '') > '' THEN ISNULL(E.AccName, '')
                      ELSE ISNULL(Dacc.AccName, '') END AS DepreAccName          , -- 상각계정 2011.08.16 -- E.Accname이 없으면 기존처럼...
 --                ISNULL(E.AccName                , '') AS DepreAccName           , -- 상각계정 2011.02.24 사용부서관리의 상각계정으로 변경        
                 ISNULL(info.SrtDepreYM          , '') AS SrtDepreYM             , -- 상각시작년월        
                 ISNULL(info.EndDepreYM          , '') AS EndDepreYM             , -- 상각완료년월        
                 ISNULL(info.UseYear             , '') AS UseYear                , -- 내용년수        
                 ISNULL(info.DepreRate           , '') AS DepreRate              , -- 상각률        
                 ISNULL(info.IsRemAmtCheck       , '') AS IsRemAmtCheck          , -- 잔액기준상각
                 ISNULL(asst.IsRemUseMonDepre    ,'0') AS IsRemUseMonDepre       , -- 잔존내용연수기준정액상각 2011.04.22 추가           
                 ISNULL(t.GainAmt                ,  0) AS BasicGainAmt           , -- 기초취득가액        
                 ISNULL(t.TermAddAmt             ,  0) AS TermAddAmt             , -- 당기자산증가액(취득)        
                 ISNULL(t.TermDecAmt             ,  0) AS TermDecAmt             , -- 당기자산감소액(취득)        
                 ISNULL(t.EndGainAmt           ,  0) AS EndGainAmt             , -- 기말취득가액        
                 ISNULL(t.BasicDepreAmt          ,  0) AS BasicDepreAmt          , -- 기초상각누계액        
                 ISNULL(t.TermAddDepreAmt        ,  0) AS TermAddDepreAmt        , -- 당기상각증가액        
                 ISNULL(t.TermDecDepreAmt        ,  0) AS TermDecDepreAmt        , -- 당기상각감소액        
                 ISNULL(t.EndDepreAmt            ,  0) AS EndDepreAmt            , -- 기말상각누계액        
                 ISNULL(t.ToMonDepreAmt          ,  0) AS ToMonDepreAmt          , -- 당월상각액        
                 ISNULL(t.BasicNotDepreAmt       ,  0) AS BasicNotDepreAmt       , -- 기초미상각잔액        
                 ISNULL(t.EndNotDepreAmt         ,  0) AS EndNotDepreAmt         , -- 기말미상각잔액        
                 ISNULL(asst.AsstSeq             ,  0) AS AsstSeq                , -- 자산번호내부코드        
                 ISNULL(t.TermAddEstAmt          ,  0) AS TermAddEstAmt          , -- 당기자산증가액(자본적지출)        
                 ISNULL(t.TermDecEstAmt          ,  0) AS TermDecEstAmt          , -- 당기자산감소액(자본적지출)        
                 ISNULL(info.RemainAmt           ,  0) AS RemainAmt              , -- 최종잔존가액 
                 ISNULL(CCtr.CCtrName            , '') AS CCtrName               , -- 활동센터명
                 ISNULL(CCtr.CCtrSeq             ,  0) AS CCtrSeq                 -- 활동센터코드            
                           
            FROM _TACAsst AS asst WITH (NOLOCK) LEFT OUTER JOIN _TDABizUnit AS Biz WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Biz.CompanySeq        
                                                 AND asst.BizUnit        = Biz.BizUnit        
                                                JOIN _TACAsstText AS info WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = info.CompanySeq        
                                                 AND asst.AsstSeq        = info.AsstSeq        
                                                JOIN _TACAsstDefault AS de WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = de.CompanySeq        
                                                 AND asst.AsstTypeSeq    = de.AsstTypeSeq        
                                                JOIN _TACAsstAccSet AS accset WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = accset.CompanySeq        
                                                 AND de.AsstAccTypeSeq   = accset.AsstAccTypeSeq        
                                                LEFT OUTER JOIN _TDAAccount AS acc WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = acc.CompanySeq        
                                               AND accset.GainAccSeq   = acc.AccSeq        
                                                LEFT OUTER JOIN _TDAAccount AS Dacc WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Dacc.CompanySeq        
                            AND de.DepreAccSeq      = Dacc.AccSeq        
                                                LEFT OUTER JOIN _TDACust AS Cust WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = Cust.CompanySeq        
                                                 AND asst.GainCustSeq    = Cust.CustSeq        
                                                LEFT OUTER JOIN _TDADept AS Dept WITH (NOLOCK)        
                                                  ON asst.CompanySeq      = Dept.CompanySeq        
                                                 AND asst.DeptSeq        = Dept.DeptSeq        
                                                LEFT OUTER JOIN #TACAsstInOut AS t        
                                                  ON asst.AsstSeq        = t.AsstSeq        
                                                LEFT OUTER JOIN _TACAsstDept AS D WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = D.CompanySeq        
                                                 AND asst.AsstSeq        = D.AsstSeq        
                                                 AND D.DeptSerl          = 1        
                                                LEFT OUTER JOIN _TDAAccount AS E WITH (NOLOCK)        
                                                  ON asst.CompanySeq     = E.CompanySeq        
                                                 AND D.AccSeq            = E.AccSeq  
                                                LEFT OUTER JOIN _TDACCtr      AS CCtr
                                                  ON asst.CompanySeq     = CCtr.CompanySeq
                                                 AND D.CCtrSeq           = CCtr.CCtrSeq
                                                --LEFT OUTER JOIN _TDASMinor AS minor ON asst.CompanySeq = minor.CompanySeq   
                                                -- AND acc.SMAccType = minor.MinorSeq        
           WHERE 1 = 1        
             AND asst.CompanySeq         = @CompanySeq        
             AND asst.AsstSeq           IN (SELECT AsstSeq FROM #Asst)        
             --AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (T.BasicNotDepreAmt <= info.RemainAmt))  --수정 EndNotDepreAmt -> BasicNotDepreAmt      
             --                   OR (@DepreCpt = 4518002 AND (T.BasicNotDepreAmt > info.RemainAmt)) ) --수정 EndNotDepreAmt -> BasicNotDepreAmt      
             AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND ((ISNULL(T.BasicNotDepreAmt,0)) = 0 
                                                             AND ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))= 0) 
                                                                     OR (ISNULL(T.EndNotDepreAmt,0)- ISNULL(info.RemainAmt,0)) = 0
                                                                     )
                                   )  
                                      --기초미상각잔액이 0이고 (당기자산증가액 - 당기자산감소액이 0이거나 기말미상각잔액이 0인것을 상각완료로 판단.
                                OR (@DepreCpt = 4518002 AND (--((ISNULL(T.BasicNotDepreAmt,0)) <> 0 
                                                              ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))<> 0
                                                                     OR (ISNULL(T.EndNotDepreAmt,0)- ISNULL(info.RemainAmt,0)) <> 0)
                                                                     )
                                    )
                 )
             AND ((@DepreAccSeq = 0 OR de.DepreAccSeq = @DepreAccSeq)OR (@DepreAccSeq = 0 OR d.AccSeq = @DepreAccSeq)) 
             AND (@SMAccType = 0 OR acc.SMAccType = @SMAccType)        
     END                                                    
     
       
                 
                     
     SELECT  ISNULL(a.BizUnitName          , '') AS BizUnitName            , -- 사업부문
             ISNULL(a.AccName              , '') AS AccName                , -- 취득계정
             ISNULL(a.DeptName             , '') AS DeptName               , -- 관리부서 
             ISNULL(SUM(a.BasicGainAmt      ),  0) AS BasicGainAmt           , -- 기초취득가액
             ISNULL(SUM(a.TermAddAmt        ),  0) + ISNULL(SUM(a.TermAddEstAmt),0) AS TermAddAmt             , -- 당기자산증가액
             ISNULL(SUM(a.TermDecAmt        ),  0) + ISNULL(SUM(a.TermDecEstAmt),0) AS TermDecAmt             , -- 당기자산감소액
             ISNULL(SUM(a.EndGainAmt        ),  0) AS EndGainAmt             , -- 기말취득가액
              ISNULL(SUM(a.BasicDepreAmt     ),  0) AS BasicDepreAmt          , -- 기초상각누계액
             ISNULL(SUM(a.TermAddDepreAmt   ),  0) AS TermAddDepreAmt        , -- 당기상각증가액
             ISNULL(SUM(a.TermDecDepreAmt   ),  0) AS TermDecDepreAmt        , -- 당기상각감소액
             ISNULL(SUM(a.EndDepreAmt       ),  0) AS EndDepreAmt            , -- 기말상각누계액
              ISNULL(SUM(a.ToMonDepreAmt     ),  0) AS ToMonDepreAmt          , -- 당월상각액
             ISNULL(SUM(a.BasicNotDepreAmt  ),  0) AS BasicNotDepreAmt       , -- 기초미상각잔액
             ISNULL(SUM(a.EndNotDepreAmt    ),  0) AS EndNotDepreAmt           -- 기말미상각잔액
        FROM #TACAsstAccList AS a 
       GROUP BY a.BizUnitName, a.AccName, a.DeptName
            
  RETURN
GO
exec amoerp_SACAsstDeptAccDepreListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit />
    <DispoFin>0</DispoFin>
    <QueryYMFr>201301</QueryYMFr>
    <QueryYMTo>201312</QueryYMTo>
    <AccSeq />
    <SMAccType />
    <DepreCpt />
    <SMAccStd>1</SMAccStd>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020288,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017059