
IF OBJECT_ID('KPX_SPDMPSDailyProdPlanQuickDataAddQuery') IS NOT NULL 
    DROP PROC KPX_SPDMPSDailyProdPlanQuickDataAddQuery
GO 

-- v2014.10.08 

-- 선택배치- 데이터추가버튼 by 이재천   
CREATE PROC KPX_SPDMPSDailyProdPlanQuickDataAddQuery  
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
    
    DECLARE @docHandle      INT,  
            @ItemSeq        INT,  
            @WorkCenterSeq  INT,
            @Cnt            INT  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq = ISNULL( ItemSeq, 0 ),  
           @WorkCenterSeq = ISNULL( WorkCenterSeq, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq         INT, 
            WorkCenterSeq   INT
           )    
    
    IF @WorkingTag = '1' SELECT @Cnt = 1 
    IF @WorkingTag = '2' SELECT @Cnt = 2 
    IF @WorkingTag = '3' SELECT @Cnt = 3 
    IF @WorkingTag = '4' SELECT @Cnt = 4 
    IF @WorkingTag = '5' SELECT @Cnt = 5 
    IF @WorkingTag = '6' SELECT @Cnt = 6 
    IF @WorkingTag = '7' SELECT @Cnt = 7 
    IF @WorkingTag = '8' SELECT @Cnt = 8 
    IF @WorkingTag = '9' SELECT @Cnt = 9 
    IF @WorkingTag = '10' SELECT @Cnt = 10
    
    IF ISNULL(@Cnt,0) = 0 SELECT @Cnt = 1 
    
    CREATE TABLE #Result 
    (
        WorkCenterSeq       INT, 
        WorkCenterName      NVARCHAR(100), 
        ItemName            NVARCHAR(100), 
        Qty                 DECIMAL(19,5), 
        Cnt                 INT, 
        Dur                 DECIMAL(19,5), 
        AStock              DECIMAL(19,5), 
        TStock              DECIMAL(19,5),  
        ItemSeq             INT 
    )
        
    DECLARE @WhileCnt INT 
    SELECT @WhileCnt = 1 
    
    WHILE (1 = 1)
    BEGIN 
        
        INSERT INTO #Result 
        SELECT A.WorkCenterSeq, 
               A.WorkCenterName, 
               B.ItemName, 
               A.CapaRate AS Qty, 
               1 AS Cnt, 
               0 AS Dur, 
               0 AS AStock, 
               0 AS TStock, 
               B.ItemSeq 
          FROM _TPDBaseWorkCenter   AS A 
          LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = @COmpanySeq AND B.ItemSeq = @ItemSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WorkCenterSeq = @WorkCenterSeq 
        
        IF @WhileCnt = @Cnt
        BEGIN 
            BREAK
        END 
        ELSE 
        BEGIN 
            SELECT @WhileCnt = @WhileCnt + 1
        END 
    END 
    
    SELECT * FROM #Result 

    
      
return 
go 
exec KPX_SPDMPSDailyProdPlanQuickDataAddQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq>24722</ItemSeq>
    <WorkCenterSeq>100315</WorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024882,@WorkingTag=N'1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020927