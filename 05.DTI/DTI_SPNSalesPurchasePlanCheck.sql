
IF OBJECT_ID('DTI_SPNSalesPurchasePlanCheck') IS NOT NULL 
    DROP PROC DTI_SPNSalesPurchasePlanCheck
GO 

-- v2014.03.31 

-- [경영계획]판매구매계획입력_DTI(체크) by이재천
CREATE PROC DTI_SPNSalesPurchasePlanCheck
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
            @Results        NVARCHAR(250), 
            @CostYM         NCHAR(6), 
            @SMCostMng      INT, 
            @CostMngAmdSeq  INT, 
            @PlanYear       NCHAR(4), 
            @Cnt            INT, 
            @ItemSeq        INT, 
            @CostKeySeq     INT 
    
    CREATE TABLE #DTI_TPNSalesPurchasePlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TPNSalesPurchasePlan'
    
    SELECT @SMCostMng = A.SMCostMng, 
           @CostMngAmdSeq = A.PlanKeySeq, 
           @PlanYear = A.PlanYear, 
           @ItemSeq = A.ItemSeq 
      FROM #DTI_TPNSalesPurchasePlan AS A 
    
    SELECT @Cnt = 1
    
    WHILE ( @Cnt < 13 )
    BEGIN
        SELECT @CostYM = @PlanYear + RIGHT('00'+CAST(@Cnt AS NVARCHAR),2) 
        
        -- CostKeySeq 가져오기.  
        EXEC @CostKeySeq = dbo._SESMDCostKeySeq @CompanySeq, @CostYM, 0, @SMCostMng, @CostMngAmdSeq, @PlanYear, @PgmSeq   
        
        UPDATE #DTI_TPNSalesPurchasePlan
           SET CostKeySeq = @CostKeySeq
         WHERE TITLE_IDX0_SEQ = @Cnt
        
        SELECT @Cnt = @Cnt + 1
    END
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,''  
      
    UPDATE A  
       SET Result       = @Results, --REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #DTI_TPNSalesPurchasePlan AS A   
      JOIN (SELECT S.ItemSeq, S.EmpSeq, S.DeptSeq, S.PlanType, S.CostKeySeq, S.BizUnit-- , Count(1) AS Cnt
              FROM (SELECT A1.ItemSeq, A1.EmpSeq, A1.DeptSeq, A1.PlanType, A1.CostKeySeq, A1.BizUnit 
                      FROM #DTI_TPNSalesPurchasePlan AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ItemSeq, A1.EmpSeq, A1.DeptSeq, A1.PlanType, A1.CostKeySeq, A1.BizUnit  
                      FROM DTI_TPNSalesPurchasePlan AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #DTI_TPNSalesPurchasePlan   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ItemSeq = A1.ItemSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ItemSeq, S.EmpSeq, S.DeptSeq, S.PlanType, S.CostKeySeq, S.BizUnit 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ItemSeq = B.ItemSeq AND A.EmpSeq = B.EmpSeq AND A.DeptSeq = B.DeptSeq AND A.PlanType = B.PlanType AND A.CostKeySeq = B.CostKeySeq AND A.BizUnit = B.BizUnit ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0   
    
    -- 체크1, 해당 년도의 판매/구매계획마감처리가 되어 저장,수정,삭제 할수 없습니다. 
    UPDATE A 
       SET Result = N'해당 년도의 판매/구매계획마감처리가 되어 저장,수정,삭제 할수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #DTI_TPNSalesPurchasePlan AS A 
      JOIN DTI_TESMBMAClosing AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq AND B.IsClosed = '1' AND B.SMClosing = 1000394005 ) 
      JOIN  _TESMDCostKey     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CostKeySeq = B.CostKeySeq AND C.PlanYear = A.PlanYear ) 
     WHERE A.Status = 0 
    
    -- 체크1, END 
    
    -- 번호+코드 따기 :           
    DECLARE @Count          INT,  
            @Seq            INT, 
            @MIN_ROW_IDX    INT 
            
    SELECT @MIN_ROW_IDX = (SELECT MIN(ROW_IDX) FROM #DTI_TPNSalesPurchasePlan) 
    
    SELECT @Count = COUNT(1) FROM #DTI_TPNSalesPurchasePlan WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        SELECT @Seq = ISNULL((SELECT MAX(Serl) FROM DTI_TPNSalesPurchasePlan WHERE CompanySeq = @CompanySeq),0) -- dbo._SCOMCreateSeq @CompanySeq, 'DTI_TPNSalesPurchasePlan', 'Serl', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE A  
           SET Serl = @Seq + A.ROW_IDX - @MIN_ROW_IDX + 1   
          FROM #DTI_TPNSalesPurchasePlan AS A 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    END -- end if   
    
    SELECT * FROM #DTI_TPNSalesPurchasePlan 
    
    RETURN    
GO

begin tran
exec DTI_SPNSalesPurchasePlanCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>51351</Results>
    <TITLE_IDX0_SEQ>1</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>101</TITLE_IDX1_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>1521513</Results>
    <TITLE_IDX0_SEQ>2</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>102</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>51351351</Results>
    <TITLE_IDX0_SEQ>3</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>103</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>51351</Results>
    <TITLE_IDX0_SEQ>4</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>104</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>351312</Results>
    <TITLE_IDX0_SEQ>5</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>105</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>6</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>106</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>7</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>107</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>8</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>108</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>9</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>109</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>10</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>110</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>11</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>111</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ItemName>반제품2_TEST(이재천)</ItemName>
    <ItemNo>반제품2No_TEST(이재천)</ItemNo>
    <Spec />
    <ItemSeq>1000588</ItemSeq>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <SumPlanAmt>53326878</SumPlanAmt>
    <Serl>2</Serl>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>12</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>112</TITLE_IDX1_SEQ>
    <BizUnit>1</BizUnit>
    <PlanKeySeq>547</PlanKeySeq>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021944,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018429
rollback