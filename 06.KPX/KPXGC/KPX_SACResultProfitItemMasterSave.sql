  
IF OBJECT_ID('KPX_SACResultProfitItemMasterSave') IS NOT NULL   
    DROP PROC KPX_SACResultProfitItemMasterSave  
GO  
  
-- v2014.12.20  
  
-- 실현손익상품마스터-저장 by 이재천   
CREATE PROC KPX_SACResultProfitItemMasterSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TACResultProfitItemMaster (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACResultProfitItemMaster'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACResultProfitItemMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACResultProfitItemMaster'    , -- 테이블명        
                  '#KPX_TACResultProfitItemMaster'    , -- 임시 테이블명        
                  'ResultProfitSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACResultProfitItemMaster WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
    
        DELETE B   
          FROM #KPX_TACResultProfitItemMaster AS A   
          JOIN KPX_TACResultProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.ResultProfitSeq = A.ResultProfitSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACResultProfitItemMaster WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMHelpCom = A.UMHelpCom,  
               B.FundSeq = A.FundSeq,  
               B.CancelDate = A.CancelDate,  
               B.CancelAmt = A.CancelAmt,  
               B.CancelResultAmt = A.CancelResultAmt,  
               B.AllCancelDate = A.AllCancelDate,  
               B.AllCancelAmt = A.AllCancelAmt,  
               B.AllCancelResultAmt = A.AllCancelResultAmt,  
               B.SplitDate = A.SplitDate,  
               B.SliptAmt = A.SliptAmt,  
               B.ResultReDate = A.ResultReDate, 
               B.ResultReAmt = A.ResultReAmt, 
               B.ResultAmt = A.ResultAmt,  
               B.Remark1 = A.Remark1,  
               B.Remark2 = A.Remark2,  
               B.Remark3 = A.Remark3,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_TACResultProfitItemMaster AS A   
          JOIN KPX_TACResultProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.ResultProfitSeq = A.ResultProfitSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
   
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACResultProfitItemMaster WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TACResultProfitItemMaster  
        (   
            CompanySeq,ResultProfitSeq,StdDate,UMHelpCom,FundSeq,  
            CancelDate,CancelAmt,CancelResultAmt,AllCancelDate,AllCancelAmt,  
            AllCancelResultAmt,SplitDate,SliptAmt,ResultReDate, ResultReAmt, 
            ResultAmt,Remark1,Remark2,Remark3,LastUserSeq,
            LastDateTime   
        )   
        SELECT @CompanySeq,A.ResultProfitSeq,A.StdDate,A.UMHelpCom,A.FundSeq,  
               A.CancelDate,A.CancelAmt,A.CancelResultAmt,A.AllCancelDate,A.AllCancelAmt,  
               A.AllCancelResultAmt,A.SplitDate,A.SliptAmt,A.ResultReDate, A.ResultReAmt, 
               A.ResultAmt,A.Remark1,A.Remark2,A.Remark3,@UserSeq,
               GETDATE()   
          FROM #KPX_TACResultProfitItemMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TACResultProfitItemMaster   
      
    RETURN  