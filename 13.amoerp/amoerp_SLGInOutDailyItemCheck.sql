
IF OBJECT_ID('amoerp_SLGInOutDailyItemCheck') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemCheck
GO 

-- v2013.11.26 

-- �����ǰ��üũ_amoerp by����õ

-- v2012.09.06
  /************************************************************        
 ��  �� - �����ǰ�� üũ        
 �ۼ��� - 2008�� 10��          
 �ۼ��� - ����ȯ        
 ������ - 2010.06.12 ������ : ����� ����Ҽ��� �ڸ��� ����
    2011.05.11 by ��ö��
   1) IsBatch�� ISNULL()ó���� - �Ϻ� ����Ʈ���� IsBatch�� default�� constraint�� �����Ͽ� ���� �߻�
 ************************************************************/        
 CREATE PROC amoerp_SLGInOutDailyItemCheck        
     @xmlDocument    NVARCHAR(MAX),          
     @xmlFlags       INT = 0,          
     @ServiceSeq     INT = 0,          
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT = 1,          
     @LanguageSeq    INT = 1,          
     @UserSeq        INT = 0,          
     @PgmSeq         INT = 0          
 AS               
     DECLARE @Count       INT,          
             @Seq         INT,          
             @MessageType INT,          
             @Status      INT,          
             @GoodQtyDecLength INT,
             @MatQtyDecLength  INT,
             @Results     NVARCHAR(250),
             @AssetCheck  INT
      EXEC @GoodQtyDecLength    = dbo._SCOMEnvR @CompanySeq, 8, @UserSeq, @@PROCID -- �Ǹ�/��ǰ �Ҽ����ڸ���
     EXEC @MatQtyDecLength     = dbo._SCOMEnvR @CompanySeq, 5, @UserSeq, @@PROCID -- ���� �Ҽ����ڸ���
      CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)          
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDaily'
         
     -- ���� ����Ÿ ��� ����          
     CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)          
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TLGInOutDailyItem'         
      IF @WorkingTag = 'D'
     BEGIN
         UPDATE #TLGInOutDailyItem
            SET WorkingTag = 'D'
     END 
    
    -- üũ0, Lot������ �����ʹ� ������ �� �����ϴ�. 

         UPDATE A
            SET A.Result = N'Lot������ �����ʹ� ������ �� �����ϴ�.', 
                A.MessageType = 123,        
                A.Status = 2424     
           FROM #TLGInOutDailyItem AS A 
          WHERE EXISTS (SELECT 1 FROM amoerp_TLGInOutDailyItemMergeSub WHERE CompanySeq = @CompanySeq AND InOutSeq = A.InOutSeq AND InOutSerl = A.InOutSerl)
            AND A.WorkingTag = 'U'
    -- üũ0, END
    
  -- üũ1, serial��Ͽ��� 
  
  -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.
  -- SerialNo��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.
  EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           8, -- select * from _TCAMessageLanguage where MessageSeq = 8
                           @LanguageSeq,           
                           0,'SerialNo'
  
  
  -- �� ����, ��Ʈǰ����� ������ �ʿ䰡 ����, �� �ܰ�� �� ���� ������ �ܰ� ����ǿ������� SerialNo����� �ϴϱ�...  
  UPDATE A
     SET A.Result   = REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ), 
      A.MessageType = @MessageType,        
      A.Status   = @Status     
    FROM #TLGInOutDailyItem     AS A 
    --JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )
    JOIN _TLGInOutSerialStock     AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )
   WHERE A.WorkingTag IN ( 'U', 'D' ) 
     AND A.Status = 0  
  
  -- üũ1, END
     
     -- üũ2, ������â�� ���翩�� 
     
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1001, -- select * from _TCAMessageLanguage where MessageSeq = 1001
                           @LanguageSeq,           
                           23905, N'������â��' -- select * from _TCADictionary where Word like '%������%'
   
  UPDATE A
     SET A.Result   = A.OutWHName + '-' + @Results,
      A.MessageType = @MessageType,        
      A.Status   = @Status     
    FROM #TLGInOutDailyItem AS A 
   WHERE A.WorkingTag IN ( 'A' ) 
     AND A.Status = 0  
     AND A.InOutType IN (81,83)
     AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = A.OutWHSeq AND SMWHKind = 8002008 )
     --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8002 
     
     -- üũ2, END
     
  
  
     -- üũ3, ��Ÿ�԰� ��, LotNo���� ��, �ش� ǰ���� LotMaster�� ��ϵǾ�����
     
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                          @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1170, -- select * from _TCAMessageLanguage where MessageSeq = 1170
                           @LanguageSeq,           
                           0, '', -- select * from _TCADictionary where Word like '%������%'
                           0, 'LotNo' -- select * from _TCADictionary where Word like '%������%'
   
  UPDATE A
     SET A.Result   = REPLACE(@Results,'@1', '(' + C.ItemName + ' / ' + C.ItemNo + ')'),
      A.MessageType = @MessageType,        
      A.Status   = @Status     
    FROM #TLGInOutDailyItem AS A 
            LEFT OUTER JOIN _TLGLotMaster AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo
            LEFT OUTER JOIN _TDAItem AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq
            LEFT OUTER JOIN _TDAItemStock AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq
   WHERE A.WorkingTag IN ( 'A', 'U' ) 
     AND A.Status = 0  
     AND A.InOutType = 40
        AND ISNULL(A.LotNo,'') <> ''
        AND ISNULL(D.IsLotMng,'') = '1'
        AND B.CompanySeq IS NULL
     
     -- üũ3, END
     
  
  
      -------------------------------------------    
     -- ��Ʈǰ�� ����ι��̵� ���� jhpark 2012.03.30   
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
          @Status      OUTPUT,  
          @Results     OUTPUT,  
          1345                  , -- @1�� @2@3�� @4�� �� �ֽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1345)  
          @LanguageSeq ,
          '',''              
     UPDATE #TLGInOutDailyItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TLGInOutDailyItem AS A   
            JOIN _TDAItemSales AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
      WHERE A.WorkingTag IN ('A', 'U')  
        AND B.IsSet = '1'  
        AND A.Status = 0  
        AND EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE BizUnit <> ReqBizUnit)
     
     -------------------------------------------    
     -- ��Ʈǰ�� ��Ÿ����� ���� jhpark 2012.03.30   
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
          @Status      OUTPUT,  
          @Results     OUTPUT,  
          1081                  , -- @1��[��] @2������ϰ����մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1081)  
          @LanguageSeq ,
          1615,'' , 48342, ''
     
     UPDATE #TLGInOutDailyItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TLGInOutDailyItem   AS A   
       JOIN _TDAItemSales        AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
      WHERE A.WorkingTag IN ('A', 'U')  
        AND B.IsSet = '1'  
        AND A.Status = 0  
        AND EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE ReqBizUnit IS NULL)
        AND A.InOutType <> 100   -- ��Ź��� ����
        AND A.InOutType <> 50    -- ��Ź��� ���� 
        AND A.InOutType <> 51    -- ��Ź��ǰ ���� 
     
     -- # ������ ��Ź��� �����ϴ� ������ �Ʒ��� �����ϴ�. 
     -- 1. �������� ��Ź��� ���μ����� �ŷ����� �Ǹ��� ���� �ۿ� �����ϴ�. 
     -- 2. ��Ʈǰ�� �Ǹ��� ������ ����ǰ���� ���ݰ�꼭 ������ �߻��ϱ� ������ 
     --    ��Ź����Է½� ������ �ʿ����� �ʽ��ϴ�. 
     
     ---------------------------------------------------------------------------------
     -- ǰ��� �ڻ�з� �� ��üǰ��� �ڻ�з� ��ġ Ȯ�� üũ 
     ---------------------------------------------------------------------------------     
     -- ǰ��԰ݴ�ü�Է�ȭ�� üũ
     IF (SELECT TOP 1 InOutType FROM #TLGInOutDailyItem)='90'
     BEGIN
   DECLARE @EnvValue NVARCHAR(500)
    SELECT @EnvValue = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 2
   IF @@ROWCOUNT = 0 OR ISNULL( @EnvValue, '' ) = '' SELECT @EnvValue = '' 
          CREATE TABLE #IDX_No (IDX_No INT)
         
     -- ��üǰ���� ���� ǰ��� ������ �����߻�
         IF 0 < (SELECT COUNT(1) FROM #TLGInOutDailyItem WHERE ItemSeq = OriItemSeq) AND @EnvValue <> 'DHE' -- ���������� üũ���� 
         BEGIN
             
             INSERT  INTO #IDX_No(IDX_No)
             SELECT IDX_NO FROM #TLGInOutDailyItem WHERE ItemSeq = OriItemSeq
              EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                   @Status      OUTPUT,    
                                   @Results     OUTPUT,      
                                   1289               ,  -- ���� ǰ���� ��ü�� �Ұ��� �մϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%ǰ��%')      
                                   @LanguageSeq       ,       
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
               
             UPDATE #TLGInOutDailyItem 
                SET  Result        = @Results,                  
                     MessageType   = @MessageType,                  
                     Status        = @Status  
               FROM #TLGInOutDailyItem AS A JOIN #IDX_No B ON A.IDX_No=B.IDX_No     
              WHERE  A.WorkingTag IN ('A','U')
         END
         
         TRUNCATE TABLE #IDX_No
         
         -- ǰ�� �ڻ� �з��� �������� ������ �����߻�        
         INSERT INTO #IDX_No(IDX_No)   
         SELECT IDX_NO FROM #TLGInOutDailyItem A 
                                    LEFT OUTER JOIN _TDAItem B            ON B.CompanySeq = @CompanySeq 
                                                                         AND A.ItemSeq    = B.ItemSeq
                                    LEFT OUTER JOIN _TDAItem C            ON C.CompanySeq = @CompanySeq 
                                                                         AND A.OriItemSeq = C.ItemSeq
                                            WHERE ISNULL(B.AssetSeq,'') <> ISNULL(C.AssetSeq,'')
         
         IF @@RowCount > 0 AND @EnvValue <> 'FINE' -- ȭ�λ�� üũ���� 
         BEGIN
             EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                   @Status      OUTPUT,      
                                   @Results     OUTPUT,      
                                   1288               ,  -- ǰ�� �ڻ� �з��� �����ؾ� ����� �����մϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%ǰ��%')      
                                   @LanguageSeq       ,       
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
               
             UPDATE #TLGInOutDailyItem      
                SET  Result        = @Results,                  
                     MessageType   = @MessageType,                  
                     Status        = @Status  
               FROM #TLGInOutDailyItem AS A JOIN #IDX_No B ON A.IDX_No=b.IDX_No  
              WHERE  A.WorkingTag IN ('A','U')           
                      
         END
         DROP TABLE #IDX_No
     END
     /*
       -------------------------------------------        
      -- Lot������ Lot�ʼ�üũüũ        
      -------------------------------------------        
      EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                            @Status      OUTPUT,        
                            @Results     OUTPUT,        
                            1171               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1171)        
                            @LanguageSeq       ,         
                            0,'�����'     
       UPDATE #TLGInOutDailyItem        
         SET Result        = @Results,        
             MessageType   = @MessageType,        
             Status        = @Status        
       FROM  #TLGInOutDailyItem A
             JOIN (SELECT  X.InOutType, X.InOutSeq, X.InOutSerl
                     FROM  #TLGInOutDailyItem X
                           LEFT OUTER JOIN _TLGInOutLotSub Y WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq
                                                    AND X.InOutType  = Y.InOutType
                                                    AND X.InOutSeq   = Y.InOutSeq
                                                    AND X.InOutSerl  = Y.InOutSerl
                                                    AND X.InOutDataSerl = 0
                   GROUP BY X.InOutType, X.InOutSeq, X.InOutSerl) B ON B.InOutType  = A.InOutType
                                                                   AND B.InOutSeq   = A.InOutSeq
                                                                   AND B.InOutSerl  = A.InOutSerl
             JOIN  _TDAItemStock C ON C.CompanySeq = @CompanySeq AND A.ItemSeq = C.ItemSeq AND C.IsLotMng = '1'
      WHERE  (A.InOutType <> '310' AND ISNULL(A.LotNo, '') = '')
         OR  (A.InOutType = '310' AND ISNULL(A.ORILotNo, '') = '')
    --*/
 --     UPDATE #TLGInOutDailyItem          
 --        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),          
 --            MessageType   = @MessageType,          
 --            Status        = @Status          
 --       FROM #TLGInOutDailyItem AS A JOIN ( SELECT S.InOutSeq, S.InOutSerl        
 --                                      FROM (          
 --                                            SELECT A1.InOutSeq, A1.InOutSerl        
 --                                              FROM #TLGInOutDailyItem AS A1          
 --                                             WHERE A1.WorkingTag IN ('U')          
 --                                               AND A1.Status = 0          
 --                                            UNION ALL          
 --                                            SELECT A1.InOutSeq, A1.InOutSerl        
 --                                              FROM _TLGInOutDailyItem AS A1 JOIN _TLGInOutDaily AS A10          
 --                                                     ON A1.CompanySeq = A10.CompanySeq    
 --                                                    AND A1.InOutSeq   = A10.InOutSeq    
 --                                                    AND A10.IsBatch <> '1'    
 --          WHERE A1.InOutSeq  NOT IN (SELECT InOutSeq          
 --                                                                            FROM #TLGInOutDailyItem           
 --                                                                           WHERE WorkingTag IN ('U','D')           
 --                                                                             AND Status = 0)          
 --                                               AND A1.InOutSerl  NOT IN (SELECT InOutSerl          
 --                                                                             FROM #TLGInOutDailyItem           
 --                                                                            WHERE WorkingTag IN ('U','D')           
 --                                                                              AND Status = 0)          
 --                                               AND A1.CompanySeq = @CompanySeq          
 --                                           ) AS S          
 --                                     GROUP BY S.InOutSeq, S.InOutSerl        
 --                                     HAVING COUNT(1) > 1          
 --                                   ) AS B ON A.InOutSeq  = B.InOutSeq          
 --                                         AND A.InOutSerl = B.InOutSerl          
   /***************** ���ش��� üũ ************************************/  
  /***************** ���ش��� üũ ************************************/  
      EXEC dbo._SCOMMessage @MessageType OUTPUT,
                            @Status      OUTPUT,
                            @Results     OUTPUT,
                            1008         , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '���ش���%' )
                            @LanguageSeq , 
                            2474,''   -- SELECT * FROM _TCADictionary WHERE Word like '%���ش���%'
      -- ���ش�������
      UPDATE #TLGInOutDailyItem          
         SET Result       = @Results,          
             MessageType   = @MessageType,          
             Status        = @Status          
       FROM  #TLGInOutDailyItem AS A
             JOIN _TDAItemStock AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                 AND A.ItemSeq    = B.ItemSeq     
      WHERE A.Status = 0    
        AND ISNULL(B.IsQtyChange,'') <> '1'    
        AND ISNULL(A.Qty,0) <> 0
        AND ISNULL(A.STDQty,0) = 0
  
      EXEC dbo._SCOMMessage @MessageType OUTPUT,
                            @Status      OUTPUT,
                            @Results     OUTPUT,
                            1008         , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '���ش���%' )
                            @LanguageSeq       , 
                            7,''   -- SELECT * FROM _TCADictionary WHERE Word like '%���ش���%'
      -- ǰ��
      UPDATE #TLGInOutDailyItem          
         SET Result        = @Results,          
             MessageType   = @MessageType,          
             Status        = @Status          
       FROM  #TLGInOutDailyItem  
      WHERE Status = 0    
        AND ISNULL(ItemSeq,0) = 0
   /***************** ���ش��� üũ ************************************/  
  /***************** ���ش��� üũ ************************************/  
     UPDATE #TLGInOutDailyItem
        SET STDQty = CASE T.MinorValue WHEN '0' THEN ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END), @GoodQtyDecLength)
                                                ELSE ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END), @MatQtyDecLength)
                     END
       FROM #TLGInOutDailyItem AS A
            JOIN _TDAItemUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                               AND A.ItemSeq    = B.ItemSeq
                                               AND A.UnitSeq    = B.UnitSeq
            JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                AND A.ItemSeq    = C.ItemSeq
            JOIN _TDAItem      AS I WITH(NOLOCK) ON A.ItemSeq   = I.ItemSeq
                                                AND I.CompanySeq = @CompanySeq
            JOIN _TDAItemAsset AS S WITH(NOLOCK) ON I.AssetSeq   = S.AssetSeq
                                                AND S.CompanySeq = @CompanySeq
            JOIN _TDASMinor    AS T WITH(NOLOCK) ON S.SMAssetGrp = T.MinorSeq
                                                AND T.CompanySeq = @CompanySeq
      WHERE A.Status = 0
        AND ISNULL(A.Qty,0) <> 0
        AND ISNULL(C.IsQtyChange,'') <> '1'
  
           
     SELECT @Count = COUNT(1) FROM #TLGInOutDailyItem WHERE WorkingTag = 'A' AND Status = 0          
              
     IF @Count > 0          
     BEGIN            
         -- Ű�������ڵ�κ� ����            
         SELECT @Seq = ISNULL((SELECT MAX(A.InOutSerl)          
                                 FROM amoerp_TLGInOutDailyItemMerge AS A WITH(NOLOCK) JOIN _TLGInOutDaily AS A10  WITH(NOLOCK)         
                                                     ON A.CompanySeq = A10.CompanySeq    
                                                    AND A.InOutSeq   = A10.InOutSeq    
                                                    AND ISNULL( A10.IsBatch, '0' ) <> '1'    -- 20110511 
                                WHERE A.CompanySeq = @CompanySeq          
                                  AND A.InOutSeq  IN (SELECT InOutSeq        
                                                        FROM #TLGInOutDailyItem          
                                                       WHERE InOutSeq = A.InOutSeq)),0)          
           
         -- Temp Talbe �� ������ Ű�� UPDATE          
         UPDATE #TLGInOutDailyItem          
            SET InOutSerl   = @Seq + A.DataSeq      
           FROM #TLGInOutDailyItem AS A         
          WHERE A.WorkingTag = 'A'          
            AND A.Status = 0          
     END            
  
     SELECT * FROM #TLGInOutDailyItem          
  
  RETURN
  GO
  begin tran
exec amoerp_SLGInOutDailyItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InOutSerl>1</InOutSerl>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <ItemName>�ٽ��ѹ��׽�Ʈ_����õ</ItemName>
    <ItemNo>�ٽ��ѹ��׽�Ʈ_����õ</ItemNo>
    <Spec>Test_Spec</Spec>
    <UnitName>EA</UnitName>
    <Price>0</Price>
    <Qty>15</Qty>
    <InOutDetailKindName>��Źó��</InOutDetailKindName>
    <STDUnitName>EA</STDUnitName>
    <STDQty>15</STDQty>
    <Amt>0</Amt>
    <InWHName>������</InWHName>
    <InOutKindName>��Źó��</InOutKindName>
    <LotNo />
    <SerialNo />
    <InOutRemark />
    <DVPlaceName />
    <OriSTDQty>0</OriSTDQty>
    <OriQty>0</OriQty>
    <OriItemSeq>0</OriItemSeq>
    <OriUnitSeq>0</OriUnitSeq>
    <IsStockSales xml:space="preserve"> </IsStockSales>
    <InOutDetailKind>8046001</InOutDetailKind>
    <InOutKind>8023005</InOutKind>
    <EtcOutVAT>0</EtcOutVAT>
    <UnitSeq>2</UnitSeq>
    <OutWHSeq>5</OutWHSeq>
    <InWHSeq>11</InWHSeq>
    <DVPlaceSeq>0</DVPlaceSeq>
    <CCtrSeq>0</CCtrSeq>
    <EtcOutAmt>0</EtcOutAmt>
    <ItemSeq>27439</ItemSeq>
    <OriItemName />
    <OriUnitName />
    <OutWHName>(��)û�ֱ���õ�ֱ�ȸ������� ����ġ������ ��</OutWHName>
    <CCtrName />
    <FromTableSeq>16</FromTableSeq>
    <FromSeq>1000205</FromSeq>
    <FromSerl>1</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <InOutSeq>1001292</InOutSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <InOutType>50</InOutType>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InOutSerl>2</InOutSerl>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <ItemName>Lot�׽�Ʈ_����õ</ItemName>
    <ItemNo>Lot�׽�Ʈ_����õ</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <Price>0</Price>
    <Qty>25</Qty>
    <InOutDetailKindName>��Źó��</InOutDetailKindName>
    <STDUnitName>EA</STDUnitName>
    <STDQty>25</STDQty>
    <Amt>0</Amt>
    <InWHName>������</InWHName>
    <InOutKindName>��Źó��</InOutKindName>
    <LotNo />
    <SerialNo />
    <InOutRemark />
    <DVPlaceName />
    <OriSTDQty>0</OriSTDQty>
    <OriQty>0</OriQty>
    <OriItemSeq>0</OriItemSeq>
    <OriUnitSeq>0</OriUnitSeq>
    <IsStockSales xml:space="preserve"> </IsStockSales>
    <InOutDetailKind>8046001</InOutDetailKind>
    <InOutKind>8023005</InOutKind>
    <EtcOutVAT>0</EtcOutVAT>
    <UnitSeq>2</UnitSeq>
    <OutWHSeq>5</OutWHSeq>
    <InWHSeq>11</InWHSeq>
    <DVPlaceSeq>0</DVPlaceSeq>
    <CCtrSeq>0</CCtrSeq>
    <EtcOutAmt>0</EtcOutAmt>
    <ItemSeq>27375</ItemSeq>
    <OriItemName />
    <OriUnitName />
    <OutWHName>(��)û�ֱ���õ�ֱ�ȸ������� ����ġ������ ��</OutWHName>
    <CCtrName />
    <FromTableSeq>16</FromTableSeq>
    <FromSeq>1000205</FromSeq>
    <FromSerl>2</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <InOutSeq>1001292</InOutSeq>
    <InOutType>50</InOutType>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit>1</BizUnit>
    <DeptSeq>135</DeptSeq>
    <EmpSeq>1863</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426
rollback