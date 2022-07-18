
IF OBJECT_ID('yw_SPJTIngReportIsStopSave') IS NOT NULL 
    DROP PROC yw_SPJTIngReportIsStopSave
GO

-- v2014.07.10 

-- 프로젝트진행조회_yw(중단여부저장) by이재천 
CREATE PROC dbo.yw_SPJTIngReportIsStopSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    CREATE TABLE #yw_TPJTProject (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTProject'     
    IF @@ERROR <> 0 RETURN  
    
    -- UPDATE    
    UPDATE B
      SET IsStop = A.IsStop 
     FROM #yw_TPJTProject       AS A 
     JOIN yw_TPJTProject        AS B ON ( B.CompanySeq = @CompanySeq AND A.PJTSeq = B.PJTSeq ) 
    WHERE A.Status = 0    
    
    UPDATE A 
       SET Result = CASE WHEN A.IsStop = '0' THEN '중단 취소 되었습니다.' ELSE '중단되었습니다.' END
      FROM #yw_TPJTProject AS A 
    
    SELECT * FROM #yw_TPJTProject 
    
    RETURN 
