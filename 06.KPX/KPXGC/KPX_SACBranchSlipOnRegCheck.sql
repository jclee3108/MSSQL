  
IF OBJECT_ID('KPX_SACBranchSlipOnRegCheck') IS NOT NULL   
    DROP PROC KPX_SACBranchSlipOnRegCheck  
GO  
  
-- v2015.02.25  
  
-- 본지점대체전표생성(건별반제)-체크 by 이재천   
CREATE PROC KPX_SACBranchSlipOnRegCheck  
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
      
    CREATE TABLE #TACSlip( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TACSlip'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #TACSlip   
      
    RETURN  