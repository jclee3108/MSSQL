  
IF OBJECT_ID('hye_SSLOilGasCloseListSave') IS NOT NULL   
    DROP PROC hye_SSLOilGasCloseListSave
GO  
  
-- v2017.01.10
  
-- POS주유소충전소마감현황_hye-저장 by이재천 
CREATE PROC hye_SSLOilGasCloseListSave  
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
    
    --select * from #DataBlock3 

    --select @DateFr, @DateTo 
    
    IF @WorkingTag = 'A' -- 일괄마감 
    BEGIN 
        INSERT INTO hye_TSLOilSalesIsClose 
        ( 
            CompanySeq, BizUnit, StdYMDate, io_type, IsClose, 
            CloseDate, LastUserSeq, LastDateTime, PgmSeq
        )
        SELECT @CompanySeq AS CompanySeq, 
               A.BizUnit, 
               A.TITLE_IDX0_SEQ AS StdYMDate, 
               CASE WHEN @UMSlipKind = 1013901001 THEN 'O' ELSE 'I' END AS io_type, 
               '1' AS IsClose, 
               CONVERT(NCHAR(8),GETDATE(),112) AS CloseDate, 
               @UserSeq, 
               GETDATE(), 
               @PgmSeq 
          FROM #DataBlock3 AS A 
         WHERE A.TITLE_IDX0_SEQ BETWEEN @DateFr AND @DateTo 
           AND NOT EXISTS (
                            SELECT 1 
                              FROM hye_TSLOilSalesIsClose 
                             WHERE CompanySeq = @CompanySeq 
                               AND BizUnit = A.BizUnit 
                               AND StdYMDate = A.TITLE_IDX0_SEQ
                               AND io_type = CASE WHEN @UMSlipKind = 1013901001 THEN 'O' ELSE 'I' END
                          )
    
    
        
        UPDATE A
           SET IsClose = '1' 
          FROM hye_TSLOilSalesIsClose   AS A 
          JOIN #DataBlock3              AS B ON ( B.BizUnit = A.BizUnit 
                                              AND B.TITLE_IDX0_SEQ = A.StdYMDate 
                                              AND CASE WHEN @UMSlipKind = 1013901001 THEN 'O' ELSE 'I' END = A.io_type
                                              AND B.TITLE_IDX0_SEQ BETWEEN @DateFr AND @DateTo
                                                ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND ISNULL(A.IsClose,'0') = '0' 
    END 


    IF @WorkingTag = 'D' -- 일괄마감취소
    BEGIN 
        
        UPDATE A
           SET IsClose = '0' 
          FROM hye_TSLOilSalesIsClose   AS A 
          JOIN #DataBlock3              AS B ON ( B.BizUnit = A.BizUnit 
                                              AND B.TITLE_IDX0_SEQ = A.StdYMDate 
                                              AND CASE WHEN @UMSlipKind = 1013901001 THEN 'O' ELSE 'I' END = A.io_type
                                              AND B.TITLE_IDX0_SEQ BETWEEN @DateFr AND @DateTo
                                                ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND ISNULL(A.IsClose,'0') = '1' 
    END 



    SELECT * FROM #DataBlock1
    SELECT * FROM #DataBlock3


    RETURN 
GO
begin tran 


exec hye_SSLOilGasCloseListSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170101</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170102</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170103</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170104</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170105</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170106</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170107</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170108</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170109</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170110</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170111</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170112</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170113</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170114</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170115</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170116</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170117</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170118</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170119</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170120</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170121</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170122</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170123</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170124</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170125</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170126</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170127</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170128</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170129</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170130</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <BizUnitName>화학사업부문</BizUnitName>
    <BizUnit>801</BizUnit>
    <TITLE_IDX0_SEQ>20170131</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <StdYM>201701</StdYM>
    <DateTo>20170110</DateTo>
    <DateFr>20170101</DateFr>
    <SlipKindName>판매</SlipKindName>
    <SlipKind>1013901001</SlipKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730179,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730064



rollback 