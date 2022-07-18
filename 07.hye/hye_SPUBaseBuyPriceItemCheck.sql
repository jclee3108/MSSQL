  
IF OBJECT_ID('hye_SPUBaseBuyPriceItemCheck') IS NOT NULL   
    DROP PROC hye_SPUBaseBuyPriceItemCheck  
GO  
  
-- v2016.12.15
  
-- 구매단가등록-체크 by 이재천
CREATE PROC hye_SPUBaseBuyPriceItemCheck  
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
      
    CREATE TABLE #hye_TPUBaseBuyPriceItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hye_TPUBaseBuyPriceItem'   
    IF @@ERROR <> 0 RETURN     
    
    --------------------------------------------------------------
    -- 체크1, 최종건이 아니면 수정,삭제를 할 수 없습니다. 
    --------------------------------------------------------------
    UPDATE A
       SET Result = '최종건이 아니면 수정,삭제를 할 수 없습니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #hye_TPUBaseBuyPriceItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND A.EndDate <> '99991231'
    --------------------------------------------------------------
    -- 체크1, END 
    --------------------------------------------------------------

    --------------------------------------------------------------
    -- 체크2, 최종건보다 유효시작일이 작거나 같습니다.
    --------------------------------------------------------------
    UPDATE A
       SET Result = '최종건보다 유효시작일이 작거나 같습니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #hye_TPUBaseBuyPriceItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND EXISTS (SELECT 1 
                     FROM hye_TPUBaseBuyPriceItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.UMDVGroupSeq = A.UMDVGroupSeq 
                      AND Z.ItemSeq = A.ItemSeq 
                      AND Z.UnitSeq = A.UnitSeq 
                      AND Z.CurrSeq = A.CurrSeq 
                      AND Z.SrtDate >= A.SrtDate 
                      AND Z.PriceSeq <> A.PriceSeq 
                  )
    --------------------------------------------------------------
    -- 체크2, END 
    --------------------------------------------------------------

    --------------------------------------------------------------
    -- 체크3, 중복 된 데이터가 입력되었습니다.
    --------------------------------------------------------------
     IF EXISTS ( SELECT 1 
                   FROM #hye_TPUBaseBuyPriceItem 
                  WHERE WorkingTag IN ( 'A', 'U' ) 
                  GROUP BY UMDVGroupSeq, ItemSeq, UnitSeq, CurrSeq, SrtDate
                  HAVING COUNT(1) > 1 
               )
    BEGIN
        UPDATE A
           SET Result = '중복 된 데이터가 입력되었습니다.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #hye_TPUBaseBuyPriceItem AS A 
    END 
    --------------------------------------------------------------
    -- 체크3, END 
    --------------------------------------------------------------

    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hye_TPUBaseBuyPriceItem WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hye_TPUBaseBuyPriceItem', 'PriceSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #hye_TPUBaseBuyPriceItem  
           SET PriceSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hye_TPUBaseBuyPriceItem   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hye_TPUBaseBuyPriceItem  
     WHERE Status = 0  
       AND ( PriceSeq = 0 OR PriceSeq IS NULL )  
      
    SELECT * FROM #hye_TPUBaseBuyPriceItem   
      
    RETURN  

GO
begin tran


exec hye_SPUBaseBuyPriceItemCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PriceSeq />
    <ItemNo>*바나나크림빵</ItemNo>
    <ItemName>*바나나크림빵</ItemName>
    <Spec />
    <ItemSeq>226</ItemSeq>
    <UnitName>EA</UnitName>
    <UnitSeq>1</UnitSeq>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <UMDVGroup>출하그룹2</UMDVGroup>
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <SrtDate>20161208</SrtDate>
    <EndDate />
    <YSSPrice>0</YSSPrice>
    <DelvPrice>0</DelvPrice>
    <StdPrice>0</StdPrice>
    <SalesPrice>0</SalesPrice>
    <ChgPrice>0</ChgPrice>
    <IsChg>0</IsChg>
    <Summary />
    <Remark />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730168,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730058
rollback 