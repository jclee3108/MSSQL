  
IF OBJECT_ID('KPX_SACFundMasterCheck') IS NOT NULL   
    DROP PROC KPX_SACFundMasterCheck  
GO  
  
-- v2014.12.16 
  
-- 금융상품명세서-체크 by 이재천   
CREATE PROC KPX_SACFundMasterCheck  
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
    
    CREATE TABLE #KPX_TACFundMaster( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACFundMaster'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :            
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TACFundMaster WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TACFundMaster', 'FundSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TACFundMaster  
           SET FundSeq = @Seq + DataSeq--,  
               --SampleNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    
    -- 상품 코드 따기 
    DECLARE @BaseCode NVARCHAR(100), 
            @MaxSerl  INT, 
            @Len      INT  
    
    SELECT @BaseCode = G.ValueText + D.ValueText 
      FROM #KPX_TACFundMaster           AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.FundKindM AND B.Serl = 1000001 )
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.MinorSeq AND E.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 ) 
    
    SELECT @Len = Len(@BaseCode)
    
    SELECT @MaxSerl = MAX(CONVERT(INT,RIGHT(FundCode,4)))
      FROM KPX_TACFundMaster AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.FundCode,@Len) = @BaseCode
    
    UPDATE A 
       SET FundCode = @BaseCode + '-' + RIGHT('000' + CONVERT(NVARCHAR(10),ISNULL(@MaxSerl,0) + A.DataSeq),4)
      FROM #KPX_TACFundMaster AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A'
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TACFundMaster   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TACFundMaster  
     WHERE Status = 0  
       AND ( FundSeq = 0 OR FundSeq IS NULL )  
      
    SELECT * FROM #KPX_TACFundMaster   
      
    RETURN  
GO 

begin tran 
exec KPX_SACFundMasterCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FundName>12123123</FundName>
    <FundCode />
    <BankSeq>13</BankSeq>
    <BankName>지금도 한혜진일걸</BankName>
    <TitileName />
    <FundKind>상품유형1</FundKind>
    <FundKindL>상품대분류1</FundKindL>
    <FundKindM>1010430001</FundKindM>
    <FundKindMName>상품중분류1</FundKindMName>
    <FundKindS>1010431001</FundKindS>
    <FundKindSName>상품소분류1</FundKindSName>
    <ItemResult />
    <BeforeRate>0</BeforeRate>
    <FixRate>0</FixRate>
    <Hudle>0</Hudle>
    <SalesName />
    <EmpName />
    <ActCompany />
    <BillCompany />
    <SetupTypeName />
    <BaseCost />
    <ActType />
    <Trade />
    <TagetAdd>0</TagetAdd>
    <OpenInterest>0</OpenInterest>
    <InvestType />
    <OldFundSeq />
    <OldFundName />
    <SetupDate />
    <DurDate />
    <AccDate />
    <Interest />
    <Barrier />
    <EarlyRefund />
    <TrustLevel />
    <Remark1 />
    <Remark2 />
    <Remark3 />
    <Act>0</Act>
    <FundSeq>0</FundSeq>
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026661,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022318

rollback 