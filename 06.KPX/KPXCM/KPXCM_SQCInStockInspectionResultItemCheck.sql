IF OBJECT_ID('KPXCM_SQCInStockInspectionResultItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionResultItemCheck
GO 

-- v2016.09.29 

-- KPXCM용으로 개발 by이재천 

/************************************************************
 설  명 - 데이터-재고검사등록 : 재고검사등록I체크
 작성일 - 20141204
 작성자 - 오정환
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SQCInStockInspectionResultItemCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #KPX_TQCTestResultItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestResultItem'

----===============--
---- 필수입력 체크 --
----===============--

---- 필수입력 Message 받아오기
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')
                          @LanguageSeq       , 
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

-- 필수입력 Check 
      UPDATE #KPX_TQCTestResultItem
         SET Result        = @Results,
             MessageType   = @MessageType,
             Status        = @Status
        FROM #KPX_TQCTestResultItem AS A
       WHERE A.WorkingTag IN ('A','U')
         AND A.Status = 0
         AND (A.TestItemSeq = 0 OR  A.AnalysisSeq   = 0
                                OR  A.QCUnitSeq     = 0)



--==================================================================================--  
------ 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존재하지 않으면 에러처리 ----------
--==================================================================================--  
    IF  EXISTS (SELECT 1   
                  FROM #KPX_TQCTestResultItem AS A LEFT OUTER JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq    = @CompanySeq 
                                                                                                          AND A.StockQCSeq    = B.QCSeq
                                                                                                          AND A.StockQCSerl   = B.QCSerl
                          
                 WHERE A.WorkingTag IN ('U', 'D')
                   AND B.QCSerl IS NULL )  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
         UPDATE #KPX_TQCTestResultItem  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #KPX_TQCTestResultItem AS A LEFT OUTER  JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq    = @CompanySeq 
                                                                                                    AND A.StockQCSeq    = B.QCSeq
                                                                                                    AND A.StockQCSerl   = B.QCSerl
                          
          WHERE A.WorkingTag IN ('U', 'D')
            AND B.QCSerl IS NULL
    END   




--guide : '디테일 키 생성' --------------------------
    DECLARE @MaxSeq      INT ,
            @Count       INT
  

    SELECT @Count = COUNT(1) FROM  #KPX_TQCTestResultItem    WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN

      SELECT @MaxSeq =ISNULL(MAX(A.QCSerl),0)
        FROM KPX_TQCTestResultItem         AS A JOIN #KPX_TQCTestResultItem    AS B ON  A.QCSeq= B.StockQCSeq
       WHERE A.CompanySeq  = @CompanySeq 
         AND B.WorkingTag = 'A'            
         AND B.Status = 0 
          
      UPDATE A                
         SET StockQCSerl  = @MaxSeq + RowNum   
        FROM #KPX_TQCTestResultItem A JOIN (SELECT DataSeq, ROW_NUMBER()OVER(ORDER BY DataSeq) AS RowNum 
                                              FROM #KPX_TQCTestResultItem 
                                             WHERE WorkingTag = 'A') B ON A.DataSeq = B.DataSeq
       WHERE WorkingTag = 'A'            
         AND Status = 0 
    END             
                           
    SELECT * FROM #KPX_TQCTestResultItem 

RETURN    



go
exec KPXCM_SQCInStockInspectionResultItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StockQCSerl>0</StockQCSerl>
    <TestItemSeq>9</TestItemSeq>
    <AnalysisSeq>80</AnalysisSeq>
    <QCUnitSeq>13</QCUnitSeq>
    <TestValue>245</TestValue>
    <SMTestResult>6035003</SMTestResult>
    <IsSpecial>0</IsSpecial>
    <EmpSeq>0</EmpSeq>
    <Contents />
    <ContentsContents />
    <TestDate>20160708</TestDate>
    <RegDate />
    <RegEmpSeq>0</RegEmpSeq>
    <RegEmpName />
    <RegTime />
    <LastDate />
    <LastEmpName />
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <StockQCSeq>28151</StockQCSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037459,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030582