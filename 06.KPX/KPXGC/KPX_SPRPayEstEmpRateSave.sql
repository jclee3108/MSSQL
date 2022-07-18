  
IF OBJECT_ID('KPX_SPRPayEstEmpRateSave') IS NOT NULL   
    DROP PROC KPX_SPRPayEstEmpRateSave  
GO  
  
-- v2014.12.15  
  
-- 급여추정 개인별인상율-저장 by 이재천   
CREATE PROC KPX_SPRPayEstEmpRateSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPRPayEstEmpRate (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayEstEmpRate'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRPayEstEmpRate')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRPayEstEmpRate'    , -- 테이블명        
                  '#KPX_TPRPayEstEmpRate'    , -- 임시 테이블명        
                  'YY,EmpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'YY,EmpSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstEmpRate WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN  
          
        DELETE B   
          FROM #KPX_TPRPayEstEmpRate AS A   
          JOIN KPX_TPRPayEstEmpRate AS B ON ( B.CompanySeq = @CompanySeq AND A.YY = B.YY AND A.EmpSeqOld = B.EmpSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstEmpRate WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.EmpSeq   = A.EmpSeq,  
               B.EstRate   = A.EstRate,  
               B.AddRate   = A.AddRate,  
               B.Remark   = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
          FROM #KPX_TPRPayEstEmpRate AS A   
          JOIN KPX_TPRPayEstEmpRate AS B ON ( B.CompanySeq = @CompanySeq AND A.YY = B.YY AND A.EmpSeqOld = B.EmpSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstEmpRate WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPRPayEstEmpRate  
        (   
            CompanySeq, YY, EmpSeq, EstRate, AddRate, 
            Remark, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.YY, A.EmpSeq, A.EstRate, A.AddRate, 
               A.Remark, @UserSeq, GETDATE()
          FROM #KPX_TPRPayEstEmpRate AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    UPDATE A
       SET EmpSeqOld = EmpSeq 
      FROM #KPX_TPRPayEstEmpRate AS A 
    
    SELECT * FROM #KPX_TPRPayEstEmpRate   
    
    RETURN  