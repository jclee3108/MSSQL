IF OBJECT_ID('KPXCM_SSLImpBLItemListQuery') IS NOT NULL 
    DROP PROC KPXCM_SSLImpBLItemListQuery
GO 

-- v2016.05.11 

/************************************************************

    Ver.20140630

 설  명 - 데이터-수입BL(조회) : 품목현황조회
 작성일 - 20090525
 작성자 - 이성덕
 수정일 - 2009.08.28 BY 송경애
         :: 조회조건(프로젝트, 프로젝트번호) 추가, 컬럼(프로젝트, 프로젝트번호)추가
          2009.12.02 BY 박소연
         :: 원천업무(SourceTable)/원천관리번호(SourceNo)/원천번호(SourceRefNo) 조회 조건 추가 및 Field추가
          2011.03.11 BY 이상화
         :: 조회조건(규격) 추가
************************************************************/

CREATE PROC KPXCM_SSLImpBLItemListQuery
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
    DECLARE @docHandle           INT,
            @BLNo                NVARCHAR(100),
            @BLRefNo             NVARCHAR(100),
            @BLDateFr            NCHAR(8),
            @BLDateTo            NCHAR(8),
            @BizUnit             INT,
            @SMImpType           INT,
            @DeptSeq             INT,
            @CustSeq             INT,
            @EmpSeq              INT,
            @UMPriceTerms        INT,
            @UMPayment1          INT,
            @UMPayment2          INT,
            @SMProgressType      INT, 
            @ItemName            NVARCHAR(100),
            @ItemNo              NVARCHAR(100),
            @PJTName             NVARCHAR(100) ,   -- 프로젝트명
            @PJTNo               NVARCHAR(100),    -- 프로젝트번호    
            @UMSupplyType        INT            ,    
            @TopUnitName         NVARCHAR(200)  ,    
            @TopUnitNo           NVARCHAR(200)  ,
            @Spec				 NVARCHAR(100)    -- 규격 (20110311 이상화 추가)   

    -- 추가변수 20091202 박소연 
    DECLARE @SourceTableSeq INT,  
            @SourceNo       NVARCHAR(30),  
            @SourceRefNo    NVARCHAR(30),  
            @TableName      NVARCHAR(100),  
            @TableSeq       INT,  
            @SQL            NVARCHAR(MAX) 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 

    SELECT @BLNo            = ISNULL(BLNo,''),
           @BLRefNo         = ISNULL(BLRefNo,''),
           @BLDateFr        = ISNULL(BLDateFr,''),
           @BLDateTo        = ISNULL(BLDateTo,''),
           @BizUnit         = ISNULL(BizUnit,0),
           @SMImpType       = ISNULL(SMImpType,0),
           @DeptSeq         = ISNULL(DeptSeq,0),
           @CustSeq         = ISNULL(CustSeq,0),
           @EmpSeq          = ISNULL(EmpSeq,0),
           @UMPriceTerms    = ISNULL(UMPriceTerms,0),
           @UMPayment1      = ISNULL(UMPayment1,0),
           @UMPayment2      = ISNULL(UMPayment2,0),
           @SMProgressType  = ISNULL(SMProgressType, 0),
           @ItemName        = ISNULL(ItemName,''),
           @ItemNo          = ISNULL(ItemNo,''),
           @PJTName         = ISNULL(PJTName,  '') ,                        
           @PJTNo           = ISNULL(PJTNo,  ''),  
           @SourceTableSeq  = ISNULL(SourceTableSeq, 0),  -- 추가 20091202 박소연 
           @SourceNo        = ISNULL(SourceNo, ''),       -- 추가 20091202 박소연 
           @SourceRefNo     = ISNULL(SourceRefNo, ''),    -- 추가 20091202 박소연 
           @UMSupplyType    = ISNULL(UMSupplyType ,  0),    
           @TopUnitName     = ISNULL(TopUnitName  , ''),                        
           @TopUnitNo       = ISNULL(TopUnitNo    , ''),
           @Spec			= ISNULL(Spec		  , '')   -- 규격 (20110311 이상화 추가)     
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (  BLNo                NVARCHAR(100),
            BLRefNo             NVARCHAR(100),
            BLDateFr            NCHAR(8),
            BLDateTo            NCHAR(8),
            BizUnit             INT,
            SMImpType           INT,
DeptSeq             INT,
            CustSeq             INT,
            EmpSeq              INT,
            UMPriceTerms        INT,
            UMPayment1          INT,
            UMPayment2          INT,
            SMProgressType      INT, 
            ItemName            NVARCHAR(100),
            ItemNo              NVARCHAR(100),
            PJTName             NVARCHAR(100),
            PJTNo               NVARCHAR(100),  
            SourceTableSeq      INT,            -- 추가 20091202 박소연 
            SourceNo            NVARCHAR(30),   -- 추가 20091202 박소연 
            SourceRefNo         NVARCHAR(30),   -- 추가 20091202 박소연
            UMSupplyType        INT          ,    
            TopUnitName         NVARCHAR(200),    
            TopUnitNo           NVARCHAR(200),
            Spec				NVARCHAR(100))  -- 규격 (20110311 이상화 추가) 

    IF @BLDateFr = '' SELECT @BLDateFr = '00010101'
    IF @BLDateTo = '' SELECT @BLDateTo = '99991231'

    -- 기초데이터테이블
    CREATE TABLE #TEMP_TUIImpBLItem(IDX_NO  INT IDENTITY, CompanySeq INT,  BLSeq  INT, BLSerl INT)

    --  진행 테이블  
    CREATE TABLE #TEMPTUIImpBLProg(IDX_NO INT IDENTITY, CompanySeq INT, BLSeq INT, BLSerl INT, CompleteCHECK INT, SMProgressType INT, IsStop NCHAR(1))   

--    -- 원천테이블
--    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))        

--    -- 원천 데이터 테이블
--    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
--                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))        


--------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 기초데이터
    INSERT INTO #TEMP_TUIImpBLItem(CompanySeq, BLSeq, BLSerl)
    SELECT A.CompanySeq, A.BLSeq, B.BLSerl
      FROM _TUIImpBL AS A WITH(NOLOCK)
            JOIN _TUIImpBLItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                AND A.BLSeq = B.BLSeq
            LEFT OUTER JOIN _TDAItem       AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq AND B.ItemSeq = L.ItemSeq
            LEFT OUTER JOIN _TPJTProject   AS Y WITH(NOLOCK) ON A.CompanySeq = Y.CompanySeq AND B.PJTSeq = Y.PJTSeq

     WHERE A.CompanySeq = @CompanySeq
       AND (@BLNo = '' OR A.BLNo LIKE '%' + @BLNo + '%')
       AND (@BLRefNo = '' OR A.BLRefNo LIKE '%' + @BLRefNo + '%')
       AND (@BizUnit = 0 OR @BizUnit = A.BizUnit)
       AND (@SMImpType = 0 OR @SMImpType = A.SMImpKind)
       AND (@DeptSeq = 0 OR @DeptSeq = A.DeptSeq)
       AND (@CustSeq = 0 OR @CustSeq = A.CustSeq)
       AND (@EmpSeq = 0 OR @EmpSeq = A.EmpSeq)
       AND (@UMPayment1 = 0 OR @UMPayment1 = A.UMPayment1)
       AND (@UMPayment2 = 0 OR @UMPayment2 = A.UMPayment2)
       AND (@UMPriceTerms = 0 OR @UMPriceTerms = A.UMPriceTerms)
       AND (A.BLDate BETWEEN @BLDateFr AND @BLDateTo)
       AND (L.ItemName = '' OR L.ItemName LIKE '%' + @ItemName + '%')
       AND (L.ItemNo = '' OR L.ItemNo LIKE '%' + @ItemNo + '%')
       AND (@PJTName = '' OR Y.PJTName LIKE  @PJTName + '%')
       AND (@PJTNo = ''   OR Y.PJTNo LIKE  @PJTNo + '%')
       AND (@Spec = ''    OR L.Spec  LIKE  @Spec  + '%') -- 규격 (이상화 20110311 추가)


    -- 진행데이터
    INSERT INTO #TEMPTUIImpBLProg(CompanySeq, BLSeq, BLSerl, CompleteCHECK, IsStop)    
    SELECT A.CompanySeq, A.BLSeq, A.BLSerl, -1, NULL  
      FROM #TEMP_TUIImpBLItem  AS A 

    EXEC _SCOMProgStatus @CompanySeq, '_TUIImpBLItem', 1036002, '#TEMPTUIImpBLProg', 'BLSeq', 'BLSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', '', 'BLSeq', 'BLSerl', '', '_TUIImpBL', @PgmSeq
  
    UPDATE #TEMPTUIImpBLProg     
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --진행중단    
                    WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료    
                                         WHEN A.IsStop = '1' THEN 1037005       -- 중단    
                                         WHEN A.CompleteCHECK = 1 THEN 1037003  -- 확정(승인)  
                                         ELSE B.MinorSeq END)    
      FROM #TEMPTUIImpBLProg AS A WITH(NOLOCK)    
          LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND B.MajorSeq = 1037    
                                                      AND A.CompleteCHECK = B.Minorvalue  


    /****** 미입고 수량을 구하기 위한 진행 조회 :: 20130625 박성호 추가 ***/
    
    -- 진행체크 테이블 값 테이블 CREATE & INSERT      
    CREATE TABLE #TMP_PROGRESSTABLE (  
        IDOrder   INT,   
        TABLENAME NVARCHAR(100))
      
    INSERT #TMP_PROGRESSTABLE         
    SELECT 1, '_TUIImpDelvItem' -- 수입입고

    -- 진행 공통 SP OUTPUT TABLE      
    CREATE TABLE #TCOMProgressTracking (  
        IDX_NO  INT			  ,   
        IDOrder INT			  ,   
        Seq     INT			  ,   
        Serl    INT			  ,   
        SubSerl INT			  ,      
        Qty     DECIMAL(19, 5),   
        StdQty  DECIMAL(19, 5),   
        Amt     DECIMAL(19, 5),   
        VAT     DECIMAL(19, 5))
  
    -- 진행 공통 SP 실행  
    EXEC _SCOMProgressTracking @CompanySeq            = @CompanySeq         ,   
                               @TableName             = '_TUIImpBLItem'     ,   
                               @TempTableName         = '#TEMP_TUIImpBLItem',   
                               @TempSeqColumnName     = 'BLSeq'             ,   
                               @TempSerlColumnName    = 'BLSerl'            ,   
                               @TempSubSerlColumnName = ''
    
    -- 진행 SUM 값 데이터 테이블 CREATE & INSERT
    CREATE TABLE #BL_Prog (  
        IDX_NO    INT			,  
        DelvQty   DECIMAL(19, 5))

    INSERT INTO #BL_Prog(IDX_NO, DelvQty)
    SELECT A.IDX_NO, SUM(CASE WHEN IDOrder = 1 THEN A.Qty ELSE 0 END) AS 'DelvQty'
      FROM #TCOMProgressTracking AS A
     GROUP BY A.IDX_NO

    -- 미 입고수량 SELECT
    SELECT A.CompanySeq, A.BLSeq, A.BLSerl, B.DelvQty
      INTO #TEMP_DelvQty
      FROM #TEMP_TUIImpBLItem AS A
           JOIN #BL_Prog      AS B ON A.IDX_NO = B.IDX_NO

    /*******************************************************************/

    -------------------------------------------        
    -- 원천진행 조회   20091202 박소연 추가
    -------------------------------------------     
    CREATE TABLE #TempResult  
    (  
        InOutSeq  INT,  -- 진행내부번호  
        InOutSerl  INT,  -- 진행순번  
        InOutSubSerl    INT,  
        SourceRefNo     NVARCHAR(30),  
        SourceNo        NVARCHAR(30)  
    )  
  
    IF ISNULL(@SourceTableSeq, 0) <> 0  
    BEGIN  
        CREATE TABLE #TMP_SOURCETABLE        
        (        
            IDOrder INT IDENTITY,        
            TABLENAME   NVARCHAR(100)        
        )        
          
        CREATE TABLE #TCOMSourceTracking        
        (         
            IDX_NO      INT,        
            IDOrder     INT,        
            Seq         INT,        
            Serl        INT,        
            SubSerl     INT,        
            Qty         DECIMAL(19, 5),        
            STDQty      DECIMAL(19, 5),        
            Amt         DECIMAL(19, 5),        
            VAT         DECIMAL(19, 5)        
        )        
          
        CREATE TABLE #TMP_SOURCEITEM  
        (        
            IDX_NO        INT IDENTITY,        
            SourceSeq     INT,        
            SourceSerl    INT,        
            SourceSubSerl INT  
        )           
  
  
        IF ISNULL(@TableName, '') <> ''  
        BEGIN  
            SELECT @TableSeq = ProgTableSeq      
              FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블      
             WHERE ProgTableName = @TableName    
        END  
  
        IF ISNULL(@TableSeq,0) = 0  
        BEGIN  
            SELECT @TableSeq = ISNULL(ProgTableSeq, 0)  
              FROM _TCAPgmDev  
             WHERE PgmSeq = @PgmSeq  
  
            SELECT @TableName = ISNULL(ProgTableName, '')  
              FROM _TCOMProgTable  
             WHERE ProgTableSeq = @TableSeq  
        END  
  
        INSERT INTO #TMP_SOURCETABLE(TABLENAME)      
        SELECT ISNULL(ProgTableName,'')  
          FROM _TCOMProgTable  
         WHERE ProgTableSeq = @SourceTableSeq  
  
        -- 주의  
        INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(진행), 2(미진행)      
        SELECT  A.BLSeq, A.BLSerl, 0      
          FROM #TEMPTUIImpBLProg     AS A WITH(NOLOCK)           
  

        EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''        
 
-- 수정시작
        SELECT @SQL = 'INSERT INTO #TempResult '
        SELECT @SQL = @SQL + 'SELECT C.SourceSeq, C.SourceSerl, C.SourceSubSerl, ' +
                             CASE WHEN ISNULL(A.ProgMasterTableName,'') = '' THEN ''''' AS InOutRefNo, '''' AS InOutNo ' 
                                                                             ELSE (CASE WHEN ISNULL(A.ProgTableRefNoColumn,'') = '' THEN ''''' AS InOutNo, ' ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableRefNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutNo, ' END) +
                                                                                  (CASE WHEN ISNULL(A.ProgTableNoColumn,'') = '' THEN ''''' AS InOutRefNo ' ELSE (CASE WHEN ISNULL(A.ProgMasterSubTableName,'') = '' THEN 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo '                                                                                                                                                                                                                          
                                                                                                                                                                                                                   ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterSubTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo  ' END) END) END + 
                            ' FROM #TCOMSourceTracking AS A  ' +
                            ' JOIN #TMP_SOURCETABLE AS B ON A.IDOrder = B.IDOrder ' +
                            ' JOIN #TMP_SOURCEITEM AS  C ON A.IDX_NO  = C.IDX_NO ' +
                            ' JOIN _TCOMProgTable AS D WITH(NOLOCK) ON B.TableName = D.ProgTableName  '
          FROM _TCOMProgTable AS A WITH(NOLOCK) 
         WHERE A.ProgTableSeq = @SourceTableSeq
-- 수정종료
        EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq  
  
        SELECT @SQL = ''
    END
/************************************************************************************************************************************************************************/

/**********************************************************
    최종조회데이터                                         
**********************************************************/
    SELECT A.BizUnit           AS BizUnit,          --사업부문코드
           A.SMImpKind         AS SMImpKind,        --수입구분코드
           A.BLNo              AS BLNo,             --BL번호
           A.BLDate            AS BLDate,           --BL일자
           A.BLRefNo           AS BLRefNo,          --BL관리번호
           A.DeptSeq           AS DeptSeq,          --부서코드
           A.EmpSeq            AS EmpSeq,           --사원코드
           A.CustSeq           AS CustSeq,          --거래처코드
           A.CurrSeq           AS CurrSeq,          --통화코드
           A.ExRate            AS ExRate,           --환율
           A.UMPriceTerms      AS UMPriceTerms,     --가격조건코드
           A.UMPayment1        AS UMPayment1,       --결제방법코드
           A.UMPayment2        AS UMPayment2,       --결제시기코드
           B.BLSeq             AS BLSeq,
           B.BLSerl            AS BLSerl,
           B.ItemSeq           AS ItemSeq,          --품목코드
           B.UnitSeq           AS UnitSeq,          --단위코드
           B.Price             AS Price,            --가격
           B.Qty               AS Qty,              --수량
           B.CurAmt            AS CurAmt,           --금액
           B.DomAmt            AS DomAmt,           --원화금액
           B.ShipDate          AS ShipDate,         --선적예정일
           B.STDUnitSeq        AS STDUnitSeq,       --기준단위코드
           B.STDQty            AS STDQty,           --기준단위수량

           (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit   = BizUnit)       AS BizUnitName,         --사업부문
           (SELECT MinorName   FROM _TDASMinor  WHERE CompanySeq = @CompanySeq AND A.SMImpKind = MinorSeq)      AS SMImpTypeName,       --수입구분
           (SELECT DeptName    FROM _TDADept    WHERE CompanySeq = @CompanySeq AND A.DeptSeq   = DeptSeq)       AS DeptName,            --부서
           (SELECT EmpName     FROM _TDAEmp     WHERE CompanySeq = @CompanySeq AND A.EmpSeq    = EmpSeq)        AS EmpName,             --사원
           (SELECT CustName    FROM _TDACust    WHERE CompanySeq = @CompanySeq AND A.CustSeq   = CustSeq)       AS CustName,            --거래처  
           (SELECT CurrName    FROM _TDACurr    WHERE CompanySeq = @CompanySeq AND A.CurrSeq   = CurrSeq)       AS CurrName,            --통화
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPriceTerms = MinorSeq)   AS UMPriceTermsName,    --가격조건
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPayment1 = MinorSeq)     AS UMPayment1Name,      --결제방법
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPayment2 = MinorSeq)     AS UMPayment2Name,      --결제시기
           L.ItemNo            AS ItemNo,              --품목번호
           L.ItemName          AS ItemName,            --품목명
           L.Spec              AS Spec,                --규격
           (SELECT UnitName    FROM _TDAUnit  WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)           AS UnitName,            --단위
           (SELECT UnitName    FROM _TDAUnit  WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq)        AS STDUnitName,         --기준단위
           Y.PJTName           AS PJTName,             --프로젝트명
           Y.PJTNo             AS PJTNo,               -- 프로젝트번호
           Y.PJTSeq            AS PJTSeq,              -- 프로젝트코드
           A.IsPJT             AS IsPJT,
           (SELECT MinorName   FROM _TDASMinor  WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) AS SMProgressTypeName,  -- 진행상태           
           B.Remark            AS Remark,              -- 비고
           B.LotNo             AS LotNo,               -- LotNo
           ISNULL(AW.SourceNo,'')     AS SourceNo,         -- 추가 20091201 박소연 
           ISNULL(AW.SourceRefNo, '') AS SourceRefNo,   -- 추가 20091201 박소연
           M2.ItemNo            AS UpperUnitNo,   
           M2.ItemName          AS UpperUnitName,     
           M4.ItemName          AS TopUnitName,   
           M4.ItemNo            AS TopUnitNo,
           M5.UMMatQuality      AS UMMatQuality,
           M6.MinorName         AS UMMatQualityName,
           (B.Qty - ISNULL(DQ.DelvQty, 0)) AS NotDelvQty, -- 20130625 박성호 추가
           A.PrePaymentDate -- 기타정보 결제예정일

      FROM #TEMP_TUIImpBLItem   AS BL 
            JOIN _TUIImpBL      AS A WITH(NOLOCK) ON BL.CompanySeq = A.CompanySeq 
                                                 AND BL.BLSeq      = A.BLSeq
            JOIN _TUIImpBLItem  AS B WITH(NOLOCK) ON BL.CompanySeq = B.CompanySeq 
                                                 AND BL.BLSeq      = B.BLSeq
                                                 AND BL.BLSerl     = B.BLSerl
            JOIN #TEMPTUIImpBLProg AS Z WITH(NOLOCK) ON BL.BLSeq   = Z.BLSeq
                                                    AND BL.BLSerl  = Z.BLSerl
            LEFT OUTER JOIN _TDAItem       AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq 
                                                            AND B.ItemSeq    = L.ItemSeq
            LEFT OUTER JOIN _TPJTProject   AS Y WITH(NOLOCK) ON A.CompanySeq = Y.CompanySeq 
                                                            AND B.PJTSeq     = Y.PJTSeq
            LEFT OUTER JOIN #TempResult AS AW WITH(NOLOCK) ON A.CompanySeq = @CompanySeq  -- 추가 20091202 박소연 
                                                          AND B.BLSeq = AW.InOutSeq     -- 추가 20091202 박소연 
                                                          AND B.BLSerl = AW.InOutSerl   -- 추가 20091202 박소연
           LEFT OUTER JOIN _TPJTBOM       AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySEq    
                                                           AND B.PJTSeq = M5.PJTSeq    
                                                           AND B.WBSSeq = M5.BOMSerl    
           LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON B.CompanySeq = M1.CompanySeq    
                                                           AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M5.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM    
           LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON B.CompanySEq = M2.CompanySeq    
                                                           AND M1.ItemSeq = M2.ItemSeq    
           LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON B.CompanySeq = M3.CompanySeq    
                                                           AND B.PJTSeq = M3.PJTSeq    
                                                           AND M3.BOMSerl <> -1    
                                                           AND ISNULL(M3.BeforeBOMSerl,0) = 0    
                                                           AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위    
                                                           AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1 
           LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON B.CompanySeq = M4.CompanySeq    
                                                           AND M3.ItemSeq = M4.ItemSeq   
           LEFT OUTER JOIN _TDAUMinor     AS M6 WITH(NOLOCK) ON B.CompanySeq = M6.CompanySeq
                                                            AND M5.UMMatQuality = M6.MinorSeq
           LEFT OUTER JOIN #TEMP_DelvQty  AS DQ WITH(NOLOCK) ON B.CompanySeq = DQ.CompanySeq
                                                            AND B.BLSeq      = DQ.BLSeq
                                                            AND B.BLSerl     = DQ.BLSerl

    WHERE --(@SMProgressType = 0 OR Z.SMProgressType = @SMProgressType) 
	      (@SMProgressType = 0 OR (Z.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND Z.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )           
      AND (@SourceNo = '' OR AW.SourceNo LIKE @SourceNo + '%')           -- 추가 20091202 박소연
      AND (@SourceRefNo = '' OR AW.SourceRefNo LIKE @SourceRefNo + '%')  -- 추가 20091202 박소연
      AND (@UMSupplyType = 0  OR M5.UMSupplyType = @UMSupplyType)    
      AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')         
      AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%') 
 ORDER BY A.BLDate, A.BLNo, B.BLSerl


RETURN
GO


