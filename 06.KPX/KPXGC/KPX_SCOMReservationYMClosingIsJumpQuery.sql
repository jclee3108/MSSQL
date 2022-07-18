  
IF OBJECT_ID('KPX_SCOMReservationYMClosingIsJumpQuery') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingIsJumpQuery  
GO  
  
-- v2015.07.28  
  
-- 예약마감관리-점프조회 by 이재천   
CREATE PROC KPX_SCOMReservationYMClosingIsJumpQuery  
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
            @AccUnit        INT, 
            @ClosingYM      NCHAR(6) 
            
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @AccUnit     = ISNULL( AccUnit, 0 ), 
           @ClosingYM   = ISNULL( ClosingYM, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AccUnit        INT, 
            ClosingYM      NCHAR(6)
           )    
    
    SELECT @ClosingYM + '01' AS DateFr, 
           CONVERT(NCHAR(8),DATEADD(DAY, -1, DATEADD(MONTH, 1, @ClosingYM + '01')),112) AS DateTo, 
           (SELECT TOP 1 BizUnit FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND AccUnit = @AccUnit) AS BizUnit, 
           (SELECT TOP 1 BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND AccUnit = @AccUnit) AS BizUnitName, 
           (SELECT TOP 1 AccUnitName FROM _TDAAccUnit WHERE CompanySeq = @CompanySeq AND AccUnit = @AccUnit) AS AccUnitName, 
           @AccUnit AS AccUnit, 
           @ClosingYM + '01' AS QryDateFr, 
           CONVERT(NCHAR(8),DATEADD(DAY, -1, DATEADD(MONTH, 1, @ClosingYM + '01')),112) AS QryDateTo
    
    RETURN  
GO
exec KPX_SCOMReservationYMClosingIsJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ClosingYM>201501</ClosingYM>
    <AccUnit>1</AccUnit>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031128,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025935