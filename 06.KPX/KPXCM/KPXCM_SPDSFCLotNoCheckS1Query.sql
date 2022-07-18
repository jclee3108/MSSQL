IF OBJECT_ID('KPXCM_SPDSFCLotNoCheckS1Query') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCLotNoCheckS1Query
GO 

-- v2016.04.26 

-- Lot오류검사-중복조회 by 전경만   
CREATE PROC KPXCM_SPDSFCLotNoCheckS1Query
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
            @FactUnit       INT,
            @UMProcType     INT,
            @DateFr         NCHAR(8),
            @DateTo         NCHAR(8), 
            @ProdFlag       INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit        = ISNULL(FactUnit, 0),
           @UMProcType      = ISNULL(UMProcType, 0),
           @DateFr          = ISNULL(DateFr, ''),
           @DateTo          = ISNULL(DateTo, ''), 
           @ProdFlag        = ISNULL(ProdFlag, 0)
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit        INT,
            UMProcType      INT,
            DateFr          NCHAR(8),
            DateTo          NCHAR(8), 
            ProdFlag        INT
           )    
    
    
     -- 구분이 등록 되어 있는 워크 센터만 조회  
    SELECT C.ValueSeq as WorkCenterSeq --,D.ValueSeq,E.ValueSeq,F.ValueSeq  
      INTO #WorkCenter  
      FROM _TDAUMinorValue  AS C WITH(NOLOCK)       
      JOIN _TDAUMinorValue  AS D WITH(NOLOCK)ON C.CompanySeq = D.CompanySeq And C.MajorSeq = D.MajorSeq And C.MinorSeq = D.MinorSeq and D.Serl = 1000002      
      JOIN _TDAUMinorValue  AS E WITH(NOLOCK)ON D.CompanySeq = E.CompanySeq And E.MajorSeq = 1011265    And E.MinorSeq = D.ValueSeq and E.Serl = 1000001      
      JOIN _TDAUMinorValue  AS F WITH(NOLOCK)ON E.CompanySeq = F.CompanySeq And F.MajorSeq = 1011266    And F.MinorSeq = E.ValueSeq and F.Serl = 1000001      
     WHERE C.CompanySeq = @CompanySeq 
       AND C.MajorSeq = 1011346  
       AND C.Serl = 1000001  
       AND (@ProdFlag = 0 or D.ValueSeq = @ProdFlag or E.ValueSeq= @ProdFlag Or F.ValueSeq = @ProdFlag)  
    
    
    SELECT A.ProdPlanSeq,
           A.FactUnit,
           A.SrtDate,
           A.EndDate,
           A.WorkCond1,
           A.WorkCond2,
           A.WorkCond3,
           A.WorkCenterSeq,
           A.ItemSeq,
           A.ProdQty
      INTO #ProdPlan
      FROM _TPDMPSDailyProdPlan AS A
           LEFT OUTER JOIN KPX_TPDWorkCenterRate AS W WITH(NOLOCK) ON W.CompanySeq = A.CompanySeq
                                                                  AND W.WorkCenterSeq = A.WorkCenterSeq

     WHERE A.CompanySeq = @CompanySeq
       AND A.SrtDate BETWEEN @DateFr AND @DateTo
       AND A.FactUnit = @FactUnit
       AND (@UMProcType = 0 OR W.UMProcType = @UMProcType)
       AND ISNULL(A.WorkCond1,'') <> ''
       AND ISNULL(A.WorkCond2,'') <> ''
       AND ISNULL(A.WorkCond3,'') <> ''
       AND A.WorkCenterSeq IN (SELECT WorkCenterSeq FROM #WorkCenter)      
       

    SELECT A.ProdPlanSeq, 
           A.ItemSeq, 
           I.ItemName,
           I.ItemNo,
           I.Spec,
           A.WorkCond3,
           CASE WHEN LEN(A.WorkCond3) = 8 THEN CONVERT(NVARCHAR(10),CONVERT(INT,SUBSTRING(A.WorkCond3,6,3)))
                WHEN LEN(A.WorkCond3) > 8 THEN CONVERT(NVARCHAR(10),CONVERT(INT,SUBSTRING(A.WorkCond3,6,3))) + '-' + SUBSTRING(A.WorkCond3,9,10) END AS LotSeq, 
           STUFF(STUFF(A.SrtDate,5,0,'-'),8,0,'-') + ' ' + STUFF(A.WorkCond1,3,0,':') AS SrtDateTime,
           STUFF(STUFF(A.EndDate,5,0,'-'),8,0,'-') + ' ' + STUFF(A.WorkCond2,3,0,':') AS EndDateTime, 
           A.SrtDate, 
           A.EndDate, 
           A.WorkCond1          AS SrtTime,
           A.WorkCond2          AS EndTime,
           A.ProdQty            AS Qty,
           C.ProcSeq,
           P.ProcName,
           A.WorkCenterSeq,
           DATEDIFF(MINUTE, CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1, 2)),
           CONVERT(DATETIME, A.EndDate+SPACE(1)+LEFT(A.WorkCond2,2)+':'+RIGHT(A.WorkCond2, 2))) AS Dur, 
           D.WorkCenterName, 
           A.WorkcenterSeq, 
           RIGHT('00' + CONVERT(NVARCHAR(10),RTRIM(DATEDIFF(MINUTE, CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1, 2)),
           CONVERT(DATETIME, A.EndDate+SPACE(1)+LEFT(A.WorkCond2,2)+':'+RIGHT(A.WorkCond2, 2)))/60)),2) + ':' + 
           RIGHT('00' + CONVERT(NVARCHAR(10),RTRIM( DATEDIFF(MINUTE, CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1, 2)),
           CONVERT(DATETIME, A.EndDate+SPACE(1)+LEFT(A.WorkCond2,2)+':'+RIGHT(A.WorkCond2, 2)))%60)),2) AS Dur2 -- 분을 00:00 형식으로 시간으로 계산 
           
           
           
           
      FROM _TPDMPSDailyProdPlan AS A
           LEFT OUTER JOIN KPX_TPDWorkCenterRate AS W WITH(NOLOCK) ON W.CompanySeq = A.CompanySeq
                                                                  AND W.WorkCenterSeq = A.WorkCenterSeq
           LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq
                                                     AND I.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN _TPDROUItemProcWC AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq
                                                              AND C.ItemSeq = A.ItemSeq
                                                              AND C.FactUnit = A.FactUnit
                                                              AND C.WorkCenterSeq = A.WorkCenterSeq
           LEFT OUTER JOIN _TPDBaseProcess AS P WITH(NOLOCK) ON P.CompanySeq = C.CompanySeq
                                                            AND P.ProcSeq = C.ProcSeq
           JOIN (SELECT ItemSeq, WorkCond3
                              FROM #ProdPlan
                             GROUP BY ItemSeq, WorkCond3
                             HAVING COUNT(ProdPlanSeq) > 1) AS B ON B.ItemSeq = A.ItemSeq
                                                                AND B.WorkCond3 = A.WorkCond3
           LEFT OUTER JOIN _TPDBaseWorkCenter AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkcenterSeq ) 

     WHERE A.CompanySeq = @CompanySeq
       AND A.SrtDate BETWEEN @DateFr AND @DateTo
       AND A.FactUnit = @FactUnit
       AND (@UMProcType = 0 OR W.UMProcType = @UMProcType)
       AND A.WorkCenterSeq IN (SELECT WorkCenterSeq FROM #WorkCenter)      
     ORDER BY A.ItemSeq, A.WorkCond3
RETURN

GO


exec KPXCM_SPDSFCLotNoCheckS1Query @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>3</FactUnit>
    <DateFr>20160101</DateFr>
    <DateTo>20160421</DateTo>
    <UMProcType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031307,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029989