  
IF OBJECT_ID('DTI_SPJTPublicSISalesPlanCheck') IS NOT NULL   
    DROP PROC DTI_SPJTPublicSISalesPlanCheck  
GO  
  
-- v2014.04.07  
  
-- 공공SI사업경영계획_DTI-체크 by 이재천   
CREATE PROC DTI_SPJTPublicSISalesPlanCheck  
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
    
    CREATE TABLE #DTI_TPJTPublicSISalesPlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TPJTPublicSISalesPlan'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE #DTI_TPJTPublicSISalesPlan
      SET WorkingTag = 'D' 
     FROM #DTI_TPJTPublicSISalesPlan 
    WHERE WorkingTag = 'A' 
    
    UPDATE #DTI_TPJTPublicSISalesPlan 
       SET WorkingTag = 'A' 
      FROM #DTI_TPJTPublicSISalesPlan 
     WHERE WorkingTag = 'U'
    
    UPDATE B 
       SET WorkingTag = 'U'
      FROM DTI_TPJTPublicSISalesPlan AS A 
      JOIN #DTI_TPJTPublicSISalesPlan AS B ON ( B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType AND B.TITLE_IDX0_SEQ = A.PlanYM ) 
    
    IF NOT EXISTS ( SELECT 1 FROM #DTI_TPJTPublicSISalesPlan AS A 
                             JOIN DTI_TPJTPublicSISalesPlan  AS B ON ( B.CompanySeq = @CompanySeq AND LEFT(B.PlanYM,4) = A.PlanYear ) 
                  )
    BEGIN 
        UPDATE A
           SET Result = N'등록된 자료가 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #DTI_TPJTPublicSISalesPlan AS A 
         WHERE A.WorkingTag = 'D' 
    END
    
    SELECT * FROM #DTI_TPJTPublicSISalesPlan 
    
      
    RETURN  
GO
exec DTI_SPJTPublicSISalesPlanCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>234234</Results>
    <TITLE_IDX0_SEQ>201401</TITLE_IDX0_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201402</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201403</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201404</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201405</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201406</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201407</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201408</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201409</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201410</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201411</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>S/W</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419001</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201413</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201401</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>34235</Results>
    <TITLE_IDX0_SEQ>201402</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201403</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201404</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201405</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201406</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201407</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201408</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201409</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201410</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201411</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>내부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419003</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201413</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201401</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201402</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>34234</Results>
    <TITLE_IDX0_SEQ>201403</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201404</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201405</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>32</IDX_NO>
    <DataSeq>32</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201406</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>33</IDX_NO>
    <DataSeq>33</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201407</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>34</IDX_NO>
    <DataSeq>34</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201408</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>35</IDX_NO>
    <DataSeq>35</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201409</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>36</IDX_NO>
    <DataSeq>36</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201410</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>37</IDX_NO>
    <DataSeq>37</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201411</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>38</IDX_NO>
    <DataSeq>38</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>39</IDX_NO>
    <DataSeq>39</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>외부용역</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419004</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201413</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>40</IDX_NO>
    <DataSeq>40</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201401</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>41</IDX_NO>
    <DataSeq>41</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201402</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>42</IDX_NO>
    <DataSeq>42</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201403</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>43</IDX_NO>
    <DataSeq>43</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>235</Results>
    <TITLE_IDX0_SEQ>201404</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>44</IDX_NO>
    <DataSeq>44</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201405</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>45</IDX_NO>
    <DataSeq>45</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201406</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>46</IDX_NO>
    <DataSeq>46</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201407</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>47</IDX_NO>
    <DataSeq>47</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201408</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>48</IDX_NO>
    <DataSeq>48</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201409</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>49</IDX_NO>
    <DataSeq>49</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201410</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>50</IDX_NO>
    <DataSeq>50</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201411</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>51</IDX_NO>
    <DataSeq>51</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>52</IDX_NO>
    <DataSeq>52</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>4</ROW_IDX>
    <SMCostTypeName>프로젝트매출[A1]</SMCostTypeName>
    <SMItemTypeName>매출조정금액</SMItemTypeName>
    <SMCostType>1000418001</SMCostType>
    <SMItemType>1000419011</SMItemType>
    <Results>0</Results>
    <TITLE_IDX0_SEQ>201413</TITLE_IDX0_SEQ>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022071,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018561