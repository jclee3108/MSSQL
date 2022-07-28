
IF OBJECT_ID('_SACLendListSubQuery') IS NOT NULL 
    DROP PROC _SACLendListSubQuery
GO 

-- v2014.02.07 

-- 대여금현황(SS2조회) by이재천
CREATE PROC dbo._SACLendListSubQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
	DECLARE @docHandle  INT,
		    @LendSeq    INT,  
		    @PivotDate  NCHAR(8)
    
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
	SELECT @LendSeq   = ISNULL(LendSeq,0), 
	       @PivotDate = ISNULL(PivotDate,'')
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (LendSeq     INT, 
	        PivotDate   NCHAR(8) )
    
    -- Title 
    CREATE TABLE #Title 
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(50), 
        TitleSeq    INT 
        
    )
    INSERT INTO #Title(Title, TitleSeq)
    SELECT ISNULL(C.WordSite, ISNULL(C.Word, B.RemName )), -- 관리항목  
           A.RemSeq -- 관리항목코드  
      FROM _TDAAccountSub AS A  
      JOIN _TDAAccountRem AS B ON ( B.CompanySeq = A.CompanySeq AND B.RemSeq = A.RemSeq )  
      LEFT OUTER JOIN _TCADictionary AS C ON ( C.LanguageSeq = @LanguageSeq AND B.WordSeq = C.WordSeq )  
     WHERE A.CompanySeq = @CompanySeq 
      AND A.AccSeq = (SELECT AccSeq FROM _TACLend WHERE CompanySeq = @CompanySeq AND LendSeq = @LendSeq) 
    ORDER BY A.Sort

    SELECT * FROM #Title 
    
    -- 고정부 
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0,1), 
        LendSeq     INT, 
        LendNo      NVARCHAR(50), 
        PayDate     NCHAR(8), 
        AccName     NVARCHAR(100), 
        AccSeq      INT, 
        Amt         DECIMAL(19,5), 
        SlipNo      NVARCHAR(100), 
        Remark      NVARCHAR(1000), 
        SlipSeq     INT 
    )
    INSERT INTO #FixCol (LendSeq, LendNo, PayDate, AccName, AccSeq, Amt, SlipNo, Remark, SlipSeq) 
    SELECT A.LendSeq, A.LendNo, C.AccDate, E.AccName, A.AccSeq, C.CrAmt, C.SlipID, C.Summary, C.SlipSeq 
      FROM _TACLend AS A  
      LEFT OUTER JOIN _TACSlipRem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.RemSeq = 2059 AND B.RemValSeq = A.LendSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
      LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACSlip    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.SlipMstSeq = C.SlipMstSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LendSeq = @LendSeq
       AND C.SMDrOrCr = -1 
       AND C.AccDate <= @PivotDate 
       AND F.IsSet = '1' 
           
    SELECT * FROM #FixCol 
    
    -- 가변부 
    
    -- 관리항목값가져오기
    CREATE TABLE #tmp_SlipRemValue              
    (   
        LendSeq    INT, 
        AccSeq     INT, 
        SlipSeq    INT,   
        RemSeq     INT,   
        Seq        INT,   
        RemValText NVARCHAR(100),   
        CellType   NVARCHAR(50),   
        IsDrEss    NCHAR(1),   
        IsCrEss    NCHAR(1),   
        Sort       INT--,  
        --CustNo     NVARCHAR(200)   
    )   
      
    INSERT INTO #tmp_SlipRemValue   
    (   
        LendSeq, AccSeq, SlipSeq, RemSeq, Seq, 
        RemValText, CellType, IsDrEss, IsCrEss, Sort
    )   
    
    SELECT A.LendSeq, 
           A.AccSeq, 
           B.SlipSeq, 
           D.RemSeq, 
           D.RemValSeq, 
           D.RemValText, 
           CASE F.SMInputType WHEN 4016001 THEN 'enText'              
                              WHEN 4016002 THEN 'enCodeHelp'              
                              WHEN 4016003 THEN 'enFloat'              
                              WHEN 4016004 THEN 'enFloat'              
                              WHEN 4016005 THEN 'enDate'              
                              WHEN 4016006 THEN 'enText'              
                              WHEN 4016007 THEN 'enFloat'              
                              ELSE 'enText'              
                              END AS CellType,       -- 입력형태 
           E.IsDrEss,              
           E.IsCrEss,              
           E.Sort--,
      FROM _TACLend AS A  
      LEFT OUTER JOIN _TACSlipRem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.RemSeq = 2059 AND B.RemValSeq = A.LendSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
                 JOIN _TACSlipRem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = C.SlipSeq )  
                 JOIN _TDAAccountSub AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = A.AccSeq AND E.RemSeq = D.RemSeq ) 
                 JOIN _TDAAccountRem AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.RemSeq = D.RemSeq ) 
      LEFT OUTER JOIN _TACSlip       AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.SlipMstSeq = C.SlipMstSeq ) 
     WHERE A.LendSeq = @LendSeq 
       AND C.SMDrOrCr = -1 
       AND C.AccDate <= @PivotDate  
       AND G.IsSet = '1'
    
    EXEC _SUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue' 
    
    --select * from #tmp_SlipRemValue
    -- 관리항목값을 가져오기, END 
    
    
    CREATE TABLE #Value
    (
        RemSeq      INT, 
        SlipSeq     INT, 
        Results     NVARCHAR(100), 
    )
    INSERT INTO #Value (RemSeq, SlipSeq, Results) 
    SELECT RemSeq, SlipSeq, RemValue
      FROM #tmp_SlipRemValue
    
    SELECT B.RowIdx, A.ColIdx, C.Results
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.RemSeq ) 
      JOIN #FixCol AS B ON ( B.SlipSeq = C.SlipSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN
GO
exec _SACLendListSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <LendSeq>46</LendSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9674,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11497