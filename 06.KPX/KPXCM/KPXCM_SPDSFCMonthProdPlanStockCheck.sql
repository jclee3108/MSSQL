  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockCheck  
GO  
  
-- v2015.10.20  
  
-- 월생산계획-체크 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockCheck  
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
    
    CREATE TABLE #KPXCM_TPDSFCMonthProdPlanStock( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthProdPlanStock'   
    IF @@ERROR <> 0 RETURN     
    
    ----------------------------------------------------------------------------------------
    -- 체크1, 해당 생산사업장, 계획년월은 이미 등록 되어 있습니다. 
    ----------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '해당 생산사업장, 계획년월은 이미 등록 되어 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
     WHERE A.WorkingTag = 'A' 
       AND EXISTS (SELECT 1 FROM KPXCM_TPDSFCMonthProdPlanStock WHERE CompanySeq = @CompanySeq AND FactUnit = A.FactUnit AND PlanYM = A.PlanYM)  
       AND @WorkingTag <> 'Cfm'
    ----------------------------------------------------------------------------------------
    -- 체크1, 해당 생산사업장, 계획년월은 이미 등록 되어 있습니다. 
    ----------------------------------------------------------------------------------------   
    
    ----------------------------------------------------------------------------------------
    -- 체크2, 월생산계획 확정 된 데이터는 수정/삭제 할 수 없습니다. 
    ----------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '월생산계획 확정 된 데이터는 수정/삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TPDSFCMonthProdPlanStock  AS A 
      JOIN KPXCM_TPDSFCMonthProdPlanStock   AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq AND B.PlanYMSub = B.PlanYM ) 
     WHERE A.Status = 0 
       AND B.IsCfm = '1'
    ----------------------------------------------------------------------------------------
    -- 체크2, END 
    ----------------------------------------------------------------------------------------    
    
    IF @WorkingTag <> 'Cfm'
    BEGIN 
        -- 번호+코드 따기 :           
        DECLARE @Count  INT,  
                @Seq    INT   
          
        SELECT @Count = COUNT(1) FROM #KPXCM_TPDSFCMonthProdPlanStock WHERE WorkingTag = 'A' AND Status = 0 
        
        
        
        IF @Count > 0  
        BEGIN  
            
            DECLARE @BaseDate           NVARCHAR(8),   
                    @MaxNo              NVARCHAR(50)  
              
            SELECT @BaseDate    = PlanYM 
              FROM #KPXCM_TPDSFCMonthProdPlanStock   
             WHERE WorkingTag = 'A'   
               AND Status = 0     
            
            EXEC dbo._SCOMCreateNo 'SITE', 'KPXCM_TPDSFCMonthProdPlanStock', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
            
            -- 키값생성코드부분 시작  
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDSFCMonthProdPlanStock', 'PlanSeq', @Count
              
            -- Temp Talbe 에 생성된 키값 UPDATE  
            UPDATE #KPXCM_TPDSFCMonthProdPlanStock  
               SET PlanSeq = @Seq + DataSeq,  
                   PlanNo  = @MaxNo      
             WHERE WorkingTag = 'A'  
               AND Status = 0  
          
        END -- end if   
        
        -- 내부코드 0값 일 때 에러처리   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                              @Status      OUTPUT,      
                              @Results     OUTPUT,      
                              1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                              @LanguageSeq         
          
        UPDATE #KPXCM_TPDSFCMonthProdPlanStock   
           SET Result        = @Results,      
               MessageType   = @MessageType,      
               Status        = @Status      
          FROM #KPXCM_TPDSFCMonthProdPlanStock  
         WHERE Status = 0  
           AND ( PlanSeq = 0 OR PlanSeq IS NULL )  
    END 
    
    SELECT * FROM #KPXCM_TPDSFCMonthProdPlanStock   
      
    RETURN  
Go
begin tran 
exec KPXCM_SPDSFCMonthProdPlanStockCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit />
    <FactUnitName />
    <PlanSeq>27</PlanSeq>
    <IsStockCfm>1</IsStockCfm>
    <PlanNo>2014030004</PlanNo>
    <PlanYM>201405</PlanYM>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <RptProdSalesQty1>123423</RptProdSalesQty1>
    <RptSelfQty1>423423</RptSelfQty1>
    <RptSalesQty1>423423</RptSalesQty1>
    <RptProdSalesQty2>4234</RptProdSalesQty2>
    <RptSelfQty2>23423</RptSelfQty2>
    <RptSalesQty2>4234</RptSalesQty2>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069
rollback 