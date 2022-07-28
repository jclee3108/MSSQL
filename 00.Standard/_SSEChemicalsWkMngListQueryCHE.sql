
IF OBJECT_ID('_SSEChemicalsWkMngListQueryCHE') IS NOT NULL 
    DROP PROC _SSEChemicalsWkMngListQueryCHE
GO 

-- v2015.02.17 

/************************************************************  
  ��  �� - ������-ȭ�й�����������_capro : ��ȸ  
  �ۼ��� - 20110603  
  �ۼ��� - �����  
 ************************************************************/  
 CREATE PROC dbo._SSEChemicalsWkMngListQueryCHE  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT             = 0,  
     @ServiceSeq     INT             = 0,  
     @WorkingTag     NVARCHAR(10)    = '',  
     @CompanySeq     INT             = 1,  
     @LanguageSeq    INT             = 1,  
     @UserSeq        INT             = 0,  
     @PgmSeq         INT             = 0  
 AS    
     --��ȸ����    
     DECLARE @docHandle     INT ,    
             @ChmcSeq       INT ,           
             @InOutWkType   INT ,    
             @RetYearMonth  NCHAR(6),  
             @FactUnit      INT  
                 
     --SP��뺯��            
     DECLARE @DD            NVARCHAR(2)  ,--���ڻ�����    
             @LastDate      INT          ,--�ش���� ���ϼ�    
             @RowNum        INT          ,    
             @CreatDate     NCHAR(8)     ,--��������    
             @InWkType      INT          ,--�����۾������ڵ�    
             @InWkTypeName  NVARCHAR(100),--�����۾�����    
             @OutWkType     INT          ,--����۾������ڵ�    
             @OutWkTypeName NVARCHAR(100) --����۾�����    
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
     
     SELECT  @ChmcSeq       = ChmcSeq        ,    
             @InOutWkType   = InOutWkType    ,    
             @RetYearMonth  = RetYearMonth       
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
       WITH  (ChmcSeq        INT ,    
              InOutWkType    INT ,    
              RetYearMonth   NCHAR(6) )   
   
   
   
     --DataBlock1 ���� ��ȸ�� ���̺�    
     CREATE TABLE #_TSEChemicalsWkListCHE    
     (    
         Seq               INT IDENTITY  ,      
         RetDate           NCHAR(8)      , -- �����             
         ItemSeq           INT           , -- ǰ���ڵ�         
         PrintName         NVARCHAR(100) , -- ǰ��(��¸�)     
         ItemNo            NVARCHAR(100) , -- ǰ��             
         ToxicName         NVARCHAR(400) , -- ����ǰ��         
         MainPurpose       NVARCHAR(400) , -- �ֿ�뵵         
         Content           NVARCHAR(400) , -- �Է�             
         UnitSeq           INT           , -- �����ڵ�         
         UnitName          NVARCHAR(100) , -- ����                
         PreQty            DECIMAL(19,5 ), -- �̿���                
         InWkType          INT           , -- �԰����ڵ�          
         InWkTypeName      NVARCHAR(100) , -- �԰���              
         InQty             DECIMAL(19,5) , -- �԰����              
         InCustSeq         INT           , -- �԰��ȣ�ڵ�          
         InCustName        NVARCHAR(100) , -- �԰��ȣ��            
         InOwner           NVARCHAR(100) , -- �԰��ǥ�ڼ���        
         InBizNo           NVARCHAR(100) , -- �԰����ڵ�Ϲ�ȣ    
         InBizAddr         NVARCHAR(100) , -- �԰��ȣ�ּ�          
         InTelNo           NVARCHAR(100) , -- �԰��ȣ��ȭ��ȣ      
         OutWkType         INT           , -- ������ڵ�          
         OutWkTypeName     NVARCHAR(100) , -- �����              
         OutQty            DECIMAL(19,5) , -- ������              
         OutCustSeq        INT           , -- ����ȣ�ڵ�          
         OutCustName       NVARCHAR(100) , -- ����ȣ��            
         OutOwner          NVARCHAR(100) , -- �԰��ǥ�ڼ���        
         OutBizNo          NVARCHAR(100) , -- ������ڵ�Ϲ�ȣ    
         OutBizAddr        NVARCHAR(100) , -- ����ȣ�ּ�          
         OutTelNo          NVARCHAR(100) , -- ����ȣ��ȭ��ȣ      
         StockQty          DECIMAL(19,5) , -- ���                
         ReMark            NVARCHAR(100) , -- ���    
         InPutDesc         NVARCHAR(400) , -- ���Գ����� ��ŷ    
         OutPutDesc        NVARCHAR(400)   -- ������� ��ŷ    
     )            
      
     -- ��ȸ�� ǰ��    
     CREATE TABLE #GetInOutItem    
     (    
         ItemSeq    INT    
     )    
     -- ��� ���� ����    
     CREATE TABLE #GetInOutStock    
     (    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT,    
         UnitSeq         INT,    
         PrevQty         DECIMAL(19,5),    
         InQty           DECIMAL(19,5),    
         OutQty          DECIMAL(19,5),    
         StockQty        DECIMAL(19,5),    
         STDPrevQty      DECIMAL(19,5),    
         STDInQty        DECIMAL(19,5),    
         STDOutQty       DECIMAL(19,5),    
         STDStockQty     DECIMAL(19,5)    
     )    
     
     --Item ���ϱ�    
     INSERT INTO #GetInOutItem    
     SELECT DISTINCT A.ItemSeq    
       FROM _TSEChemicalsListCHE AS A WITH(NOLOCK)    
      WHERE A.CompanySeq = @CompanySeq    
        AND (@ChmcSeq = 0 or A.ChmcSeq = @ChmcSeq)    
   
   
     --��������           
     SELECT @LastDate = CONVERT(INT, DAY(DATEADD(D, -1, DATEADD(M, 1, @RetYearMonth+'01'))))    
     
     SELECT @RowNum = 0    
     --��ȸ���� �ϼ����� / �̿��� / ��� ����/    
     WHILE @RowNum < @LastDate    
     BEGIN    
             SELECT @RowNum = @RowNum + 1    
             SELECT @DD = CONVERT(NVARCHAR(2),@RowNum,112)    
             SELECT @CreatDate = @RetYearMonth + (CASE WHEN LEN(@DD) = 1 THEN '0'+@DD ELSE @DD END)    
                 
             --��� ���̺� ����    
             DELETE FROM #GetInOutStock    
                 
             -- â����� ��������    
             EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,    -- �����ڵ�    
                                     @BizUnit      = 0          ,    -- ����ι�    
                                     @FactUnit     = 0          ,    -- ��������    
                                     @DateFr       = @CreatDate ,    -- ��ȸ�ⰣFr    
                                     @DateTo       = @CreatDate ,    -- ��ȸ�ⰣTo    
                                     @WHSeq        = 0          ,    -- â������    
                                     @SMWHKind     = 0          ,    -- â���к� ��ȸ    
                                     @CustSeq      = 0          ,    -- ��Ź�ŷ�ó    
                                     @IsTrustCust  = ''         ,    -- ��Ź����    
                                     @IsSubDisplay = ''         ,    -- ���â�� ��ȸ    
                                     @IsUnitQry    = ''         ,    -- ������ ��ȸ    
                                     @QryType      = 'S'             -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������               
                
             INSERT #_TSEChemicalsWkListCHE    
                   ( RetDate       , -- �����                  
                     ItemSeq       , -- ǰ���ڵ�                
                     PrintName     , -- ǰ��(��¸�)            
                     ItemNo        , -- ǰ��                    
                     ToxicName     , -- ����ǰ��                
                     MainPurpose   , -- �ֿ�뵵                
                     Content       , -- �Է�                    
                     UnitSeq       , -- �����ڵ�                
                     UnitName      , -- ����                    
                     PreQty        , -- �̿���                  
                     InWkType      , -- �԰����ڵ�            
                     InWkTypeName  , -- �԰���                
                     InQty         , -- �԰����                
                     InCustSeq     , -- �԰��ȣ�ڵ�            
                     InCustName    , -- �԰��ȣ��              
                     InOwner       , -- �԰��ǥ�ڼ���          
                     InBizNo       , -- �԰����ڵ�Ϲ�ȣ      
                     InBizAddr     , -- �԰��ȣ�ּ�            
                     InTelNo       , -- �԰��ȣ��ȭ��ȣ        
                     OutWkType     , -- ������ڵ�            
                     OutWkTypeName , -- �����                
                     OutQty        , -- ������                
                     OutCustSeq    , -- ����ȣ�ڵ�            
                     OutCustName   , -- ����ȣ��              
                     OutOwner      , -- �԰��ǥ�ڼ���      
                     OutBizNo      , -- ������ڵ�Ϲ�ȣ      
                     OutBizAddr    , -- ����ȣ�ּ�            
                     OutTelNo      , -- ����ȣ��ȭ��ȣ         
                     StockQty      , -- ���                  
                     ReMark        ) -- ���                  
               SELECT  @RetYearMonth +  (CASE WHEN LEN(@DD) = 1 THEN '0'+@DD ELSE @DD END), --����    
                     0      , -- ǰ���ڵ�                
                     ''     , -- ǰ��(��¸�)            
                     ''     , -- ǰ��                    
                     ''     , -- ����ǰ��                
                       ''     , -- �ֿ�뵵                 
                     ''     , -- �Է�                    
                     0      , -- �����ڵ�                
                     ''     , -- ����                    
                     0      , -- �̿���                  
                     0      , -- �԰����ڵ�            
                     ''     , -- �԰���                
                     0      , -- �԰����                
                     0      , -- �԰��ȣ�ڵ�            
                     ''     , -- �԰��ȣ��              
                     ''     , -- �԰��ǥ�ڼ���          
                     ''     , -- �԰����ڵ�Ϲ�ȣ      
                     ''     , -- �԰��ȣ�ּ�            
                     ''     , -- �԰��ȣ��ȭ��ȣ        
                     0      , -- ������ڵ�            
                     ''     , -- �����                
                     0      , -- ������                
                     0      , -- ����ȣ�ڵ�            
                     ''     , -- ����ȣ��              
                     ''     , -- �԰��ǥ�ڼ���          
                     ''     , -- ������ڵ�Ϲ�ȣ      
                     ''     , -- ����ȣ�ּ�            
                     ''     , -- ����ȣ��ȭ��ȣ        
                     ISNULL((SELECT SUM(STDStockQty) FROM #GetInOutStock),0), -- ���                  
                     ''         -- ���            
                 
             --�̿��� ����           
             IF @DD = '1'    
             BEGIN    
                 --��� ���̺� ����    
                 DELETE FROM #GetInOutStock    
                 SELECT @CreatDate = CONVERT(CHAR(8),dateadd(DAY,-1,@CreatDate),112)      
                     
                 -- â����� ��������    
                 EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,   -- �����ڵ�    
                                         @BizUnit      = 0          ,   -- ����ι�    
                                         @FactUnit     = 0          ,   -- ��������    
                                         @DateFr       = @CreatDate ,   -- ��ȸ�ⰣFr    
                                         @DateTo       = @CreatDate ,   -- ��ȸ�ⰣTo    
                                         @WHSeq        = 0          ,   -- â������    
                                         @SMWHKind     = 0          ,   -- â���к� ��ȸ    
                                         @CustSeq      = 0          ,   -- ��Ź�ŷ�ó    
                                         @IsTrustCust  = ''         ,   -- ��Ź����    
                                         @IsSubDisplay = ''         ,   -- ���â�� ��ȸ    
                                         @IsUnitQry    = ''         ,   -- ������ ��ȸ    
                                         @QryType      = 'S'            -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������      
                     
                     
                UPDATE #_TSEChemicalsWkListCHE    
                   SET PreQty = ISNULL((SELECT SUM(STDStockQty) FROM #GetInOutStock),0) --�̿��� ����    
                 WHERE Seq = 1    
                  --SELECT * FROM #GetInOutStock   
             END    
                        
     END    
         
     -- �������� ���    
     UPDATE #_TSEChemicalsWkListCHE    
        SET ItemSeq    = A.ItemSeq     ,  -- ǰ���ڵ�                       
            PrintName  = A.PrintName   ,  -- ��¸�      
            ItemNo     = B.ItemNo      ,  -- ǰ��        
            ToxicName  = A.ToxicName   ,  -- ��������    
            MainPurpose= A.MainPurpose ,  -- �ֿ�뵵    
            Content    = A.Content     ,  -- �Է�        
            UnitSeq    = B.UnitSeq     ,  -- �����ڵ�    
            UnitName   = C.UnitName       -- ����                
      FROM  _TSEChemicalsListCHE   AS A WITH (NOLOCK)    
            JOIN _TDAItem            AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                         AND A.ItemSeq    = B.ItemSeq    
            LEFT OUTER JOIN _TDAUnit AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq    
                                                       AND B.UnitSeq    = C.UnitSeq    
     WHERE  A.CompanySeq = @CompanySeq    
       AND  (@ChmcSeq = 0 or A.ChmcSeq    = @ChmcSeq)                  
   
   
   
     -- �۾����п� �ش��ϴ� �԰�/����� ��������      
     SELECT @InWkType     = ISNULL(A.InWkType,0),    
            @InWkTypeName = B.MinorName,              
            @OutWkType    = ISNULL(A.OutWkType,0),    
            @OutWkTypeName= C.MinorName    
       FROM _TSEChemicalsWkListCHE   AS A    
            LEFT OUTER JOIN _TDASMinor AS B ON A.CompanySeq = B.CompanySeq    
                                           AND A.InWkType   = B.MinorSeq    
            LEFT OUTER JOIN _TDASMinor AS C ON A.CompanySeq = C.CompanySeq    
                                           AND A.OutWkType  = C.MinorSeq                                            
      WHERE A.CompanySeq  = @CompanySeq  
        AND A.ChmcSeq     = @ChmcSeq    
        AND A.InOutWkType = @InOutWkType    
   
   
      -- �۾����� ���          
      UPDATE #_TSEChemicalsWkListCHE    
         SET InWkType      = ISNULL(@InWkType,0)      ,    
             InWkTypeName  = @InWkTypeName  ,    
             OutWkType     = ISNULL(@OutWkType,0)     ,    
             OutWkTypeName = @OutWkTypeName      
   
      -- ��¹��� ���� ��ŷ ���(Ȳ���϶�)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET InPutDesc     = CASE WHEN InWkType = 0 THEN OutWkTypeName + '������ ��� �� ��� ��Ȳ�� '+CHAR(10)+PrintName+ ' �԰�(����) �������� ����' ELSE '' END, --��¹��� ���� ��ŷ(���Գ������� �����϶�)    
             OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '������ ��� �� ��� ��Ȳ�� '+CHAR(10)+PrintName+ ' �԰�(����) �������� ����' ELSE '' END, --��¹��� ���� ��ŷ(��������� �����϶�)     
             StockQty      = CASE WHEN @InOutWkType = 6121005 THEN 0 ELSE StockQty END,
             PreQty        = CASE WHEN @InOutWkType = 6121005 THEN 0 ELSE PreQty END
       WHERE ItemNo = 'PD03'  
   
   
      -- ��¹��� ���� ��ŷ ���(�����϶�)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET InPutDesc     = CASE WHEN InWkType = 0 THEN '�������� ȭ�й��� ��� �������� ����' ELSE '' END, --��¹��� ���� ��ŷ(��������� �����϶�)     
             OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '������ ��� �� ��� ��Ȳ�� '+CHAR(10)+PrintName+ ' �԰�(����) �������� ����' ELSE '' END, --��¹��� ���� ��ŷ(���Գ������� �����϶�)    
             StockQty      = CASE WHEN @InOutWkType = 6121005 OR @InOutWkType = 6121004 THEN 0 ELSE StockQty END,
             PreQty        = CASE WHEN @InOutWkType = 6121005 OR @InOutWkType = 6121004 THEN 0 ELSE PreQty END
       WHERE ItemNo = '405-0000-001-0'            
   
      -- ��¹��� ���� ��ŷ ���(Ȳ���϶�)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '������ ��� �� ��� ��Ȳ�� '+CHAR(10)+PrintName+ ' �԰�(����) �������� ����' ELSE '' END , --��¹��� ���� ��ŷ(���Գ������� �����϶�)    
             StockQty      = CASE WHEN OutWkType = 0 THEN 0 ELSE StockQty END
       WHERE ItemNo = '411-0000-001-0'  
   
     -- �԰���    
     CREATE TABLE #GetInQty    
     (    
         RetDate           NCHAR(8)      ,    
         InCustCd          INT           ,    
         InQty             DECIMAL(19,5) ,    
     )         
     
     --�����    
     CREATE TABLE #GetOutQty    
     (    
         RetDate           NCHAR(8)      ,    
         OutCustCd         INT           ,    
         OutQty            DECIMAL(19,5) 
     )    
     ----------------------------------------------------------------------�԰���    
     IF @InWkType      = 6122001 --����(�������)-�ϼ�ǰ��    
     BEGIN    
         INSERT #GetInQty  
               (RetDate ,  
                InCustCd,  
                InQty     )  
         SELECT A.WorkDate,  
                0         ,  
        CASE WHEN @ChmcSeq = 9 THEN A.StdUnitOKQty * 1.28 ELSE A.StdUnitOKQty END  
           FROM _TPDSFCWorkReport  AS A  
                JOIN #GetInOutItem AS B ON A.GoodItemSeq = B.ItemSeq  
          WHERE A.CompanySeq = @CompanySeq  
            AND CONVERT(CHAR(6),A.WorkDate,112) = @RetYearMonth  
            AND A.FactUnit = CASE WHEN @ChmcSeq = 9 THEN 3 ELSE A.FactUnit END -- ���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� 3���� �����͸� �����ϱ� ����  
             
     END    
     ELSE IF @InWkType = 6122002 --����(�����԰�-����)    
     BEGIN    
             
         INSERT #GetInQty    
               (RetDate ,    
                InCustCd,    
                InQty     )    
         SELECT A.DelvInDate,    
                A.CustSeq   ,    
                B.StdUnitQty    
           FROM _TPUDelvIn AS A    
                JOIN _TPUDelvInItem AS B ON A.CompanySeq = B.CompanySeq     
                                        AND A.DelvInSeq  = B.DelvInSeq    
                JOIN #GetInOutItem  AS C ON B.ItemSeq    = C.ItemSeq    
          WHERE A.CompanySeq = @CompanySeq    
              AND B.SMImpType   = 8008001  -- ����       
            AND CONVERT(CHAR(6),A.DelvInDate,112) = @RetYearMonth                
                   
                   
     END    
     ELSE IF @InWkType = 6122003 --����(�����԰�-��������)    
     BEGIN    
         INSERT #GetInQty    
               (RetDate ,    
                InCustCd,    
                InQty     )    
         SELECT A.DelvInDate,    
                A.CustSeq   ,    
                B.StdUnitQty    
           FROM _TPUDelvIn AS A    
                JOIN _TPUDelvInItem AS B ON A.CompanySeq = B.CompanySeq     
                                        AND A.DelvInSeq  = B.DelvInSeq    
                JOIN #GetInOutItem  AS C ON B.ItemSeq    = C.ItemSeq    
          WHERE A.CompanySeq = @CompanySeq    
            AND B.SMImpType  <> 8008001  -- ��������    
            AND CONVERT(CHAR(6),A.DelvInDate,112) = @RetYearMonth      
     END    
   
      ----------------------------------------------------------------------�����         
      IF @OutWkType      = 6123001 --�Ǹ�(�ŷ���ǥ)    
      BEGIN    
         INSERT #GetOutQty    
               (RetDate  ,    
                OutCustCd,    
                OutQty     )  
         SELECT A.InvoiceDate,    
                A.CustSeq    ,    
                B.STDQty    
          FROM _TSLInvoice          AS A WITH(NOLOCK)      
               JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq      
                                                     AND A.InvoiceSeq  = B.InvoiceSeq      
               JOIN #GetInOutItem                AS C ON B.ItemSeq     = C.ItemSeq                                          
         WHERE A.CompanySeq = @CompanySeq    
           AND CONVERT(CHAR(6),A.InvoiceDate,112) = @RetYearMonth  
           AND A.IsDelvCfm = '1'  
      END    
      ELSE IF @OutWkType = 6123002 --���(��������)    
      BEGIN    
         INSERT #GetOutQty    
               (RetDate  ,    
                OutCustCd,    
                OutQty     )    
         SELECT A.InputDate,    
                0          ,    
                A.StdUnitQty  
           FROM _TPDSFCMatinput AS A WITH(NOLOCK)  
                JOIN #GetInOutItem AS C ON A.MatItemSeq = C.ItemSeq     
          WHERE A.CompanySeq = @CompanySeq    
            AND CONVERT(CHAR(6),A.InputDate,112) = @RetYearMonth  
             
      END         
          
      IF EXISTS (SELECT 1 FROM #GetInQty)    
      BEGIN    
          --�԰� ���� ���    
          UPDATE #_TSEChemicalsWkListCHE    
             SET InQty = B.InQty    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (SELECT L1.RetDate, SUM(L1.InQty) InQty    
                         FROM #GetInQty AS L1    
                        GROUP BY L1.RetDate)    AS B ON A.RetDate = B.RetDate    
              
              
          --�԰� ���� ��ü ���� ���    
          UPDATE #_TSEChemicalsWkListCHE    
             SET InCustSeq   =  B.InCustCd,    
                 InCustName  =  B.CustName,    
                 InOwner     =  B.Owner,    
                 InBizNo     =  B.BizNo,    
                 InBizAddr   =  B.BizAddr,    
                 InTelNo     =  B.TelNo    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (   SELECT A.InCustCd ,    
                                 A.CustName ,    
                                 A.Owner    ,    
                                 A.BizNo    ,    
                                 A.BizAddr  ,    
                                 A.TelNo    ,    
                                 RANK() OVER (ORDER BY A.InCustCd) Seq    
                            FROM (SELECT DISTINCT     
                                         A.InCustCd ,    
                                         B.CustName ,    
                                         B.Owner    ,    
                                         B.BizNo    ,    
                                         B.BizAddr  ,    
                                         B.TelNo    
                                    FROM #GetInQty     AS A    
                                         JOIN _TDACust AS B ON A.InCustCd = B.CustSeq    
                            WHERE B.CompanySeq = @CompanySeq) AS A ) AS B ON A.Seq = B.Seq    
                
      END    
          
      IF EXISTS (SELECT 1 FROM #GetOutQty)        
      BEGIN              
          --��� ���� ���    
          UPDATE #_TSEChemicalsWkListCHE    
             SET OutQty = B.OutQty    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (SELECT L1.RetDate, SUM(L1.OutQty) OutQty    
                         FROM #GetOutQty AS L1    
                        GROUP BY L1.RetDate)    AS B ON A.RetDate = B.RetDate     
                            
          --��� ���� ��ü ���� ���    
          UPDATE #_TSEChemicalsWkListCHE    
             SET OutCustSeq   =  B.OutCustCd,    
                 OutCustName  =  B.CustName,    
                 OutOwner     =  B.Owner,    
                 OutBizNo     =  B.BizNo,    
                 OutBizAddr   =  B.BizAddr,    
                 OutTelNo     =  B.TelNo    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (   SELECT A.OutCustCd ,    
                                 A.CustName ,    
                                   A.Owner    ,    
                                 A.BizNo    ,    
                                 A.BizAddr  ,    
                                 A.TelNo    ,    
                                 RANK() OVER (ORDER BY A.OutCustCd) Seq    
                            FROM (SELECT DISTINCT     
                                         A.OutCustCd ,    
                                         B.CustName ,    
                                         B.Owner    ,    
                                         B.BizNo    ,    
                                         B.BizAddr  ,    
                                         B.TelNo    
                                    FROM #GeTOutQty     AS A    
                                         JOIN _TDACust AS B ON A.OutCustCd = B.CustSeq    
                                   WHERE B.CompanySeq = @CompanySeq) AS A ) AS B ON A.Seq = B.Seq                                             
      END    
          
   
     IF @WorkingTag = 'P'  
     BEGIN  
         --��� ���� ��������    
         --�۾����� ��� ��¿�    
         IF @InWkType > 0 --���Գ��������    
         BEGIN    
              --�۾����� '' ó��    
              UPDATE #_TSEChemicalsWkListCHE    
             SET InWkType      = @InWkType      ,    
                     InWkTypeName  = (CASE WHEN  @InWkType > 0 AND Seq =1 THEN @InWkTypeName ELSE '"' END)    
                         
              --�԰��ü ���� ���� '' ó��           
              IF EXISTS (SELECT 1 FROM #_TSEChemicalsWkListCHE WHERE Seq =1 AND InCustSeq > 0)    
              BEGIN    
                  UPDATE #_TSEChemicalsWkListCHE    
                     SET InCustName   = '"', -- �԰��ȣ��             
                         InOwner      = '"', -- �԰��ǥ�ڼ���         
                    InBizNo      = '"', -- �԰����ڵ�Ϲ�ȣ     
                         InBizAddr    = '"', -- �԰��ȣ�ּ�           
                         InTelNo      = '"'  -- �԰��ȣ��ȭ��ȣ       
                   WHERE ISNULL(InCustSeq,0) = 0    
              END            
         END    
   
         IF @OutWkType > 0 --����� �����    
         BEGIN    
              --�۾����� '' ó��    
              UPDATE #_TSEChemicalsWkListCHE    
                 SET OutWkType     = @OutWkType     ,    
                     OutWkTypeName = (CASE WHEN  @OutWkType > 0 AND Seq =1 THEN @OutWkTypeName ELSE '"' END)            
                     
              --����ü ���� ���� '' ó��           
              IF EXISTS (SELECT 1 FROM #_TSEChemicalsWkListCHE WHERE Seq =1 AND OutCustSeq > 0)    
              BEGIN    
                  UPDATE #_TSEChemicalsWkListCHE    
                     SET OutCustName = '"', -- ����ȣ��             
                         OutOwner    = '"', -- �԰��ǥ�ڼ���         
                         OutBizNo    = '"', -- ������ڵ�Ϲ�ȣ     
                         OutBizAddr  = '"', -- ����ȣ�ּ�           
                         OutTelNo    = '"'  -- ����ȣ��ȭ��ȣ      
                   WHERE ISNULL(OutCustSeq,0) = 0    
                END                  
         END  
   
   
         SELECT Seq           ,      
                SubString(RetDate,1,4) RetYear,    
                SubString(RetDate,5,2)+'/'+CONVERT(VARCHAR(2),CONVERT(INT,SubString(RetDate,7,2)),112)  AS RetDate, -- �����      
                @InOutWkType  AS InOutWkType,           
                ItemSeq       , -- ǰ���ڵ�         
                PrintName     , -- ǰ��(��¸�)     
                ItemNo        , -- ǰ��             
                ToxicName     , -- ����ǰ��         
                MainPurpose   , -- �ֿ�뵵         
                Content       , -- �Է�             
                UnitSeq       , -- �����ڵ�         
                UnitName      , -- ����                
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE PreQty END AS PreQty, -- �̿���(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� �̿��� ǥ�� ����)  
                InWkType      , -- �԰����ڵ�          
                InWkTypeName  , -- �԰���              
                InQty         , -- �԰����              
                InCustSeq     , -- �԰��ȣ�ڵ�          
                InCustName    , -- �԰��ȣ��            
                InOwner       , -- �԰��ǥ�ڼ���        
                InBizNo       , -- �԰����ڵ�Ϲ�ȣ    
                InBizAddr     , -- �԰��ȣ�ּ�          
                InTelNo       , -- �԰��ȣ��ȭ��ȣ      
                OutWkType     , -- ������ڵ�          
                OutWkTypeName , -- �����              
                CASE WHEN @ChmcSeq = 9 THEN InQty ELSE OutQty END AS OutQty, -- ������(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� �԰�=��� ���� ǥ��)          
                OutCustSeq    , -- ����ȣ�ڵ�          
                OutCustName   , -- ����ȣ��            
                OutOwner      , -- �԰��ǥ�ڼ���        
                OutBizNo      , -- ������ڵ�Ϲ�ȣ    
                OutBizAddr    , -- ����ȣ�ּ�          
                OutTelNo      , -- ����ȣ��ȭ��ȣ      
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE StockQty END AS StockQty, -- ���(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� ��� ǥ�� ����)  
                ReMark        , -- ���    
                InPutDesc     , -- ���Գ����� ��ŷ    
                OutPutDesc      -- ������� ��ŷ    
           FROM #_TSEChemicalsWkListCHE  
          WHERE @InWkType > 0 OR @OutWkType > 0  
     END  
     ELSE  
     BEGIN  
         --DataBlock1    
         SELECT Seq           ,  
                RetDate       ,  
                ItemSeq       ,  
                PrintName     ,  
                ItemNo        ,  
                ToxicName     ,  
                MainPurpose   ,  
                Content       ,  
                UnitSeq       ,  
                UnitName      ,  
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE PreQty END AS PreQty, -- �̿���(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� �̿��� ǥ�� ����)  
                InWkType      ,  
                InWkTypeName  ,  
                InQty         ,  
                InCustSeq     ,  
                InCustName    ,  
                InOwner       ,  
                InBizNo       ,  
                InBizAddr     ,  
                InTelNo       ,  
                OutWkType     ,  
                OutWkTypeName ,  
                CASE WHEN @ChmcSeq = 9 THEN InQty ELSE OutQty END AS OutQty, -- ������(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� �԰�=��� ���� ǥ��)          
                OutCustSeq    ,  
                OutCustName   ,  
                OutOwner      ,  
                OutBizNo      ,  
                OutBizAddr    ,  
                OutTelNo      ,  
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE StockQty END AS StockQty, -- ���(���̵�ϽǾƹ���������Ʈ(������Ž)�� ��� ��� ǥ�� ����)  
                ReMark        ,  
                InPutDesc     ,  
                OutPutDesc      
           FROM #_TSEChemicalsWkListCHE  
          WHERE @InWkType > 0 OR @OutWkType > 0  
   
         --DataBlock2    
         SELECT A.InCustCd  AS InCustSeq ,    
                A.CustName  AS InCustName,    
                A.Owner     AS InOwner   ,    
                A.BizNo     AS InBizNo   ,    
                A.BizAddr   AS InBizAddr ,    
                A.TelNo     AS InTelNo   ,    
                RANK() OVER (ORDER BY A.InCustCd) Seq    
           FROM (SELECT DISTINCT     
                          A.InCustCd ,    
                        B.CustName ,    
                        B.Owner    ,    
                        B.BizNo    ,    
                        B.BizAddr  ,    
                        B.TelNo    
                   FROM #GetInQty     AS A    
                        JOIN _TDACust AS B ON A.InCustCd = B.CustSeq    
                  WHERE B.CompanySeq = @CompanySeq) AS A    
          WHERE @InWkType > 0 OR @OutWkType > 0  
   
         --DataBlock3    
         SELECT A.OutCustCd AS OutCustSeq ,    
                A.CustName  AS OutCustName,    
                A.Owner     AS OutOwner   ,    
                A.BizNo     AS OutBizNo   ,    
                A.BizAddr   AS OutBizAddr ,    
                A.TelNo     AS OutTelNo   ,       
                RANK() OVER (ORDER BY A.OutCustCd) Seq    
           FROM (SELECT DISTINCT     
                        A.OutCustCd ,    
                        B.CustName ,    
                        B.Owner    ,    
                        B.BizNo    ,    
                        B.BizAddr  ,    
                        B.TelNo    
                   FROM #GeTOutQty     AS A    
                   LEFT OUTER JOIN _TDACust AS B ON B.CompanySeq = @CompanySeq AND A.OutCustCd = B.CustSeq    
                  WHERE B.CompanySeq = @CompanySeq) AS A  
          WHERE @InWkType > 0 OR @OutWkType > 0  
     END  
   
     RETURN