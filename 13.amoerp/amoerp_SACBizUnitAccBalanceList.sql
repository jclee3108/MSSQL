
IF OBJECT_ID('amoerp_SACBizUnitAccBalanceList') IS NOT NULL 
    DROP PROC amoerp_SACBizUnitAccBalanceList
GO 

-- v2013.12.31 

-- ����κ� ������ �ܾ� ��ȸ_amoerp(��ȸ) by����õ
CREATE PROC amoerp_SACBizUnitAccBalanceList
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
            @AccUnit        INT,  
            @AccDate        NCHAR(8),  
            @AccDateTo      NCHAR(8),  
            @RemValue       INT, 
            @AccSeqFr       INT,
            @AccSeqTo       INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @AccUnit        = ISNULL(AccUnit            ,  0),  
            @AccDate        = ISNULL(AccDate            , ''),  
            @AccDateTo      = ISNULL(AccDateTo          , ''),  
            @RemValue       = ISNULL(RemValue           ,  0), 
            @AccSeqFr       = ISNULL(AccSeqFr           ,  0), 
            @AccSeqTo       = ISNULL(AccSeqTo           ,  0) 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  AccUnit         INT,  
            AccDate         NVARCHAR(8),  
            AccDateTo       NVARCHAR(8),  
            RemValue        INT, 
            AccSeqFr        INT,
            AccSeqTo        INT 
         )
    DECLARE @FormatSeq      INT,  
            @FrFSItemSort   INT,  
            @ToFSItemSort   INT 
    
    -- ����� --------------------------------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(100), 
        TItleSeq    INT 
    )
    
    INSERT INTO #Title (Title, TitleSeq) 
    SELECT A.RemValueName, A.RemValueSerl
      FROM _TDAAccountRemValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @RemValue = 0 OR A.RemValueSerl = @RemValue )
       AND A.RemSeq = 9037 
       
     ORDER BY A.RemValueSerl 
     
    SELECT * FROM #Title 
    
    -- ����� END ----------------------------------------------------------------------------
    
    -- ������ --------------------------------------------------------------------------------
    CREATE TABLE #FixCol
    (
     RowIdx     INT IDENTITY(0, 1), 
     AccSeq     INT, 
     AccNo      NVARCHAR(100), 
     AccName    NVARCHAR(100) 
    )
    
    --=================================================  
    -- ����������  
    --=================================================  
    CREATE TABLE #AccSeqList (AccSeq INT)  
    
    SELECT @FormatSeq       = a.FormatSeq    
      FROM _TCOMFSForm AS a JOIN _TCOMFSKind AS b    
                              ON a.CompanySeq   = b.CompanySeq    
                             AND a.FSKindSeq    = b.FSKindSeq    
                            JOIN _TCOMFSDomain AS C    
                                ON a.CompanySeq   = c.CompanySeq    
                             AND a.FSDomainSeq  = c.FSDomainSeq    
     WHERE a.CompanySeq     = @CompanySeq    
       AND c.FSDomainNo     = 'GAAPFS' 
       AND b.FSKindNo       = 'TB'    
       AND a.IsDefault = '1'    
       AND LEFT(@AccDateTo, 6) BETWEEN a.FrYM AND a.ToYM  
    
    SELECT @FrFSItemSort = MIN(FSItemSort)      
      FROM _TCOMFSFormTree WITH (NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND FormatSeq = @FormatSeq   
    
    SELECT @ToFSItemSort = MAX(FSItemSort)      
      FROM _TCOMFSFormTree WITH (NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND FormatSeq = @FormatSeq        
    
    INSERT INTO #AccSeqList (AccSeq)  
    SELECT a.FSItemSeq  
      FROM _TCOMFSFormTree AS a WITH (NOLOCK) 
      JOIN _TDAAccount AS acc WITH (NOLOCK) ON a.CompanySeq  = acc.CompanySeq AND a.FSItemSeq   = acc.AccSeq  
     WHERE a.CompanySeq   = @CompanySeq   
       AND a.FormatSeq    = @FormatSeq  
       AND a.FSItemSort  >= @FrFSItemSort   
       AND a.FSItemSort  <= @ToFSItemSort  
       AND acc.IsSlip     = '1'  

    CREATE TABLE #SlipSum (    
        AccSeq          INT,    
        AccName         NVARCHAR(100),    
        UMCostType      INT,    
        UMCostTypeName  NVARCHAR(100),    
        RemSeq1         INT,    
        Rem1Name        NVARCHAR(100),    
        RemSeq2         INT,    
        Rem2Name        NVARCHAR(100),    
        RemValSeq1      INT,    
        RemVal1Name     NVARCHAR(100),    
        RemRefValue1    NVARCHAR(100),    
        RemValSeq2      INT,    
        RemVal2Name     NVARCHAR(100),    
        RemRefValue2    NVARCHAR(100),    
        CurrSeq         INT,    
        CurrName        NVARCHAR(100),    
        IniForAmt       DECIMAL(19,5),    
        DrForAmt        DECIMAL(19,5),    
        CrForAmt        DECIMAL(19,5),    
        RemForAmt       DECIMAL(19,5),    
        IniAmt          DECIMAL(19,5),    
        DrAmt           DECIMAL(19,5),    
        CrAmt           DECIMAL(19,5),    
        RemAmt          DECIMAL(19,5))    
    
    EXEC _SCOMSlipSumQuery1    
        @WorkingTag             = @WorkingTag       , -- ����� ������    
        @CompanySeq             = @CompanySeq       , -- �����ڵ�    
        @LanguageSeq            = @LanguageSeq      , -- ���    
        @UserSeq                = @UserSeq          , -- �����    
        @SMAccStd               = 1                 , -- ȸ����ر���    
        @QueryKind              = 'REM'             , -- ACC:����, REM:�����׸�, 2REM:2���������׸�    
        @IsCurr                 = '0'               , -- 1 : ��ȭ    
        @AccUnit                = @AccUnit          , -- ȸ�����    
        @SlipUnit               = 0                 , -- ��ǥ��������    
        @AccDateFr              = @AccDate          , -- ȸ����(From)    
        @AccDateTo              = @AccDateTo        , -- ȸ����(To)    
        @UMCostType             = 0                 , -- ��뱸��    
        @CurrSeq                = 0                 , -- ��ȭ    
        @RemSeq1                = 9037              , -- �����׸�1    
        @RemSeq2                = 0                 , -- �����׸�2    
        @RemValSeq1             = @RemValue         , -- �����׸�1    
        @RemValSeq2             = 0                   -- �����׸�2    
        

    -- ��� 0�� ���� ����  
    -- �Ⱓ�� ���/���Ͱ����� �������� (+)(-)�ϴ� ��찡 ������, ��ȸ�� ���� �ʾ� Jump�� �� �� ���ٴ� �Ƿڰ� �־���  
    -- BS���� �߿����� �̿�,��/��,�ܾ��� ��� 0�� �͸� ��ȸ���� �ʱ�� ��  
    DELETE #SlipSum  
      FROM #SlipSum AS A 
      JOIN _TDAAccount AS B ON B.CompanySeq = @CompanySeq AND A.AccSeq = B.AccSeq  
     WHERE A.IniAmt = 0 AND A.DrAmt = 0 AND A.CrAmt = 0 AND A.RemAmt = 0  
       AND B.SMAccKind IN (4018001, 4018002, 4018003) 

    INSERT INTO #FixCol ( AccSeq, AccNo, AccName ) 
    SELECT DISTINCT 
           A.AccSeq                     AS AccSeq           ,  
           ISNULL(C.AccNo     , '')     AS AccNo            ,  
           CASE WHEN A.UMCostType = 0 THEN A.AccName  
                ELSE A.AccName + '(' + A.UMCostTypeName + ')'  
                END                     AS AccName
      FROM #SlipSum               AS A 
      JOIN _TDAAccountSub         AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.AccSeq = B.AccSeq )   
      LEFT OUTER JOIN _TDAAccount AS C WITH (NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.AccSeq = C.AccSeq ) 
    
     ORDER BY AccSeq, AccNo, AccName
         
    SELECT * FROM #FixCol
        --    select * from #SlipSum 
        --return 
    -- ������ END ----------------------------------------------------------------------------

    -- ������ --------------------------------------------------------------------------------
    CREATE TABLE #Value
    (
     RemAmt     DECIMAL(19, 5), 
     RemValSeq  INT, 
     AccSeq     INT, 
     AccNo      NVARCHAR(100), 
     AccName    NVARCHAR(100) 
    )

    INSERT INTO #Value ( AccSeq, AccNo, AccName, RemValSeq, RemAmt ) 
    SELECT A.AccSeq ,  
           ISNULL(C.AccNo     , ''),  
           CASE WHEN A.UMCostType = 0 THEN A.AccName  
                ELSE A.AccName + '(' + A.UMCostTypeName + ')'  
                END AS AccName,           
           ISNULL(A.RemValSeq1, 0 ), 
           ISNULL(A.RemAmt, 0)   
      FROM #SlipSum               AS A 
      LEFT OUTER JOIN _TDAAccount AS C WITH (NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.AccSeq = C.AccSeq ) 
    
     ORDER BY A.AccSeq, ISNULL(C.AccNo,''), AccName
    --DECLARE @Cnt INT
    --SELECT @Cnt = -1
    
    --WHILE (1=1)
    --BEGIN
    --    IF NOT EXISTS (SELECT 1 FROM #FixCol WHERE AccSeq > @Cnt)
    --    BEGIN
    --        BREAK
    --    END
        
    --    SELECT TOP 1 @Cnt = AccSeq
    --      FROM #FixCol 
    --     WHERE AccSeq > @Cnt
    --     ORDER BY AccSeq
        
    --    IF EXISTS (SELECT 1 FROM #Value WHERE AccSeq = @Cnt)
    --    BEGIN
    --        INSERT INTO #Value ( AccSeq, AccNo, AccName, RemValSeq, RemAmt )
    --        SELECT AccSeq, AccNo, AccName, B.TItleSeq, 0 
    --          FROM #FixCol AS A
    --          JOIN #Title  AS B ON ( 1=1 )
    --         WHERE A.AccSeq = @Cnt  
    --           AND B.TitleSeq NOT IN ( SELECT RemValSeq FROM #Value WHERE AccSeq = @Cnt )
    --    END
    --    ELSE
    --    BEGIN
    --        INSERT INTO #Value ( AccSeq, AccNo, AccName, RemValSeq, RemAmt )
    --        SELECT AccSeq, AccNo, AccName, B.TItleSeq, 0 
    --          FROM #FixCol AS A
    --          JOIN #Title  AS B ON ( 1=1 )
    --         WHERE A.AccSeq = @Cnt  
    --    END
        
    --    SELECT @Cnt = @Cnt+1
    --END
    
    
    -- ������ END ----------------------------------------------------------------------------
    
    SELECT B.RowIdx, A.ColIdx, C.RemAmt AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.RemValSeq ) 
      JOIN #FixCol AS B ON ( B.AccSeq = C.AccSeq ) 
     ORDER BY  B.RowIdx,A.ColIdx
    
    RETURN
GO
exec amoerp_SACBizUnitAccBalanceList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RemValue />
    <AccUnit>1</AccUnit>
    <AccDate>20131201</AccDate>
    <AccDateTo>20131231</AccDateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020281,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1017055