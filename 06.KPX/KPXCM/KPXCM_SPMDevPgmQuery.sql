  
IF OBJECT_ID('KPXCM_SPMDevPgmQuery') IS NOT NULL   
    DROP PROC KPXCM_SPMDevPgmQuery  
GO  
  
-- v2015.09.17  
  
-- (관리)프로그램개발현황_KPXCM-조회 by 이재천   
CREATE PROC KPXCM_SPMDevPgmQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @DevOrder   NVARCHAR(200),
            @DevName    NVARCHAR(200), 
            @FrFinDate  NCHAR(8),  
            @FrPlanDate NCHAR(8), 
            @PgmClass   NVARCHAR(200), 
            @Module     NVARCHAR(200),
            @Consultant NVARCHAR(200),
            @PgmName    NVARCHAR(200),
            @Remark2    NVARCHAR(500),
            @Remark3    NVARCHAR(500),
            --@IsModule   NCHAR(1),
            @Remark5    NVARCHAR(500),
            @ToPlanDate NCHAR(8),
            @Remark4    NVARCHAR(500),
            --@StdDate    NCHAR(8),
            @Remark1    NVARCHAR(500),
            @SMIsFinSeq INT,
            @ToFinDate  NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DevOrder    = ISNULL( DevOrder  , '' ), 
           @DevName     = ISNULL( DevName   , '' ), 
           @FrFinDate   = ISNULL( FrFinDate , '' ), 
           @FrPlanDate  = ISNULL( FrPlanDate, '' ), 
           @PgmClass    = ISNULL( PgmClass  , '' ), 
           @Module      = ISNULL( Module    , '' ), 
           @Consultant  = ISNULL( Consultant, '' ), 
           @PgmName     = ISNULL( PgmName   , '' ), 
           @Remark2     = ISNULL( Remark2   , '' ), 
           @Remark3     = ISNULL( Remark3   , '' ), 
           --@IsModule    = ISNULL( IsModule  , '0' ), 
           @Remark5     = ISNULL( Remark5   , '' ), 
           @ToPlanDate  = ISNULL( ToPlanDate, '' ), 
           @Remark4     = ISNULL( Remark4   , '' ), 
           --@StdDate     = ISNULL( StdDate   , '' ), 
           @Remark1     = ISNULL( Remark1   , '' ), 
           @SMIsFinSeq  = ISNULL( SMIsFinSeq, 0 ), 
           @ToFinDate   = ISNULL( ToFinDate , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DevOrder   NVARCHAR(200),
            DevName    NVARCHAR(200),
            FrFinDate  NCHAR(8),  
            FrPlanDate NCHAR(8), 
            PgmClass   NVARCHAR(200),
            Module     NVARCHAR(200),
            Consultant NVARCHAR(200),
            PgmName    NVARCHAR(200),
            Remark2    NVARCHAR(500),
            Remark3    NVARCHAR(500),
            --IsModule   NCHAR(1),
            Remark5    NVARCHAR(500),
            ToPlanDate NCHAR(8),
            Remark4    NVARCHAR(500),
            --StdDate    NCHAR(8),
            Remark1    NVARCHAR(500),
            SMIsFinSeq INT,
            ToFinDate  NCHAR(8) 
           )    
    
    IF @ToPlanDate = '' SELECT @ToPlanDate = '99991231'
    IF @ToFinDate = '' SELECT @ToFinDate = '99991231'
    
    -- 최종조회   
    SELECT *, B.MinorName AS SMIsFin
      FROM KPX_TPMDevPgm AS A 
      LEFT OUTER JOIN _TDASMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMIsFinSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @DevOrder = '' OR A.DevOrder LIKE @DevOrder + '%' )
       AND ( @DevName = '' OR A.DevName LIKE @DevName + '%' )
       AND ( @PgmClass = '' OR A.PgmClass LIKE @PgmClass + '%' )
       AND ( @Module = '' OR A.Module LIKE @Module + '%' )
       AND ( @Consultant = '' OR A.Consultant LIKE @Consultant + '%' )
       AND ( @PgmName = '' OR A.PgmName LIKE @PgmName + '%' )
       AND ( @Remark2 = '' OR A.Remark2 LIKE @Remark2 + '%' )
       AND ( @Remark3 = '' OR A.Remark3 LIKE @Remark3 + '%' )
       AND ( @Remark4 = '' OR A.Remark4 LIKE @Remark4 + '%' )
       AND ( @Remark5 = '' OR A.Remark5 LIKE @Remark5 + '%' )
       AND ( @Remark1 = '' OR A.Remark1 LIKE @Remark1 + '%' )
       AND ( @SMIsFinSeq = 0 OR A.SMIsFinSeq LIKE @SMIsFinSeq ) 
       AND ( A.FinDate BETWEEN @FrFinDate AND @ToFinDate ) 
       AND ( A.PlanDate BETWEEN @FrPlanDate AND @ToPlanDate ) 
       AND ( A.FinDate BETWEEN @FrFinDate AND @ToPlanDate ) 
    RETURN 
go
exec KPXCM_SPMDevPgmQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate>20150917</StdDate>
    <DevOrder />
    <Module />
    <PgmName />
    <FrPlanDate />
    <ToPlanDate />
    <PgmClass />
    <Consultant />
    <DevName />
    <FrFinDate />
    <ToFinDate />
    <SMIsFinSeq />
    <Remark1 />
    <Remark2 />
    <IsModule>0</IsModule>
    <Remark3 />
    <Remark4 />
    <Remark5 />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032115,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026590