  
IF OBJECT_ID('hncom_SPRAdjWithHoldRepHRMSum') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldRepHRMSum  
GO  
  
-- v2017.02.09
  
-- 원천징수이행상황신고-HRM집계_hncom by 이재천
CREATE PROC hncom_SPRAdjWithHoldRepHRMSum  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @BizSeq     INT 
           ,@RevertYM   NCHAR(6)
    
    SELECT @BizSeq = BizSeq
          ,@RevertYM = RevertYM
      FROM #Temp

    SELECT B.ValueSeq AS SMHoldRepItemSeq 
          ,SUM(A.EmpCnt) AS EmpCnt 
          ,SUM(A.TotAmt) AS TotAmt 
          ,SUM(A.IncomeTaxAmt) AS IncomeTaxAmt 
          ,SUM(A.ResidentTaxAmt) AS ResidentTaxAmt
          ,SUM(A.RuralTaxAmt) AS RuralTaxAmt 
      INTO #hncom_TAdjWithHoldList
      FROM hncom_TAdjWithHoldList       AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.MinorSeq = A.UMTypeSeq 
                                              AND B.Serl = 1000002
                                                )
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizSeq = @BizSeq 
       AND A.StdYM = @RevertYM
     GROUP BY B.ValueSeq 


    UPDATE A 
       SET Cnt = ISNULL(B.EmpCnt,0) 
          ,Amt = ISNULL(B.TotAmt,0)
          ,LevyIncomeTax = ISNULL(B.IncomeTaxAmt,0)
          ,LevyPenaltyTax = ISNULL(B.RuralTaxAmt,0)
      FROM #Temp                                AS A 
      LEFT OUTER JOIN #hncom_TAdjWithHoldList   AS B ON ( B.SMHoldRepItemSeq = A.SMHoldRepItemSeq )
    
    SELECT * FROM #Temp 

    RETURN  
GO
begin tran 
exec hncom_SPRAdjWithHoldRepHRMSum @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/간이세액</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322001</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/중도퇴사</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322002</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/일용근로</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322003</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/연말정산/합계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322004</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/연말정산/분납신청</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322028</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/연말정산/납부금액</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322029</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>근로소득/가감계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322005</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>퇴직소득 연금계좌</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322021</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>퇴직소득 그 외</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322022</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>퇴직소득 가감계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322023</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>사업소득/매월징수</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322007</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>사업소득/연말정산</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322008</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>사업소득/가감계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322009</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>기타소득 연금계좌</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322024</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>기타소득 그 외</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322025</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>기타소득 가감계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322026</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>연금소득 연금계좌</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322027</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>연금소득 공적연금(매월)</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322011</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>연금소득/연말정산</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322012</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>연금소득/가감계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322013</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>이자소득</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322014</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>배당소득</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322015</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>저축해지추징세액</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322016</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>양도소득</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322017</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>법인원천</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322018</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>수정신고(세액)</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322019</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMHoldRepItemName>총합계</SMHoldRepItemName>
    <SMHoldRepItemSeq>3322020</SMHoldRepItemSeq>
    <Cnt>0</Cnt>
    <Amt>0</Amt>
    <LevyIncomeTax>0</LevyIncomeTax>
    <LevyFarmTax>0</LevyFarmTax>
    <LevyPenaltyTax>0</LevyPenaltyTax>
    <RebateTax>0</RebateTax>
    <PaymentIncomeTax>0</PaymentIncomeTax>
    <PaymentFarmTax>0</PaymentFarmTax>
    <BizSeq>10</BizSeq>
    <RevertYM>201701</RevertYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511164,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1718
rollback 
