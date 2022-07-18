
IF OBJECT_ID('KPX_SPDMPSDailyProdPlanQuickApplySave') IS NOT NULL 
    DROP PROC KPX_SPDMPSDailyProdPlanQuickApplySave
GO 

-- v2014.10.10 

-- 선택배치(생산계획생성) by이재천 
CREATE PROC dbo.KPX_SPDMPSDailyProdPlanQuickApplySave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #TPDMPSDailyProdPlan (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'     
    IF @@ERROR <> 0 RETURN  
    
    ALTER TABLE #TPDMPSDailyProdPlan ADD LotNo NVARCHAR(50)  
    
    
    DECLARE @MaxSeq         INT, 
            @FactUnit       INT, 
            @ProdDate       INT, 
            @ProdPlanNo     NVARCHAR(20), 
            @WhileCnt       INT, 
            @DeptSeq        INT, 
            @Serl           INT, 
            @SProdPlanSeq   INT -- 시작 생산계획코드 
    
    SELECT @DeptSeq = (SELECT ISNULL(DeptSeq,1) FROM _fnAdmEmpOrd(@CompanySeq, '') WHERE EmpSeq = (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq))
    
    SELECT @FactUnit = 1 
    SELECT @ProdDate = CONVERT(NCHAR(8),GETDATE(),112) 
    
    SELECT @WhileCnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN 
        EXEC dbo._SCOMCreateNo  'PD',     
                                '_TPDMPSDailyProdPlan',     
                                @CompanySeq,     
                                @FactUnit,     
                                @ProdDate,     
                                @ProdPlanNo OUTPUT 
        
        EXEC @MaxSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDMPSDailyProdPlan', 'ProdPlanSeq', 1      
        
        UPDATE A 
           SET ProdPlanSeq = @MaxSeq + 1,  
               ProdPlanNo = @ProdPlanNo
          FROM #TPDMPSDailyProdPlan AS A 
         WHERE DataSeq = @WhileCnt 
    
        IF @WhileCnt = (SELECT MAX(DataSeq) FROM #TPDMPSDailyProdPlan)
        BEGIN 
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @WhileCnt = @WhileCnt + 1  
        END 
    END 
    
    SELECT @SProdPlanSeq = MIN(ProdPlanSeq) FROM #TPDMPSDailyProdPlan 
    
    
    SELECT @Serl = ISNULL(MAX(CONVERT(INT,RIGHT(WorkCond3,3))),0)
      FROM _TPDMPSDailyProdPlan 
     WHERE CompanySeq = @CompanySeq 
       AND ItemSeq = (SELECT TOP 1 ItemSeq FROM #TPDMPSDailyProdPlan) 
     GROUP BY SUBSTRING(ProdPlanDate,3,4), ItemSeq
    
    SELECT @CompanySeq AS CompanySeq, 
           A.ProdPlanSeq, 
           1 AS FactUnit, 
           A.ProdPlanNo,
           CONVERT(NCHAR(8), 
           DATEADD(Minute, (LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2)) * (A.DataSeq - 1), 
           CASE WHEN B.EndDate IS NULL THEN GETDATE() -- 워크센터 데이터없을 경우는 현재 날짜, 현재날짜보다 큰 경우는 생산 끝나는 날짜, 현재날짜보다 작거나 같은경우는 현재날짜
                WHEN B.EndDate > CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, SUBSTRING(B.EndDate,9,2) * 60 + SUBSTRING(B.EndDate,11,2), CONVERT(DATETIME,LEFT(B.EndDate,8)))
                WHEN B.EndDate <= CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN GETDATE() 
           END)
           ,112) AS SrtDate, 
           CONVERT(NCHAR(8), 
           DATEADD(Minute, (LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2)) * (A.DataSeq - 1), 
           CASE WHEN B.EndDate IS NULL THEN DATEADD(MInute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), GETDATE())
                WHEN B.EndDate > CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), DATEADD(Minute, SUBSTRING(B.EndDate,9,2) * 60 + SUBSTRING(B.EndDate,11,2), CONVERT(DATETIME,LEFT(B.EndDate,8))))
                WHEN B.EndDate <= CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), GETDATE())
           END)
           ,112) AS EndDate, 
           
           @DeptSeq AS DeptSeq, 
           A.WorkCenterSeq, 
           A.ItemSeq, 
           '00' AS BOMRev, 
           '00' AS ProcRev, 
           D.UnitSeq, 
           0 AS BaseStkQty, 
           0 AS PreSalesQty, 
           0 AS SOQty, 
           0 AS StkQty, 
           0 AS PreInQty, 
           Qty AS ProdQty, 
           Qty AS StdProdQty, 
           6054001 AS SMSource, 
           0 AS SourceSeq, 
           0 AS SourceSerl, 
           '' AS Remark, 
           '0' AS IsCfm, 
           0 AS CfmEmpSeq, 
           '' AS CfmDate, 
           @UserSeq AS LastuserSeq, 
           GETDATE() AS LastDateTime, 
           NULL BatchSeq, 
           D.UnitSeq AS StdUnitSeq, 
           NULL AS StockInDate, 
           REPLACE(
           SUBSTRING(CONVERT(NVARCHAR(30), 
           DATEADD(Minute, (LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2)) * (A.DataSeq - 1), 
           CASE WHEN B.EndDate IS NULL THEN GETDATE() -- 워크센터 데이터없을 경우는 현재 날짜, 현재날짜보다 큰 경우는 생산 끝나는 날짜, 현재날짜보다 작거나 같은경우는 현재날짜
                WHEN B.EndDate > CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, SUBSTRING(B.EndDate,9,2) * 60 + SUBSTRING(B.EndDate,11,2), CONVERT(DATETIME,LEFT(B.EndDate,8)))
                WHEN B.EndDate <= CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN GETDATE() 
           END)
           ,13),12,5)
           ,':','') AS SrtTime, 
           
           REPLACE(
           SUBSTRING(CONVERT(NVARCHAR(30),
           DATEADD(Minute, (LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2)) * (A.DataSeq - 1), 
           CASE WHEN B.EndDate IS NULL THEN DATEADD(MInute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), GETDATE())
                WHEN B.EndDate > CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), DATEADD(Minute, SUBSTRING(B.EndDate,9,2) * 60 + SUBSTRING(B.EndDate,11,2), CONVERT(DATETIME,LEFT(B.EndDate,8))))
                WHEN B.EndDate <= CONVERT(NCHAR(8),GETDATE(),112) + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20),GETDATE(),13),12,5),':','') THEN DATEADD(Minute, LEFT(C.StdProdTime,2) * 60 + RIGHT(C.StdProdTime,2), GETDATE())
           END)
           ,13),12,5)
           ,':','') AS EndTime, 
           CONVERT(NCHAR(8),GETDATE(),112) AS ProdPlanDate, 
           SUBSTRING(CONVERT(NCHAR(8),GETDATE(),112),3,4) + D.ItemName + RIGHT('00' + CONVERT(NVARCHAR(3),@Serl + A.DataSeq),3) AS LotNo 
           
      INTO #Temp_ProdPlan
      FROM #TPDMPSDailyProdPlan AS A 
      OUTER APPLY (SELECT MAX(EndDate + ISNULL(WorkCond2,'0000')) AS EndDate 
                     FROM _TPDMPSDailyProdPlan AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WorkCenterSeq = A.WorkCenterSeq 
                  ) AS B 
      LEFT OUTER JOIN KPX_TPDItemWCStd AS C ON ( C.CompanySeq = @CompanySeq AND C.WorkCenterSeq = A.WorkCenterSeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem         AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
    
    INSERT INTO _TPDMPSDailyProdPlan
    (
        CompanySeq,     ProdPlanSeq,        FactUnit,           ProdPlanNo,         SrtDate,        
        EndDate,        DeptSeq,            WorkcenterSeq,      ItemSeq,            BOMRev,        
        ProcRev,        UnitSeq,            BaseStkQty,         PreSalesQty,        SOQty,        
        StkQty,         PreInQty,           ProdQty,            StdProdQty,         SMSource,        
        SourceSeq,      SourceSerl,         Remark,             IsCfm,              CfmEmpSeq,        
        CfmDate,        LastUserSeq,        LastDateTime,       BatchSeq,           StdUnitSeq,        
        StockInDate,    WorkCond1,          WorkCond2,          WorkCond3,          PgmSeq, 
        ProdPlanDate,   WorkCond4 
    )
    SELECT @CompanySeq,    ProdPlanSeq,        FactUnit,           ProdPlanNo,         SrtDate,        
           EndDate,        DeptSeq,            WorkcenterSeq,      ItemSeq,            BOMRev,        
           ProcRev,        UnitSeq,            BaseStkQty,         PreSalesQty,        SOQty,        
           StkQty,         PreInQty,           ProdQty,            StdProdQty,         SMSource,        
           SourceSeq,      SourceSerl,         Remark,             IsCfm,              CfmEmpSeq,       
           CfmDate,        LastUserSeq,        LastDateTime,       BatchSeq,           StdUnitSeq,      
           StockInDate,    SrtTime,            EndTime,            LotNo,              @PgmSeq, 
           ProdPlanDate,   @SProdPlanSeq 
     FROM #Temp_ProdPlan 
    
    SELECT * FROM #TPDMPSDailyProdPlan 
    
    RETURN    
GO 
begin tran 
--select * From _TPDMPSDailyProdPlan where companyseq =1 and ProdPlanNo in ( '201410210002','201410210003' ) 
exec KPX_SPDMPSDailyProdPlanQuickApplySave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AStock>0.00000</AStock>
    <Cnt>1</Cnt>
    <Dur>0.00000</Dur>
    <IsLast>1</IsLast>
    <IsStd>0</IsStd>
    <ItemName>세호-본체</ItemName>
    <ItemSeq>1001148</ItemSeq>
    <Qty>0.00000</Qty>
    <TStock>0.00000</TStock>
    <WorkCenterName>생산계획(워크센터)</WorkCenterName>
    <WorkCenterSeq>100239</WorkCenterSeq>
    <ProdPlanNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024882,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020927

--select * From _TPDMPSDailyProdPlan where companyseq =1 and ProdPlanNo = '201410210004' 
rollback 


--sp_lock


--sp_who 181

--kill 181