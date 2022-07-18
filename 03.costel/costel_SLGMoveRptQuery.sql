
IF OBJECT_ID('costel_SLGMoveRptQuery') IS NOT NULL 
    DROP PROC costel_SLGMoveRptQuery
GO 

-- v2013.11.11 

-- 자재이동입력출력물_costel by이재천
CREATE PROC costel_SLGMoveRptQuery  
     @xmlDocument    NVARCHAR(MAX) ,                    
     @xmlFlags       INT = 0,                    
     @ServiceSeq     INT = 0,                    
     @WorkingTag     NVARCHAR(10)= '',                          
     @CompanySeq     INT = 1,                    
     @LanguageSeq    INT = 1,                    
     @UserSeq        INT = 0,                    
     @PgmSeq         INT = 0                       
AS                
    
    DECLARE @docHandle      INT,      
            @InOutSeq       INT, 
            @InOutType      INT,
            @PreQty         DECIMAL(19,5), 
            @CompanyName    NVARCHAR(50)
    
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    SELECT @InOutSeq = InOutSeq, 
           @InOutType = InOutType 
      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
      WITH (InOutSeq INT, InOutType INT)      
--    -- 진행수량 테이블
--    CREATE TABLE #MoveMat(InOutSeq  INT, InOutSerl  INT, ItemSeq INT, 
--                  ReqQty DECIMAL(19,5), PreQty DECIMAL(19,5), CurrQty DECIMAL(19,5))
      -- 원천테이블
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))        
      -- 원천 데이터 테이블
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))              
      -- 현재 데이터 테이블
     CREATE TABLE #MoveMat(IDX_NO  INT IDENTITY, InOutType INT,           InOutSeq   INT,         InOutSerl  INT, ItemSeq INT,
                           Qty  DECIMAL(19, 5),  ReqQty  DECIMAL(19, 5), PreQty   DECIMAL(19, 5))  
                          -- Qty: 금회출고수량 , ReqQty: 요청수량, PreQty: 기출고수량
      -- 진행체크할 테이블값 테이블  
     CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))  
      -- 진행체크할 데이터 테이블      
     CREATE TABLE #Temp_InOutReq(IDX_NO INT IDENTITY, InOutReqSeq INT, InOutReqSerl INT, CompleteCHECK INT, SMProgressType INT, IsStop NCHAR(1))        
                    
     -- 진행된 내역 테이블 : _SCOMProgressTracking 에서 사용      
     CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,      
                                        Qty     DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))  
     -- 기출고수량테이블
     CREATE TABLE #PreQtySum(ItemSeq INT, PreQty DECIMAL(19,5))
  
 /***************************************************************************************************
     요청수량과 기출고수량을 찾기 위해 원천 데이터를 찾는다.                                         
 ***************************************************************************************************/
     -- 1. 요청수량 찾기-----------------------------------------------------------------------------
     -- 원천테이블
     INSERT #TMP_SOURCETABLE  
     SELECT 1,'_TLGInOutReqItem'   -- 입출고요청
      -- 현 데이터
     INSERT INTO #MoveMat(InOutType, InOutSeq, InOutSerl, ItemSeq, Qty, ReqQty, PreQty)
     SELECT InOutType, InOutSeq, InOutSerl, ItemSeq, Qty, 0, 0
       FROM _TLGInOutDailyItem WITH(NOLOCK)
      WHERE CompanySeq = @CompanySeq
        AND InOutSeq   = @InOutSeq 
        AND InOutType  = @InOutType
    
     -- 원천데이터 찾기 (이동요청데이터)
    EXEC _SCOMSourceTracking @CompanySeq, '_TLGInOutDailyItem', '#MoveMat', 'InOutSeq', 'InOutSerl', ''    
    
    UPDATE A 
       SET ReqQty = C.Qty
      FROM #MoveMat AS A 
      JOIN #TCOMSourceTracking AS B ON ( A.IDX_NO = B.IDX_NO ) 
      LEFT OUTER JOIN _TLGInOutReqItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.Seq AND C.ReqSerl = B.Serl ) 
    
    SELECT A.InOutType, A.InOutSeq, D.DeptSeq, D.EmpSeq
      INTO #MoveMatSub
      FROM #MoveMat AS A 
      JOIN #TCOMSourceTracking AS B ON ( A.IDX_NO = B.IDX_NO ) 
      LEFT OUTER JOIN _TLGInOutReqItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.Seq AND C.ReqSerl = B.Serl ) 
      LEFT OUTER JOIN _TLGInOutReq     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = C.ReqSeq ) 
     GROUP BY A.InOutType, A.InOutSeq, D.DeptSeq, D.EmpSeq
    
  --    -- 2. 기출고수량 찾기---------------------------------------------------------------------------
     INSERT #TMP_PROGRESSTABLE         
     SELECT 1, '_TLGInOutDailyItem'  
      EXEC _SCOMProgressTracking @CompanySeq, '_TLGInOutReqItem', '#TCOMSourceTracking', 'Seq', 'Serl', ''  
      INSERT #PreQtySum
     SELECT B.ItemSeq, SUM(A.Qty)
       FROM #TCOMProgressTracking AS A
             LEFT OUTER JOIN _TLGInOutDailyItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                 AND A.Seq        = B.InOutSeq
                                                                 AND A.Serl       = B.InOutSerl
      GROUP BY B.ItemSeq
      UPDATE #MoveMat
        SET PreQty = B.PreQty
       FROM #MoveMat AS A
             LEFT OUTER JOIN #PreQtySum AS B ON A.ItemSeq = B.ItemSeq
  /**********************************************************
     최종조회데이터                                         
 **********************************************************/
    SELECT ISNULL(B.InOutDate, '')          AS InOutDate        ,  -- 이동일      
           ISNULL(D.EmpName, '')            AS EmpName          ,  -- 담당자      
           ISNULL(E.WHName, '')             AS InWHName         ,  -- 반출처      
           ISNULL(B.Remark, '')             AS Remark           ,  -- 비고
           ISNULL(B.Memo, '')               AS Memo             ,  -- 반출구분    
           ISNULL(F.MinorName, '')          AS OutKindName      ,  -- 재고상태    
           LTRIM(RTRIM(ISNULL(G.ItemName, ''))) + ' / ' + LTRIM(RTRIM(ISNULL(G.Spec, ''))) AS ItemNameSpec     ,  -- 품명        
           ISNULL(G.ItemNo, '')             AS ItemNo           ,  -- 품번        
           ISNULL(H.UnitName, '')           AS UnitName         ,  -- 단위        
           ISNULL(A.ReqQty, 0 )             AS MoveReqQty       ,  -- 요청수량    
           ISNULL(A.PreQty, 0 )             AS PreMoveQty       ,  -- 기출고수량  
           ISNULL(A.Qty, 0 )                AS CurrMoveQty      ,  -- 금회출고수량
           ISNULL(C.InOutRemark, '')        AS InOutRemark      ,  -- 비고        
           A.IDX_NO                         AS No               ,  -- 번호        
           A.InOutSeq                       AS InOutSeq         ,  -- 입출고내부번호  
           ISNULL(@CompanyName, '')         AS CompanyName      ,  -- 법인명      
           ISNULL(B.InOutNo, '')            AS InOutNo          ,   -- 입출고번호  
           ISNULL(I.DeptName, '')           AS DeptName         ,  -- 부서
           ISNULL(C.LotNo ,   '')           AS LotNo            ,  -- LotNo
           ISNULL(LM.ValiDate, '')          AS ValiDate         ,  -- 유효일자
           ISNULL(J.MinorName, '')          AS InOutDetailKindName, -- 이동구분
           ISNULL(G.ItemName, '')           AS ItemName         ,   -- 품명
           ISNULL(G.Spec, '')               AS Spec             ,   -- 규격
           ISNULL(K.WHName, '')             AS OutWHName        ,    -- 출고창고
           ISNULL(L.BizUnitName,'')         AS ReqBizUnitName   ,   --입고사업부문
           ISNULL(M.BizUnitName,'')         AS BizUnitName      ,   --출고사업부문 
           O.DeptName                       AS ReqDeptName      ,   -- 요청부서
           P.EmpName                        AS ReqEmpName           -- 요청담당자
           
      FROM #MoveMat                 AS A
      JOIN _TLGInOutDaily           AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutSeq = B.InOutSeq AND A.InOutType = B.InOutType ) 
      JOIN _TLGInOutDailyItem       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.InOutSeq = C.InOutSeq AND A.InOutSerl = C.InOutSerl AND A.InOutType = C.InOutType ) 
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( B.CompanySeq = D.CompanySeq AND B.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDAWH        AS E WITH(NOLOCK) ON ( B.CompanySeq = E.CompanySeq AND B.InWHSeq = E.WHSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS F WITH(NOLOCK) ON ( C.CompanySeq = F.CompanySeq AND C.InOutKind = F.MinorSeq ) 
      LEFT OUTER JOIN _TDAItem      AS G WITH(NOLOCK) ON ( C.CompanySeq = G.CompanySeq AND C.ItemSeq = G.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS H WITH(NOLOCK) ON ( C.CompanySeq = H.CompanySeq AND C.UnitSeq = H.UnitSeq ) 
      LEFT OUTER JOIN _TDADept      AS I WITH(NOLOCK) ON ( B.CompanySeq = I.CompanySeq AND B.DeptSeq = I.DeptSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS J WITH(NOLOCK) ON ( C.CompanySeq = J.CompanySeq AND C.InOutDetailKind = J.MinorSeq ) 
      LEFT OUTER JOIN _TLGLotMaster AS LM WITH(NOLOCK) ON ( C.CompanySeq = LM.CompanySeq AND C.LotNo = LM.LotNo AND C.ItemSeq = LM.ItemSeq ) 
      LEFT OUTER JOIN _TDAWH        AS K WITH(NOLOCK) ON ( B.CompanySeq = K.CompanySeq AND B.OutWHSeq = K.WHSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS L WITH(NOLOCK) ON ( B.CompanySeq = L.CompanySeq AND B.ReqBizUnit = L.BizUnit ) 
      LEFT OUTER JOIN _TDABizUnit   AS M WITH(NOLOCK) ON ( B.CompanySeq = M.CompanySeq AND B.BizUnit = M.BizUnit ) 
      LEFT OUTER JOIN #MoveMatSub   AS N WITH(NOLOCK) ON ( N.InOutSeq = A.InOutSeq AND N.InOutType = A.InOutType ) 
      LEFT OUTER JOIN _TDADept      AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.DeptSeq = N.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.EmpSeq = N.EmpSeq ) 
    
    RETURN
GO
exec costel_SLGMoveRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InOutSeq>1001172</InOutSeq>
    <InOutType>82</InOutType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019245,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5484