
IF OBJECT_ID('DTI_SPJTSalesProfitListCreateRev') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListCreateRev 
GO 

-- v2014.03.19 

-- 프로젝트별매출이익현황_DTI(차수증가) by이재천
CREATE PROC dbo.DTI_SPJTSalesProfitListCreateRev
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #DTI_TPJTSalesProfitPlan (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TPJTSalesProfitPlan'     
    IF @@ERROR <> 0 RETURN  
    
    DELETE FROM #DTI_TPJTSalesProfitPlan WHERE SMItemType = 0 OR LEFT(SMItemType,9) = 111111111
    
    INSERT INTO DTI_TPJTSalesProfitPlan 
    ( 
        CompanySeq, PJTSeq, SMCostType, SMItemType, Rev, 
        PlanAmt, RevRemark, RevDate, LastUserSeq, LastDateTime, PgmSeq 
    ) 
    SELECT @CompanySeq, A.PJTSeq, A.SMCostType, A.SMItemType, A.ListRev + 1 , 
           A.NowPlanAmt, A.ChgReason, ChgDate, @UserSeq, GETDATE(), @PgmSeq
      FROM #DTI_TPJTSalesProfitPlan AS A 
    
    --UPDATE #DTI_TPJTSalesProfitPlan 
    --   SET ListRev = ListRev + 1 
    --  FROM #DTI_TPJTSalesProfitPlan
    
    SELECT * FROM #DTI_TPJTSalesProfitPlan 
    
    RETURN 
GO
exec DTI_SPJTSalesProfitListCreateRev @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>0</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <NowPlanAmt>38200000</NowPlanAmt>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419002</SMItemType>
    <NowPlanAmt>141435000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <NowPlanAmt>10465000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <NowPlanAmt>1954530000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>0</SMItemType>
    <NowPlanAmt>4109625000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>5</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <NowPlanAmt>37000000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>6</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419002</SMItemType>
    <NowPlanAmt>113500000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>7</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <NowPlanAmt>9100000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>8</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <NowPlanAmt>1703200000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419005</SMItemType>
    <NowPlanAmt>7800000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>1000419006</SMItemType>
    <NowPlanAmt>0</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <SMCostType>1000418002</SMCostType>
    <SMItemType>0</SMItemType>
    <NowPlanAmt>1870600000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>12</ROW_IDX>
    <SMCostType>1111111111</SMCostType>
    <SMItemType>1111111111</SMItemType>
    <NowPlanAmt>2239025000</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>13</ROW_IDX>
    <SMCostType>1111111112</SMCostType>
    <SMItemType>1111111112</SMItemType>
    <NowPlanAmt>0</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>14</ROW_IDX>
    <SMCostType>1111111113</SMCostType>
    <SMItemType>1111111113</SMItemType>
    <NowPlanAmt>1</NowPlanAmt>
    <PJTSeq>156</PJTSeq>
    <ListRev>0</ListRev>
    <ChgReason>testet</ChgReason>
    <ChgDate>20140319</ChgDate>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018260