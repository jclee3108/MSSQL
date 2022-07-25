
IF OBJECT_ID('amoerp_SACAsstDeptAccDepreListQuery') IS NOT NULL 
    DROP PROC amoerp_SACAsstDeptAccDepreListQuery
GO 

-- v2013.12.31 

-- �����μ��� ������ ����ȸ_amoerp by����õ

/************************************************************
 �ۼ��� - 2008�� 11�� 23��
 ������ - 2011�� 11�� 3��    ������  �ڻ꺰 ����ȸ�� ������ �������� ����, ������ ��ȸ�� �������� ��ȸ�ǰ� �Ѵ�. 
 �ۼ��� - �ڱټ�
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
     -- �Ⱓ���� ó�пϷ�� �ڻ����Կ� üũ���� ���� ��� 100%ó���ڻ� ���� -- 2010.12.04 by bgKeum START        
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
                                           AND A.SMDepreType     = 4118002               -- ó���� �ִ� �ڻ�        
                                           AND A.ChgDate         < @QueryYMFr + '01')    -- ��ȸ������ ����
                AND A.ChgDate         < @QueryYMFr + '01'  
              GROUP BY A.AsstSeq        
              HAVING SUM(A.GainDrAmt) - SUM(A.GainCrAmt) = 0 -- �ܾ��� 0�� �ڻ��� 100% ó���ڻ����� �ν���        
         
         -- ��󿡼� ����        
         DELETE #Asst WHERE AsstSeq IN (SELECT AsstSeq FROM #DispoFin)         
     END        
     --================================================================================================================        
     -- �Ⱓ���� ó�пϷ�� �ڻ����Կ� üũ���� ���� ��� 100%ó���ڻ� ���� -- 2010.12.04 by bgKeum END        
     --================================================================================================================        
         
     CREATE TABLE #TempBfr (        
         AsstSeq             INT             , -- �ڻ��ڵ�        
         GainAmt             DECIMAL(19,5)   , -- ������氡��        
         TermAddAmt          DECIMAL(19,5)   , -- ����ڻ�������(���)        
         TermDecAmt          DECIMAL(19,5)   , -- ����ڻ갨�Ҿ�(���)        
         EndGainAmt          DECIMAL(19,5)   , -- �⸻��氡��        
         BasicDepreAmt       DECIMAL(19,5)   , -- ���ʻ󰢴����        
         TermAddDepreAmt     DECIMAL(19,5)   , -- ����������        
         TermDecDepreAmt     DECIMAL(19,5)   , -- ���󰢰��Ҿ�        
         EndDepreAmt         DECIMAL(19,5)   , -- �⸻�󰢴����        
         ToMonDepreAmt       DECIMAL(19,5)   , -- ����󰢾�         -- �켱 Temp���� ������, ȭ�鿡���� ���ܽ�Ŵ        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- ���ʹ̻��ܾ�        
         EndNotDepreAmt      DECIMAL(19,5)   , -- �⸻�̻��ܾ�        
   TermAddEstAmt       DECIMAL(19,5)   , -- ����ڻ�������(�ں�������)        
   TermDecEstAmt       DECIMAL(19,5)   , -- ����ڻ�������(�ں�������)        
         DepreCptAmt         DECIMAL(19,5)   )         
         
    
     CREATE TABLE #TACAsstInOut (        
         AsstSeq             INT             , -- �ڻ��ڵ�        
         GainAmt             DECIMAL(19,5)   , -- ������氡��        
         TermAddAmt          DECIMAL(19,5)   , -- ����ڻ�������(���)        
         TermDecAmt          DECIMAL(19,5)   , -- ����ڻ갨�Ҿ�(���)        
         EndGainAmt          DECIMAL(19,5)   , -- �⸻��氡��        
         BasicDepreAmt       DECIMAL(19,5)   , -- ���ʻ󰢴����        
         TermAddDepreAmt     DECIMAL(19,5)   , -- ����������       
         TermDecDepreAmt     DECIMAL(19,5)   , -- ���󰢰��Ҿ�        
         EndDepreAmt         DECIMAL(19,5)   , -- �⸻�󰢴����        
   ToMonDepreAmt       DECIMAL(19,5)   , -- ����󰢾�         -- �켱 Temp���� ������, ȭ�鿡���� ���ܽ�Ŵ        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- ���ʹ̻��ܾ�        
         EndNotDepreAmt      DECIMAL(19,5)   , -- �⸻�̻��ܾ�        
         TermAddEstAmt       DECIMAL(19,5)   , -- ����ڻ�������(�ں�������)        
         TermDecEstAmt       DECIMAL(19,5)   , -- ����ڻ�������(�ں�������)        
         DepreCptAmt         DECIMAL(19,5)   )         
         
     -- ������氡��, ���ʻ󰢴����, ���ʹ̻��ܾ�        
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
         
     -- ����ڻ�������(���), ����ڻ갨�Ҿ�(���), ����������, ���󰢰��Ҿ�, ����ڻ�������(�ں�������), ����ڻ갨�Ҿ�(�ں�������)        
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
         
     -- �⸻��氡��, �⸻�󰢴����, �⸻�̻��ܾ�        
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
     -- ����󰢾� (ToDate����) ȭ�鿡�� ������        
     -- ȭ��� DataFieldName = ToMonDepreAmt ����        
     -- ������ ������ ���� �� �ʿ���� �÷����� �Ǵܵ� (ȭ��� Column Delete)        
     -- �����ٳ� �ջ󴩰�ױ��� �ֱ⶧����, ������ �����󸸸��� ���������� �ǹ���..        
     --------------------------------------------------------------------------------------------------------------        
         
     -- ����        
     INSERT INTO #TACAsstInOut (AsstSeq, GainAmt, TermAddAmt, TermDecAmt, EndGainAmt,        
                                BasicDepreAmt, TermAddDepreAmt, TermDecDepreAmt, EndDepreAmt,        
            ToMonDepreAmt, BasicNotDepreAmt, EndNotDepreAmt, TermAddEstAmt, TermDecEstAmt, DepreCptAmt)        
         SELECT a.AsstSeq, ISNULL(SUM(a.GainAmt), 0), ISNULL(SUM(a.TermAddAmt), 0), ISNULL(SUM(a.TermDecAmt), 0), ISNULL(SUM(a.EndGainAmt), 0),        
                           ISNULL(SUM(a.BasicDepreAmt), 0), ISNULL(SUM(a.TermAddDepreAmt), 0), ISNULL(SUM(a.TermDecDepreAmt), 0), ISNULL(SUM(a.EndDepreAmt), 0),        
                           ISNULL(SUM(a.ToMonDepreAmt), 0), ISNULL(SUM(a.BasicNotDepreAmt), 0), ISNULL(SUM(a.EndNotDepreAmt), 0),        
                           ISNULL(SUM(a.TermAddEstAmt), 0), ISNULL(SUM(a.TermDecEstAmt), 0), ISNULL(SUM(a.DepreCptAmt),0)        
           FROM #TempBfr AS a        
          GROUP BY a.AsstSeq        
  
     --�ڻ������ ��Ȳ�� ���� �������̺�
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
         UseYear             INT   , -- ������        
         DepreRate           DECIMAL(19,5)   , -- �󰢷�        
         IsRemAmtCheck       NCHAR(1)   , -- �ܾױ��ػ�
         IsRemUseMonDepre    NCHAR(1)   , -- �������뿬���������׻� 2011.04.22 �߰�           
         BasicGainAmt        DECIMAL(19,5)   , -- ������氡��        
         TermAddAmt          DECIMAL(19,5)   , -- ����ڻ�������(���)        
         TermDecAmt          DECIMAL(19,5)   , -- ����ڻ갨�Ҿ�(���)        
         EndGainAmt          DECIMAL(19,5)   , -- �⸻��氡��        
         BasicDepreAmt       DECIMAL(19,5)   , -- ���ʻ󰢴����        
         TermAddDepreAmt     DECIMAL(19,5)   , -- ����������        
         TermDecDepreAmt     DECIMAL(19,5)   , -- ���󰢰��Ҿ�        
         EndDepreAmt         DECIMAL(19,5)   , -- �⸻�󰢴����        
         ToMonDepreAmt       DECIMAL(19,5)   , -- ����󰢾�        
         BasicNotDepreAmt    DECIMAL(19,5)   , -- ���ʹ̻��ܾ�        
         EndNotDepreAmt      DECIMAL(19,5)   , -- �⸻�̻��ܾ�        
         AsstSeq             INT   , -- �ڻ��ȣ�����ڵ�        
         TermAddEstAmt       DECIMAL(19,5)   , -- ����ڻ�������(�ں�������)        
         TermDecEstAmt       DECIMAL(19,5)    , -- ����ڻ갨�Ҿ�(�ں�������)        
         RemainAmt           DECIMAL(19,5)   , -- ������������ 
         CCtrName            NVARCHAR(200), -- Ȱ�����͸�
         CCtrSeq             INT     -- Ȱ�������ڵ�             
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
         SELECT  ISNULL(Biz.BizUnitName          , '') AS BizUnitName            , -- ����ι�        
                 ISNULL(asst.AsstName            , '') AS AsstName               , -- �ڻ��        
                 ISNULL(asst.AsstNo              , '') AS AsstNo                 , -- �ڻ��ȣ        
                 ISNULL(asst.GainDate            , '') AS GainDate               , -- �����        
                 ISNULL(acc.AccName              , '') AS AccName                , -- ������        
                 ISNULL(asst.GainQty             ,  0) AS GainQty                , -- ������        
                 ISNULL(asst.GainAmt             ,  0) AS GainAmt                , -- ��氡��        
                 ISNULL(Cust.CustName            , '') AS GainCustName           , -- ���ó        
                 ISNULL(Dept.DeptName            , '') AS DeptName               , -- �����μ�        
 --                ISNULL(Dacc.AccName             , '') AS DepreAccName           , -- �󰢰���        
                 CASE WHEN ISNULL(E.AccName, '') > '' THEN ISNULL(E.AccName, '')
                      ELSE ISNULL(Dacc.AccName, '') END AS DepreAccName          , -- �󰢰��� 2011.08.16 -- E.Accname�� ������ ����ó��...
 --                ISNULL(E.AccName                , '') AS DepreAccName           , -- �󰢰��� 2011.02.24 ���μ������� �󰢰������� ����        
                 ISNULL(hist.SrtDepreYM          , '') AS SrtDepreYM             , -- �󰢽��۳��        
                 ISNULL(hist.EndDepreYM          , '') AS EndDepreYM             , -- �󰢿Ϸ���        
                 ISNULL(hist.UseYear             , '') AS UseYear                , -- ������        
                 ISNULL(hist.DepreRate           , '') AS DepreRate              , -- �󰢷�        
                 ISNULL(hist.IsRemAmtCheck       , '') AS IsRemAmtCheck          , -- �ܾױ��ػ�
                 ISNULL(asst.IsRemUseMonDepre    ,'0') AS IsRemUseMonDepre       , -- �������뿬���������׻� 2011.04.22 �߰�           
                 ISNULL(t.GainAmt                ,  0) AS BasicGainAmt           , -- ������氡��        
                 ISNULL(t.TermAddAmt             ,  0) AS TermAddAmt             , -- ����ڻ�������(���)        
                 ISNULL(t.TermDecAmt             ,  0) AS TermDecAmt             , -- ����ڻ갨�Ҿ�(���)        
                 ISNULL(t.EndGainAmt             ,  0) AS EndGainAmt             , -- �⸻��氡��        
                 ISNULL(t.BasicDepreAmt          ,  0) AS BasicDepreAmt          , -- ���ʻ󰢴����        
                 ISNULL(t.TermAddDepreAmt        ,  0) AS TermAddDepreAmt        , -- ����������        
                 ISNULL(t.TermDecDepreAmt        ,  0) AS TermDecDepreAmt        , -- ���󰢰��Ҿ�        
                 ISNULL(t.EndDepreAmt            ,  0) AS EndDepreAmt            , -- �⸻�󰢴����        
                 ISNULL(t.ToMonDepreAmt          ,  0) AS ToMonDepreAmt          , -- ����󰢾�        
                 ISNULL(t.BasicNotDepreAmt       ,  0) AS BasicNotDepreAmt       , -- ���ʹ̻��ܾ�        
                 ISNULL(t.EndNotDepreAmt         ,  0) AS EndNotDepreAmt         , -- �⸻�̻��ܾ�        
                 ISNULL(asst.AsstSeq             ,  0) AS AsstSeq                , -- �ڻ��ȣ�����ڵ�        
                 ISNULL(t.TermAddEstAmt          ,  0) AS TermAddEstAmt          , -- ����ڻ�������(�ں�������)        
                 ISNULL(t.TermDecEstAmt          ,  0) AS TermDecEstAmt          , -- ����ڻ갨�Ҿ�(�ں�������)        
                 ISNULL(hist.RemainAmt           ,  0) AS RemainAmt              , -- ������������ 
                 ISNULL(CCtr.CCtrName            , '') AS CCtrName               , -- Ȱ�����͸�
                 ISNULL(CCtr.CCtrSeq             ,  0) AS CCtrSeq                  -- Ȱ�������ڵ�
                 
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
             --AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (T.BasicNotDepreAmt <= info.RemainAmt))   --���� EndNotDepreAmt -> BasicNotDepreAmt      
             --                   OR (@DepreCpt = 4518002 AND (T.BasicNotDepreAmt > info.RemainAmt)) )  --���� EndNotDepreAmt -> BasicNotDepreAmt  
             AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (ISNULL(T.BasicNotDepreAmt,0) = 0 
                                                             AND ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))= 0
                                                                     OR ISNULL(T.EndNotDepreAmt,0) = 0)
                                                                     )
                                   )  
                                      --���ʹ̻��ܾ��� 0�̰� (����ڻ������� - ����ڻ갨�Ҿ��� 0�̰ų� �⸻�̻��ܾ��� 0�ΰ��� �󰢿Ϸ�� �Ǵ�.
                                OR (@DepreCpt = 4518002 AND (ISNULL(T.BasicNotDepreAmt,0) <> 0 
                                                             OR ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))<> 0
                                                                     AND ISNULL(T.EndNotDepreAmt,0) <> 0)
                                                                     )
                                    )
                 )     
             AND ((@DepreAccSeq   = 0     OR de.DepreAccSeq   = @DepreAccSeq) OR (@DepreAccSeq = 0 OR d.AccSeq = @DepreAccSeq))  --2011.04.19 �㱤ȣ ����  
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
         SELECT  ISNULL(Biz.BizUnitName          , '') AS BizUnitName            , -- ����ι�        
                 ISNULL(asst.AsstName            , '') AS AsstName               , -- �ڻ��        
                 ISNULL(asst.AsstNo              , '') AS AsstNo                 , -- �ڻ��ȣ        
                 ISNULL(asst.GainDate            , '') AS GainDate               , -- �����        
                 ISNULL(acc.AccName              , '') AS AccName                , -- ������        
                 ISNULL(asst.GainQty             ,  0) AS GainQty                , -- ������        
                 ISNULL(asst.GainAmt             ,  0) AS GainAmt                , -- ��氡��        
                 ISNULL(Cust.CustName            , '') AS GainCustName           , -- ���ó        
                 ISNULL(Dept.DeptName            , '') AS DeptName               , -- �����μ�        
 --                ISNULL(Dacc.AccName             , '') AS DepreAccName           , -- �󰢰���    
                 CASE WHEN ISNULL(E.AccName, '') > '' THEN ISNULL(E.AccName, '')
                      ELSE ISNULL(Dacc.AccName, '') END AS DepreAccName          , -- �󰢰��� 2011.08.16 -- E.Accname�� ������ ����ó��...
 --                ISNULL(E.AccName                , '') AS DepreAccName           , -- �󰢰��� 2011.02.24 ���μ������� �󰢰������� ����        
                 ISNULL(info.SrtDepreYM          , '') AS SrtDepreYM             , -- �󰢽��۳��        
                 ISNULL(info.EndDepreYM          , '') AS EndDepreYM             , -- �󰢿Ϸ���        
                 ISNULL(info.UseYear             , '') AS UseYear                , -- ������        
                 ISNULL(info.DepreRate           , '') AS DepreRate              , -- �󰢷�        
                 ISNULL(info.IsRemAmtCheck       , '') AS IsRemAmtCheck          , -- �ܾױ��ػ�
                 ISNULL(asst.IsRemUseMonDepre    ,'0') AS IsRemUseMonDepre       , -- �������뿬���������׻� 2011.04.22 �߰�           
                 ISNULL(t.GainAmt                ,  0) AS BasicGainAmt           , -- ������氡��        
                 ISNULL(t.TermAddAmt             ,  0) AS TermAddAmt             , -- ����ڻ�������(���)        
                 ISNULL(t.TermDecAmt             ,  0) AS TermDecAmt             , -- ����ڻ갨�Ҿ�(���)        
                 ISNULL(t.EndGainAmt           ,  0) AS EndGainAmt             , -- �⸻��氡��        
                 ISNULL(t.BasicDepreAmt          ,  0) AS BasicDepreAmt          , -- ���ʻ󰢴����        
                 ISNULL(t.TermAddDepreAmt        ,  0) AS TermAddDepreAmt        , -- ����������        
                 ISNULL(t.TermDecDepreAmt        ,  0) AS TermDecDepreAmt        , -- ���󰢰��Ҿ�        
                 ISNULL(t.EndDepreAmt            ,  0) AS EndDepreAmt            , -- �⸻�󰢴����        
                 ISNULL(t.ToMonDepreAmt          ,  0) AS ToMonDepreAmt          , -- ����󰢾�        
                 ISNULL(t.BasicNotDepreAmt       ,  0) AS BasicNotDepreAmt       , -- ���ʹ̻��ܾ�        
                 ISNULL(t.EndNotDepreAmt         ,  0) AS EndNotDepreAmt         , -- �⸻�̻��ܾ�        
                 ISNULL(asst.AsstSeq             ,  0) AS AsstSeq                , -- �ڻ��ȣ�����ڵ�        
                 ISNULL(t.TermAddEstAmt          ,  0) AS TermAddEstAmt          , -- ����ڻ�������(�ں�������)        
                 ISNULL(t.TermDecEstAmt          ,  0) AS TermDecEstAmt          , -- ����ڻ갨�Ҿ�(�ں�������)        
                 ISNULL(info.RemainAmt           ,  0) AS RemainAmt              , -- ������������ 
                 ISNULL(CCtr.CCtrName            , '') AS CCtrName               , -- Ȱ�����͸�
                 ISNULL(CCtr.CCtrSeq             ,  0) AS CCtrSeq                 -- Ȱ�������ڵ�            
                           
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
             --AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND (T.BasicNotDepreAmt <= info.RemainAmt))  --���� EndNotDepreAmt -> BasicNotDepreAmt      
             --                   OR (@DepreCpt = 4518002 AND (T.BasicNotDepreAmt > info.RemainAmt)) ) --���� EndNotDepreAmt -> BasicNotDepreAmt      
             AND (@DepreCpt = 0 OR (@DepreCpt = 4518001 AND ((ISNULL(T.BasicNotDepreAmt,0)) = 0 
                                                             AND ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))= 0) 
                                                                     OR (ISNULL(T.EndNotDepreAmt,0)- ISNULL(info.RemainAmt,0)) = 0
                                                                     )
                                   )  
                                      --���ʹ̻��ܾ��� 0�̰� (����ڻ������� - ����ڻ갨�Ҿ��� 0�̰ų� �⸻�̻��ܾ��� 0�ΰ��� �󰢿Ϸ�� �Ǵ�.
                                OR (@DepreCpt = 4518002 AND (--((ISNULL(T.BasicNotDepreAmt,0)) <> 0 
                                                              ( ((ISNULL(T.TermAddAmt,0) + ISNULL(T.TermAddEstAmt,0)) - (ISNULL(T.TermDecAmt,0) + ISNULL(T.TermDecEstAmt,0)))<> 0
                                                                     OR (ISNULL(T.EndNotDepreAmt,0)- ISNULL(info.RemainAmt,0)) <> 0)
                                                                     )
                                    )
                 )
             AND ((@DepreAccSeq = 0 OR de.DepreAccSeq = @DepreAccSeq)OR (@DepreAccSeq = 0 OR d.AccSeq = @DepreAccSeq)) 
             AND (@SMAccType = 0 OR acc.SMAccType = @SMAccType)        
     END                                                    
     
       
                 
                     
     SELECT  ISNULL(a.BizUnitName          , '') AS BizUnitName            , -- ����ι�
             ISNULL(a.AccName              , '') AS AccName                , -- ������
             ISNULL(a.DeptName             , '') AS DeptName               , -- �����μ� 
             ISNULL(SUM(a.BasicGainAmt      ),  0) AS BasicGainAmt           , -- ������氡��
             ISNULL(SUM(a.TermAddAmt        ),  0) + ISNULL(SUM(a.TermAddEstAmt),0) AS TermAddAmt             , -- ����ڻ�������
             ISNULL(SUM(a.TermDecAmt        ),  0) + ISNULL(SUM(a.TermDecEstAmt),0) AS TermDecAmt             , -- ����ڻ갨�Ҿ�
             ISNULL(SUM(a.EndGainAmt        ),  0) AS EndGainAmt             , -- �⸻��氡��
              ISNULL(SUM(a.BasicDepreAmt     ),  0) AS BasicDepreAmt          , -- ���ʻ󰢴����
             ISNULL(SUM(a.TermAddDepreAmt   ),  0) AS TermAddDepreAmt        , -- ����������
             ISNULL(SUM(a.TermDecDepreAmt   ),  0) AS TermDecDepreAmt        , -- ���󰢰��Ҿ�
             ISNULL(SUM(a.EndDepreAmt       ),  0) AS EndDepreAmt            , -- �⸻�󰢴����
              ISNULL(SUM(a.ToMonDepreAmt     ),  0) AS ToMonDepreAmt          , -- ����󰢾�
             ISNULL(SUM(a.BasicNotDepreAmt  ),  0) AS BasicNotDepreAmt       , -- ���ʹ̻��ܾ�
             ISNULL(SUM(a.EndNotDepreAmt    ),  0) AS EndNotDepreAmt           -- �⸻�̻��ܾ�
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