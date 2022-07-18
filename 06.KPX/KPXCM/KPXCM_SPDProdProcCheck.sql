  
IF OBJECT_ID('KPXCM_SPDProdProcCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDProdProcCheck  
GO  
  
-- v2016.03.07 
  
-- 제품별생산소요등록-체크 by 이재천  
CREATE PROC KPXCM_SPDProdProcCheck  
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
      
    CREATE TABLE #KPX_TPDProdProc( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDProdProc'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TPDProdProc   
      
    RETURN  
Go
begin tran 
exec KPXCM_SPDProdProcCheck @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1035598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029315
rollback  