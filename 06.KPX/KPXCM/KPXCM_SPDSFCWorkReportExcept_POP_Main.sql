IF OBJECT_ID('KPXCM_SPDSFCWorkReportExcept_POP_Main') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportExcept_POP_Main
GO 

-- v2016.04.14 

-- POP자재투입 빠른처리를 위해 While로 처리 by이재천 
CREATE PROC KPXCM_SPDSFCWorkReportExcept_POP_Main

AS 

    DECLARE @SrtDate    DATETIME, 
            @EndDate    DATETIME 

    SELECT @SrtDate = GETDATE() 
    
    

    IF NOT EXISTS (
                    SELECT 1
                      FROM KPX_TPDSFCWorkReportExcept_POP 
                     WHERE CompanySeq = 2 and ProcYn IN ( '0', '5' ) 
                       AND CONVERT(NCHAR(8),RegDateTime,112) BETWEEN CONVERT(NCHAR(8),DATEADD(MONTH,-1,GETDATE()),112) AND CONVERT(NCHAR(8),GETDATE(),112)
                  ) 
    BEGIN 
        RETURN 
    END 
    ELSE 
    BEGIN 
        WHILE ( 1 = 1 ) 
        BEGIN 
            
            exec KPXCM_SPDSFCWorkReportExcept_POP 2

            
            SELECT @EndDate = GETDATE()  
            
            
            select @SrtDate,@EndDate, DATEDIFF(minute,@SrtDate,@EndDate)

            
            IF 10 <= (SELECT DATEDIFF(minute,@SrtDate,@EndDate))
            BEGIN 
                BREAK 
            END 
        END 
    END 
    
RETURN 

go
begin tran 
exec KPXCM_SPDSFCWorkReportExcept_POP_Main
rollback 



