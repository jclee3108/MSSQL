  
IF OBJECT_ID('hye_SSLOilGasCloseListCheck') IS NOT NULL   
    DROP PROC hye_SSLOilGasCloseListCheck
GO  
  
-- v2017.01.10
  
-- POS주유소충전소마감현황_hye-체크 by이재천 
CREATE PROC hye_SSLOilGasCloseListCheck  
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
      
    CREATE TABLE #DataBlock1( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DataBlock1'   
    IF @@ERROR <> 0 RETURN     

    CREATE TABLE #DataBlock3( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DataBlock3'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8), 
            @UMSlipKind INT
    
    SELECT @DateFr = (SELECT TOP 1 DateFr FROM #DataBlock1)
    SELECT @DateTo = (SELECT TOP 1 DateTo FROM #DataBlock1)
    SELECT @UMSlipKind = (SELECT TOP 1 SlipKind FROM #DataBlock1)
    
    -- 체크1, 미제출이 존재하여 처리 할 수 없습니다.
    IF EXISTS (
                SELECT 1 
                  FROM #DataBlock3                      AS A 
                  LEFT OUTER JOIN hye_TSLOilSalesIsCfm AS B ON ( B.CompanySeq = @CompanySeq 
                                                             AND B.BizUnit = A.BizUnit 
                                                             AND B.StdYMDate = A.TITLE_IDX0_SEQ 
                                                               )
                 WHERE ISNULL(B.IsCfm, '0' ) = '0' 
                   AND @WorkingTag = 'A'
                   AND A.TITLE_IDX0_SEQ BETWEEN @DateFr AND @DateTo 
              )
    BEGIN 
        UPDATE A 
           SET Result = '미제출이 존재하여 처리 할 수 없습니다.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #DataBlock1 AS A 
    END 
    -- 체크1, END 

    -- 체크2, 회계반영이 되어 처리 할 수 없습니다.
    IF EXISTS (
                SELECT 1 
                  FROM #DataBlock3                          AS A 
                  LEFT OUTER JOIN hye_TSLPOSSlipRelation    AS B ON ( B.CompanySeq = @CompanySeq 
                                                                  AND B.BizUnit = A.BizUnit 
                                                                  AND B.StdDate = A.TITLE_IDX0_SEQ 
                                                                  AND B.UMSlipKind = @UMSlipKind
                                                                    )
                 WHERE ISNULL(B.SlipMstSeq, 0 ) <> 0
                   AND @WorkingTag = 'D'
                   AND A.TITLE_IDX0_SEQ BETWEEN @DateFr AND @DateTo 
              )
    BEGIN 
        UPDATE A 
           SET Result = '회계반영이 되어 처리 할 수 없습니다.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #DataBlock1 AS A 
    END 
    -- 체크2, END 
    
    SELECT * FROM #DataBlock1
    SELECT * FROM #DataBlock3
    
    RETURN 
GO
begin tran 

exec hye_SSLOilGasCloseListCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170101</TITLE_IDX0_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170102</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170103</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170104</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170105</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170106</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170107</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170108</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170109</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170110</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170111</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170112</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170113</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170114</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170115</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170116</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170117</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170118</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170119</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170120</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170121</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170122</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170123</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170124</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170125</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170126</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170127</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170128</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170129</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170130</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170131</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201701</StdYM>
    <DateTo>20170101</DateTo>
    <DateFr>20170110</DateFr>
    <SlipKind>1013901001</SlipKind>
    <SlipKindName>판매</SlipKindName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730179,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730064
rollback 