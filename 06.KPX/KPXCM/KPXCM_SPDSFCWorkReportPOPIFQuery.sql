  
IF OBJECT_ID('KPXCM_SPDSFCWorkReportPOPIFQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkReportPOPIFQuery  
GO  
  
-- v2015.11.18  
  
-- 생산실적반영(POP)-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkReportPOPIFQuery  
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
            @EmpSeq         INT, 
            @IsNoProc       NCHAR(1), 
            @RegDateTimeFr  NCHAR(8), 
            @RegDateTimeTo  NCHAR(8),
            @IFWorkReportSeq    NVARCHAR(100), 
            @ItemName       NVARCHAR(100), 
            @ProcName       NVARCHAR(100), 
            @AssyItemName   NVARCHAR(100)

    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @EmpSeq          = ISNULL( EmpSeq        , 0 ),  
           @IsNoProc        = ISNULL( IsNoProc      , '0' ),  
           @RegDateTimeFr   = ISNULL( RegDateTimeFr , '' ),  
           @RegDateTimeTo   = ISNULL( RegDateTimeTo , '' ), 
           @IFWorkReportSeq = ISNULL( IFWorkReportSeq, ''), 
           @ItemName        = ISNULL( ItemName, ''), 
           @ProcName        = ISNULL( ProcName, ''), 
           @AssyItemName    = ISNULL( AssyItemName, '')
           
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            EmpSeq         INT, 
            IsNoProc       NCHAR(1),      
            RegDateTimeFr  NCHAR(8),      
            RegDateTimeTo  NCHAR(8), 
            IFWorkReportSeq    NVARCHAR(100), 
            ItemName       NVARCHAR(100), 
            ProcName       NVARCHAR(100),             
            AssyItemName   NVARCHAR(100)            
           )    
    
    IF @RegDateTimeTo = '' SELECT @RegDateTimeTo = '99991231'
    
    -- 최종조회 
    
    -- 인터페이스 테이블 컬럼들을 그대로 넣는 작업 때문에 명칭도 Seq로 되어 있음, 
    -- 헷갈려하지마세요~
    
    SELECT A.Seq,   
           B.FactUnitName AS FactUnit,   
           C.DeptName AS DeptSeq,   
           A.IFWorkReportSeq,   
           A.WorkOrderSeq,   
           A.WorkOrderSerl,   
           A.WorkTimeGroup,   
           A.WorkStartDate,   
           A.WorkEndDate,   
           J.WorkCenterName AS WorkCenterSeq,   
           I.ItemName AS GoodItemSeq,   
           K.ProcName AS ProcSeq,   
           H.ItemName AS AssyItemSeq,   
           G.UnitName AS ProdUnitSeq,   
           A.ProdQty,   
           A.OkQty,   
           A.BadQty,   
           A.WorkStartTime,   
           A.WorkEndTime,   
           A.WorkMin,   
           A.RealLotNo,   
           F.MinorName AS WorkType,   
           A.OutKind ,  
           D.EmpName AS EmpSeq ,  
           A.Remark ,  
           CASE WHEN A.WorkingTag = 'A' THEN '신규'  
                WHEN A.WorkingTag = 'U' THEN '수정'   
                WHEN A.WorkingTag = 'D' THEN '삭제'   
                END AS WorkingTagName,   
           CASE WHEN A.ProcYn = '1' THEN '처리' ELSE '미처리' END AS ProcYn,  
           A.ProcYn AS ProcYnSub, 
           E.EmpName AS RegEmpSeq,   
           A.RegDateTime ,  
           A.ProcDateTime,   
           A.ErrorMessage,   
           A.WorkReportSeq,   
           CASE WHEN A.ProcYn = '1' THEN '-2365967' ELSE '-136743' END AS Color
      INTO #Result 
      FROM KPX_TPDSFCWorkReport_POP         AS A 
      LEFT OUTER JOIN _TDAFactUnit          AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDADept              AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.RegEmpSeq ) 
      LEFT OUTER JOIN _TDASMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.WorkType ) 
      LEFT OUTER JOIN _TDAUnit              AS G ON ( G.CompanySeq = @CompanySeq AND G.UnitSeq = A.ProdUnitSeq ) 
      LEFT OUTER JOIN _TDAItem              AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = A.AssyItemSeq ) 
      LEFT OUTER JOIN _TDAItem              AS I ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS J ON ( J.CompanySeq = @CompanySeq AND J.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDBaseProcess       AS K ON ( K.CompanySeq = @CompanySeq AND K.ProcSeq = A.ProcSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.IsPacking = '0' 
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq ) 
       AND CONVERT(NCHAR(8),A.RegDateTime,112) BETWEEN @RegDateTimeFr AND @RegDateTimeTo 
       AND ( @IFWorkReportSeq = '' OR A.IFWorkReportSeq LIKE @IFWorkReportSeq + '%' ) 
       AND ( @ItemName = '' OR I.ItemName LIKE @ItemName + '%' ) 
       AND ( @ProcName = '' OR K.ProcName LIKE @ProcName + '%' ) 
       AND ( @AssyItemName = '' OR H.ItemName LIKE @AssyItemName + '%' ) 

    IF @IsNoProc = '1' 
    BEGIN 
        
        DELETE FROM #Result WHERE ProcYnSub = '1' 
    
    END 
    
    SELECT * FROM #Result ORDER BY IFWorkReportSeq, Seq , RegDateTime
    
    RETURN  
    go
exec KPXCM_SPDSFCWorkReportPOPIFQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegDateTimeFr>20151030</RegDateTimeFr>
    <RegDateTimeTo />
    <EmpSeq />
    <IsNoProc>1</IsNoProc>
    <IFWorkReportSeq />
    <ItemName />
    <ProcName />
    <AssyItemName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033251,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027544