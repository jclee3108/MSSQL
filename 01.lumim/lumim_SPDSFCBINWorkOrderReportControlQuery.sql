
IF OBJECT_ID('lumim_SPDSFCBINWorkOrderReportControlQuery') IS NOT NULL
    DROP PROC lumim_SPDSFCBINWorkOrderReportControlQuery
GO

-- v2013.08.06 

-- BIN비움작업및조회_lumim(컨트롤조회) by이재천
CREATE PROC lumim_SPDSFCBINWorkOrderReportControlQuery                
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
		    @THTool     NVARCHAR(100), 
            @EmpId      NVARCHAR(50), 
            @ProdPlanNo NVARCHAR(50)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpId = EmpId, 
           @THTool = THTool, 
           @ProdPlanNo = ProdPlanNo 
            
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            THTool      NVARCHAR(100), 
            EmpId       NVARCHAR(50), 
            ProdPlanNo  NVARCHAR(50)
           )
    
    IF @WorkingTag = 'ProdPlanNo'
    BEGIN
        SELECT B.ItemName, 
               D.MinorName AS ProgramName, 
               A.ItemSeq, 
               A.ProdPlanSeq 
          
          FROM _TPDMPSDailyProdPlan AS A WITH(NOLOCK) 
          LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemClass AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.UMajorItemClass = 2001 ) 
          LEFT OUTER JOIN _TDAUMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.UMItemClass = D.MinorSeq ) 
          LEFT OUTER JOIN _TPDSFCWorkOrder AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ProdPlanSeq = A.ProdPlanSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.ProdPlanNo = RTRIM(@ProdPlanNo)
    END
    
    IF @WorkingTag = 'THTool'
    BEGIN
        SELECT B.ValueText AS BINNo,
               C.ValueText AS Rank
          FROM _TDAUMinor AS A WITH(NOLOCK)
          JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 AND B.ValueText = RIGHT(@THTool,3) )  
          JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000006 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.MajorSeq = 1008247 
    END
    
    IF @WorkingTag = 'EmpId'
    BEGIN
        SELECT A.EmpName, 
               B.PosName AS Position, 
               A.EmpSeq 
          FROM _TDAEmp AS A 
          JOIN _fnAdmEmpOrd( @CompanySeq, CONVERT(NVARCHAR(12),GETDATE(),112)) AS B ON ( B.EmpSeq = A.EmpSeq ) 
         WHERE A.CompanySeq = @COmpanySeq 
           AND B.EmpId = RTRIM(@EmpId)
    END
    RETURN

GO
exec lumim_SPDSFCBINWorkOrderReportControlQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>ProdPlanNo</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ProdPlanNo>201307260013</ProdPlanNo>
    <THTool />
    <EmpId />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016984,@WorkingTag=N'ProdPlanNo',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014493