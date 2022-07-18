  
IF OBJECT_ID('KPXLS_SPDQCRequestInsPurchaseJumpOut') IS NOT NULL   
    DROP PROC KPXLS_SPDQCRequestInsPurchaseJumpOut  
GO  
  
-- v2015.12.16 
  
-- 수입검사의뢰조회-Jump조회 by 이재천 
CREATE PROC KPXLS_SPDQCRequestInsPurchaseJumpOut  
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
            @ReqSeq         INT, 
            @ReqSerl        INT, 
            @SMSourceType   INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReqSeq   = ISNULL( ReqSeq, 0 ), 
           @ReqSerl   = ISNULL( ReqSerl, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ReqSeq      INT, 
            ReqSerl     INT
           )    
    
    
    SELECT @SMSourceType = B.SMSourceType 
      FROM KPXLS_TQCRequestItem AS A 
      LEFT OUTER JOIN KPXLS_TQCRequest AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ReqSeq = @ReqSeq 
       AND A.ReqSerl = @ReqSerl 
    
    

    
    DECLARE @QCType INT 
    
    
    IF EXISTS ( 
                SELECT 1 
                  FROM KPX_TQCTestResult 
                 WHERE CompanySeq = @CompanySeq 
                   AND ReqSeq = @ReqSeq 
                   AND ReqSerl = @ReqSerl 
              ) 
    BEGIN
        SELECT '진행 된 데이터입니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
               
        SELECT '진행 된 데이터입니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
    
    END 
    ELSE 
    BEGIN 
        
        
        SELECT @QCType = ( 
                            SELECT TOP 1 QCType
                              FROM KPX_TQCQAProcessQCType 
                             WHERE CompanySeq = @CompanySeq 
                               AND InQC = 1000498001
                         ) 
        
        
        IF @SMSourceType = 1000522008 
        BEGIN 
            -- 최종조회   
            SELECT F.BizUnitName, 
                   E.BizUnit, 
                   G.CustName, 
                   E.CustSeq, 
                   E.DelvNo, 
                   H.ItemName, 
                   H.ItemNo, 
                   D.ItemSeq, 
                   '국내' AS ExpKindName, 
                   E.DelvDate, 
                   D.Qty AS DelvTotQty, 
                   I.UnitName, 
                   D.UnitSeq, 
                   A.ReqDate, 
                   B.Storage, 
                   J.EmpName, 
                   A.EmpSeq, 
                   A.DeptSeq, 
                   K.DeptName, 
                   B.CarNo, 
                   B.CreateCustName, 
                   B.QCReqList, 
                   A.Remark, 
                   A.ReqSeq, 
                   C.ReqSerl,
                   A.ReqNo, 
                   D.LotNo, 
                   L.MakerLotNo, 
                   D.ItemSeq, 
                   @QCType AS QCType, 
                   0 AS Status
            
              FROM KPXLS_TQCRequest                     AS A 
              LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR   AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
              LEFT OUTER JOIN KPXLS_TQCRequestItem      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = A.ReqSeq ) 
              LEFT OUTER JOIN _TPUDelvItem              AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = C.SourceSeq AND D.DelvSerl = C.SourceSerl ) 
              LEFT OUTER JOIN _TPUDelv                  AS E ON ( E.CompanySeq = @CompanySeq AND E.DelvSeq = D.DelvSeq ) 
              LEFT OUTER JOIN _TDABizUnit               AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = E.BizUnit ) 
              LEFT OUTER JOIN _TDACust                  AS G ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = E.CustSeq ) 
              LEFT OUTER JOIN _TDAItem                  AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = D.ItemSeq ) 
              LEFT OUTER JOIN _TDAUnit                  AS I ON ( I.CompanySeq = @CompanySeq AND I.UnitSeq = D.UnitSeq ) 
              LEFT OUTER JOIN _TDAEmp                   AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = A.EmpSeq ) 
              LEFT OUTER JOIN _TDADept                  AS K ON ( K.CompanySeq = @CompanySeq AND K.DeptSeq = A.DeptSeq ) 
              LEFT OUTER JOIN KPXLS_TPUDelvItemAdd      AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = D.DelvSeq AND L.DelvSerl = D.DelvSerl ) 
             WHERE A.CompanySeq = @CompanySeq  
               AND C.ReqSeq = @ReqSeq 
               AND C.ReqSerl = @ReqSerl 
            

            
            SELECT ISNULL(D.InTestItemName,'') AS InTestItemName,   
                   ISNULL(D.OutTestItemName,'') AS OutTestItemName,   
                   ISNULL(D.TestItemSeq,0) AS TestItemSeq,   
                   E.QAAnalysisType AS QAAnalysisType,   
                   E.QAAnalysisTypeName AS QAAnalysisName,   
                   F.QCUnit,   
                   F.QCUnitName,   
                   C.SMInputType,   
                   G.MinorName AS SMInputTypeName,   
                   C.LowerLimit,   
                   C.UpperLimit, 
                   0 AS Status

              FROM KPXLS_TQCRequestItem                 AS B   
              LEFT OUTER JOIN KPXLS_TQCRequest          AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
              LEFT OUTER JOIN _TPUDelvItem              AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq AND H.DelvSerl = B.SourceSerl ) 
                         JOIN KPX_TQCQASpec             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = H.ItemSeq AND C.QCType = @QCType AND A.ReqDate BETWEEN C.SDate AND C.EDate )   
              LEFT OUTER JOIN KPX_TQCQATestItems        AS D ON ( D.CompanySeq = @CompanySeq AND D.TestItemSeq = C.TestItemSeq )   
              LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON ( E.CompanySeq = @CompanySeq AND E.QAAnalysisType = C.QAAnalysisType )   
              LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS F ON ( F.CompanySeq = @CompanySeq AND F.QCUnit = C.QCUnit )   
              LEFT OUTER JOIN _TDASMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.SMInputType )   
             WHERE B.CompanySeq = @CompanySeq    
               AND ( B.ReqSeq = @ReqSeq )  
               AND ( B.ReqSerl = @ReqSerl )     
        END 
        ELSE
        BEGIN 
            -- 최종조회   
            SELECT F.BizUnitName, 
                   E.BizUnit, 
                   G.CustName, 
                   E.CustSeq, 
                   E.DelvNo, 
                   H.ItemName, 
                   H.ItemNo, 
                   D.ItemSeq, 
                   '수입' AS ExpKindName, 
                   E.DelvDate, 
                   D.Qty AS DelvTotQty, 
                   I.UnitName, 
                   D.UnitSeq, 
                   A.ReqDate, 
                   B.Storage, 
                   J.EmpName, 
                   A.EmpSeq, 
                   A.DeptSeq, 
                   K.DeptName, 
                   B.CarNo, 
                   B.CreateCustName, 
                   B.QCReqList, 
                   A.Remark, 
                   A.ReqSeq, 
                   C.ReqSerl,
                   A.ReqNo, 
                   D.LotNo, 
                   D.Memo1 AS MakerLotNo, 
                   D.ItemSeq, 
                   @QCType AS QCType, 
                   0 AS Status
            
              FROM KPXLS_TQCRequest                     AS A 
              LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR   AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
              LEFT OUTER JOIN KPXLS_TQCRequestItem      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = A.ReqSeq ) 
              LEFT OUTER JOIN _TUIImpDelvItem           AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = C.SourceSeq AND D.DelvSerl = C.SourceSerl ) 
              LEFT OUTER JOIN _TUIImpDelv               AS E ON ( E.CompanySeq = @CompanySeq AND E.DelvSeq = D.DelvSeq ) 
              LEFT OUTER JOIN _TDABizUnit               AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = E.BizUnit ) 
              LEFT OUTER JOIN _TDACust                  AS G ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = E.CustSeq ) 
              LEFT OUTER JOIN _TDAItem                  AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = D.ItemSeq ) 
              LEFT OUTER JOIN _TDAUnit                  AS I ON ( I.CompanySeq = @CompanySeq AND I.UnitSeq = D.UnitSeq ) 
              LEFT OUTER JOIN _TDAEmp                   AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = A.EmpSeq ) 
              LEFT OUTER JOIN _TDADept                  AS K ON ( K.CompanySeq = @CompanySeq AND K.DeptSeq = A.DeptSeq ) 
             WHERE A.CompanySeq = @CompanySeq  
               AND C.ReqSeq = @ReqSeq 
               AND C.ReqSerl = @ReqSerl 
            

            
            SELECT ISNULL(D.InTestItemName,'') AS InTestItemName,   
                   ISNULL(D.OutTestItemName,'') AS OutTestItemName,   
                   ISNULL(D.TestItemSeq,0) AS TestItemSeq,   
                   E.QAAnalysisType AS QAAnalysisType,   
                   E.QAAnalysisTypeName AS QAAnalysisName,   
                   F.QCUnit,   
                   F.QCUnitName,   
                   C.SMInputType,   
                   G.MinorName AS SMInputTypeName,   
                   C.LowerLimit,   
                   C.UpperLimit, 
                   0 AS Status

              FROM KPXLS_TQCRequestItem                 AS B   
              LEFT OUTER JOIN KPXLS_TQCRequest          AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
              LEFT OUTER JOIN _TUIImpDelvItem           AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq AND H.DelvSerl = B.SourceSerl ) 
                         JOIN KPX_TQCQASpec             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = H.ItemSeq AND C.QCType = @QCType AND A.ReqDate BETWEEN C.SDate AND C.EDate )   
              LEFT OUTER JOIN KPX_TQCQATestItems        AS D ON ( D.CompanySeq = @CompanySeq AND D.TestItemSeq = C.TestItemSeq )   
              LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON ( E.CompanySeq = @CompanySeq AND E.QAAnalysisType = C.QAAnalysisType )   
              LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS F ON ( F.CompanySeq = @CompanySeq AND F.QCUnit = C.QCUnit )   
              LEFT OUTER JOIN _TDASMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.SMInputType )   
             WHERE B.CompanySeq = @CompanySeq    
               AND ( B.ReqSeq = @ReqSeq )  
               AND ( B.ReqSerl = @ReqSerl )  
        END               
    END 
    
    RETURN  
    go
exec KPXLS_SPDQCRequestInsPurchaseJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqSeq>36</ReqSeq>
    <ReqSerl>2</ReqSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033670,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027885