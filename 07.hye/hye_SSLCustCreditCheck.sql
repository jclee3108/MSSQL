   
IF OBJECT_ID('hye_SSLCustCreditCheck') IS NOT NULL     
    DROP PROC hye_SSLCustCreditCheck    
GO    
    
-- v2016.08.29  
    
-- 거래처별여신한도등록_hye-체크 by 이재천   
CREATE PROC hye_SSLCustCreditCheck    
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
        
    CREATE TABLE #hye_TDACustLimitInfo( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hye_TDACustLimitInfo'     
    IF @@ERROR <> 0 RETURN       
    
    DECLARE @MaxSerl INT 

    SELECT @MaxSerl = MAX(A.LimitSerl)
      FROM hye_TDACustLimitInfo AS A 
    WHERE A.CompanySeq = @CompanySeq 
      AND EXISTS (SELECT 1 FROM #hye_TDACustLimitInfo WHERE CustSeq = A.CustSeq) 
    
    UPDATE A
       SET LimitSerl = ISNULL(@MaxSerl,0) + A.DataSeq 
      FROM #hye_TDACustLimitInfo AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    SELECT * FROM #hye_TDACustLimitInfo 
    
    RETURN   
    GO
    exec hye_SSLCustCreditCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsCfm>0</IsCfm>
    <LimitKindName>순수신용</LimitKindName>
    <LimitAmt>1</LimitAmt>
    <SrtDate>20160801</SrtDate>
    <EndDate>20160802</EndDate>
    <Remark />
    <LimitSerl>0</LimitSerl>
    <CustSeq>0</CustSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730094,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730020