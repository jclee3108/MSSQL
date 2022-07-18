  
IF OBJECT_ID('KPXCM_SPDSFWorkOrderPOPFailQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFWorkOrderPOPFailQuery  
GO  
  
-- v2015.11.24  
  
-- 작업지시연동모니터링-조회 by 이재천   
CREATE PROC KPXCM_SPDSFWorkOrderPOPFailQuery  
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
            -- 조회조건 
            @IsPack         NCHAR(1), 
            @RegDateTo      NCHAR(8), 
            @RegDateFr      NCHAR(8), 
            @FactUnit       INT, 
            @ItemEngSName   NVARCHAR(100), 
            @IsErr          NCHAR(1), 
            @WorkOrderNo    NVARCHAR(100)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @IsPack         = ISNULL( IsPack         , '0' ),  
           @RegDateTo      = ISNULL( RegDateTo      , '' ),  
           @RegDateFr      = ISNULL( RegDateFr      , '' ),  
           @FactUnit       = ISNULL( FactUnit       , 0 ),  
           @ItemEngSName   = ISNULL( ItemEngSName   , '' ), 
           @IsErr          = ISNULL( IsErr          , '0' ), 
           @WorkOrderNo    = ISNULL( WorkOrderNo   , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            IsPack         NCHAR(1), 
            RegDateTo      NCHAR(8),       
            RegDateFr      NCHAR(8),       
            FactUnit       INT,       
            ItemEngSName   NVARCHAR(100), 
            IsErr          NCHAR(1), 
            WorkOrderNo    NVARCHAR(100)
           )    
    
    IF @RegDateTo = '' SELECT @RegDateTo = '99991231'
    
    -- 최종조회   
    SELECT A.WorkOrderSeq, 
           A.WorkOrderSerl, 
           CASE WHEN A.IsPacking = '0' THEN '생산작업지시' ELSE '포장작업지시' END AS IsPacking, 
           A.IsPacking AS IsPackingSub,
           A.WorkOrderNo, 
           A.WorkOrderDate, 
           B.FactUnitName, 
           C.WorkCenterName,
           CASE WHEN D.ItemEngSName = '' THEN D.ItemName ELSE D.ItemEngSName END AS GoodItemName, 
           E.ProcName AS ProcSeq, 
           F.UnitName AS ProdUnitName,
           A.BOMRev, 
           A.OrderQty, 
           A.WorkSrtDate, 
           A.WorkStartTime, 
           A.WorkEndDate, 
           A.WorkEndTime, 
           A.LotNo, 
           G.MinorName AS WorkTypeName, 
           A.Remark, 
           A.WorkTimeGroup, 
           H.EmpName, 
           I.MinorName AS UMProgTypeName, 
           A.RegDateTime, 
           A.ProcDateTime, 
           CASE WHEN A.ProcYn = '0' THEN '미처리' 
                WHEN A.ProcYn = '1' THEN '처리' 
                WHEN A.ProcYn = '9' THEN 'MES 작업시작으로 인한 연동 오류' 
                END AS ProcYn, 
           A.OutLotNo, 
           CASE WHEN A.WorkingTag = 'A' THEN '신규' 
                WHEN A.WorkingTag = 'U' THEN '수정' 
                WHEN A.WorkingTag = 'D' THEN '삭제' 
                END AS WorkingTagName, 
           A.ProcYn AS ProcYnSub, 
           A.PackingLocation, 
           A.Serl, 
           A.TankName, 
           A.PatternRev, 
           A.Procflg, 
           A.CustItemName, 
           A.SourceSeq, 
           A.SourceSerl, 
           CASE WHEN J.ItemEngSName = '' THEN J.ItemName ELSE J.ItemEngSName END AS PatternItemSeq, 
           K.MinorName AS PostProc, 
           A.SubItemName  
      INTO #Result            
      FROM KPX_TPDSFCWorkOrder_POP          AS A 
      LEFT OUTER JOIN _TDAFactUnit          AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS C ON ( C.CompanySeq = @CompanySeq AND C.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TDAItem              AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TPDBaseProcess       AS E ON ( E.CompanySeq = @CompanySeq AND E.ProcSeq = A.ProcSeq ) 
      LEFT OUTER JOIN _TDAUnit              AS F ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = A.ProdUnitSeq ) 
      LEFT OUTER JOIN _TDASMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.WorkType ) 
      LEFT OUTER JOIN _TDAEmp               AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMProgType ) 
      LEFT OUTER JOIN _TDAItem              AS J ON ( J.CompanySeq = @CompanySeq AND J.ItemSeq = A.PatternItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = A.PostProc ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( CONVERT(NCHAR(8),A.RegDateTime,112) BETWEEN @RegDateFr AND @RegDateTo )
       AND ( @ItemEngSName = '' OR CASE WHEN D.ItemEngSName = '' THEN D.ItemName ELSE D.ItemEngSName END LIKE @ItemEngSName + '%' ) 
       AND ( @FactUnit = 0 OR A.FactUnit = @FactUnit ) 
       AND ( @WorkOrderNo = '' OR A.WorkOrderNo LIKE @WorkOrderNo + '%' ) 
    
    
    IF @IsErr = '1' 
    BEGIN
        DELETE A 
          FROM #Result AS A 
         WHERE ProcYnSub = '1' 
    END 
    
    IF @IsPack = '0' 
    BEGIN 
        DELETE A
          FROM #Result AS A 
         WHERE IsPackingSub = '1' 
    END 
    
    SELECT * FROM #Result 
        
    RETURN  
    
    go
exec KPXCM_SPDSFWorkOrderPOPFailQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsErr>0</IsErr>
    <FactUnit>3</FactUnit>
    <RegDateFr>20151024</RegDateFr>
    <RegDateTo />
    <WorkOrderNo />
    <ItemEngSName />
    <IsPack>0</IsPack>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033351,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026558