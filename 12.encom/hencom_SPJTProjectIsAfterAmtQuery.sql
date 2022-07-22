 
IF OBJECT_ID('hencom_SPJTProjectIsAfterAmtQuery') IS NOT NULL   
    DROP PROC hencom_SPJTProjectIsAfterAmtQuery  
GO  
  
-- v2017.03.23
  
-- 현장추가정보등록_HNCOM-후불여부 by 이재천
CREATE PROC hencom_SPJTProjectIsAfterAmtQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @UMPayType  INT, 
            @IsAfterAmt NCHAR(1) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @UMPayType = ISNULL( UMPayType, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( UMPayType   INT )    
    

    
    SELECT @IsAfterAmt = ValueText
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.Serl = 1000002 
       AND A.MinorSeq = @UMPayType 
    
    SELECT ISNULL(@IsAfterAmt,0) AS IsAfterAmt

    RETURN  
    go
    exec hencom_SPJTProjectIsAfterAmtQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMPayType>1011589003</UMPayType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032047,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026564