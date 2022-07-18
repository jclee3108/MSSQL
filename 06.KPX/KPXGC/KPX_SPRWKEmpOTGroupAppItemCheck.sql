  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppItemCheck') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppItemCheck  
GO  
  
-- v2014.12.17  
  
-- OT일괄신청- 품목 체크 by 이재천   
CREATE PROC KPX_SPRWKEmpOTGroupAppItemCheck  
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
    
    CREATE TABLE #KPX_TPRWKEmpOTGroupAppEmp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPRWKEmpOTGroupAppEmp'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TPRWKEmpOTGroupAppEmp   
    
    RETURN  