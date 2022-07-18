  
IF OBJECT_ID('KPX_SCOMReservationYMClosingQuery') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingQuery  
GO  
  
-- v2015.07.28  
  
-- 예약마감관리-조회 by 이재천   
CREATE PROC KPX_SCOMReservationYMClosingQuery  
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
            @ClosingYear    NCHAR(4)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ClosingYear     = ISNULL( ClosingYear, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ClosingYear    NCHAR(4)
           )    
    
    CREATE TABLE #YM 
    (
        YM          NCHAR(6), 
        AccUnit     INT 
    )
    
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '01', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
    
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '02', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '03', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '04', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '05', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '06', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '07', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '08', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '09', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '10', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '11', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
     
    INSERT INTO #YM ( YM, AccUnit ) 
    SELECT @ClosingYear + '12', A.AccUnit 
      FROM _TDAAccUnit AS A 
     WHERE A.CompanySeq = @CompanySeq 
    
    
    SELECT A.YM AS ClosingYM, 
           C.AccUnitName, 
           A.AccUnit, 
           B.ReservationDate, 
           B.ReservationTime, 
           CASE WHEN LTRIM(RTRIM(B.ProcDate)) = '실패' THEN LTRIM(RTRIM(B.ProcDate)) 
                ELSE STUFF(STUFF(STUFF(STUFF(B.ProcDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') 
                END AS ProcDate, 
           B.ProcResult, 
           B.ClosingSeq, 
           B.IsCancel 

      FROM #YM AS A 
      LEFT OUTER JOIN KPX_TCOMReservationYMClosing  AS B ON ( B.CompanySeq = @CompanySeq AND B.AccUnit = A.AccUnit AND B.ClosingYM = A.YM ) 
      LEFT OUTER JOIN _TDAAccUnit                   AS C ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.AccUnit ) 
    
    RETURN  
GO
exec KPX_SCOMReservationYMClosingQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ClosingYear>2015</ClosingYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031128,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025935