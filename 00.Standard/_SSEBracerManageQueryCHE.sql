IF OBJECT_ID('_SSEBracerManageQueryCHE') IS NOT NULL 
    DROP PROC _SSEBracerManageQueryCHE
GO 

-- v2015.07.13 
/************************************************************  
  설  명 - 데이터-보호구일괄지급 : 조회  
  작성일 - 20110328  
  작성자 - 박헌기  
 ************************************************************/  
 CREATE PROC [dbo].[_SSEBracerManageQueryCHE]  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT             = 0,  
     @ServiceSeq     INT             = 0,  
     @WorkingTag     NVARCHAR(10)    = '',  
     @CompanySeq     INT             = 1,  
     @LanguageSeq    INT             = 1,  
     @UserSeq        INT             = 0,  
     @PgmSeq         INT             = 0  
 AS  
       
     DECLARE @docHandle      INT ,  
             @BrKind         INT ,  
             @BrType         INT ,  
             @GiveDate       NCHAR(8)   
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
   
     SELECT  @BrKind       = BrKind        ,  
             @BrType       = BrType        ,  
             @GiveDate     = GiveDate          
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
       WITH  (BrKind        INT ,  
              BrType        INT ,  
              GiveDate      NCHAR(8)  )  
     
       
     SELECT  A.BracerSeq  ,   
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
             A.Remark      
       FROM  _TSEBracerCHE AS A WITH (NOLOCK)  
             LEFT OUTER JOIN _TDAUMinor  AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.GiveType = B.MinorSeq  
             LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,CONVERT(CHAR(8),GETDATE(),112)) AS C ON A.EmpSeq= C.EmpSeq  
             LEFT OUTER JOIN _TDAUMinor  AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.BrKind   = D.MinorSeq  
             LEFT OUTER JOIN _TDAUMinor  AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.BrType   = E.MinorSeq  
             LEFT OUTER JOIN _TDAUMinor  AS F WITH (NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.BrSize   = F.MinorSeq  
      WHERE  A.CompanySeq = @CompanySeq  
        AND  A.GiveType   = 20064002  
        AND  A.BrKind     = @BrKind      
        AND  A.BrType     = @BrType     
        AND  A.GiveDate   = @GiveDate       
   
     RETURN
GO
exec _SSEBracerManageQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <GiveDate>20150713</GiveDate>
    <BrKind>20057003</BrKind>
    <BrType>20058001</BrType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10008,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100114


