  
IF OBJECT_ID('KPX_SQCReportinappropriateListQuery') IS NOT NULL   
    DROP PROC KPX_SQCReportinappropriateListQuery  
GO  
  
-- v2014.12.19  
  
-- 부적합보고서조회-조회 by 이재천   
CREATE PROC KPX_SQCReportinappropriateListQuery  
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
            @ReportDateFr   NCHAR(8), 
            @ReportDateTo   NCHAR(8), 
            @ReturnDateFr   NCHAR(8), 
            @ReturnDateTo   NCHAR(8), 
            @ReportOutNo    NVARCHAR(100), 
            @DeptName       NVARCHAR(100), 
            @EmpName        NVARCHAR(100), 
            @ReturnDeptName NVARCHAR(100), 
            @ItemName       NVARCHAR(100), 
            @LotNo          NVARCHAR(100), 
            @QCTypeName     NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ReportDateFr        = ISNULL( ReportDateFr  , '' ),  
           @ReportDateTo        = ISNULL( ReportDateTo  , '' ),  
           @ReturnDateFr        = ISNULL( ReturnDateFr  , '' ),  
           @ReturnDateTo        = ISNULL( ReturnDateTo  , '' ),  
           @ReportOutNo         = ISNULL( ReportOutNo   , '' ),  
           @DeptName            = ISNULL( DeptName      , '' ),  
           @EmpName             = ISNULL( EmpName       , '' ),  
           @ReturnDeptName      = ISNULL( ReturnDeptName, '' ),  
           @ItemName            = ISNULL( ItemName      , '' ),  
           @LotNo               = ISNULL( LotNo         , '' ),  
           @QCTypeName          = ISNULL( QCTypeName    , '' )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
                ReportDateFr   NCHAR(8), 
                ReportDateTo   NCHAR(8), 
                ReturnDateFr   NCHAR(8), 
                ReturnDateTo   NCHAR(8), 
                ReportOutNo    NVARCHAR(100),
                DeptName       NVARCHAR(100),
                EmpName        NVARCHAR(100),
                ReturnDeptName NVARCHAR(100),
                ItemName       NVARCHAR(100),
                LotNo          NVARCHAR(100),
                QCTypeName     NVARCHAR(100) 
           )    
    
    -- 최종조회   
    SELECT A.ReportOutNo, -- 관리번호 
           A.ReportDate, -- 발신일 
           A.ReturnDate, -- 회신일 
           A.DeptSeq, 
           B.DeptName, 
           A.EmpSeq, 
           C.EmpName, 
           A.ReturnDeptSeq, 
           D.DeptName AS returnDeptName,  
           E.Cause, -- 발생원인 
           F.ProcRemark, -- 처리방안 
           G.RecuRemark, -- 재발방지대책
           I.ItemName, 
           I.ItemNo,
           I.Spec, 
           H.LotNo, 
           J.QCTypeName
           
      FROM KPX_TQCReportOut                             AS A 
      LEFT OUTER JOIN _TDADept                          AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp                           AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                          AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.ReturnDeptSeq ) 
      LEFT OUTER JOIN KPX_TQCReportOutCause             AS E ON ( E.CompanySeq = @CompanySeq AND E.ReportType = A.ReportType AND E.ReportSeq = A.ReportSeq AND E.Serl = A.Serl ) 
      LEFT OUTER JOIN KPX_TQCReportOutProc              AS F ON ( F.CompanySeq = @CompanySeq AND F.ReportType = A.ReportType AND F.ReportSeq = A.ReportSeq AND F.Serl = A.Serl ) 
      LEFT OUTER JOIN KPX_TQCReportOutRecurrence        AS G ON ( G.CompanySeq = @CompanySeq AND G.ReportType = A.ReportType AND G.ReportSeq = A.ReportSeq AND G.Serl = A.Serl ) 
      LEFT OUTER JOIN KPX_TQCInStockInspectionResult    AS H ON ( H.CompanySeq = @CompanySeq AND H.StockQCSeq = A.ReportSeq ) 
      LEFT OUTER JOIN _TDAItem                          AS I ON ( I.CompanySeq = @COmpanySeq AND I.ItemSeq = H.ItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType            AS J ON ( J.CompanySeq = @CompanySeq AND J.QCType = H.QCType ) 
     WHERE A.CompanySeq = @CompanySeq  
    
    RETURN  