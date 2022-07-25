drop proc test_SACLedgerQueryRemBalance
go
/************************************************************  
��  �� - �����׸� ������ �ܾ� ��Ȳ ��ȸ  
�ۼ��� - 2008�� 12�� 01��  
�ۼ��� - ������  
************************************************************/  
CREATE PROC dbo.test_SACLedgerQueryRemBalance  
  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10) = '',  
    @CompanySeq     INT = 0,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHandle      INT,  
            @AccUnit        INT,  
            @AccDate        NCHAR(8),  
            @AccDateTo      NCHAR(8),  
            @RemValSeq      INT, 
            @AccSeqFr       INT,
            @AccSeqTo       INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @AccUnit        = ISNULL(AccUnit            ,  0),  
            @AccDate        = ISNULL(AccDate            , ''),  
            @AccDateTo      = ISNULL(AccDateTo          , ''),  
            @RemValSeq      = ISNULL(RemValSeq          ,  0), 
            @AccSeqFr       = ISNULL(AccSeqFr           ,  0), 
            @AccSeqTo       = ISNULL(AccSeqTo           ,  0) 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  AccUnit         INT,  
            AccDate         NVARCHAR(8),  
            AccDateTo       NVARCHAR(8),  
            RemValSeq       INT, 
            AccSeqFr        INT,
            AccSeqTo        INT 
         )
    DECLARE @FormatSeq      INT,  
            @FrFSItemSort   INT,  
            @ToFSItemSort   INT  
            
    --=================================================  
    -- ����������  
    --=================================================  
    CREATE TABLE #AccSeqList (  
        AccSeq          INT)  
  
  
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
  
  
    -- ��ü��ȸ��  
    SELECT @FrFSItemSort = MIN(FSItemSort)      
      FROM _TCOMFSFormTree WITH (NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND FormatSeq = @FormatSeq   

  
    -- ��ü��ȸ��  
    SELECT @ToFSItemSort = MAX(FSItemSort)      
      FROM _TCOMFSFormTree WITH (NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND FormatSeq = @FormatSeq     
    
    -- FROM����������Tree ����(������MIN)    
    SELECT @FrFSItemSort = ISNULL(FSItemSort, 0)     
      FROM _TCOMFSFormTree WITH (NOLOCK)    
     WHERE CompanySeq = @CompanySeq    
       AND FormatSeq = @FormatSeq    
       AND FSItemSeq = @AccSeqFr    
    
    IF @@ROWCOUNT = 0 OR ISNULL(@FrFSItemSort, 0) = 0     
    BEGIN    
        SELECT @FrFSItemSort = MIN(FSItemSort)    
          FROM _TCOMFSFormTree WITH (NOLOCK)    
         WHERE CompanySeq = @CompanySeq    
           AND FormatSeq = @FormatSeq    
    END 
    -- TO����������Tree ����(������MAX)    
    SELECT @ToFSItemSort = ISNULL(FSItemSort, 0)     
      FROM _TCOMFSFormTree WITH (NOLOCK)    
     WHERE CompanySeq       = @CompanySeq    
       AND FormatSeq        = @FormatSeq    
       AND FSItemSeq        = @AccSeqTo    
    IF @@ROWCOUNT = 0 OR ISNULL(@ToFSItemSort, 0) = 0     
    BEGIN    
        SELECT @ToFSItemSort = MAX(FSItemSort)    
          FROM _TCOMFSFormTree WITH (NOLOCK)    
         WHERE CompanySeq = @CompanySeq    
           AND FormatSeq = @FormatSeq    
    END    
    
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
        @SMAccStd               = 1         , -- ȸ����ر���    
        @QueryKind              = 'REM'             , -- ACC:����, REM:�����׸�, 2REM:2���������׸�    
        @IsCurr                 = '0'               , -- 1 : ��ȭ    
        @AccUnit                = @AccUnit          , -- ȸ�����    
        @SlipUnit               = 0                 , -- ��ǥ��������    
        @AccDateFr              = @AccDate          , -- ȸ����(From)    
        @AccDateTo              = @AccDateTo        , -- ȸ����(To)    
        @UMCostType             = 0                 , -- ��뱸��    
        @CurrSeq                = 0                 , -- ��ȭ    
        @RemSeq1                = 1021              , -- �����׸�1    
        @RemSeq2                = 0                 , -- �����׸�2    
        @RemValSeq1             = @RemValSeq        , -- �����׸�1    
        @RemValSeq2             = 0                   -- �����׸�2    
        
        -- ��� 0�� ���� ����  
        -- �Ⱓ�� ���/���Ͱ����� �������� (+)(-)�ϴ� ��찡 ������, ��ȸ�� ���� �ʾ� Jump�� �� �� ���ٴ� �Ƿڰ� �־���  
        -- BS���� �߿����� �̿�,��/��,�ܾ��� ��� 0�� �͸� ��ȸ���� �ʱ�� ��  
        DELETE #SlipSum  
          FROM #SlipSum AS A JOIN _TDAAccount AS B  
                               ON B.CompanySeq  = @CompanySeq  
                              AND A.AccSeq      = B.AccSeq  
         WHERE A.IniAmt = 0 AND A.DrAmt = 0 AND A.CrAmt = 0 AND A.RemAmt = 0  
           AND B.SMAccKind IN (4018001, 4018002, 4018003)  
        
        SELECT A.AccSeq                     AS AccSeq           ,  
               ISNULL(acc.AccNo     , '')   AS AccNo            ,  
               CASE WHEN A.UMCostType = 0 THEN A.AccName  
                    ELSE A.AccName + '(' + A.UMCostTypeName + ')'  
                    END                          AS AccName          ,  
               ISNULL(A.RemVal1Name , '')   AS RemValName1      ,  
               ISNULL(A.RemValSeq1  ,  0)   AS RemValSeq        ,  
               ISNULL(A.IniAmt      ,  0)   AS ForwardDrAmt     ,  
               ISNULL(A.DrAmt       ,  0)   AS DrAmt            ,  
               ISNULL(A.CrAmt       ,  0)   AS CrAmt            ,  
               ISNULL(A.RemAmt      ,  0)   AS RemainAmt          
          FROM #SlipSum AS A JOIN _TDAAccountSub AS accsub WITH (NOLOCK)  
                                   ON accsub.CompanySeq = @CompanySeq  
                                  AND A.AccSeq          = accsub.AccSeq  
                                  --AND accsub.RemSeq     = 1021
                                 LEFT OUTER JOIN _TDAAccount AS acc WITH (NOLOCK)  
                                   ON acc.CompanySeq    = @CompanySeq  
                                  AND A.AccSeq          = acc.AccSeq                         
        --      WHERE A.IniAmt <> 0 OR A.DrAmt <> 0 OR A.CrAmt <> 0 OR A.RemAmt <> 0  
            ORDER BY acc.AccNo, A.RemVal1Name  
    
    RETURN  
  
GO
exec test_SACLedgerQueryRemBalance @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMAccStd>1</SMAccStd>
    <FSDomainSeq />
    <AccUnit />
    <AccDate>20070101</AccDate>
    <AccDateTo>20131231</AccDateTo>
    <SlipUnit />
    <RemSeq>1021</RemSeq>
    <RemValSeq />
    <UMCostType />
    <AccSeqFr />
    <AccSeqTo />
    <CheckRemGroup>0</CheckRemGroup>
    <LinkCreateID />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1291,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=300193