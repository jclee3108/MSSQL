
IF OBJECT_ID('KPX_SPDSFCProdPackOrderDeleteCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderDeleteCheck  
GO  
  
-- v2014.11.25
  
-- 포장작업지시입력-삭제 체크 by이재천   
CREATE PROC KPX_SPDSFCProdPackOrderDeleteCheck  
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
    
    CREATE TABLE #KPX_TPDSFCProdPackOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrder'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TPDSFCProdPackOrder 
      
    RETURN  
    GO 
    exec KPX_SPDSFCProdPackOrderDeleteCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsCfm>0</IsCfm>
    <PackOrderSeq>11</PackOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349