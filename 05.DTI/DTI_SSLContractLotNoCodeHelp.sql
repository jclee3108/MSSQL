
IF OBJECT_ID('DTI_SSLContractLotNoCodeHelp') IS NOT NULL 
    DROP PROC DTI_SSLContractLotNoCodeHelp
GO

-- v2013.01.23 
    
-- 계약등록LotNo코드도움_DTI By이재천    
  CREATE PROC DTI_SSLContractLotNoCodeHelp        
      @WorkingTag     NVARCHAR(1)      ,    -- WorkingTag            
      @LanguageSeq    INT              ,    -- 언어            
      @CodeHelpSeq    INT              ,    -- 코드도움(코드)            
      @DefQueryOption INT              ,    -- 2: direct search            
      @CodeHelpType   TINYINT          ,            
      @PageCount      INT = 20         ,            
      @CompanySeq     INT = 1          ,            
      @Keyword        NVARCHAR(50) = '',            
      @Param1         NVARCHAR(50) = '',            
      @Param2         NVARCHAR(50) = '',            
      @Param3         NVARCHAR(50) = '',            
      @Param4         NVARCHAR(50) = '',            
      @PageSize       INT = 50            
   AS            
    
    DECLARE @WHSeq   INT, @StdDate NCHAR(8)        
    SELECT @StdDate = CONVERT(NCHAR(6), GetDATE(), 112) + '31'   
    
    IF @Param2 = '' OR @Param2 = '0'   
        SELECT @WHSeq = 0   
    ELSE  
        SELECT @WHSeq = @Param2
    
    CREATE TABLE #GetInOutLot            
    (              
        LotNo      NVARCHAR(30),            
        ItemSeq    INT              
    )    
    CREATE TABLE #GetInOutLotStock              
    (              
        WHSeq           INT,              
        FunctionWHSeq   INT,              
        LotNo           NVARCHAR(30),            
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
   
    INSERT INTO #GetInOutLot              
    SELECT DISTINCT LotNo, ItemSeq        
      FROM _TLGLotMaster WITH(NOLOCK)        
     WHERE CompanySeq = @CompanySeq        
       AND LotNo LIKE @Keyword + '%'        
       AND ItemSeq = @Param1 
    
    -- 창고재고 가져오기              
    EXEC _SLGGetInOutLotStock   @CompanySeq   = @CompanySeq,   -- 법인코드              
                                @BizUnit      = 0,      -- 사업부문              
                                @FactUnit     = 0,     -- 생산사업장              
                                @DateFr       = @StdDate,       -- 조회기간Fr              
                                @DateTo       = @StdDate,       -- 조회기간To              
                                @WHSeq        = @WHSeq,        -- 창고지정              
                                @SMWHKind     = 0,     -- 창고구분별 조회              
                                @CustSeq      = 0,      -- 수탁거래처              
                                @IsTrustCust  = '0',  -- 수탁여부              
                                @IsSubDisplay = '0', -- 기능창고 조회              
                                @IsUnitQry    = '0',    -- 단위별 조회              
                                @QryType      = 'S'       -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고             
    
    SET ROWCOUNT @PageCount      
    
    SELECT A.LotNo        AS LotNo,        
           B.ItemName     AS ItemName,        
           B.ItemNo       AS ItemNo,        
           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq), '') AS UnitName,        
           A.CreateDate   AS CreateDate,        
           A.CreateTime   AS CreateTime,        
           A.SourceLotNo  AS SourceLotNo,        
           A.OriLotNo     AS OriLotNo,        
           A.ValiDate,        
           A.ValidTime,        
           A.RegDate,        
           ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = X.WHSeq), '') AS WHName,        
           ISNULL(X.StockQty,0) AS StockQty,        
           C.LotSeq AS LotSeq,        
           A.Remark AS Remark,      
           CASE WHEN ISNULL(D.DomPrice, 0) <> 0 THEN D.DomPrice     
           ELSE    
           CASE WHEN ISNULL(F.Qty,0) = 0 THEN 0 ELSE  ISNULL(F.DomAmt, 0)/F.Qty End    
           END AS UnitPrice,    
           CASE WHEN ISNULL(E.CustSeq, '') <> '' THEN    
           ISNULL((SELECT CustName FROM _TDACust WHERE CustSeq = E.CustSeq And CompanySeq = @CompanySeq), '')    
           ELSE    
           ISNULL((SELECT CustName FROM _TDACust WHERE CustSeq = G.CustSeq And CompanySeq = @CompanySeq),'')    
           END AS PurchCustName,    
           X.WHSeq      
      FROM _TLGLotMaster AS A WITH (NOLOCK)        
      JOIN DTI_TLGLotEmp LE ON LE.CompanySeq = @CompanySeq AND A.ItemSeq = LE.ItemSeq AND A.LotNo = LE.LotNo AND LE.EmpSeq = @Param3 
      JOIN (SELECT LotNo, ItemSeq, WHSeq, SUM(ISNULL(STDStockQty,0)) AS StockQty        
              FROM #GetInOutLotStock        
             GROUP BY LotNo, ItemSeq, WHSeq) AS X ON A.CompanySeq = @CompanySeq        
                                                 AND X.LotNo      = A.LotNo        
                                                 AND X.ItemSeq    = A.ItemSeq        
                                                 AND (@Param2 = '' OR @Param2 = '0'   
                                                      OR X.WHSeq  = @Param2  
                                                     )        
      LEFT OUTER JOIN _TDAItem          AS B WITH (NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq )   
      LEFT OUTER JOIN _TLGLotSeq        AS C WITH (NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.ItemSeq = C.ItemSeq AND A.LotNo = C.LotNo )   
      LEFT OUTER JOIN _TPUDelvItem      AS D WITH (NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.ItemSeq = D.ItemSeq AND A.LotNo = D.LOTNo AND ISNull(D.IsReturn, '') <> '1' )-- 반품 제외    
      LEFT OUTER JOIN _TPUDelv          AS E WITH (NOLOCK) ON ( D.CompanySeq = E.CompanySeq AND D.DelvSeq = E.DelvSeq )   
      LEFT OUTER JOIN _TUIImpDelvItem   AS F WITH (NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.ItemSeq = F.ItemSeq AND A.LotNo = F.LOTNo )   
      LEFT OUTER JOIN _TUIImpDelv       AS G WITH (NOLOCK) ON ( F.CompanySeq = G.CompanySeq AND F.DelvSeq = G.DelvSeq )   
     WHERE A.CompanySeq = @CompanySeq        
       AND A.LotNo LIKE @Keyword + '%'        
       AND (@Param1 = '' OR @Param1 = '0' OR A.ItemSeq  = @Param1)        
     ORDER BY A.LotNo 
    
    SET ROWCOUNT 0        
    
    RETURN  
GO
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1001846',@Keyword=N'%%',@Param1=N'27375',@Param2=N'1222',@Param3=N'2028',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=147,@WkDeptSeq=59,@EmpSeq=2028,@UserSeq=50322