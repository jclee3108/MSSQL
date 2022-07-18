  
IF OBJECT_ID('KPX_SSLDelvItemPriceCheck') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceCheck  
GO  
  
-- v2014.11.12  
  
-- 거래처별납품처단가등록-체크 by 이재천   
CREATE PROC KPX_SSLDelvItemPriceCheck  
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
      
    CREATE TABLE #KPX_TSLDelvItemPrice( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLDelvItemPrice'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------------------
    -- 체크1, 중복여부 체크 
    ------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #KPX_TSLDelvItemPrice
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TSLDelvItemPrice AS A  
      JOIN (SELECT S.CustSeq, S.DVPlaceSeq, S.ItemSeq, S.UnitSeq, S.CurrSeq, S.SDate
              FROM (SELECT A1.CustSeq, A1.DVPlaceSeq, A1.ItemSeq, A1.UnitSeq, A1.CurrSeq, A1.SDate
                      FROM #KPX_TSLDelvItemPrice AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.CustSeq, A1.DVPlaceSeq, A1.ItemSeq, A1.UnitSeq, A1.CurrSeq, A1.SDate
                      FROM KPX_TSLDelvItemPrice AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TSLDelvItemPrice   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND CustSeq = A1.CustSeq 
                                                 AND DVPlaceSeq = A1.DVPlaceSeq 
                                                 AND ItemSeq = A1.ItemSeq 
                                                 AND UnitSeq = A1.UnitSeq 
                                                 AND CurrSeq = A1.CurrSeq 
                                                 AND SDate = A1.SDate
                                      )  
                   ) AS S  
             GROUP BY S.CustSeq, S.DVPlaceSeq, S.ItemSeq, S.UnitSeq, S.CurrSeq, S.SDate 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.CustSeq = B.CustSeq AND A.DVPlaceSeq = B.DVPlaceSeq AND A.ItemSeq = B.ItemSeq AND A.UnitSeq = B.UnitSeq AND A.CurrSeq = B.CurrSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    ------------------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------
    -- 체크2, 최종 데이터만을 수정/삭제할 수 있습니다.
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM #KPX_TSLDelvItemPrice WHERE Status = 0 AND WorkingTag IN ( 'D','U' ) AND EDate <> '99991231') 
    BEGIN
        UPDATE A
           SET Result = '최종 데이터만을 수정/삭제할 수 있습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TSLDelvItemPrice AS A 
         WHERE Status = 0 
    END 
    ------------------------------------------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------
    -- 체크3, 적용시작일이 최종단가의 적용시작일보다 커야 합니다. 
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1
                 FROM #KPX_TSLDelvItemPrice AS A 
                 OUTER APPLY (SELECT MAX(Y.SDate) AS MaxSDate, Z.CustSeq, Z.DVPlaceSeq, Z.UnitSeq, Z.ItemSeq 
                                FROM #KPX_TSLDelvItemPrice AS Z 
                                JOIN KPX_TSLDelvItemPrice  AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.CustSeq = Z.CustSeq AND Y.DVPlaceSeq = Z.DVPlaceSeq AND Y.UnitSeq = Z.UnitSeq AND Y.ItemSeq = Z.ItemSeq ) 
                               WHERE Z.CustSeq = A.CustSeq 
                                 AND Z.DVPlaceSeq = A.DVPlaceSeq 
                                 AND Z.UnitSeq = A.UnitSeq 
                                 AND Z.ItemSeq = A.ItemSeq 
                               GROUP BY Z.CustSeq, Z.DVPlaceSeq, Z.UnitSeq, Z.ItemSeq 
                             ) AS B 
                WHERE A.Status = 0 
                  AND A.WorkingTag IN ( 'A', 'U' ) 
                  AND A.SDate <= B.MaxSDate 
              )
    BEGIN
        UPDATE A
           SET Result = '적용시작일이 최종단가의 적용시작일보다 커야 합니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TSLDelvItemPrice AS A 
         WHERE Status = 0 
    END 
    
    ------------------------------------------------------------------------------------------
    -- 체크3, END 
    ------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------
    -- 번호+코드 따기 :           
    ------------------------------------------------------------------------------------------
    DECLARE @Count  INT,  
            @Seq    INT   
    
    SELECT @Count = COUNT(1) FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TSLDelvItemPrice', 'DVItemPriceSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TSLDelvItemPrice  
           SET DVItemPriceSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END 
    
    ------------------------------------------------------------------------------------------
    -- 내부코드 0값 일 때 에러처리   
    ------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
    
    UPDATE #KPX_TSLDelvItemPrice   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TSLDelvItemPrice  
     WHERE Status = 0  
       AND ( DVItemPriceSeq = 0 OR DVItemPriceSeq IS NULL )  
      
    SELECT * FROM #KPX_TSLDelvItemPrice   
      
    RETURN  
GO 
exec KPX_SSLDelvItemPriceCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>27439</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <CurrSeq>1</CurrSeq>
    <SDate>20141119</SDate>
    <EDate />
    <DrumPrice>0</DrumPrice>
    <TankPrice>0</TankPrice>
    <BoxPrice>0</BoxPrice>
    <Remark />
    <DVItemPriceSeq>0</DVItemPriceSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CustSeq>12541</CustSeq>
    <DVPlaceSeq>98</DVPlaceSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025779,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021314