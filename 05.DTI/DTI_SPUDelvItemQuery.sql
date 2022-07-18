
IF OBJECT_ID('DTI_SPUDelvItemQuery') IS NOT NULL
    DROP PROC DTI_SPUDelvItemQuery
    
GO
--v2013.06.12

-- 구매납품세부조회_DTI (매출처/EndUser 추가) By이재천
/*************************************************************************************************            
  설  명 - 구매납품 디테일조회      
  작성일 - 2008.8.18 : CREATEd by 노영진      
     
  수정일 - 2010년 10월 21일 이용춘( MakerSeq, MakerName 추가)  
           2011년 02월 10일 이상화(사업부문 컬럼추가) 
  수정내역 :: ItemSeqOLD(공정품코드), LotNoOLD(LotNo) Select 추가; LotNo 변경(U) 시에 LotNoMaster에 업데이트가 되지 않아서 2011.5.11 김세호  
           :: 2011. 7. 4 hkim StdUnitQty 계산 되는 부분 수정
 *************************************************************************************************/            
CREATE PROC DTI_SPUDelvItemQuery      
    @xmlDocument    NVARCHAR(MAX),          
    @xmlFlags       INT = 0,          
    @ServiceSeq     INT = 0,          
    @WorkingTag     NVARCHAR(10)= '',          
    @CompanySeq     INT = 1,          
    @LanguageSeq    INT = 1,          
    @UserSeq        INT = 0,          
    @PgmSeq         INT = 0          
 AS 
                  
    DECLARE @docHandle INT,           
            @DelvSerl  INT,      
            @QCAutoIn  NCHAR(1)      
       
    -- 서비스 마스타 등록 생성          
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'         
      
    IF @@ERROR <> 0 RETURN          
          
    SELECT @DelvSerl = DelvSerl FROM #TPUDelvItem      
      
    CREATE TABLE #tem_QCData
        (      
            CompanySeq   INT,      
            DelvSeq      INT,      
            DelvSerl     INT,      
            TestEndDate  NCHAR(8),      
            Qty          DECIMAL(19,5),      
            PassedQty    DECIMAL(19,5),      
            ReqInQty     DECIMAL(19,5),      
            QCStdUnitQty DECIMAL(19,5)       
        )      
    
    -- 환경설정값 가져오기  # 무검사품 자동입고 여부      
    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT        
     
    SELECT @WorkingTag = WorkingTag FROM #TPUDelvItem      
    IF @WorkingTag = 'J'       
        GoTo Jump_Qry      
    ------------------------      
    --입고의뢰수량----------      
    ------------------------          
    INSERT INTO #tem_QCData(CompanySeq  ,DelvSeq,  DelvSerl,   TestEndDate,   Qty,     PassedQty,    ReqInQty ,QCStdUnitQty)      
         SELECT @CompanySeq,          
                B.SourceSeq,          
                B.SourceSerl,         
                SUBSTRING(TestEndDate,1,8) ,       
                A.Qty  ,      
                SUM(ISNULL(PassedQty,0)),      
                SUM(ISNULL(ReqInQty,0)),      
                SUM(ISNULL(CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE ISNULL(ReqInQty,0) * (ConvNum/ConvDen) END,0))      
           FROM #TPUDelvItem     AS A       
           JOIN _TPDQCTestReport AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                  AND A.DelvSeq    = B.SourceSeq      
                                                  AND B.SourceType = '1'      
           JOIN _TPUDelvItem     AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq      
                                                  AND C.DelvSeq    = B.SourceSeq      
                                                  AND C.DelvSerl   = B.SourceSerl      
           LEFT OUTER JOIN _TDAItemUnit AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq      
                                                         AND C.ItemSeq    = D.ItemSeq      
                                                         AND C.UnitSeq    = D.UnitSeq      
            GROUP BY B.SourceSeq, B.SourceSerl,A.Qty,B.TestEndDate      
        
    ------------------------      
    --입고의뢰수량 END------      
    ------------------------      
     
    --------------        
    --조회결과  나중에 내 외자 구분하기(환율확인해야함)      
    --------------        
    SELECT M.DelvNo                    AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- 품명        
           I.ItemNo                AS ItemNo           ,     -- 품번        
           I.Spec                      AS Spec             ,     -- 규격        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- 단위        
           ISNULL(D.Price,0)           AS Price            ,     -- 단가        
           ISNULL(D.Qty,0)             AS Qty              ,     -- 금회납품수량        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- 금액        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- 금액        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- 원화단가            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- 원화금액        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- 원화금액        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- 부가세      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- 원화부가세        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- 부가세포함여부      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- 부가세율      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- 부가세율
           ISNULL(L.WHName ,'')        AS WHName           ,     -- 창고      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- 납품장소(창고)코드         
           K.CustName                  AS DelvCustName     ,     -- 납품처               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- 납품처코드                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- 영업거래처명           
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- 영업거래처                 
           ''                          AS SMQcTypeName     ,     -- 검사구분      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- 검사구분      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- 단위(재고단위)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- 단위(재고단위)        
           ISNULL(D.stdUnitQty,0)      AS StdUnitQty       ,     -- 재고단위수량        
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- 재고단위환산수량      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- 품목코드        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- 단위코드        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.DelvSerl,'')       AS DelvSerl         ,     -- 납품순번        
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- 구매입고점프시 필요      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- 구매입고점프시 필요      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- 구매입고점프시 필요      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- 프로젝트코드      
           P.PJTName                   AS PJTName          ,     -- 프로젝트      
           P.PJTNo                     AS PJTNo            ,      -- 프로젝트번호      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           ''                         AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC금액        
           CASE WHEN D.SMQcType = 6035001 THEN '' ELSE X.TestEndDate    END    AS QcDate           ,     -- 검사일  ,      
           CASE WHEN D.SMQcType = 6035001 THEN 0 ELSE X.ReqInQty       END    AS QCQty            ,     -- 입고의뢰수량  ,      
           CASE WHEN D.SMQcType = 6035001 THEN 0 ELSE X.QCStdUnitQty   END    AS QCStdUnitQty  ,         -- 입고의뢰수량(기준단위) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  추가  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName 추가
           P.BizUnit       AS BizUnit,     -- 사업부문코드    (이상화 추가)
           PP.BizUnitName      AS BizUnitName,    -- 프로젝트사업부문(이상화 추가)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- 공정품 코드 Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호
           D.IsFiction                AS IsFiction       ,      -- 2011. 12. 30 hkim 추가
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim 추가
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim 추가
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim 추가
           T.EvidName                 AS EvidName        ,       -- 2011. 12. 30 hkim 추가
           D.Memo1                    AS SalesCustSeq    ,      -- 매출처코드
           D.Memo2                    AS EndUserSeq      ,      -- EndUser코드
           A.CustName                 AS SalesCustName   ,      -- 매출처
           B.CustName                 AS EndUserName            -- EndUser
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv        AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                              AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust     AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                      AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN _TDACurr     AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                      AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem     AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                      AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit     AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                      AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                        AND D.ItemSeq     = UU.ItemSeq       
                                                        AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- 구매기본단위      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- 기준단위(재고단위)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  환산단위(기준단위)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  영업거래처      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  영업거래처      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  영업거래처      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  영업거래처      
                                                         AND D.WhSeq      = L.WHSeq   --  영업거래처      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  프로젝트      
                                                         AND D.PJTSeq      = P.PJTSeq      
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- 사업부문 (이상화 추가)
               AND P.BizUnit  = PP.BizUnit
 --    LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
 --                                                           AND D.PJTSeq      = N.PJTSeq      
 --                                                           AND D.WBSSeq      = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- 입고의뢰수량      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- 면세 제외
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid            AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                           AND D.EvidSeq    = T.EvidSeq   
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 )                                                           
                                                   
       
     WHERE D.CompanySeq   = @CompanySeq      
 RETURN      
 --------------------------------------------------------------------------      
    Jump_Qry:      
    DECLARE @IsOver NCHAR(1)
  
    SELECT @IsOver = ISNULL(IsOverFlow, '0')
      FROM _TCOMProgRelativeTables 
     WHERE CompanySeq = @CompanySeq
       AND FromTableSeq = 10 
       AND ToTableSeq   = 9
       
    -- 진행 수량 가져오고      
    -------------------      --입고진행여부-----      
    -------------------      
    CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))          
        
    CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT)      
      
    CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))            

    CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), CurAmt DECIMAL(19,5), CurVAT DECIMAL(19, 5))      

    INSERT #TMP_PROGRESSTABLE           
    SELECT 1, '_TPUDelvInItem'               -- 구매입고      
       
    -- 구매납품          
    EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvItem', 'DelvSeq', 'DelvSerl', ''             

    INSERT INTO #OrderTracking          
    SELECT IDX_NO,          
           SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),          
           SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END),      
           SUM(CASE IDOrder WHEN 1 THEN VAT     ELSE 0 END)         
      FROM #TCOMProgressTracking          
     GROUP BY IDX_No          
      
    INSERT INTO #tem_QCData(CompanySeq  ,DelvSeq,  DelvSerl,   TestEndDate,   Qty,     PassedQty,    ReqInQty ,QCStdUnitQty)      
         SELECT @CompanySeq,          
                B.SourceSeq,          
                B.SourceSerl,         
                SUBSTRING(TestEndDate,1,8) ,       
                A.Qty  ,      
                SUM(ISNULL(PassedQty,0)),      
                SUM(ISNULL(ReqInQty,0)),      
                SUM(ISNULL(CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE ISNULL(ReqInQty,0) * (ConvNum/ConvDen) END,0))      
           FROM #TPUDelvItem             AS A       
           JOIN _TPDQCTestReport         AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                          AND A.DelvSeq    = B.SourceSeq      
                                                          AND B.SourceType = '1'      
           JOIN _TPUDelvItem             AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq      
                                                          AND C.DelvSeq    = B.SourceSeq      
                                                          AND C.DelvSerl   = B.SourceSerl      
           LEFT OUTER JOIN _TDAItemUnit  AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq      
                                                          AND C.ItemSeq    = D.ItemSeq      
                                                          AND C.UnitSeq    = D.UnitSeq      
          GROUP BY B.SourceSeq, B.SourceSerl, A.Qty, B.TestEndDate      
       
     -- QC 수량 - 진행 수량(미검사품)      
    SELECT M.DelvNo          AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- 품명        
           I.ItemNo                    AS ItemNo           ,     -- 품번        
           I.Spec                      AS Spec             ,     -- 규격        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- 단위        
           ISNULL(D.Price,0)           AS Price            ,     -- 단가        
           ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0) AS Qty              ,     -- 금회납품수량        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- 금액        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- 금액        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- 원화단가            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- 원화금액        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- 원화금액        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- 부가세      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- 원화부가세        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- 부가세포함여부      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- 부가세율      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- 부가세율
           ISNULL(L.WHName ,'')        AS WHName           ,     -- 창고      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- 납품장소(창고)코드         
           K.CustName                  AS DelvCustName     ,     -- 납품처               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- 납품처코드                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- 영업거래처명           
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- 영업거래처                 
           ''                          AS SMQcTypeName     ,     -- 검사구분      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- 검사구분      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- 단위(재고단위)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- 단위(재고단위)        
           --ISNULL(D.stdUnitQty,0)      AS StdUnitQty       ,     -- 재고단위수량        
           CASE ISNULL(F.ConvDen,0) WHEN 0 THEN 0 ELSE ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0) * ( ISNULL(F.ConvNum,0)/ISNULL(F.ConvDen,0)) END AS StdUnitQty ,            
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- 재고단위환산수량      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- 품목코드        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- 단위코드        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- 구매입고점프시 필요      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- 구매입고점프시 필요      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- 구매입고점프시 필요      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- 프로젝트코드      
           P.PJTName                   AS PJTName          ,     -- 프로젝트      
           P.PJTNo                     AS PJTNo            ,     -- 프로젝트번호      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           N.WBSName                   AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC금액        
           CASE WHEN D.SMQcType = 6035001 THEN M.DelvDate  ELSE X.TestEndDate    END    AS QcDate           ,     -- 검사일  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.Qty       ELSE X.ReqInQty       END    AS QCQty            ,     -- 입고의뢰수량  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.StdUnitQty ELSE X.QCStdUnitQty   END    AS QCStdUnitQty   ,        -- 입고의뢰수량(기준단위) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  추가  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName 추가 
           P.BizUnit       AS BizUnit,     -- 사업부문코드    (이상화 추가)
           PP.BizUnitName      AS BizUnitName,    -- 프로젝트사업부문(이상화 추가)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- 공정품 코드 Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호
           D.IsFiction              AS IsFiction       ,      -- 2011. 12. 30 hkim 추가
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim 추가
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim 추가
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim 추가
           T.EvidName                 AS EvidName        ,      -- 2011. 12. 30 hkim 추가
           D.Memo1                    AS SalesCustSeq    ,      -- 매출처코드
           D.Memo2                    AS EndUserSeq      ,      -- EndUser코드
           A.CustName                 AS SalesCustName   ,      -- 매출처
           B.CustName                 AS EndUserName            -- EndUser
           
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv        AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                                         AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust        AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                         AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN #OrderTracking  AS ZZ               ON Z.IDX_No     = ZZ.IDX_No      
      LEFT OUTER JOIN _TDACurr        AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                         AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem        AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                         AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit        AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                         AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                         AND D.ItemSeq     = UU.ItemSeq       
                                                         AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- 구매기본단위      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- 기준단위(재고단위)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  환산단위(기준단위)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  영업거래처      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  영업거래처      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  영업거래처      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  영업거래처      
                                                         AND D.WhSeq      = L.WHSeq     --  영업거래처      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  프로젝트      
                                                         AND D.PJTSeq      = P.PJTSeq      
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- 사업부문 (이상화 추가)
                                                         AND P.BizUnit  = PP.BizUnit
      LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
                                                         AND D.PJTSeq      = N.PJTSeq      
                                                         AND D.WBSSeq       = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- 입고의뢰수량      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- 면세 제외
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid            AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                          AND D.EvidSeq    = T.EvidSeq                                                             
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 ) 
       
     WHERE D.CompanySeq   = @CompanySeq      
       AND ((@IsOver <> '1' AND (ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0)) <> 0) OR @IsOver = '1')        
       AND D.SMQCType    NOT IN (6035001)      
       
     UNION ALL      
     -- 원수량 - 진행 수량(무검사품)      
    SELECT M.DelvNo                    AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- 품명        
           I.ItemNo                    AS ItemNo           ,     -- 품번        
           I.Spec                      AS Spec             ,     -- 규격        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- 단위        
           ISNULL(D.Price,0)           AS Price            ,    -- 단가        
           ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0) AS Qty              ,     -- 금회납품수량        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- 금액        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- 금액        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- 원화단가            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- 원화금액        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- 원화금액        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- 부가세      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- 원화부가세        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- 부가세포함여부      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- 부가세율      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- 부가세율
           ISNULL(L.WHName ,'')        AS WHName           ,     -- 창고      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- 납품장소(창고)코드         
           K.CustName                  AS DelvCustName     ,     -- 납품처               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- 납품처코드                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- 영업거래처명            
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- 영업거래처                 
           ''                          AS SMQcTypeName     ,     -- 검사구분      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- 검사구분      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- 단위(재고단위)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- 단위(재고단위)        
           CASE ISNULL(F.ConvDen,0) WHEN 0 THEN 0 ELSE ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0) * ( ISNULL(F.ConvNum,0)/ISNULL(F.ConvDen,0)) END AS StdUnitQty ,            
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- 재고단위환산수량      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- 품목코드        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- 단위코드        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- 구매입고점프시 필요      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- 구매입고점프시 필요      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- 구매입고점프시 필요      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- 프로젝트코드      
           P.PJTName                   AS PJTName          ,     -- 프로젝트      
           P.PJTNo                     AS PJTNo            ,     -- 프로젝트번호      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           N.WBSName                   AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC금액        
           CASE WHEN D.SMQcType = 6035001 THEN M.DelvDate  ELSE X.TestEndDate    END    AS QcDate           ,     -- 검사일  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.Qty       ELSE X.ReqInQty       END    AS QCQty            ,     -- 입고의뢰수량  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.StdUnitQty ELSE X.QCStdUnitQty   END    AS QCStdUnitQty  ,         -- 입고의뢰수량(기준단위) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  추가  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName 추가
           P.BizUnit       AS BizUnit,     -- 사업부문코드    (이상화 추가)
           PP.BizUnitName      AS BizUnitName,    -- 프로젝트사업부문(이상화 추가)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- 공정품 코드 Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No 업데이트시 LotMaster에 업데이트 안되서 추가 2011. 5. 11 김세호            
           D.IsFiction                AS IsFiction       ,      -- 2011. 12. 30 hkim 추가
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim 추가
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim 추가
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim 추가
           T.EvidName                 AS EvidName        ,      -- 2011. 12. 30 hkim 추가
           D.Memo1                    AS SalesCustSeq    ,      -- 매출처코드
           D.Memo2                    AS EndUserSeq      ,      -- EndUser코드
           A.CustName                 AS SalesCustName   ,      -- 매출처
           B.CustName                 AS EndUserName            -- EndUser
           
                
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv     AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                           AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust        AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                         AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN #OrderTracking  AS ZZ               ON Z.IDX_No     = ZZ.IDX_No      
      LEFT OUTER JOIN _TDACurr        AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                         AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem        AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                         AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit        AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                         AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                         AND D.ItemSeq     = UU.ItemSeq       
                                                         AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- 구매기본단위      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- 기준단위(재고단위)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  환산단위(기준단위)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  영업거래처      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  영업거래처      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  영업거래처      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  영업거래처      
                                                         AND D.WhSeq      = L.WHSeq     --  영업거래처      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  프로젝트      
                                                         AND D.PJTSeq      = P.PJTSeq
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- 사업부문 (이상화 추가)
                                                         AND P.BizUnit  = PP.BizUnit     
      LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
                                                         AND D.PJTSeq      = N.PJTSeq      
                                                         AND D.WBSSeq      = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- 입고의뢰수량      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- 면세 제외
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid         AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                        AND D.EvidSeq    = T.EvidSeq     
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 )                                                         
       
     WHERE D.CompanySeq   = @CompanySeq      
       AND ((@IsOver <> '1' AND (ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0)) <> 0) OR (@IsOver = '1'))
       AND D.SMQCType IN( 6035001)      
       
       
 RETURN        
 GO
exec DTI_SPUDelvItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DelvSeq>133707</DelvSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553