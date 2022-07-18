  
IF OBJECT_ID('KPXLS_SQCProInspRequestQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestQuery  
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-조회 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @DelvSeq    INT, 
            @ItemSeq    INT, 
            @ExpKind    INT, -- 1 내수 , 2 수입 
            @IsPass     NCHAR(1)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvSeq   = ISNULL( DelvSeq, 0 ), 
           @ItemSeq   = ISNULL( ItemSeq, 0 ), 
           @ExpKind   = ISNULL( ExpKind, 0 ), 
           @IsPass    = ISNULL( IsPass, '0')
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DelvSeq     INT, 
            ItemSeq     INT, 
            ExpKind     INT, 
            IsPass      NCHAR(1) 
           )    
    
    IF @ExpKind = 1 
    BEGIN  
        -- 최종조회   
        SELECT DISTINCT 
               A.DelvSeq, 
               B.ItemSeq, 
               C.ItemName, 
               A.BizUnit, 
               D.BizUnitName, 
               '국내' AS ExpKindName, 
               A.CustSeq, 
               E.CustName, 
               A.DelvNo, 
               C.ItemNo, 
               A.DelvDate, 
               F.DelvTotQty AS DelvTotQty, 
               B.UnitSeq, 
               G.UnitName, 
               (SELECT TOP 1 QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq AND InQc = 1000498001) AS QCType, 
               (SELECT TOP 1 QCTypeName FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq AND InQc = 1000498001) AS QCTypeName, 
               H.ReqNo, 
               ISNULL(H.ReqDate,CONVERT(NCHAR(8),GETDATE(),112)) AS ReqDate, 
               J.EmpName, 
               H.EmpSeq, 
               K.DeptName, 
               H.DeptSeq, 
               H.Remark, 
               I.Storage, 
               I.CarNo, 
               I.CreateCustName, 
               I.QCReqList, 
               H.ReqSeq, 
               1 AS ExpKind, 
               ISNULL(H.FromPgmSeq,1027813) AS FromPgmSeq 
                
          FROM _TPUDelv                     AS A 
                     JOIN _TPUDelvItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDABizUnit       AS D ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = A.BizUnit ) 
          LEFT OUTER JOIN _TDACust          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN ( 
                            SELECT Z.DelvSeq, Z.ItemSeq, SUM(Z.Qty) AS DelvTotQty 
                              FROM _TPUDelvItem AS Z 
                              LEFT OUTER JOIN KPXLS_TPUDelvItemAdd AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.DelvSeq = Z.DelvSeq AND Y.DelvSerl = Z.DelvSerl ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.DelvSeq = @DelvSeq 
                               AND Z.ItemSeq = @ItemSeq 
                               AND Y.IsPass = @IsPass 
                            GROUP BY Z.DelvSeq, Z.ItemSeq 
                          ) AS F ON ( F.DelvSeq = B.DelvSeq AND F.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS G ON ( G.CompanySeq = @CompanySeq AND G.UnitSeq = B.UnitSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequest  AS H ON ( H.CompanySeq = @CompanySeq AND H.SourceSeq = A.DelvSeq AND H.SMSourceType = 1000522008 AND H.PgmSeq = @PgmSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR   AS I ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = H.ReqSeq ) 
          LEFT OUTER JOIN _TDAEmp                   AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = H.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                  AS K ON ( K.CompanySeq = @CompanySeq AND K.DeptSeq = H.DeptSeq ) 
          LEFT OUTER JOIN KPXLS_TPUDelvItemAdd      AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = B.DelvSeq AND L.DelvSerl = B.DelvSerl ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND A.DelvSeq = @DelvSeq 
           AND B.ItemSeq = @ItemSeq 
           AND L.IsPass = @IsPass
    END 
    ELSE
    BEGIN
    
        -- 최종조회   
        SELECT DISTINCT 
               A.DelvSeq, 
               B.ItemSeq, 
               C.ItemName, 
               A.BizUnit, 
               D.BizUnitName, 
               '수입' AS ExpKindName, 
               A.CustSeq, 
               E.CustName, 
               A.DelvNo, 
               C.ItemNo, 
               A.DelvDate, 
               F.DelvTotQty AS DelvTotQty, 
               B.UnitSeq, 
               G.UnitName, 
               (SELECT TOP 1 QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq AND InQc = 1000498001) AS QCType, 
               (SELECT TOP 1 QCTypeName FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq AND InQc = 1000498001) AS QCTypeName, 
               H.ReqNo, 
               ISNULL(H.ReqDate,CONVERT(NCHAR(8),GETDATE(),112)) AS ReqDate, 
               J.EmpName, 
               H.EmpSeq, 
               K.DeptName, 
               H.DeptSeq, 
               H.Remark, 
               I.Storage, 
               I.CarNo, 
               I.CreateCustName, 
               I.QCReqList, 
               H.ReqSeq, 
               2 AS ExpKind, 
               ISNULL(H.FromPgmSeq,1028086) AS FromPgmSeq 

          FROM _TUIImpDelv                  AS A 
                     JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDABizUnit       AS D ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = A.BizUnit ) 
          LEFT OUTER JOIN _TDACust          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN ( 
                            SELECT Z.DelvSeq, Z.ItemSeq, SUM(Z.Qty) AS DelvTotQty 
                              FROM _TUIImpDelvItem AS Z 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.DelvSeq = @DelvSeq 
                               AND Z.ItemSeq = @ItemSeq 
                               AND Z.Memo3 = @IsPass 
                            GROUP BY Z.DelvSeq, Z.ItemSeq 
                          ) AS F ON ( F.DelvSeq = B.DelvSeq AND F.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS G ON ( G.CompanySeq = @CompanySeq AND G.UnitSeq = B.UnitSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequest  AS H ON ( H.CompanySeq = @CompanySeq AND H.SourceSeq = A.DelvSeq AND H.SMSourceType = 1000522007 AND H.PgmSeq = @PgmSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR   AS I ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = H.ReqSeq ) 
          LEFT OUTER JOIN _TDAEmp                   AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = H.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                  AS K ON ( K.CompanySeq = @CompanySeq AND K.DeptSeq = H.DeptSeq ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND A.DelvSeq = @DelvSeq 
           AND B.ItemSeq = @ItemSeq 
           AND B.Memo3 = @IsPass
    END 
    RETURN  
    go
exec KPXLS_SQCProInspRequestQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DelvSeq>1000182</DelvSeq>
    <ItemSeq>27375</ItemSeq>
    <ExpKind>2</ExpKind>
    <IsPass>0</IsPass>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845



--select * from _TCAPgm where caption like '%수입입고품목조회%'