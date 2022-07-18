  
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotQuery  
GO  
  
-- v2016.03.02  
  
-- 긴급작업지시입력-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @DateFr         NCHAR(8), 
            @DateTo         NCHAR(8), 
            @WorkOrderNo    NVARCHAR(100), 
            @LotNo          NVARCHAR(100), 
            @ItemSeq        INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DateFr         = ISNULL( DateFr      , '' ), 
           @DateTo         = ISNULL( DateTo      , '' ), 
           @WorkOrderNo    = ISNULL( WorkOrderNo , '' ), 
           @LotNo          = ISNULL( LotNo       , '' ), 
           @ItemSeq        = ISNULL( ItemSeq     , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DateFr         NCHAR(8), 
            DateTo         NCHAR(8), 
            WorkOrderNo    NVARCHAR(100), 
            LotNo          NVARCHAR(100), 
            ItemSeq        INT 
           )    
    IF @DateTo = '' 
    BEGIN 
        SELECT @DateTo = '99991231'
    END 
    
    -- 최종조회   
    SELECT A.PilotSeq, 
           A.ProdPlanSeq, 
           A.WorkOrderSeq, 
           B.WorkOrderNo, 
           C.ProdPlanNo, 
           A.WorkCenterSeq, 
           D.WorkCenterName, 
           A.ItemSeq, 
           E.ItemEngSName AS ItemName, 
           A.LotNo, 
           LEFT(A.SrtDate,4) + '-' + SUBSTRING(A.SrtDate,5,2) + '-' + RIGHT(A.SrtDate,2) + ' ' + A.SrtHour AS SrtTime, 
           LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + RIGHT(A.EndDate,2) + ' ' + A.EndHour AS EndTime, 
           A.PatternSeq, 
           F.PatternRev AS PatternRev, 
           A.Remark AS Memo 
      FROM KPXCM_TPDSFCWorkOrderPilot       AS A 
      LEFT OUTER JOIN _TPDSFCWorkOrder      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan  AS C ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = A.ProdPlanSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS D ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TDAItem              AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq ) 
      OUTER APPLY (
                    SELECT Z.PatternRev
                      FROM KPX_TPDProdProc AS Z 
                     WHERE Z.CompanySeq = @CompanySeq  
                       AND Z.ItemSeq = A.ItemSeq 
                       AND CONVERT(INT,Z.PatternRev) = A.PatternSeq 
                       and isnull(Z.UseYn,'0') = '0'  
                  ) AS F 

     WHERE A.CompanySeq = @CompanySeq  
       AND A.SrtDate BETWEEN @DateFr AND @DateTo  
       AND ( @WorkOrderNo = '' OR B.WorkOrderNo LIKE @WorkOrderNo + '%' ) 
       AND ( @LotNo = '' OR A.LotNo LIKE @LotNo + '%' ) 
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq ) 
    
    RETURN  
    go
exec KPXCM_SPDSFCWorkOrderPilotQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DateFr>20161201</DateFr>
    <DateTo>20161201</DateTo>
    <WorkOrderNo />
    <ItemSeq />
    <LotNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029271