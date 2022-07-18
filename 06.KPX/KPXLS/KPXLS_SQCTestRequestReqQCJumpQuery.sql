  
IF OBJECT_ID('KPXLS_SQCTestRequestReqQCJumpQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCTestRequestReqQCJumpQuery  
GO  
  
-- v2015.12.29
  
-- 생산실적조회-최종검사 점프조회 by 이재천 
CREATE PROC KPXLS_SQCTestRequestReqQCJumpQuery  
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
            @WorkReportSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkReportSeq   = ISNULL( WorkReportSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
      WITH (WorkReportSeq   INT)    
    
    IF EXISTS (SELECT 1 FROM KPXLS_TQCRequest WHERE CompanySeq = @CompanySeq AND SourceSeq = @WorkReportSeq AND FromPgmSeq = 1028252)
    BEGIN
        SELECT 1234 AS Status, 
               1234 AS MessageType, 
               '최종검사의뢰 건이 존재 합니다.' AS Result 
    END 
    ELSE 
    BEGIN 
    
        -- 최종조회   
        SELECT B.WorkOrderNo, 
               A.WorkReportSeq AS SourceSeq, 
               0 AS SourceSerl, 
               A.ProdQty AS OrderQty, 
               A.FactUnit, 
               1028252 AS FromPgmSeq, 
               A.RealLotNo AS LotNo, 
               C.ItemName AS GoodItemName, 
               C.ItemNo AS GoodItemNo, 
               D.UnitName AS GoodItemSpec,
               CONVERT(NCHAR(8),GETDATE(),112) AS QCTestReqDate, 
               0 AS Status ,
               A.GoodItemSeq 
          FROM _TPDSFCWorkReport            AS A 
          LEFT OUTER JOIN _TPDSFCWorkOrder  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkorderSerl = A.WorkorderSerl ) 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = A.ProdUnitSeq ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND A.WorkReportSeq = @WorkReportSeq 
    END 
      
    RETURN  
    go
    exec KPXLS_SQCTestRequestReqQCJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WorkReportSeq>1002243</WorkReportSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033562,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028252