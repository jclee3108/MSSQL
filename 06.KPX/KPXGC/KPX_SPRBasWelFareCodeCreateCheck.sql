  
IF OBJECT_ID('KPX_SPRBasWelFareCodeCreateCheck') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeCreateCheck  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-기간생성 체크 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeCreateCheck  
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
    
    CREATE TABLE #KPX_THRWelCodeYearItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelCodeYearItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크 1, 왼쪽 시트를 선택 해 주시기 바랍니다.
    UPDATE A
       SET Result = '왼쪽 시트를 선택 해 주시기 바랍니다.', 
           MessageType = 1234, 
           Status = 1234 
           
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND (A.SMRegType = 0 OR A.SubWelCodeSeq = 0 OR A.SubWelCodeName = '')
    -- 체크 1, END 
    
    
    -- 체크 2, 이미 생성된 데이터가 있습니다.
    IF EXISTS (SELECT 1 
                 FROM KPX_THRWelCodeYearItem AS A 
                 JOIN #KPX_THRWelCodeYearItem AS B ON ( B.YY = A.YY AND B.SubWelCodeSeq = A.WelCodeSeq ) 
                WHERE A.CompanySeq = @CompanySeq 
              ) 
    BEGIN
        UPDATE A
       SET Result = '이미 생성된 데이터가 있습니다.', 
           MessageType = 1234, 
           Status = 1234     
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
    END 
    -- 체크 2, END 
    
    -- 체크 3, 해당 년도는 필수입니다.
    UPDATE A
       SET Result = '해당 년도는 필수입니다.', 
           MessageType = 1234, 
           Status = 1234     
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND A.YY = '' 
    -- 체크 2, END 
    
    SELECT * FROM #KPX_THRWelCodeYearItem 
    
    RETURN  
GO 
exec KPX_SPRBasWelFareCodeCreateCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SubWelCodeName>복리후생명</SubWelCodeName>
    <YY>2014</YY>
    <SubWelCodeSeq>10</SubWelCodeSeq>
    <SMRegType>3226002</SMRegType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026356,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021406