
IF OBJECT_ID('_SSEBracerListQueryCHE') IS NOT NULL 
    DROP PROC _SSEBracerListQueryCHE
GO 

-- v2015.07.30 

/************************************************************
  설  명 - 데이터-보호구일괄지급 : 리스트조회
  작성일 - 20110329
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC [dbo].[_SSEBracerListQueryCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
      DECLARE @docHandle    INT,
             @GiveType     INT ,
             @EmpSeq       INT ,
             @BrKind       INT ,
             @BrType       INT ,
             @BrSize       INT ,
             @DeptSeq      INT ,
             @GiveDateFrom NCHAR(8) ,
             @GiveDateTo   NCHAR(8), 
             @BizUnit       INT 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @GiveType     = ISNULL(GiveType,0)      ,
             @EmpSeq       = ISNULL(EmpSeq,0)        ,
             @BrKind       = ISNULL(BrKind,0)        ,
             @BrType       = ISNULL(BrType,0)        ,
             @BrSize       = ISNULL(BrSize,0)        ,
             @DeptSeq      = ISNULL(DeptSeq,0)       ,
             @GiveDateFrom = ISNULL(GiveDateFrom,'')  ,
             @GiveDateTo   = ISNULL(GiveDateTo,''), 
             @BizUnit      = ISNULL(BizUnit,0)  
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (GiveType      INT ,
             EmpSeq         INT ,
             BrKind         INT ,
             BrType         INT ,
             BrSize         INT ,
             DeptSeq        INT ,
             GiveDateFrom   NCHAR(8) ,
             GiveDateTo     NCHAR(8), 
             BizUnit        INT )
             
     SELECT  A.BracerSeq  ,
             A.GiveType   ,
             A.GiveTypeName,
             A.EmpSeq     ,
             A.EmpName    ,
             A.DeptSeq    ,
             A.DeptName,
             A.BrKind     ,
             A.BrKindName ,
             A.BrType     ,
             A.BrTypeName ,
             A.GiveDate   ,
             A.GiveCnt    ,
             A.BrSize     ,
             A.BrSizeName ,
             A.Remark,
             A.BizUnit, 
             A.BizUnitName 
       FROM (SELECT  A.BracerSeq  ,
                     A.GiveType   ,
                     B.MinorName AS GiveTypeName,
                     A.EmpSeq     ,
                     C.EmpName    ,
                     C.DeptSeq    ,
                     C.DeptName,
                     A.BrKind     ,
                     D.MinorName AS BrKindName ,
                     A.BrType     ,
                     E.MinorName AS BrTypeName ,
                     A.GiveDate   ,
                     A.GiveCnt    ,
                     A.BrSize     ,
                     F.MinorName AS BrSizeName ,
                     A.Remark, 
                     G.BizUnit, 
                     H.BizUnitName 
               FROM  _TSEBracerCHE AS A WITH (NOLOCK)
                     LEFT OUTER JOIN _TDAUMinor  AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.GiveType = B.MinorSeq
                     LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,CONVERT(CHAR(8),GETDATE(),112)) AS C ON A.EmpSeq= C.EmpSeq
                     LEFT OUTER JOIN _TDAUMinor  AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.BrKind   = D.MinorSeq
                     LEFT OUTER JOIN _TDAUMinor  AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.BrType   = E.MinorSeq
                     LEFT OUTER JOIN _TDAUMinor  AS F WITH (NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.BrSize   = F.MinorSeq
                     LEFT OUTER JOIN _TDADept    AS G WITH (NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = C.DeptSeq ) 
                     LEFT OUTER JOIN _TDABizUnit AS H WITH (NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.BizUnit = G.BizUnit ) 
              WHERE  A.CompanySeq = @CompanySeq
                AND  (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
                AND  (@BrKind = 0 OR A.BrKind = @BrKind)
                AND  (@BrType = 0 OR A.BrType = @BrType)
                AND  (@BrSize = 0 OR A.BrSize = @BrSize)
                AND  A.GiveDate BETWEEN @GiveDateFrom AND @GiveDateTo      
                AND ( @BizUnit = 0 OR G.BizUnit = @BizUnit )            
            ) AS A
      WHERE (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
      RETURN
      GO
      exec _SSEBracerListQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BIzUnit />
    <GiveDateFrom>20150701</GiveDateFrom>
    <GiveDateTo>20150730</GiveDateTo>
    <DeptSeq />
    <EmpSeq />
    <GiveType />
    <BrKind />
    <BrType />
    <BrSize />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10008,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100117