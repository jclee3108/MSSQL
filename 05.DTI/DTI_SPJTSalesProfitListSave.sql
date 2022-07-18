  
IF OBJECT_ID('DTI_SPJTSalesProfitListSave') IS NOT NULL   
    DROP PROC DTI_SPJTSalesProfitListSave  
GO  
  
-- v2014.03.18  
  
-- 프로젝트별매출이익현황_DTI(저장) by 이재천   
CREATE PROC DTI_SPJTSalesProfitListSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #DTI_TPJTSalesProfitResult (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TPJTSalesProfitResult'   
    IF @@ERROR <> 0 RETURN    
    
    --select * from #DTI_TPJTSalesProfitResult
    --return 
    DECLARE @ClosingNextCostYM NCHAR(6), 
            @PJTSeq INT 
    SELECT @ClosingNextCostYM = ISNULL((  
                                         SELECT CONVERT(NCHAR(6),DATEADD(MONTH, 1, MAX(A.CostYM) + '01'),112)  
                                           FROM _TESMDCostKey AS A   
                                           JOIN _TESMCProfClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq )   
                                          WHERE B.IsClosing = '1'  
                                            AND A.CompanySeq = @CompanySeq   
                                       ),'19000101'  
                                      )  
    SELECT TOP 1 @PJTSeq = PJTSeq 
      FROM #DTI_TPJTSalesProfitResult 
    
    SELECT MAX(A.WorkingTag) AS WorkingTag,   
           MAX(CASE WHEN A.TITLE_IDX1_SEQ = 100 THEN A.Results ELSE 0 END) AS FcstAmt ,  
           MAX(CASE WHEN A.TITLE_IDX1_SEQ = 200 THEN A.Results ELSE 0 END) AS ResultAmt,   
           A.SMCostType, A.SMItemType, A.PJTSeq, A.TITLE_IDX0_SEQ
      INTO #DTI_TPJTSalesProfitResult_SUB  
      FROM #DTI_TPJTSalesProfitResult AS A   
     WHERE A.TITLE_IDX0_SEQ = @ClosingNextCostYM  
     GROUP BY A.SMCostType, A.SMItemType, A.PJTSeq, A.TITLE_IDX0_SEQ
    
    IF EXISTS (SELECT 1 FROM #DTI_TPJTSalesProfitResult_SUB WHERE WorkingTag = 'U')  
    BEGIN   
        UPDATE A  
           SET FcstAmt = B.FcstAmt,   
               ResultAmt = B.ResultAmt 
          FROM DTI_TPJTSalesProfitResult AS A   
          JOIN #DTI_TPJTSalesProfitResult_SUB AS B ON ( B.PJTSeq = A.PJTSeq AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType AND B.TITLE_IDX0_SEQ = A.ResultYM )   
         WHERE WorkingTag = 'U' 
         
        INSERT INTO DTI_TPJTSalesProfitResult
        (  
            CompanySeq, PJTSeq, SMCostType, SMItemType, ResultYM,   
            FcstAmt, ResultAmt, LastUserSeq, LastDateTime, PgmSeq  
        )   
        SELECT @CompanySeq, A.PJTSeq, A.SMCostType, A.SMItemType, A.TITLE_IDX0_SEQ, 
               A.FcstAmt, A.ResultAmt, @UserSeq, GETDATE(), @PgmSeq 
          FROM #DTI_TPJTSalesProfitResult_SUB AS A  
         WHERE NOT EXISTS (SELECT 1 
                            FROM DTI_TPJTSalesProfitResult AS A   
                            JOIN #DTI_TPJTSalesProfitResult_SUB AS B ON ( B.PJTSeq = A.PJTSeq AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType AND B.TITLE_IDX0_SEQ = A.ResultYM )   
                          )
         
    END  
    
    --IF EXISTS (SELECT 1 FROM #DTI_TPJTSalesProfitResult_SUB WHERE WorkingTag = 'A')  
    --BEGIN    
    --    INSERT INTO DTI_TPJTSalesProfitResult
    --    (  
    --        CompanySeq, PJTSeq, SMCostType, SMItemType, ResultYM,   
    --        FcstAmt, ResultAmt, LastUserSeq, LastDateTime, PgmSeq  
    --    )   
    --    SELECT @CompanySeq, A.PJTSeq, A.SMCostType, A.SMItemType, A.TITLE_IDX0_SEQ, 
    --           A.FcstAmt, A.ResultAmt, @UserSeq, GETDATE(), @PgmSeq 
    --      FROM #DTI_TPJTSalesProfitResult_SUB AS A  
    --     WHERE A.WorkingTag = 'A'  
        
    --    IF @@ERROR <> 0 RETURN  
    --END
    
    SELECT * FROM #DTI_TPJTSalesProfitResult
    
    RETURN  
GO
begin tran 
exec DTI_SPJTSalesProfitListSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201212</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>1000</Results>
    <TITLE_IDX0_SEQ>201212</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201212</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201301</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201301</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201301</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201302</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201302</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201302</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201303</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201303</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201303</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201304</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201304</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201304</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201305</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201305</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201305</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201306</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>100</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201306</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>200</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201306</TITLE_IDX0_SEQ>
    <TITLE_IDX1_SEQ>300</TITLE_IDX1_SEQ>
    <PJTSeq>156</PJTSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018260
select * from DTI_TPJTSalesProfitResult 
rollback 