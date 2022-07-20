  
IF OBJECT_ID('mnpt_SPRWkEmpRepWkConfirmCheck') IS NOT NULL   
    DROP PROC mnpt_SPRWkEmpRepWkConfirmCheck  
GO  
    
-- v2018.01.23  
  
-- 휴일근무신청확정-체크 by 이재천
CREATE PROC mnpt_SPRWkEmpRepWkConfirmCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #mnpt_TPREEWkEmpRepWk( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TPREEWkEmpRepWk'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #mnpt_TPREEWkEmpRepWk   
      
    RETURN  
