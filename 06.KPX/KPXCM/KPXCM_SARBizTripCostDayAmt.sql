  
IF OBJECT_ID('KPXCM_SARBizTripCostDayAmt') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostDayAmt  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-일당금계산 by 이재천   
CREATE PROC KPXCM_SARBizTripCostDayAmt  
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
            @TripEmpSeq INT, 
            @CostSeq    INT, 
            @TripFrDate NCHAR(8), 
            @TripToDate NCHAR(8), 
            @Day        INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @TripEmpSeq   = ISNULL( TripEmpSeq, 0 ), 
           @CostSeq      = ISNULL( CostSeq, 0 ), 
           @TripFrDate   = ISNULL( TripFrDate, '' ), 
           @TripToDate   = ISNULL( TripToDate, '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            TripEmpSeq   INT, 
            CostSeq      INT, 
            TripFrDate   NCHAR(8), 
            TripToDate   NCHAR(8) 
            
           )    
    
    SELECT @Day = COUNT(1) 
      FROM _TCOMCalendar AS A 
     WHERE A.Solar BETWEEN @TripFrDate AND @TripToDate
    
    -- 최종조회   
    SELECT D.MinorSeq AS  UMTripKind,
           D.MinorName AS UMTripKindName, 
           (ISNULL(B.Price,0) * @Day) * ( CONVERT(DECIMAL(19,5),C.ValueText) / 100 ) AS Amt, 
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @CostSeq) + ' ' + CONVERT(NVARCHAR(100),@Day) + '일' AS  Remark
      FROM _fnAdmEmpOrd(@CompanySeq, '')    AS A 
      LEFT OUTER JOIN _TARBizTripItem       AS B ON ( B.CompanySeq = @CompanySeq AND B.UMPgSeq = A.UMPgSeq AND B.UMTripItemSeq = 4023001 ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = @CostSeq AND C.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = 1011518001 ) 
     WHERE A.EmpSeq = @TripEmpSeq 
    
    RETURN  
GO 
exec KPXCM_SARBizTripCostDayAmt @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CostSeq>1011517002</CostSeq>
    <TermDay>3</TermDay>
    <TripEmpSeq>2028</TripEmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397