IF OBJECT_ID('KPXLS_SQCCOAPrintListQuery') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintListQuery
GO 

-- v2015.12.22 

-- 시험성적서조회(COA)-조회
CREATE PROC KPXLS_SQCCOAPrintListQuery
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT, 
            @CustName       NVARCHAR(100),
            @EngCustName    NVARCHAR(100),
            @COADateFr      NCHAR(8),
            @COADateTo      NCHAR(8),
            @COANo          NVARCHAR(100),
            @ItemName       NVARCHAR(100),
            @CustItemName   NVARCHAR(100),
            @LotNo          NVARCHAR(100),
            @QCTypeName     NVARCHAR(100),
            @SMSourceType   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CustName        = ISNULL(CustName, ''),
           @EngCustName     = ISNULL(EngCustName, ''),
           @COADateFr       = ISNULL(COADateFr, ''),
           @COADateTo       = ISNULL(COADateTo, ''),
           @COANo           = ISNULL(COANo, ''),
           @ItemName        = ISNULL(ItemName, ''),
           @CustItemName    = ISNULL(CustItemName, ''),
           @LotNo           = ISNULL(LotNo, ''),
           @QCTypeName      = ISNULL(QCTypeName, ''),
           @SMSourceType	= ISNULL(SMSourceType,0)
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            CustName       NVARCHAR(100),
            EngCustName    NVARCHAR(100),
            COADateFr      NCHAR(8),
            COADateTo      NCHAR(8),
            COANo          NVARCHAR(100),
            ItemName       NVARCHAR(100),
            CustItemName   NVARCHAR(100),
            LotNo          NVARCHAR(100),
            QCTypeName     NVARCHAR(100),
            SMSourceType   INT
           )
            
    
    SELECT A.COASeq,
           A.COADate,
           A.ItemSeq,
           A.LotNo,
           A.ShipDate,
           I.ItemName,
           I.ItemNo,
           I.Spec,
           I.UnitSeq,
           U.UnitName,
           C.CustName,
           A.CustEngName AS EngCustName,
           A.CustSeq,
           S.CustItemName,
           A.QCType,
           Q.QCTypeName,
           A.IsPrint,
           CASE WHEN A.IsPrint = '1' THEN
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010505002)
                ELSE 
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010505001) END AS UMStatusName,
           CASE WHEN A.IsPrint = '1' THEN
                (SELECT MinorSeq FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010505002)
                ELSE 
                (SELECT MinorSeq FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1010505001) END AS UMStatus,
           A.COANo, 
           A.OriWeight, 
           A.TotWeight, 
           A.CreateDate, 
           A.ReTestDate, 
           A.TestResultDate
      FROM KPXLS_TQCCOAPrint AS A
           LEFT OUTER JOIN _TDACust AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq
                                                     AND C.CustSeq = A.CustSeq
           LEFT OUTER JOIN _TDACustAdd AS E WITH(NOLOCK) ON E.CompanySeq = C.CompanySeq
                                                        AND E.CustSeq = C.CustSeq
           LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq
                                                     AND I.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN _TSLCustItem AS S WITH(NOLOCK) ON S.CompanySeq = A.CompanySeq
                                                         AND S.CustSeq = A.CustSeq
                                                         AND S.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = I.CompanySeq
                                                     AND U.UnitSeq = I.UnitSeq
           LEFT OUTER JOIN KPX_TQCQAProcessQCType AS Q WITH(NOLOCK) ON Q.CompanySeq = A.CompanySeq
                                                                   AND Q.QCType = A.QCType
     WHERE A.CompanySeq = @CompanySeq
       AND (@CustName = '' OR C.CustName LIKE @CustName+'%')
       AND (@EngCustName = '' OR E.EngCustName LIKE @EngCustName +'%')
       AND A.COADate BETWEEN @COADateFr AND @COADateTo
       AND (@COANo = '' OR A.COANo LIKE @COANo+'%')
       AND (@ItemName = '' OR I.ItemName LIKE @ItemName+'%')
       AND (@CustItemName = '' OR S.CustItemName LIKE @CustItemName +'%')
       AND (@LotNo = '' OR A.LotNo LIKE @LotNo+'%')
       AND (@QCTypeName = '' OR Q.QCTypeName LIKE @QCTypeName+'%')
    
    RETURN
GO


exec KPXLS_SQCCOAPrintListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <COADateFr>20151201</COADateFr>
    <COADateTo>20151222</COADateTo>
    <CustName />
    <EngCustName />
    <COANo />
    <QCTypeName />
    <ItemName />
    <CustItemName />
    <LotNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034002,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028150