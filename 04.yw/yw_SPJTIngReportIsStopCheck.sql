
IF OBJECT_ID('yw_SPJTIngReportIsStopCheck') IS NOT NULL 
    DROP PROC yw_SPJTIngReportIsStopCheck
GO 

-- v2014.07.10 

-- 프로젝트진행조회_yw(중단여부체크) by이재천 
CREATE PROC dbo.yw_SPJTIngReportIsStopCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #yw_TPJTProject (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTProject'
    
    SELECT * FROM #yw_TPJTProject 
    
    RETURN    
GO
exec yw_SPJTIngReportIsStopCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>1</IsStop>
    <Result />
    <PJTSeq>20</PJTSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023492,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019727