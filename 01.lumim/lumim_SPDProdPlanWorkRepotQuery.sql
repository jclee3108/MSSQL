  
IF OBJECT_ID('lumim_SPDProdPlanWorkRepotQuery') IS NOT NULL   
    DROP PROC lumim_SPDProdPlanWorkRepotQuery  
GO  
  
-- v2013.08.19  
  
-- 제조지시별생산실적조회_lumim(조회) by이재천   
CREATE PROC lumim_SPDProdPlanWorkRepotQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @WorkTeamSeq    INT,  
            @WorkDateFr     NVARCHAR(8), 
            @WorkDateTo     NVARCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkTeamSeq = ISNULL(WorkTeamSeq, 0), 
           @WorkDateFr  = ISNULL(WorkDateFr, ''), 
           @WorkDateTo  = ISNULL(WorkDateTo, '')  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkTeamSeq    INT,  
            WorkDateFr     NVARCHAR(8),
            WorkDateTo     NVARCHAR(8) 
           )    
    
    IF @WorkDateTo = '' SELECT @WorkDateTo = '99991231'
    
    -- 생산의뢰 원천찾기, BEGIN
    
    CREATE TABLE #Temp (IDX_NO INT IDENTITY, ProdPlanSeq INT) 
            
    INSERT INTO #Temp(ProdPlanSeq) 
         SELECT A.ProdPlanSeq
           FROM _TPDMPSDailyProdPlan AS A
           LEFT OUTER JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq ) 
           LEFT OUTER JOIN _TPDSFCWorkReport AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = B.WorkOrderSeq AND C.WorkOrderSerl = B.WorkOrderSerl ) 
          WHERE A.CompanySeq = @CompanySeq
            AND C.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo 
            AND C.WorkTimeGroup = @WorkTeamSeq 
    
    CREATE TABLE #TMP_SourceTable 
            (IDOrder   INT, 
             TableName NVARCHAR(100))  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
         SELECT 1, '_TPDMPSProdReqItem' 
    
    CREATE TABLE #TCOMSourceTracking 
            (IDX_NO  INT, 
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
    
    EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPDMPSDailyProdPlan', 
             @TempTableName = '#Temp', 
             @TempSeqColumnName = 'ProdPlanSeq', 
             @TempSerlColumnName = '', 
             @TempSubSerlColumnName = '' 
    
    -- 생산의뢰 원천찾기, END
    
    
    -- 최종조회   
    SELECT B.ProcName, -- 공정명
           A.ProcSeq, -- 공정내부코드
           CASE WHEN ISNULL(R.ValueSeq,0) = 0 THEN ''     
                ELSE ( SELECT ISNULL(MinorName,'')       
                         FROM _TDAUMinor WITH(NOLOCK)       
                        WHERE CompanySeq = @CompanySeq AND MinorSeq = R.ValueSeq ) END AS ModelName,  -- 품목중분류 
           R.ValueSeq AS ModelSeq, -- 품목중분류코드
           E.ProdPlanNo, -- 생산계획번호
           A.ProdQty, -- 생산수량
           A.WorkDate, -- 작업일
           A.GoodItemSeq AS ItemSeq, -- 품목코드
           C.ItemName, -- 품명
           F.UnitName, -- 단위
           G.MinorName AS WorkTeamKindName, -- 작업조구분
           A.WorkTimeGroup AS WorkTeamKind, -- 작업조구분코드
           O.CustName, -- 거래처
           N.CustSeq -- 거래처코드
           
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDBaseProcess AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ProcSeq = A.ProcSeq ) 
      JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq 
                                       AND C.AssetSeq = (
                                                         SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1
                                                        ) 
                                         )   
      LEFT OUTER JOIN _TDAItemClass        AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.ItemSeq = C.ItemSeq AND P.UMajorItemClass = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor           AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MajorSeq = LEFT( P.UMItemClass, 4 ) AND P.UMItemClass = Q.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue      AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MajorSeq = 2001 AND R.MinorSeq = Q.MinorSeq AND R.Serl = 1001 ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkOrderSeq = A.WorkOrderSeq AND D.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ProdPlanSeq = D.ProdPlanSeq ) 
      LEFT OUTER JOIN _TDAUnit             AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor           AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.WorkTimeGroup ) 
      LEFT OUTER JOIN #TEMP               AS L WITH(NOLOCK) ON ( L.ProdPlanSeq = E.ProdPlanSeq ) 
      LEFT OUTER JOIN #TCOMSourceTracking AS M WITH(NOLOCK) ON ( M.IDX_NO = L.IDX_NO ) 
      LEFT OUTER JOIN _TPDMPSProdReqItem  AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.ProdReqSeq = M.Seq ) 
      LEFT OUTER JOIN _TDACust            AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = N.CustSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo 
       AND A.WorkTimeGroup = @WorkTeamSeq 
     
     ORDER BY E.ProdPlanNo
    
    RETURN  
GO
exec lumim_SPDProdPlanWorkRepotQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkDateFr>20130101</WorkDateFr>
    <WorkDateTo>20130820</WorkDateTo>
    <WorkTeamSeq>6017001</WorkTeamSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017187,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014703