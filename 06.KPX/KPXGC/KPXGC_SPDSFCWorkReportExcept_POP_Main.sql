IF OBJECT_ID('KPXGC_SPDSFCWorkReportExcept_POP_Main') IS NOT NULL 
    DROP PROC KPXGC_SPDSFCWorkReportExcept_POP_Main
GO 

-- v2016.04.14 

-- POP자재투입 빠른처리를 위해 While로 처리 by이재천 
CREATE PROC KPXGC_SPDSFCWorkReportExcept_POP_Main

AS 

    DECLARE @SrtDate    DATETIME, 
            @EndDate    DATETIME 

    SELECT @SrtDate = GETDATE() 
    
    

    IF NOT EXISTS (
                    SELECT 1
                      FROM KPX_TPDSFCWorkReportExcept_POP 
                     WHERE CompanySeq = 1 and ProcYn IN ( '0', '5' ) 
                       AND CONVERT(NCHAR(8),RegDateTime,112) BETWEEN CONVERT(NCHAR(8),DATEADD(MONTH,-1,GETDATE()),112) AND CONVERT(NCHAR(8),GETDATE(),112)
                  ) 
    BEGIN 
        RETURN 
    END 
    ELSE 
    BEGIN 
        WHILE ( 1 = 1 ) 
        BEGIN 
            
            exec KPXGC_SPDSFCMatInput_POP 1 

            
            SELECT @EndDate = GETDATE()  
            
            
            select @SrtDate,@EndDate, DATEDIFF(minute,@SrtDate,@EndDate)

            
            IF 10 <= (SELECT DATEDIFF(minute,@SrtDate,@EndDate))
            BEGIN 
                BREAK 
            END 
        END 
    END 
    
    /*
    CREATE TABLE #StockSum 
    (
        IDX_NO      INT IDENTITY, 
        CompanySeq  INT, 
        InOutYM     NCHAR(6) 
    )
    
    INSERT INTO #StockSum ( CompanySeq, InOutYM ) 
    SELECT DISTINCT CompanySeq, InOutYM 
      FROM KPXCM_TPDSFCMatInputStockApply 
    
    DECLARE @Cnt        INT, 
            @XmlData    NVARCHAR(MAX) 
    SELECT @Cnt = 1 
    
    IF EXISTS (SELECT 1 FROM #StockSum)  -- 재고재집계 (생산실적) 
    BEGIN 
        WHILE ( 1 = 1 ) 
        BEGIN     
            SELECT @XmlData = '' 
            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT 'U' AS WorkingTag, 
                                                               1 AS IDX_NO, 
                                                               1 AS DataSeq, 
                                                               0 AS Selected, 
                                                               0 AS Status, 
                                                               InOutYM, 
                                                               130 AS SMInOutType, 
                                                               1 AS UserSeq 
                                                          FROM #StockSum 
                                                         WHERE IDX_NO = @Cnt               
                                                           FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                                    ))              
            
            EXEC _SLGReInOutStockSum               
                 @xmlDocument  = @XmlData,              
                 @xmlFlags     = 2,              
                 @ServiceSeq   = 5248,              
                 @WorkingTag   = N'',              
                 @CompanySeq   = 2,              
                 @LanguageSeq  = 1,              
                 @UserSeq      = 1,           
                 @PgmSeq       = 5956        
            
            
            IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #StockSum),0)
            BEGIN
                BREAK 
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
            
        END 
    END 
    */
    -- 재고재집계처리 후 삭제 (KPXCM_SPDSFCWorkReportExcept_POP Sp에서 Insert)
    --TRUNCATE TABLE KPXCM_TPDSFCMatInputStockApply 
    
    RETURN 

--go
--begin tran 
--exec KPXGC_SPDSFCWorkReportExcept_POP_Main
--rollback 


