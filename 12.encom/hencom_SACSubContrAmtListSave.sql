  
IF OBJECT_ID('hencom_SACSubContrAmtListSave') IS NOT NULL   
    DROP PROC hencom_SACSubContrAmtListSave  
GO  
  
-- v2017.07.07
  
-- 도급비지급내역-저장 by 이재천
CREATE PROC hencom_SACSubContrAmtListSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACSubContrAmtList (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACSubContrAmtList'   
    IF @@ERROR <> 0 RETURN    


    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACSubContrAmtList')    
        
    EXEC _SCOMLog @CompanySeq   ,        
                    @UserSeq      ,        
                    'hencom_TACSubContrAmtList'    , -- 테이블명        
                    '#hencom_TACSubContrAmtList'    , -- 임시 테이블명        
                    'StdDate,SlipUnit'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                    @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSubContrAmtList WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #hencom_TACSubContrAmtList AS A   
          JOIN hencom_TACSubContrAmtList AS B ON ( B.CompanySeq = @CompanySeq AND A.StdDate = B.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSubContrAmtList WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  


        UPDATE B   
           SET B.SubContrAmt1   = A.SubContrAmt1, 
               B.SubContrAmt2   = A.SubContrAmt2, 
               B.SubContrAmt3   = A.SubContrAmt3, 
               B.SubContrAmt4   = A.SubContrAmt4, 
               B.SubContrAmt5   = A.SubContrAmt5, 
               B.SubContrAmt6   = A.SubContrAmt6, 
               B.DeductAmt1     = A.DeductAmt1, 
               B.DeductAmt2     = A.DeductAmt2, 
               B.DeductAmt3     = A.DeductAmt3, 
               B.DeductAmt4     = A.DeductAmt4, 
               B.DeductAmt5     = A.DeductAmt5, 
               B.DeductAmt6     = A.DeductAmt6, 
               B.ThisMonthAmt   = A.ThisMonthAmt, 
               B.Remark         = A.Remark, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #hencom_TACSubContrAmtList  AS A   
          JOIN hencom_TACSubContrAmtList   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSubContrAmtList WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACSubContrAmtList  
        (   
            CompanySeq, StdDate, SlipUnit, SubContrAmt1, SubContrAmt2, 
            SubContrAmt3, SubContrAmt4, SubContrAmt5, SubContrAmt6, DeductAmt1, 
            DeductAmt2, DeductAmt3, DeductAmt4, DeductAmt5, DeductAmt6, 
            ThisMonthAmt, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, StdDate, SlipUnit, SubContrAmt1, SubContrAmt2, 
            SubContrAmt3, SubContrAmt4, SubContrAmt5, SubContrAmt6, DeductAmt1, 
            DeductAmt2, DeductAmt3, DeductAmt4, DeductAmt5, DeductAmt6, 
            ThisMonthAmt, Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #hencom_TACSubContrAmtList AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_TACSubContrAmtList   
    
    RETURN  
