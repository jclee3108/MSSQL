
IF OBJECT_ID('amoerp_SSLInvoiceInfoQuery') IS NOT NULL 
    DROP PROC amoerp_SSLInvoiceInfoQuery 
GO

-- v2013.11.25 

-- �ŷ�������Ȳ_amoerp by����õ
  /*********************************************************************************************************************      
     ȭ��� : �ŷ�������Ȳ      
     SP Name: _SSLInvoiceInfoQuery      
     �ۼ��� : 2008.08.07 : CREATEd by ������          
     ������ : û��ó �÷��߰�   2010.6.17 by �ֹμ�      
              2010.08.03 ������ - ����������, ���������� �߰�
     2013.05.02 ��³� - ������¿� �̿Ϸ��߰�
 ********************************************************************************************************************/      
 CREATE PROC amoerp_SSLInvoiceInfoQuery
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,          
     @PgmSeq         INT = 0      
 AS             
     DECLARE @docHandle      INT,      
             @BizUnit        INT,       
             @InvoiceDateFr  NCHAR(8),       
             @InvoiceDateTo  NCHAR(8),       
             @InvoiceNo      NVARCHAR(20),      
             @UMOutKind      INT,      
             @DeptSeq        INT,       
             @EmpSeq         INT,       
             @CustSeq        INT,      
             @CustNo         NVARCHAR(20), 
    @BillCustSeq    INT,           -- 20100617 �ֹμ� ����    
             @SMProgressType INT,  
             @IsInvConfirm   NCHAR(1),  
             @PJTName        NVARCHAR(200),  
             @PJTNo          NVARCHAR(100),
    @SMExpKind  INT    ,
             @SMLocalType    INT
       
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
       
     -- Temp�� INSERT          
     --    INSERT INTO #TXBProcessActRevQry(ProcessCd,ProcessRev,ActivitySeq,ActivityRev)          
     SELECT  @BizUnit          = ISNULL(BizUnit, 0),       
             @InvoiceDateFr    = ISNULL(InvoiceDateFr, ''),       
             @InvoiceDateTo    = ISNULL(InvoiceDateTo, ''),       
             @InvoiceNo        = LTRIM(RTRIM(ISNULL(InvoiceNo, ''))),      
             @UMOutKind        = ISNULL(UMOutKind, 0),       
             @DeptSeq          = ISNULL(DeptSeq, 0),       
             @EmpSeq           = ISNULL(EmpSeq, 0),       
             @CustSeq          = ISNULL(CustSeq, ''),      
             @CustNo           = LTRIM(RTRIM(ISNULL(CustNo, ''))), 
    @BillCustSeq      = ISNULL(BillCustSeq, ''),        -- 20100617 �ֹμ� ����    
             @SMProgressType   = ISNULL(SMProgressType, 0),  
             @PJTName          = ISNULL(PJTName, ''),  
             @PJTNo            = ISNULL(PJTNo, ''),
    @SMExpKind    = ISNULL(SMExpKind,0),
             @SMLocalType      = ISNULL(SMLocalType,0)
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
     WITH (BizUnit INT,        InvoiceDateFr NCHAR(8), InvoiceDateTo NCHAR(8), InvoiceNo NVARCHAR(20), UMOutKind INT,        
           DeptSeq INT,        EmpSeq        INT,      CustSeq       INT,      CustNo NVARCHAR(20)   , BillCustSeq  INT,
           SMProgressType INT, PJTName NVARCHAR(200),  PJTNo NVARCHAR(100),    SMExpKind INT,          SMLocalType INT )    
       
     IF @InvoiceDateTo = ''      
         SELECT @InvoiceDateTo = '99991231'      
       
 /***********************************************************************************************************************************************/      
 ---------------------- ������ ���� ����  
     DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
   
     IF @InvoiceDateTo = '99991231'  
         SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)  
     ELSE  
         SELECT  @OrgStdDate = @InvoiceDateTo 
   
     SELECT @SMOrgSortSeq = 0  
     SELECT @SMOrgSortSeq = SMOrgSortSeq  
       FROM _TCOMOrgLinkMng WITH(NOLOCK)
      WHERE CompanySeq = @CompanySeq  
        AND PgmSeq     = @PgmSeq  
     
     DECLARE @DeptTable Table( DeptSeq INT )  
   
     INSERT  @DeptTable  
     SELECT  DISTINCT DeptSeq  
       FROM  dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)  
   
 ---------------------- ������ ���� ����    
      -- �ŷ�����ǰ��������� Table  
     CREATE TABLE #Tmp_InvoiceItemProg(IDX_NO INT IDENTITY, InvoiceSeq INT, InvoiceSerl INT, CompleteCHECK INT, SMProgressType INT, 
                                   SalesSeq INT,     Qty DECIMAL(19,5),   TotCurAmt DECIMAL(19,5), TotCurVAT DECIMAL(19,5), TotCur DECIMAL(19,5),    
                                   TotDomAmt DECIMAL(19,5), TotDomVAT DECIMAL(19,5), TotDom DECIMAL(19,5),
                                   CompanySeq INT, BizUnit INT,
                       SMExpKind INT,InvoiceNo NVARCHAR(20),InvoiceDate NCHAR(8),UMOutKind INT,DeptSeq INT,EmpSeq INT,
                       CustSeq INT,BKCustSeq INT,AGCustSeq INT,DVPlaceSeq INT,
                       CurrSeq INT,ExRate Decimal(19,5),IsOverCredit NCHAR(1),
                       IsMinAmt NCHAR(1),IsStockSales NCHAR(1),Remark NVARCHAR(1000),Memo NVARCHAR(1000),IsDelvCfm NCHAR(1),IsPJT NCHAR(1), 
                       SMSalesCrtKind INT, SMLocalType INT, LastUserSeq INT, LastDateTime NCHAR(8))  
      -- ���� 
     CREATE TABLE #TMP_PROGRESSTABLE      
     (      
         IDOrder INT,      
         TABLENAME   NVARCHAR(100)      
     )      
      CREATE TABLE #TCOMProgressTracking      
     (       IDX_NO      INT,      
             IDOrder     INT,      
             Seq         INT,      
             Serl        INT,      
             SubSerl     INT,      
             Qty         DECIMAL(19, 5),      
             STDQty         DECIMAL(19, 5),      
             Amt         DECIMAL(19, 5)   ,      
             VAT         DECIMAL(19, 5)      
     )      
  
     INSERT INTO #Tmp_InvoiceItemProg(InvoiceSeq, InvoiceSerl, CompleteCHECK, Qty, TotCurAmt, TotCurVAT, TotCur, TotDomAmt, TotDomVAT, TotDom,
             CompanySeq, BizUnit, UMOutKind, DeptSeq, EmpSeq, CustSeq, BKCustSeq, AGCustSeq, DVPlaceSeq, SMExpKind, InvoiceDate, InvoiceNo, 
             CurrSeq, IsOverCredit, IsMinAmt, IsStockSales, Memo, Remark, IsDelvCfm, IsPJT , SMSalesCrtKind, SMLocalType, LastUserSeq, LastDateTime)  
      SELECT  A.InvoiceSeq, Item.InvoiceSerl, -1, ISNULL(Item.Qty, 0),
             ISNULL(Item.CurAmt, 0), 
             ISNULL(Item.CurVAT, 0), ISNULL(Item.CurAmt, 0) + ISNULL(Item.CurVAT, 0),    
             ISNULL(Item.DomAmt, 0), ISNULL(Item.DomVAT, 0), ISNULL(Item.DomAmt, 0) + ISNULL(Item.DomVAT, 0),
             A.CompanySeq, A.BizUnit, A.UMOutKind, A.DeptSeq, A.EmpSeq, A.CustSeq, A.BKCustSeq, A.AGCustSeq, A.DVPlaceSeq, 
             A.SMExpKind, A.InvoiceDate, A.InvoiceNo, 
             A.CurrSeq, A.IsOverCredit, A.IsMinAmt, A.IsStockSales, A.Memo, A.Remark, A.IsDelvCfm, A.IsPJT , A.SMSalesCrtKind,
             CASE  ISNULL(Item.IsLocal,0) WHEN '1' THEN 8218001
                                          WHEN '2' THEN 8218002 ELSE 0 END, 
             A.LastUserSeq, CONVERT(NCHAR(8), A.LastDateTime, 112)                                         
       FROM _TSLInvoice AS A WITH(NOLOCK)    
            JOIN amoerp_TSLInvoiceItemMerge AS Item WITH(NOLOCK) ON A.CompanySeq = Item.CompanySeq AND A.InvoiceSeq = Item.InvoiceSeq
            JOIN _TDASMinorValue AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                   AND A.SMExpKind  = B.MinorSeq    
                                                   AND B.Serl       = 1001    
                                                   AND B.ValueText  = '1'    
            LEFT OUTER JOIN _TDACust AS C WITh(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                                                      AND A.CustSeq    = C.CustSeq    
 --           LEFT OUTER JOIN amoerp_TSLInvoiceItemMerge AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
 --                                                            AND A.InvoiceSeq = D.InvoiceSeq  
            LEFT OUTER JOIN _TPJTProject AS P WITH(NOLOCK) ON Item.CompanySEq = P.CompanySeq  
                                                  AND Item.PJTSeq = P.PJTSeq  
      WHERE A.CompanySeq = @CompanySeq        
        AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)      
        AND (A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo)      
        AND (@InvoiceNo = '' OR A.InvoiceNo LIKE @InvoiceNo + '%')      
        AND (@UMOutKind = 0 OR A.UMOutKind = @UMOutKind)      
 ---------- ������ ���� ���� �κ�    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- ������ ���� ���� �κ�     
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)      
        AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)      
        AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%')   
        AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%') 
     AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind) 
        AND (@PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%')  
        AND (@SMLocalType = 0 OR (@SMLocalType = 8218001 AND ISNULL(Item.IsLocal,'') = '1') OR (@SMLocalType = 8218002 AND ISNULL(Item.IsLocal,'') = '2'))
  --SELECT * FROM #Tmp_InvoiceItemProg
     --/*********************************** 
     -- ���೻�� ������ ��ȸ
     --***********************************/   
     INSERT #TMP_PROGRESSTABLE      
     SELECT 1,'_TSLSalesItem'      
      exec _SCOMProgressTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceItemProg', 'InvoiceSeq', 'InvoiceSerl', ''
  
   --  SELECT *  FROM #TCOMProgressTracking
     -- �ŷ��������� Table    
     CREATE TABLE #Tmp_InvoiceProg(IDX_NO INT IDENTITY, InvoiceSeq INT, 
                 CompleteCHECK INT, SMProgressType INT, SalesSeq INT,
                 TotCurAmt DECIMAL(19,5), TotCurVAT DECIMAL(19,5), TotCur DECIMAL(19,5),    
                 TotDomAmt DECIMAL(19,5), TotDomVAT DECIMAL(19,5), TotDom DECIMAL(19,5),
                 CompanySeq INT, BizUnit INT,
     SMExpKind INT,InvoiceNo NVARCHAR(20),InvoiceDate NCHAR(8),UMOutKind INT,DeptSeq INT,EmpSeq INT,
     CustSeq INT,BKCustSeq INT,AGCustSeq INT,DVPlaceSeq INT,
     CurrSeq INT,ExRate Decimal(19,5),IsOverCredit NCHAR(1),
     IsMinAmt NCHAR(1),IsStockSales NCHAR(1),Remark NVARCHAR(1000),Memo NVARCHAR(1000),IsDelvCfm NCHAR(1),
                 IsPJT NCHAR(1), SMSalesCrtKind INT, SMLocalType INT, SalesAmt DECIMAL(19,5), LastUserSeq INT, LastDateTime NCHAR(8))
   CREATE INDEX IDX ON #Tmp_InvoiceProg(IDX_NO, InvoiceSeq, CompleteCHECK, SMProgressType, SalesSeq)
     
 --    -- �ݾ����̺�     
 --    DECLARE @InvoiceAmt TABLE (InvoiceSeq INT, TotCurAmt DECIMAL(19,5), TotCurVAT DECIMAL(19,5), TotCur DECIMAL(19,5),    
 --                                               TotDomAmt DECIMAL(19,5), TotDomVAT DECIMAL(19,5), TotDom DECIMAL(19,5))    
     
      --����ݾװ� ��������.
     SELECT A.InvoiceSeq, MAX(B.Seq) AS SalesSeq, SUM(ISNULL(Amt,0)) AS SalesAmt, SUM(ISNULL(VAT,0)) AS SalesVat 
       INTO #Tmp_SalesProg
       FROM #Tmp_InvoiceItemProg AS A 
             JOIN #TCOMProgressTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE A.Qty * B.Qty >= 0 
      GROUP BY A.InvoiceSeq
  
     -- �ݾױ��ϱ�    
     INSERT INTO #Tmp_InvoiceProg(InvoiceSeq, CompleteCHECK,
             TotCurAmt, TotCurVAT, TotCur, TotDomAmt, TotDomVAT, TotDom,
             CompanySeq, BizUnit, UMOutKind, DeptSeq, EmpSeq, CustSeq, BKCustSeq, AGCustSeq, DVPlaceSeq, SMExpKind, InvoiceDate, InvoiceNo, 
             CurrSeq, IsOverCredit, IsMinAmt, IsStockSales, Memo, Remark, IsDelvCfm, IsPJT , SMSalesCrtKind, SMLocalType, LastUserSeq, LastDateTime)  
      SELECT  InvoiceSeq, CompleteCHECK, SUM(TotCurAmt), SUM(TotCurVAT), SUM(TotCur), SUM(TotDomAmt), SUM(TotDomVAT), SUM(TotDom),
             CompanySeq, BizUnit, UMOutKind, DeptSeq, EmpSeq, CustSeq, BKCustSeq, AGCustSeq, DVPlaceSeq, SMExpKind, InvoiceDate, InvoiceNo, 
             CurrSeq, IsOverCredit, IsMinAmt, IsStockSales, Memo, Remark, IsDelvCfm, IsPJT , SMSalesCrtKind, SMLocalType, LastUserSeq, LastDateTime
       FROM #Tmp_InvoiceItemProg 
      GROUP BY InvoiceSeq , CompleteCHECK,
               CompanySeq, BizUnit, UMOutKind, DeptSeq, EmpSeq, CustSeq, BKCustSeq, AGCustSeq, DVPlaceSeq, 
               SMExpKind,  InvoiceDate, InvoiceNo,  
               CurrSeq,  IsOverCredit, IsMinAmt, IsStockSales, Memo, Remark, IsDelvCfm, IsPJT, SMSalesCrtKind, SMLocalType, LastUserSeq, LastDateTime
      
     UPDATE #Tmp_InvoiceProg      
        SET SalesSeq  = ISNULL(B.SalesSeq,0),
            SalesAmt   = ISNULL(B.SalesAmt,0) + ISNULL(B.SalesVat,0)
       FROM #Tmp_InvoiceProg AS A 
                         JOIN #Tmp_SalesProg AS B ON A.InvoiceSeq = B.InvoiceSeq
      -- �������
     EXEC _SCOMProgStatus @CompanySeq, '_TSLInvoiceItem', 1036001, '#Tmp_InvoiceProg', 'InvoiceSeq', '', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'InvoiceSeq', 'InvoiceSerl', '', '_TSLInvoice', @PgmSeq      
     
     UPDATE #Tmp_InvoiceProg     
        SET SMProgressType = B.MinorSeq    
       FROM #Tmp_InvoiceProg AS A     
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037    
                                                         AND B.CompanySeq = @CompanySeq    
                                                         AND A.CompleteCHECK = B.Minorvalue    
      --��ǥ ǰ�� ���̺�  
     CREATE TAbLE #TempInvoiceSerl(InvoiceSeq INT,   
                                   InvoiceSerl INT,   
                                   ItemName NVARCHAR(400),   
                                   ItemNo NVARCHAR(200))    
      --��ǥǰ�� ��������  
      INSERT INTO #TempInvoiceSerl  
      SELECT B.InvoiceSeq, MIN(A.InvoiceSerl), MIN(C.ItemName), MIN(C.ItemNo)  
      FROM amoerp_TSLInvoiceItemMerge AS A WITH(NOLOCK)  
           JOIN #Tmp_InvoiceProg AS B ON A.InvoiceSeq = B.InvoiceSeq  
           LEFT OUTER JOIN _TDAItem AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq  
                                                     AND A.ItemSeq = C.ItemSeq  
      WHERE A.CompanySeq = @CompanySeq  
        
      GROUP BY B.InvoiceSeq 
      --==============================================================================
   -- ������Ʈ��������
      --==============================================================================
      CREATE TABLE #TempProject
      (
         CompanySeq  INT,
   InvoiceSeq INT,
   PJTSeq  INT
      )
      
      INSERT INTO #TempProject
      SELECT S.CompanySeq, S.InvoiceSeq, ISNULL(MAX(S.PJTSeq),0) AS PJTSeq
     FROM amoerp_TSLInvoiceItemMerge AS S WITH (NOLOCK) 
          LEFT OUTER JOIN _TPJTProject AS P WITH (NOLOCK) ON S.CompanySeq = P.CompanySeq AND S.PJTSeq = P.PJTSeq
    WHERE P.CompanySeq = @CompanySeq    
     AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')    
     AND (@PJTNo   = '' OR P.PJTNo   LIKE @PJTNo   + '%') 
    GROUP BY S.CompanySeq, S.InvoiceSeq  
     --===============================================================================      
      SELECT (SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.BizUnit = BizUnit)   AS BizUnitName,     --����ι�      
            X.InvoiceSeq     AS InvoiceSeq,      --�ŷ����������ڵ�      
            X.InvoiceDate    AS InvoiceDate,     --�ŷ�������      
            X.InvoiceNo      AS InvoiceNo,       --�ŷ�������ȣ      
            X.SMExpKind      AS SMExpKind,       --���ⱸ���ڵ�    
            (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.SMExpKind = MinorSeq)      AS SMExpKindName,   --���ⱸ��      
            I.MinorName      AS UMOutKindName,   --�����      
            X.UMOutKind      AS UMOutKind,       --������ڵ�    
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = X.SMSalesCrtKind),'') AS SMSalesCrtKindName,     --�������    
            ISNULL(x.SMSalesCrtKind,0) AS SMSalesCrtKind,         --��������ڵ�    
            (SELECT DeptName    FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.DeptSeq = DeptSeq)      AS DeptName,        --�μ�      
            (SELECT EmpName     FROM _TDAEmp  WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.EmpSeq  = EmpSeq)       AS EmpName,         --�����      
            F.CustName       AS CustName,        --�ŷ�ó      
            F.CustNo         AS CustNo,          --�ŷ�ó��ȣ      
            X.CustSeq        AS CustSeq,         --�ŷ�ó�ڵ�      
            X.CurrSeq        AS CurrSeq,         --��ȭ�ڵ�
      (SELECT CurrName FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = X.CurrSeq)       AS CurrName,  --��ȭ     
            (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.BKCustSeq = CustSeq)       AS BKCustName,      --�߰���      
            (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.AGCustSeq = CustSeq)       AS AGCustName,      --�븮��      
            (SELECT DVPlaceName FROM _TSLDeliveryCust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.DVPlaceSeq = DVPlaceSeq)   AS DVPlaceName,     --��ǰó      
            X.IsOverCredit   AS IsOverCredit,    --�����ʰ�      
            X.IsMinAmt       AS IsMinAmt,        --�ݾ׹̴�      
            X.IsStockSales   AS IsStockSales,    --�Ǹ��ĺ���      
            (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.SMProgressType = MinorSeq) AS SMProgressTypeName,--�������      
            X.SMProgressType AS SMProgressType,
            X.TotDomAmt      AS TotDomAmt,       --��ȭ�ǸŰ��װ�      
            X.TotDomVAT      AS TotVat,          --��ȭ�ΰ�����      
            X.TotDom         AS TotAmt,          --��ȭ�Ѿ�      
            X.TotCurAmt      AS TotCurAmt,       --�ǸŰ��װ�        
            X.TotCurVAT      AS TotCurVat,       --�ΰ�����        
            X.TotCur         AS TotCur,          --�Ѿ�      
            X.Memo           AS Memo,            --�޸�      
            X.Remark         AS RemarkM,          --���    
            X.IsDelvCfm      AS IsDelvCfm,   
            ISNULL(X.SalesSeq,0) AS SalesSeq,  
            X.IsPJT AS IsPJT ,   
            OutK.ValueText as ValueText,  
            CASE WHEN ISNULL(N.UpperCustSeq,0) = 0 THEN X.CustSeq ELSE N.UpperCustSeq END AS BillCustSeq,  
            CASE WHEN ISNULL(O.CustName,'') = '' THEN F.CustName ELSE O.CustName END AS BillCustName,   
            OutK.ValueText      AS IsReturn, -- ��ǰ  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MajorSeq = 8218 AND MinorSeq = X.SMLocalType), '') AS SMLocalTypeName,
            ISNULL(X.SalesAmt,0)   AS SalesPrice,
            X.TotCur - ISNULL(X.SalesAmt,0) AS NonSalesAmt,
            (SELECT UserName FROM _TCAUser WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.LastUserSeq = UserSeq)   AS LastUserName, 
            X.LastDateTime       AS LastDateTime,
            ISNULL(A.UMDVConditionSeq,0) AS UMDVConditionSeq ,
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMDVConditionSeq), '') AS UMDVConditionName,
            M.ItemName,
            M.ItemNo,
            PM.PJTSeq,
            ISNULL(P.PJTNo, '') AS PJTNo,
            ISNULL(P.PJTName, '') AS PJTName,
            ISNULL(TP.PJTTypeName, '') AS PJTTypeName  
       FROM #Tmp_InvoiceProg AS X     
             JOIN _TSLInvoice AS A WITH(NOLOCK) ON X.CompanySeq = A.CompanySeq  
                                  AND X.InvoiceSeq = A.InvoiceSeq
             JOIN _TDAUMinorValue AS OutK WITH(NOLOCK) ON X.CompanySeq = OutK.CompanySeq  
                                                      AND X.UMOutKind  = Outk.MinorSeq  
                                                      AND OutK.Serl = 2002      
             LEFT OUTER JOIN _TDACust    AS F WITH(NOLOCK) ON X.CompanySeq = F.CompanySeq      
                                                          AND X.CustSeq    = F.CustSeq      
             LEFT OUTER JOIN _TDAUMinor AS I WITH(NOLOCK) ON X.CompanySeq = I.CompanySeq      
                                          AND X.UMOutKind  = I.MinorSeq  
             LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON I.CompanySeq = L.CompanySeq    
                                                              AND I.MinorSeq   = L.MinorSeq    
                                                              AND L.Serl       = 2001    
           LEFT OUTER JOIN _TDACustGroup AS N WITH(NOLOCK) ON N.CompanySeq   = @CompanySeq  
                                                            AND X.CustSeq      = N.CustSeq  
                                                            AND N.UMCustGroup  = 8014002  
             LEFT OUTER JOIN _TDACust    AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq      
                                                          AND N.UpperCustSeq = O.CustSeq     
             LEFT OUTER JOIN #TempInvoiceSerl AS M ON X.InvoiceSeq = M.InvoiceSeq
             LEFT OUTER JOIN #TempProject     AS PM ON A.InvoiceSeq = PM.InvoiceSeq
             LEFT OUTER JOIN _TPJTProject     AS P  ON PM.PJTSeq     = P.PJTSeq 
                                                   AND PM.CompanySeq = P.CompanySeq -- 20130830 ghkim �߰�
             LEFT OUTER JOIN _TPJTType        AS TP ON P.PJTTypeSeq  = TP.PJTTypeSeq
                                                   AND P.CompanySeq  = TP.CompanySeq
      WHERE (@SMProgressType = 0 OR (X.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND X.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )
   --(@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)        
        AND (@BillCustSeq = 0 OR (ISNULL(N.UpperCustSeq,0) = 0 AND X.CustSeq = @BillCustSeq) OR (N.UpperCustSeq = @BillCustSeq))
      ORDER BY X.InvoiceDate, X.InvoiceNo    
   
     RETURN
GO
exec amoerp_SSLInvoiceInfoQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PJTName />
    <PJTNo />
    <BizUnit>1</BizUnit>
    <InvoiceDateFr>20131125</InvoiceDateFr>
    <InvoiceDateTo>20131125</InvoiceDateTo>
    <UMOutKind />
    <InvoiceNo />
    <DeptSeq />
    <EmpSeq />
    <CustSeq />
    <BillCustSeq />
    <SMExpKind />
    <SMProgressType />
    <SMLocalType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017828,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016496