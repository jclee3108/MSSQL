
IF OBJECT_ID('DTI_SSLInterTransferPJTSave') IS NOT NULL 
    DROP PROC DTI_SSLInterTransferPJTSave
GO 

-- v2014.01.10 

-- 사내대체등록(프로젝트)_DTI(저장) by이재천
CREATE PROC dbo.DTI_SSLInterTransferPJTSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    CREATE TABLE #DTI_TSLInterTransferPJT (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLInterTransferPJT'     
    IF @@ERROR <> 0 RETURN  
    

    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('DTI_TSLInterTransferPJT')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'DTI_TSLInterTransferPJT'    , -- 테이블명        
                  '#DTI_TSLInterTransferPJT'    , -- 임시 테이블명        
                  'InputYM,PJTSeq,ResourceSeq,StdYM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TSLInterTransferPJT WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B 
           SET InterBillingAmt = A.InterBillingAmt, 
               LastUserSeq = @UserSeq, 
               LastDateTime = GetDate() 
          FROM #DTI_TSLInterTransferPJT AS A 
          JOIN DTI_TSLInterTransferPJT  AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.StdYM = A.StdYM 
                                              AND B.InputYM = A.InputYM 
                                              AND B.PJTSeq = A.PJTSeq 
                                              AND B.ResourceSeq = A.ResourceSeq 
                                                )
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    
    
        IF @@ERROR <> 0  RETURN
    END  
    
    SELECT * FROM #DTI_TSLInterTransferPJT 
    
    RETURN    
GO