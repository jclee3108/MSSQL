  
IF OBJECT_ID('KPX_SHRWelConAmtSave') IS NOT NULL   
    DROP PROC KPX_SHRWelConAmtSave  
GO  
  
-- v2014.11.27  
  
-- 경조사지급기준등록-저장 by 이재천   
CREATE PROC KPX_SHRWelConAmtSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_THRWelConAmt (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelConAmt'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelConAmt')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelConAmt'    , -- 테이블명        
                  '#KPX_THRWelConAmt'    , -- 임시 테이블명        
                  'SMConMutual,ConSeq,WkItemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'SMConMutual,ConSeq,WkItemSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelConAmt WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_THRWelConAmt AS A   
          JOIN KPX_THRWelConAmt AS B ON ( B.CompanySeq = @CompanySeq AND B.SMConMutual = A.SMConMutual AND B.ConSeq = A.ConSeq AND B.WkItemSeq = A.WkItemSeqOld )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelConAmt WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WkItemSeq = A.WkItemSeq, 
               B.Numerator = A.Numerator,  
               B.Denominator = A.Denominator, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_THRWelConAmt AS A   
          JOIN KPX_THRWelConAmt AS B ON ( B.CompanySeq = @CompanySeq AND B.SMConMutual = A.SMConMutual AND B.ConSeq = A.ConSeq AND B.WkItemSeq = A.WkItemSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelConAmt WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THRWelConAmt  
        (   
            CompanySeq,SMConMutual,ConSeq,WkItemSeq,Numerator,  
            Denominator,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.SMConMutual,A.ConSeq,A.WkItemSeq,A.Numerator,  
               A.Denominator,@UserSeq,GETDATE()   
          FROM #KPX_THRWelConAmt AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A
       SET WkItemSeqOld = WkItemSeq
      FROM #KPX_THRWelConAmt AS A 
    
    SELECT * FROM #KPX_THRWelConAmt   
  
    RETURN  