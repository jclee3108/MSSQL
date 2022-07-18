  
IF OBJECT_ID('KPX_SPRPayEstGrpRateSave') IS NOT NULL   
    DROP PROC KPX_SPRPayEstGrpRateSave  
GO  
  
 --v2014.12.15  
  
-- 급여추정 직급별인상율-저장 by 이재천   
CREATE PROC KPX_SPRPayEstGrpRateSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPRPayEstGrpRate (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayEstGrpRate'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRPayEstGrpRate')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRPayEstGrpRate'    , -- 테이블명        
                  '#KPX_TPRPayEstGrpRate'    , -- 임시 테이블명        
                  'YY,UMPayType,UMPgSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'YY,UMPayType,UMPgSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstGrpRate WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TPRPayEstGrpRate AS A   
          JOIN KPX_TPRPayEstGrpRate AS B ON ( B.CompanySeq = @CompanySeq AND B.YY = A.YY AND B.UMPayType = A.UMPayType AND B.UMPgSeq = A.UMPgSeqOld )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstGrpRate WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMPgSeq = A.UMPgSeq,  
               B.EstRate = A.EstRate,  
               B.AddRate = A.AddRate,  
               B.Remark = A.Remark,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TPRPayEstGrpRate AS A   
          JOIN KPX_TPRPayEstGrpRate AS B ON ( B.CompanySeq = @CompanySeq AND B.YY = A.YY AND B.UMPayType = A.UMPayType AND B.UMPgSeq = A.UMPgSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstGrpRate WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPRPayEstGrpRate  
        (   
            CompanySeq,YY,UMPayType,UMPgSeq,EstRate,  
            AddRate,Remark,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.YY,A.UMPayType,A.UMPgSeq,A.EstRate,  
               A.AddRate,A.Remark,@UserSeq,GETDATE()   
          FROM #KPX_TPRPayEstGrpRate AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET UMPgSeqOld = UMPgSeq 
      FROM #KPX_TPRPayEstGrpRate AS A 
           
    SELECT * FROM #KPX_TPRPayEstGrpRate   
      
    RETURN  