IF OBJECT_ID('KPXLS_SSLDelvRequestCOAJumpQuery') IS NOT NULL 
    DROP PROC KPXLS_SSLDelvRequestCOAJumpQuery
GO 

-- v2016.01.05 

-- COA점프 by이재천 
CREATE PROC dbo.KPXLS_SSLDelvRequestCOAJumpQuery                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            @DelvReqSeq     INT, 
            @DelvReqSerl    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @DelvReqSeq = ISNULL(DelvReqSeq ,0), 
           @DelvReqSerl = ISNULL(DelvReqSerl, 0)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            DelvReqSeq  INT,
            DelvReqSerl INT 
            )  
    
    IF EXISTS ( SELECT 1 FROM KPXLS_TQCCOAPrint WHERE CompanySeq = @CompanySeq AND FromPgmSeq = 1028040 AND SourceSeq = @DelvReqSeq AND SourceSerl = @DelvReqSerl ) 
    BEGIN
        SELECT '시험성적서저장이 이미 되었습니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
    END 
    ELSE
    BEGIN 
        SELECT A.DelvReqSeq AS SourceSeq,--출하요청등록내부코드  
               Z.DelvReqSerl AS SourceSerl,--출하요청등록내부순번  
               @PgmSeq AS FromPgmSeq, 
               D.ItemName, --품명  
               B.ItemSeq, 
               G.CustName, --고객  
               C.CustSeq, 
               Z.LotNo, --LotNo  
               Z.TotalWeight AS TotWeight, --총무게  
               Z.RealWeight AS OriWeight, --순분무게  
               H.UnitName, 
               E.EngCustName, 
               F.CustItemName, 
               CONVERT(NCHAR(8),GETDATE(),112) ShipDate, 
               0 AS Status 
          FROM KPXLS_TSLDelvRequest     AS A 
          JOIN _TSLDVReqItem            AS B ON ( B.CompanySeq = @CompanySeq AND A.DVReqSeq = B.DVReqSeq AND A.DVReqSerl = B.DVReqSerl ) 
          JOIN _TSLDVReq                AS C ON ( C.CompanySeq = @CompanySeq AND A.DVReqSeq = C.DVReqSeq ) 
          LEFT OUTER JOIN _TDAItem      AS D ON ( D.CompanySeq = @CompanySeq AND B.ItemSeq = D.ItemSeq ) 
          LEFT OUTER JOIN _TDACust      AS G ON ( G.CompanySeq = @CompanySeq AND C.CustSeq = G.CustSeq ) 
          LEFT OUTER JOIN _TDAUnit      AS H ON ( H.CompanySeq = @CompanySeq AND B.UnitSeq = H.UnitSeq ) 
          LEFT OUTER JOIN _TDACustAdd   AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = C.CustSeq ) 
          LEFT OUTER JOIN _TSLCustItem  AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = C.CustSeq AND F.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN KPXLS_TSLDelvRequestItem AS Z ON ( Z.CompanySeq = @CompanySeq AND A.DelvReqSeq = Z.DelvReqSeq ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND A.DelvReqSeq = @DelvReqSeq 
           AND Z.DelvReqSerl = @DelvReqSerl 
    END 
    
    RETURN 
    