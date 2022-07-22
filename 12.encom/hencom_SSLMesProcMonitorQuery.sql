IF OBJECT_ID('hencom_SSLMesProcMonitorQuery') IS NOT NULL 
    DROP PROC hencom_SSLMesProcMonitorQuery
GO 

-- v2017.03.21 

/************************************************************
   설  명 - 데이터-출하일업무마감모니터링_hencom : 조회
   작성일 - 20160104
   작성자 - 박수영
   수정: 투입자재검증데이터-- 수량으로체크 by박수영2016.03.21
  ************************************************************/
   CREATE PROC dbo.hencom_SSLMesProcMonitorQuery                
   @xmlDocument      NVARCHAR(MAX) ,            
   @xmlFlags         INT  = 0,            
   @ServiceSeq       INT  = 0,            
   @WorkingTag       NVARCHAR(10)= '',                  
   @CompanySeq       INT  = 1,            
   @LanguageSeq      INT  = 1,            
   @UserSeq          INT  = 0,            
   @PgmSeq           INT  = 0         
      
  AS        
   
     DECLARE @docHandle     INT,
             @DeptSeq       INT, 
             @FrStdDate     NCHAR(8), 
             @ToStdDate     NCHAR(8) 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    SELECT @DeptSeq     = ISNULL(DeptSeq,0), 
           @FrStdDate   = ISNULL(FrStdDate,''), 
           @ToStdDate   = ISNULL(ToStdDate,'')

     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH (
             DeptSeq       INT, 
             FrStdDate     NCHAR(8),
             ToStdDate     NCHAR(8) 
          )
    
    -- 기간 날짜 담기 
    SELECT Solar AS StdDate 
      INTO #DateFrTo
      FROM _TCOMCalendar AS A 
     WHERE A.Solar BETWEEN @FrStdDate AND @ToStdDate 
    
    CREATE TABLE #TMPDept 
    (
        DeptSeq INT,
        DispSeq INT, 
        StdDate NCHAR(8)
    )
      
    INSERT #TMPDept(DeptSeq,DispSeq,StdDate)
    SELECT A.DeptSeq,A.DispSeq,B.StdDate
      FROM hencom_TDADeptAdd    AS A 
      LEFT OUTER JOIN #DateFrTo AS B ON ( 1 = 1 )
     WHERE CompanySeq = @CompanySeq
       AND ISNULL(UMTotalDiv,0) <> 0
       AND (@DeptSeq = 0 OR DeptSeq = @DeptSeq)
    
      SELECT 
          (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,
          M.DeptSeq AS DeptSeq,
          M.StdDate, 
          DATENAME(DW,M.StdDate) AS StdDay,
          (SELECT MAX(1) FROM hencom_TSLExpShipment WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND ExpShipDate = M.StdDate) AS IsExpShip, --출하예정등록여부
          (SELECT 1 FROM hencom_TSLWeather WHERE WDate = M.StdDate AND DeptSeq = M.DeptSeq) AS IsWeather ,--날씨등록여부
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportClose WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate) AS IsMesData, --출하자료존재여부
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate) AS IsGroupData,--출하자료 집계처리여부
          (SELECT MAX(1) FROM hencom_TPUSubContrCalc WHERE CompanySeq = @CompanySeq AND WorkDate = M.StdDate AND DeptSeq = M.DeptSeq) AS IsSubContrCalc, --도급운반비정산처리여부
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate AND CfmCode = '1') AS IsMesCfm, --출하자료집계확정여부
          (SELECT MAX(1) FROM hencom_TIFProdMatInputCloseSum 
                          WHERE CompanySeq = @CompanySeq 
                          AND ISNULL(StdUnitQty,0) <>  0 
                          AND SumMesKey IN (SELECT SumMesKey FROM hencom_TIFProdWorkReportCloseSum 
                                                              WHERE CompanySeq = @CompanySeq 
                                                              AND WorkDate = M.StdDate 
                                                              AND DeptSeq = M.DeptSeq)) AS IsMatMapping, --투입자재검증
          (SELECT MAX(1) FROM _TPUDelv WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND DelvDate = M.StdDate) AS IsDelv,--구매납품입력_hncom  
          (SELECT MAX(1) FROM hencom_TPUFuelIn WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND InDate = M.StdDate) AS IsFuelIn, --유류입고 여부
          (SELECT MAX(1) FROM hencom_TPUFuelOut WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND OutDate = M.StdDate) AS IsFuelOut, --유류출고 여부
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate AND (InvIsErpApply = '1' OR ProdIsErpApply = '1') ) AS IsApply --출하자료 ERP반영여부
      FROM #TMPDept AS M
      ORDER BY M.DispSeq, M.StdDate
                
   RETURN
   GO
exec hencom_SSLMesProcMonitorQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FrStdDate>20170205</FrStdDate>
    <DeptSeq />
    <ToStdDate>20170206</ToStdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034211,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028297
