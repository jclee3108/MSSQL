
IF OBJECT_ID('lumim_SPDSFCBINWorkOrderReportQuery') IS NOT NULL
    DROP PROC lumim_SPDSFCBINWorkOrderReportQuery
GO

-- v2013.08.06 

-- BIN비움작업및조회_lumim(조회) by이재천
CREATE PROC lumim_SPDSFCBINWorkOrderReportQuery 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    	
    DECLARE @docHandle      INT,
            @ProdPlanNo     NVARCHAR(100),
            @THTool         NVARCHAR(50),
            @LastDateTimeFr NVARCHAR(10),
            @BINNo          NVARCHAR(100),
            @EmpName        NVARCHAR(100),
            @ProgramName    NVARCHAR(100),
            @LastDateTimeTo NVARCHAR(10)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ProdPlanNo      = ProdPlanNo       ,
           @THTool          = THTool           ,
           @LastDateTimeFr  = LastDateTimeFr      ,
           @BINNo           = BINNo            ,
           @EmpName         = EmpName          ,
           @ProgramName     = ProgramName      ,
           @LastDateTimeTo  = LastDateTimeTo      
           
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            ProdPlanNo       NVARCHAR(100) ,
            THTool           NVARCHAR(50) ,
            LastDateTimeFr  NVARCHAR(10) ,
            BINNo            NVARCHAR(100) ,
            EmpName          NVARCHAR(100) ,
            ProgramName      NVARCHAR(100) ,
            LastDateTimeTo  NVARCHAR(10)
           )
    
    SELECT A.BINWorkOrderSeq, 
           B.ItemName, 
           D.MinorName AS ProgramName, 
           A.THTool, 
           A.BINNo, 
           H.ValueText AS RANK,
           H.ValueText AS PrintRank,
           E.EmpId,
           E.EmpName,
           E.PosName AS Position, 
           A.Qty,
           CONVERT(NVARCHAR(20),A.LastDateTime,20) AS LastDateTime,
           A.BINWorkOrderNo,
           A.ProdPlanSeq, 
           F.ProdPlanNo 
    
      FROM lumim_TPDSFCBINWorkOrder AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAItem      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemClass AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.UMajorItemClass = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.UMItemClass = D.MinorSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd( @CompanySeq, CONVERT(NVARCHAR(12),GETDATE(),112)) AS E ON ( E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ProdPlanSeq = A.ProdPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ValueSeq = D.MinorSeq AND G.Serl = 1000005 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000006 ) 
    
     WHERE A.CompanySeq = @CompanySeq
       AND (CONVERT(NVARCHAR(10),A.LastDateTime,112) BETWEEN @LastDateTimeFr AND @LastDateTimeTo)
       AND (@ProdPlanNo = '' OR F.ProdPlanNo LIKE @ProdPlanNo + '%')
       AND (@THTool = '' OR A.THTool LIKE @THTool + '%')  
       AND (@BINNo = '' OR A.BINNo LIKE @BINNo + '%')
       AND (@EmpName = '' OR E.EmpName LIKE @EmpName + '%')
       AND (@ProgramName = '' OR D.MinorName LIKE @ProgramName + '%')
    
    RETURN
GO
exec lumim_SPDSFCBINWorkOrderReportQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <LastDateTimeFr>20130801</LastDateTimeFr>
    <LastDateTimeTo>20130809</LastDateTimeTo>
    <BINNo />
    <THTool />
    <ProdPlanNo />
    <ProgramName />
    <EmpName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016984,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014493