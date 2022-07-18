
IF OBJECT_ID('KPX_SSLWeekSalesPlanSave') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanSave
GO 

-- 2014.11.17 

-- 주간판매계획입력(저장) by이재천 
CREATE PROC KPX_SSLWeekSalesPlanSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #KPX_TSLWeekSalesPlan (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TSLWeekSalesPlan'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    IF @WorkingTag = 'Del'   
    BEGIN  
      
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLWeekSalesPlanRev')      
          
        EXEC _SCOMLog @CompanySeq   ,          
                      @UserSeq      ,          
                      'KPX_TSLWeekSalesPlanRev'    , -- 테이블명          
                      '#KPX_TSLWeekSalesPlan'    , -- 임시 테이블명          
                      'BizUnit,WeekSeq,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
          
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLWeekSalesPlan')      
          
        EXEC _SCOMLog @CompanySeq   ,          
                      @UserSeq      ,          
                      'KPX_TSLWeekSalesPlan'    , -- 테이블명          
                      '#KPX_TSLWeekSalesPlan'    , -- 임시 테이블명          
                      'BizUnit,WeekSeq,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END   
    ELSE  
    BEGIN   
      
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLWeekSalesPlan')      
          
        EXEC _SCOMLog @CompanySeq   ,          
                      @UserSeq      ,          
                      'KPX_TSLWeekSalesPlan'    , -- 테이블명          
                      '#KPX_TSLWeekSalesPlan'    , -- 임시 테이블명          
                      'BizUnit,WeekSeq,PlanRev,CustSeq,ItemSeq,PlanDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                      @TableColumns , 'BizUnit,WeekSeq,PlanRev,CustSeqOld,ItemSeqOld,TITLE_IDX0_SEQ', @PgmSeq  -- 테이블 모든 필드명     
    END   
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPX_TSLWeekSalesPlan WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        
        IF @WorkingTag = 'Del'
        BEGIN
            
            DELETE B
              FROM #KPX_TSLWeekSalesPlan AS A 
              JOIN KPX_TSLWeekSalesPlan  AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.WeekSeq = A.WeekSeq AND B.PlanRev = A.PlanRev )   
            
            DELETE B  
              FROM #KPX_TSLWeekSalesPlan AS A   
              JOIN KPX_TSLWeekSalesPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.WeekSeq = A.WeekSeq AND B.PlanRev = A.PlanRev )   
            
        END 
        ELSE
        BEGIN
            DELETE B
              FROM #KPX_TSLWeekSalesPlan AS A 
              JOIN KPX_TSLWeekSalesPlan AS B ON ( B.BizUnit = A.BizUnit 
                                              AND B.WeekSeq = A.WeekSeq 
                                              AND B.PlanRev = A.PlanRev 
                                              AND B.PlanDate = A.TITLE_IDX0_SEQ 
                                              AND B.CustSeq = A.CustSeqOld  
                                              AND B.ItemSeq = ItemSeqOld 
                                                )
                 WHERE B.CompanySeq  = @CompanySeq
                   AND A.WorkingTag  = 'D' 
                   AND A.Status      = 0    
            
            IF NOT EXISTS (SELECT 1 FROM #KPX_TSLWeekSalesPlan AS A -- 시트삭제시 해당데이터가 없을때 차수테이블 데이터도 지우기   
                                    JOIN KPX_TSLWeekSalesPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.WeekSeq = A.WeekSeq AND B.PlanRev = A.PlanRev AND B.PlanDate = A.TITLE_IDX0_SEQ )   
                          )   
            BEGIN
                SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLWeekSalesPlanRev')   
                
                SELECT 1 AS IDX_NO,   
                       1 AS DataSeq,   
                       MAX(A.Status) AS Status,   
                       MAX(A.BizUnit) AS BizUnit,   
                       MAX(A.WeekSeq) AS WeekSeq,   
                       MAX(A.PlanRev) AS PlanRev,   
                       MAX(A.WorkingTag) AS WorkingTag  
                  INTO #RevLog  
                  FROM #KPX_TSLWeekSalesPlan AS A   
                
                EXEC _SCOMLog @CompanySeq   ,          
                              @UserSeq      ,          
                              'KPX_TSLWeekSalesPlanRev'    , -- 테이블명          
                              '#RevLog'    , -- 임시 테이블명          
                              'BizUnit,WeekSeq,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                               @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
                DELETE B  
                  FROM #KPX_TSLWeekSalesPlan AS A   
                  JOIN KPX_TSLWeekSalesPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.WeekSeq = A.WeekSeq AND B.PlanRev = A.PlanRev )   
            END 
            
        END 
    END  
    
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #KPX_TSLWeekSalesPlan WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET CustSeq = A.Custseq, 
               ItemSeq = A.ItemSeq, 
               UMPackingType = A.UMPackingType, 
               Qty = A.Value,
               LastUserSeq = @UserSeq,
               LastDateTime = GetDate()
          FROM #KPX_TSLWeekSalesPlan AS A 
          JOIN KPX_TSLWeekSalesPlan AS B ON ( B.BizUnit = A.BizUnit  
                                          AND B.WeekSeq = A.WeekSeq 
                                          AND B.PlanRev = A.PlanRev 
                                          AND B.PlanDate = A.TITLE_IDX0_SEQ 
                                          AND B.CustSeq = A.CustSeqOld  
                                          AND B.ItemSeq = A.ItemSeqOld
                                            )
                         
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'U' 
               AND A.Status     = 0    
   
            IF @@ERROR <> 0  RETURN
    END  
    

    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPX_TSLWeekSalesPlan WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO KPX_TSLWeekSalesPlan 
        (
            CompanySeq,     BizUnit,        WeekSeq,        PlanRev,    CustSeq,
            ItemSeq,        PlanDate,       UMPackingType,  Qty,        SDate,
            EDate,          LastUserSeq,    LastDateTime 
        ) 
        SELECT @CompanySeq,    BizUnit,        WeekSeq,        PlanRev,    CustSeq,
               ItemSeq,        TITLE_IDX0_SEQ, UMPackingType,  Value,      FromDate,
               ToDate,         @UserSeq,       GETDATE() 
              FROM #KPX_TSLWeekSalesPlan AS A   
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0    

            IF @@ERROR <> 0 RETURN
    END   
    
    UPDATE A
       SET ItemSeqOld = ItemSeq, 
           CustSeqOld = CustSeq 
      FROM #KPX_TSLWeekSalesPlan AS A 
    
    SELECT * FROM #KPX_TSLWeekSalesPlan 
    
    RETURN    
GO 
begin tran 
exec KPX_SSLWeekSalesPlanSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070102</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070103</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070104</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070105</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070106</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070107</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070108</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070109</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070110</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <CustName>(사)경기경영자총협회</CustName>
    <CustNo>123546</CustNo>
    <CustSeq>33761</CustSeq>
    <CustSeqOld>33761</CustSeqOld>
    <ItemClassLName>삼동대분류</ItemClassLName>
    <ItemClassMName>조미식품</ItemClassMName>
    <ItemClassName>장류-고추장</ItemClassName>
    <ItemName>@품목용bom4</ItemName>
    <ItemNo>@품목용bom4</ItemNo>
    <ItemSeq>14481</ItemSeq>
    <ItemSeqOld>14481</ItemSeqOld>
    <Spec />
    <UMCustClassName>대리점 시판</UMCustClassName>
    <UMPackingType>1010287001</UMPackingType>
    <UMPackingTypeName>포장구분1</UMPackingTypeName>
    <Value>0.00000</Value>
    <TITLE_IDX0_SEQ>20070111</TITLE_IDX0_SEQ>
    <BizUnit>2</BizUnit>
    <PlanRev>02</PlanRev>
    <WeekSeq>1</WeekSeq>
    <FromDate>20070101</FromDate>
    <ToDate>20070107</ToDate>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025887,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021321
rollback 