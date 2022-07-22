  
IF OBJECT_ID('hencom_SACSendAmtListSave') IS NOT NULL   
    DROP PROC hencom_SACSendAmtListSave  
GO  
  
-- v2017.07.10
  
-- 전도금내역-저장 by 이재천
CREATE PROC hencom_SACSendAmtListSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACSendAmtList (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACSendAmtList'   
    IF @@ERROR <> 0 RETURN    


    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACSendAmtList')    
        
    EXEC _SCOMLog @CompanySeq   ,        
                    @UserSeq      ,        
                    'hencom_TACSendAmtList'    , -- 테이블명        
                    '#hencom_TACSendAmtList'    , -- 임시 테이블명        
                    'StdDate,SlipUnit'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                    @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSendAmtList WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #hencom_TACSendAmtList AS A   
          JOIN hencom_TACSendAmtList AS B ON ( B.CompanySeq = @CompanySeq AND A.StdDate = B.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSendAmtList WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  


        UPDATE B   
           SET B.Amt1   = A.Amt1, 
               B.Amt2   = A.Amt2, 
               B.Amt3   = A.Amt3, 
               B.Amt4   = A.Amt4, 
               B.Amt5   = A.Amt5, 
               B.Amt6   = A.Amt6, 
               B.Amt7   = A.Amt7, 
               B.Amt8   = A.Amt8, 
               B.Amt9   = A.Amt9, 
               B.Amt10  = A.Amt10, 
               B.Amt11  = A.Amt11, 
               B.Amt12  = A.Amt12, 
               B.Amt13  = A.Amt13, 
               B.Amt14  = A.Amt14, 
               B.Amt15  = A.Amt15, 

               B.Remark         = A.Remark, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #hencom_TACSendAmtList  AS A   
          JOIN hencom_TACSendAmtList   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate AND B.SlipUnit = A.SlipUnit )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACSendAmtList WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACSendAmtList  
        (   
            CompanySeq, StdDate, SlipUnit, Amt1, Amt2, 
            Amt3, Amt4, Amt5, Amt6, Amt7, 
            Amt8, Amt9, Amt10, Amt11, Amt12, 
            Amt13, Amt14, Amt15, Remark, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, StdDate, SlipUnit, Amt1, Amt2, 
               Amt3, Amt4, Amt5, Amt6, Amt7, 
               Amt8, Amt9, Amt10, Amt11, Amt12, 
               Amt13, Amt14, Amt15, Remark, @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #hencom_TACSendAmtList AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_TACSendAmtList   
    
    RETURN  

