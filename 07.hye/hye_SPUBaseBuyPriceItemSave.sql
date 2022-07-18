  
IF OBJECT_ID('hye_SPUBaseBuyPriceItemSave') IS NOT NULL   
    DROP PROC hye_SPUBaseBuyPriceItemSave  
GO  
  
-- v2016.12.16 
  
-- 구매단가등록-저장 by 이재천
CREATE PROC hye_SPUBaseBuyPriceItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hye_TPUBaseBuyPriceItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hye_TPUBaseBuyPriceItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hye_TPUBaseBuyPriceItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hye_TPUBaseBuyPriceItem'    , -- 테이블명        
                  '#hye_TPUBaseBuyPriceItem'    , -- 임시 테이블명        
                  'PriceSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TPUBaseBuyPriceItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hye_TPUBaseBuyPriceItem AS A   
          JOIN hye_TPUBaseBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PriceSeq = B.PriceSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TPUBaseBuyPriceItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ItemSeq        = A.ItemSeq,  
               B.UnitSeq        = A.UnitSeq, 
               B.CurrSeq        = A.CurrSeq, 
               B.UMDVGroupSeq   = A.UMDVGroupSeq, 
               B.SrtDate        = A.SrtDate, 
               B.YSSPrice       = A.YSSPrice, 
               B.DelvPrice      = A.DelvPrice, 
               B.StdPrice       = A.StdPrice, 
               B.SalesPrice     = A.SalesPrice, 
               B.ChgPrice       = A.ChgPrice, 
               B.IsChg          = A.IsChg, 
               B.Summary        = A.Summary, 
               B.Remark         = A.Remark,
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #hye_TPUBaseBuyPriceItem AS A   
          JOIN hye_TPUBaseBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PriceSeq = B.PriceSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TPUBaseBuyPriceItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hye_TPUBaseBuyPriceItem  
        (   
            CompanySeq, PriceSeq, ItemSeq, UnitSeq, CurrSeq, 
            UMDVGroupSeq, SrtDate, EndDate, YSSPrice, DelvPrice, 
            StdPrice, SalesPrice, ChgPrice, IsChg, Summary, 
            Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, PriceSeq, ItemSeq, UnitSeq, CurrSeq, 
               UMDVGroupSeq, SrtDate, EndDate, YSSPrice, DelvPrice, 
               StdPrice, SalesPrice, ChgPrice, IsChg, Summary, 
               Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #hye_TPUBaseBuyPriceItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    
    -- 유효종료일 적용, Srt
    SELECT ROW_NUMBER() OVER (Partition by ItemSeq, UnitSeq, CurrSeq, UMDVGroupSeq Order by SrtDate) AS ParttionIdx,
           ItemSeq, UnitSeq, CurrSeq, UMDVGroupSeq, SrtDate, EndDate, PriceSeq 
      INTO #EndDate 
      FROM hye_TPUBaseBuyPriceItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #hye_TPUBaseBuyPriceItem 
                    WHERE UMDVGroupSeq = A.UMDVGroupSeq 
                      AND ItemSeq = A.ItemSeq 
                      AND UnitSeq = A.UnitSeq 
                      AND CurrSeq = A.CurrSeq 
                  )
    
    UPDATE A
       SET EndDate = ISNULL(CONVERT(NCHAR(8),DATEADD(Day,-1,B.SrtDate),112),'99991231')
      FROM #EndDate             AS A 
      LEFT OUTER JOIN #EndDate  AS B ON ( B.ParttionIdx - 1 = A.ParttionIdx 
                                      AND B.ItemSeq = A.ItemSeq 
                                      AND B.UnitSeq = A.UnitSeq 
                                      AND B.CurrSeq = A.CurrSeq 
                                      AND B.UMDVGroupSeq = A.UMDVGroupSeq 
                                        )
    UPDATE A
       SET EndDate = B.EndDate 
      FROM hye_TPUBaseBuyPriceItem  AS A 
      JOIN #EndDate      AS B ON ( B.PriceSeq = A.PriceSeq ) 

    UPDATE A
       SET EndDate = B.EndDate 
      FROM #hye_TPUBaseBuyPriceItem AS A 
      LEFT OUTER JOIN #EndDate      AS B ON ( B.PriceSeq = A.PriceSeq ) 
    -- 유효종료일 적용, End 

    SELECT * FROM #hye_TPUBaseBuyPriceItem 

    RETURN  
go
begin tran 
exec hye_SPUBaseBuyPriceItemSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <UMDVGroup>출하그룹2</UMDVGroup>
    <SrtDate>20161209</SrtDate>
    <EndDate xml:space="preserve">        </EndDate>
    <ItemName>*바나나크림빵</ItemName>
    <ItemNo>*바나나크림빵</ItemNo>
    <Spec />
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <ItemSeq>226</ItemSeq>
    <PriceSeq>31</PriceSeq>
    <UnitName>EA</UnitName>
    <CurrName>KRW</CurrName>
    <YSSPrice>0.00000</YSSPrice>
    <DelvPrice>0.00000</DelvPrice>
    <StdPrice>0.00000</StdPrice>
    <SalesPrice>0.00000</SalesPrice>
    <ChgPrice>0.00000</ChgPrice>
    <IsChg>0</IsChg>
    <Summary />
    <Remark />
    <UnitSeq>1</UnitSeq>
    <CurrSeq>1</CurrSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <UMDVGroup>출하그룹2</UMDVGroup>
    <SrtDate>20161216</SrtDate>
    <EndDate xml:space="preserve">        </EndDate>
    <ItemName>*바나나크림빵</ItemName>
    <ItemNo>*바나나크림빵</ItemNo>
    <Spec />
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <ItemSeq>226</ItemSeq>
    <PriceSeq>32</PriceSeq>
    <UnitName>EA</UnitName>
    <CurrName>KRW</CurrName>
    <YSSPrice>0.00000</YSSPrice>
    <DelvPrice>0.00000</DelvPrice>
    <StdPrice>0.00000</StdPrice>
    <SalesPrice>0.00000</SalesPrice>
    <ChgPrice>0.00000</ChgPrice>
    <IsChg>0</IsChg>
    <Summary />
    <Remark />
    <UnitSeq>1</UnitSeq>
    <CurrSeq>1</CurrSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <UMDVGroup>출하그룹2</UMDVGroup>
    <SrtDate>20161217</SrtDate>
    <EndDate xml:space="preserve">        </EndDate>
    <ItemName>*바나나크림빵</ItemName>
    <ItemNo>*바나나크림빵</ItemNo>
    <Spec />
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <ItemSeq>226</ItemSeq>
    <PriceSeq>33</PriceSeq>
    <UnitName>EA</UnitName>
    <CurrName>KRW</CurrName>
    <YSSPrice>0.00000</YSSPrice>
    <DelvPrice>0.00000</DelvPrice>
    <StdPrice>0.00000</StdPrice>
    <SalesPrice>0.00000</SalesPrice>
    <ChgPrice>0.00000</ChgPrice>
    <IsChg>0</IsChg>
    <Summary />
    <Remark />
    <UnitSeq>1</UnitSeq>
    <CurrSeq>1</CurrSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730168,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730058
rollback 
