
IF OBJECT_ID('amoerp_SPRWkRequestSave')IS NOT NULL 
    DROP PROC amoerp_SPRWkRequestSave
GO 
    
-- v2013.10.31 

-- 근태청구원_amoerp(저장) by이재천
CREATE PROC amoerp_SPRWkRequestSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    CREATE TABLE #amoerp_TPRWkRequest (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#amoerp_TPRWkRequest'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('amoerp_TPRWkRequest')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'amoerp_TPRWkRequest'    , -- 테이블명        
                  '#amoerp_TPRWkRequest'    , -- 임시 테이블명        
                  'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  

    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #amoerp_TPRWkRequest WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE amoerp_TPRWkRequest
          FROM #amoerp_TPRWkRequest      AS A 
          JOIN amoerp_TPRWkRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'D' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0  RETURN
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #amoerp_TPRWkRequest WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B 
           SET ETime = A.ETime, 
               STime = A.STime, 
               WkItemSeq = A.WkItemSeq, 
               SDate = A.SDate, 
               EmpSeq = A.EmpSeqS, 
               EDate = A.EDate, 
               ReqDate = A.ReqDate, 
               DeptSeq = A.DeptSeqS, 
               Remark = A.Remark, 
               LastUserSeq = @UserSeq, 
               LastDateTime = GetDate() 
          FROM #amoerp_TPRWkRequest AS A 
          JOIN amoerp_TPRWkRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status     = 0    

        IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #amoerp_TPRWkRequest WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO amoerp_TPRWkRequest (
                                         CompanySeq  , ReqSeq       , ETime   , STime   , WkItemSeq , 
                                         SDate       , EmpSeq       , EDate   , ReqDate , DeptSeq    , 
                                         Remark      , LastUserSeq  , LastDateTime 
                                        ) 
        SELECT @CompanySeq , ReqSeq    , ETime   , STime   , WkItemSeq , 
               SDate       , EmpSeqS   , EDate   , ReqDate , DeptSeqS  , 
               Remark      , @UserSeq  , GetDate() 
          FROM #amoerp_TPRWkRequest AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    

        IF @@ERROR <> 0 RETURN
    END   

    SELECT * FROM #amoerp_TPRWkRequest 
    
    RETURN    
Go