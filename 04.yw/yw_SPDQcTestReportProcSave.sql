    
IF OBJECT_ID('yw_SPDQcTestReportProcSave') IS NOT NULL 
    DROP PROC yw_SPDQcTestReportProcSave 
GO 

-- v2013.07.18 
    
-- 공정검사입력_YW(저장) by이재천 
CREATE PROC yw_SPDQcTestReportProcSave 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    CREATE TABLE #YW_TPDQCTestReport( WorkingTag NCHAR(1) NULL ) 
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDQCTestReport' 
    IF @@ERROR <> 0 RETURN 
    
    CREATE TABLE #YW_TPDQCTestReportSub( WorkingTag NCHAR(1) NULL ) 
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#YW_TPDQCTestReportSub' 
    IF @@ERROR <> 0 RETURN 
    
    -- 로그 남기기 
    DECLARE @TableColumns NVARCHAR(4000) 
    
    IF EXISTS ( SELECT 1 FROM #YW_TPDQCTestReport ) 
    BEGIN 
        -- Master 로그 
        SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDQCTestReport') 
        
        EXEC _SCOMLog @CompanySeq   , 
                      @UserSeq      , 
                      'YW_TPDQCTestReport'    , -- 테이블명 
                      '#YW_TPDQCTestReport'    , -- 임시 테이블명 
                      'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 ) 
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 
  
        -- 작업순서 : DELETE -> UPDATE -> INSERT 
        
        -- 컨트롤 DELETE, UPDATE, INSERT -- 
        
        -- DELETE 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReport WHERE WorkingTag = 'D' AND Status = 0 ) 
        BEGIN 
            DELETE B 
              FROM #YW_TPDQCTestReport AS A 
              JOIN YW_TPDQCTestReport AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq ) 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN 
        END 
        
        -- UPDATE 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReport WHERE WorkingTag = 'U' AND Status = 0 ) 
        BEGIN 
            UPDATE B 
               SET B.QCDate       = A.QCDate, 
                   B.ProdQty      = A.ProdQty, 
                   B.LastUserSeq  = @UserSeq, 
                   B.LastDateTime = GETDATE() 
              FROM #YW_TPDQCTestReport AS A 
              JOIN YW_TPDQCTestReport  AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq ) 
             WHERE A.WorkingTag = 'U' 
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN 
        END 
        
        -- INSERT 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReport WHERE WorkingTag = 'A' AND Status = 0 ) 
        BEGIN 
            INSERT INTO YW_TPDQCTestReport 
            ( 
                CompanySeq  , QCSeq       , QCDate      , QCHour      , --QCNo        , 
                SourceType  , SourceSeq   , SourceSerl  , ProdQty     , LastUserSeq , LastDateTime 
            ) 
            SELECT @CompanySeq, A.QCSeq, A.QCDate, '', 
                   '2', A.WorkOrderSeq, A.WorkOrderSerl, A.ProdQty, @UserSeq, GETDATE() 
              FROM #YW_TPDQCTestReport AS A 
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0 
            
            IF @@ERROR <> 0 RETURN 
            
        END 
    END 
    
    IF EXISTS ( SELECT 1 FROM #YW_TPDQCTestReportSub ) 
    BEGIN 
        SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDQCTestReportSub') 
        
        EXEC _SCOMLog @CompanySeq     , 
                      @UserSeq        , 
                      'YW_TPDQCTestReportSub', 
                      '#YW_TPDQCTestReportSub'  , 
                      'QCSeq,UMQcTitleSeq,Serl'     , -- CompanySeq제외 한 키 
                        @TableColumns   , 'QCSeq,UMQcTitleSeqOld,Serl', @PgmSeq 
        
        -- 시트 DELETE, UPDATE, INSERT -- 
        
        -- DELETE 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReportSub WHERE WorkingTag = 'D' AND Status = 0 ) 
        BEGIN 
            DELETE B 
              FROM #YW_TPDQCTestReportSub AS A 
              JOIN YW_TPDQCTestReportSub AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq AND B.UMQcTitleSeq = A.UMQcTitleSeqOld AND B.Serl = A.Serl ) 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN 
        END 
        
        -- UPDATE 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReportSub WHERE WorkingTag = 'U' AND Status = 0 ) 
        BEGIN 
            UPDATE B 
               SET B.UMQcTitleSeq = A.UMQcTitleSeq, 
                   B.TestValue    = A.TestValue, 
                   B.SMTestResult = A.SMTestResult, 
                   B.QCQty        = A.QCQty, 
                   B.LastUserSeq  = @UserSeq, 
                   B.LastDateTime = GETDATE() 
              FROM #YW_TPDQCTestReportSub AS A 
              JOIN YW_TPDQCTestReportSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq AND B.UMQCTitleSeq = A.UMQCTitleSeqOld AND B.Serl = A.Serl ) 
             WHERE A.WorkingTag = 'U' 
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN 
        END 
        
        -- INSERT 
        IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDQCTestReportSub WHERE WorkingTag = 'A' AND Status = 0 ) 
        BEGIN 
            INSERT INTO YW_TPDQCTestReportSub 
            ( 
                CompanySeq , QCSeq , UMQcTitleSeq , Serl         , SMTestResult, 
                TestValue  , QCQty , LastUserSeq  , LastDateTime 
            ) 
            SELECT @CompanySeq , A.QCSeq , A.UMQcTitleSeq, 1, A.SMTestResult, 
                   A.TestValue , A.QCQty , @UserSeq, GETDATE() 
              FROM #YW_TPDQCTestReportSub AS A 
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0 
        
            IF @@ERROR <> 0 RETURN 
        END 
        
        UPDATE #YW_TPDQCTestReportSub 
           SET UMQcTitleSeqOld = UMQcTitleSeq, 
               Serl =1 
         WHERE WorkingTag IN ('A','U') 
           AND Status = 0 
    END 
    SELECT * FROM #YW_TPDQCTestReport 
    SELECT * FROM #YW_TPDQCTestReportSub 
    
    RETURN 
GO 