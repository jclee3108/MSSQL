IF OBJECT_ID('KPXCM_SQCInStockInspectionResultItemSubSave') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionResultItemSubSave
GO 

-- v2016.06.15 

/************************************************************
 설  명 - 데이터-재고검사등록 : 재고검사등록I저장
 작성일 - 20141204
 작성자 - 오정환
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SQCInStockInspectionResultItemSubSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #KPX_TQCTestResultItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestResultItem'     
    IF @@ERROR <> 0 RETURN  
    
    --CREATE TABLE #KPX_TQCTestResultItem (WorkingTag NCHAR(1) NULL)  
    --EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestResultItem'     
    --IF @@ERROR <> 0 RETURN  
    
    UPDATE #KPX_TQCTestResultItem
    SET TestValue = UPPER(TestValue) 

    -- 로그 남기기  
    DECLARE @TableColumns NVARCHAR(4000)  
    
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResultItem')  
    
    EXEC _SCOMLog @CompanySeq   ,      
                  @UserSeq      ,      
                  'KPX_TQCTestResultItem'    , -- 테이블명      
                  '#KPX_TQCTestResultItem'    , -- 임시 테이블명      
                  'QCSeq,QCSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )      
                  @TableColumns , 'StockQCSeq, StockQCSerl', @PgmSeq  -- 테이블 모든 필드명 



    -- Master 합/부판정
    DECLARE @OK         INT,
            @Bad        INT,
            @Special    INT,
            @StockQCSeq INT

    SELECT @OK          = 0,
           @Bad         = 0,
           @Special     = 0


-- 작업순서 맞추기: DELETE -> UPDATE -> INSERT

    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
            DELETE KPX_TQCTestResultItem
              FROM #KPX_TQCTestResultItem      AS A JOIN KPX_TQCTestResultItem AS B ON A.CompanySeq    = @CompanySeq
                                                                                   AND A.StockQCSeq    = B.QCSeq
                                                                                   AND A.StockQCSerl   = B.QCSerl
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
         
             IF @@ERROR <> 0  RETURN
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN

            UPDATE KPX_TQCTestResultItem
               SET TestItemSeq       = A.TestItemSeq       ,
                   QAAnalysisType    = A.AnalysisSeq       ,
                   SMTestResult      = A.SMTestResult      ,
                   EmpSeq            = A.EmpSeq            ,
                   QCUnit            = A.QCUnitSeq         ,
                   TestValue         = A.TestValue         ,
                   IsSpecial         = A.IsSpecial         ,
                   Remark            = A.Remark            ,
                   Contents          = A.Contents          ,
                   RegDate           = CASE WHEN ISNULL(B.RegDate, '') <> '' THEN B.RegDate        
                                            ELSE GETDATE() END, 
                   RegEmpSeq         = CASE WHEN ISNULL(B.RegEmpSeq, 0) <> 0 THEN B.RegEmpSeq         
                                            ELSE (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) END, 
                   LastUserSeq       = @UserSeq            ,
                   LastDateTime      = GETDATE()
              FROM #KPX_TQCTestResultItem      AS A JOIN KPX_TQCTestResultItem AS B ON B.CompanySeq    = @CompanySeq
                                                                                   AND A.StockQCSeq    = B.QCSeq
                                                                                   AND A.StockQCSerl   = B.QCSerl
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'U' 
               AND A.Status     = 0    
   
            IF @@ERROR <> 0  RETURN

    END  
    

    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
            


            INSERT INTO KPX_TQCTestResultItem (
                                                CompanySeq      ,
                                                QCSeq           ,
                                                QCSerl          ,
                                                TestItemSeq     ,
                                                QAAnalysisType  ,
                                                QCUnit          ,
                                                TestValue       ,
                                                SMTestResult    ,
                                                IsSpecial       ,
                                                TestHour        ,
                                                EmpSeq          ,
                                                TestDate        ,
                                                GetSample       ,
                                                Remark          ,
                                                Contents        ,
                                                IsChecked       ,
                                                SMSourceType    ,
                                                SourceSeq       ,
                                                SourceSerl      ,
                                                RegDate         ,
                                                RegEmpSeq       ,
                                                LastUserSeq     ,
                                                LastDateTime    ,
                                                QCType
                                            ) 
            SELECT @CompanySeq      ,
                   StockQCSeq       , 
                   StockQCSerl      , 
                   TestItemSeq      , 
                   AnalysisSeq      , 
                   QCUnitSeq        , 
                   TestValue        ,
                   SMTestResult     , 
                   IsSpecial        ,
                   0                ,
                   EmpSeq           , 
                   TestDate         ,
                   ''               ,
                   Remark           ,
                   Contents         , 
                   ''               ,
                   1000522001       , 
                   0                ,
                   0                ,
                   GetDate()        ,
                   (SELECT EmpSeq FROM _TCAUser WHERE COmpanySEq = @CompanySEq AND UserSeq = @Userseq),
                   @UserSeq         ,
                   GetDate()        ,
                   0
              FROM #KPX_TQCTestResultItem
             WHERE WorkingTag = 'A' 
               AND Status = 0    

            IF @@ERROR <> 0 RETURN


    END   

    -- Master 합/부 업데이트
    CREATE TABLE #Temp
    (   
        SMTestResult    INT,
        IsSpecial       NCHAR(1)
    )

    INSERT #Temp
    SELECT A.SMTestResult,
           A.IsSpecial
      FROM KPX_TQCTestResultItem A JOIN #KPX_TQCTestResultItem B ON A.CompanySeq    = @CompanySeq
                                                                AND A.QCSeq         = B.StockQCSeq
                                                                AND A.QCSerl       <> B.StockQCSerl
    UNION ALL

    SELECT SMTestResult,
           IsSpecial
      FROM #KPX_TQCTestResultItem

    IF EXISTS(SELECT 1 FROM #Temp WHERE SMTestResult = 6035004 AND IsSpecial <> '1') -- 불합격 이면서 특채가 아닌건이 존재 하면 불합격
    BEGIN
        SELECT @Bad = 1
    END
    ELSE IF EXISTS(SELECT 1 FROM #Temp WHERE SMTestResult = 6035004 AND IsSpecial = '1') -- 불합격 이면서 특채이면 특채
    BEGIN
        SELECT @Special = 1
    END
    ELSE -- 합격
    BEGIN
        SELECT @OK = 1
    END

    SELECT TOP 1 
           @StockQCSeq = StockQCSeq
      FROM #KPX_TQCTestResultItem
            
    IF @OK = 1
    BEGIN
        UPDATE KPX_TQCTestResult
            SET SMTestResult = 1010418001
            WHERE 1=1
            AND CompanySeq  = @CompanySeq
            AND QCSeq       = @StockQCSeq

        UPDATE #KPX_TQCTestResultItem
           SET SMTestResultMst          = 1010418001

    END
    ELSE IF @Bad = 1
    BEGIN
        UPDATE KPX_TQCTestResult
            SET SMTestResult = 1010418002
            WHERE  1=1
            AND CompanySeq  = @CompanySeq
            AND QCSeq       = @StockQCSeq

        UPDATE #KPX_TQCTestResultItem
            SET SMTestResultMst          = 1010418002
    END
    ELSE
    BEGIN
        UPDATE KPX_TQCTestResult
            SET SMTestResult = 1010418003
            WHERE 1=1
            AND CompanySeq  = @CompanySeq
            AND QCSeq       = @StockQCSeq

        UPDATE #KPX_TQCTestResultItem
            SET SMTestResultMst          = 1010418003

    END
        
    UPDATE A
        SET SMTestResultNameMst = B.MinorName
        FROM #KPX_TQCTestResultItem as a 
        LEFT OUTER JOIN _TDAUMInor AS B ON ( B.CompanySeq = @COmpanySeq AND B.MinorSeq = A.SMTestResultMst ) 
    
    
    --측정치와 합/부를 공백으로 변경하게되면 RegDate, RegEmpSeq를 없앰    
    UPDATE A    
       SET A.RegDate   = NULL,    
           A.RegEmpSeq = NULL    
      FROM KPX_TQCTestResultItem    AS A   
      JOIN #KPX_TQCTestResultItem   AS B ON A.QCSeq = B.StockQCSeq AND A.QCSerl = B.StockQCSerl    
     WHERE A.CompanySeq   = @CompanySeq    
       AND A.TestValue    = ''    
       AND A.SMTestResult = 0    
       
    UPDATE A    
       SET RegDate   = CASE WHEN B.TestValue = '' AND B.SMTestResult = 0 THEN NULL ELSE CONVERT(NCHAR(8),B.RegDate,112) END,    
           RegEmpSeq = CASE WHEN B.TestValue = '' AND B.SMTestResult = 0 THEN NULL ELSE B.RegEmpSeq END,    
           RegEmpName = CASE WHEN B.TestValue = '' AND B.SMTestResult = 0 THEN NULL ELSE (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = B.RegEmpSeq) END,    
           RegTime = CASE WHEN B.TestValue = '' AND B.SMTestResult = 0 THEN NULL ELSE CONVERT(NVARCHAR(5), B.RegDate, 108) END  
      FROM #KPX_TQCTestResultItem   AS A   
      JOIN KPX_TQCTestResultItem    AS B ON A.StockQCSeq = B.QCSeq AND A.StockQCSerl = B.QCSerl  
     WHERE B.CompanySeq   = @CompanySeq    
    
    
    UPDATE A    
       SET LastDate = CASE WHEN A.RegDate IS NULL THEN '' ELSE (CASE WHEN B.LastDateTime = B.RegDate THEN '' ELSE CONVERT(NVARCHAR(100),B.LastDateTime,20) END) END,   
           LastEmpName = CASE WHEN A.RegDate IS NULL THEN '' ELSE (CASE WHEN B.LastDateTime = B.RegDate THEN '' ELSE C.UserName END) END  
      FROM #KPX_TQCTestResultItem   AS A   
      JOIN KPX_TQCTestResultItem    AS B ON A.StockQCSeq = B.QCSeq AND A.StockQCSerl = B.QCSerl  
      JOIN _TCAUser                 AS C ON ( C.CompanySeq = @CompanySeq AND C.UserSeq = B.LastUserSeq )   
     WHERE B.CompanySeq   = @CompanySeq    

    SELECT * FROM #KPX_TQCTestResultItem 
RETURN 
GO
begin tran 
exec KPXCM_SQCInStockInspectionResultItemSubSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <StockQCSeq>235</StockQCSeq>
    <StockQCSerl>1</StockQCSerl>
    <TestItemSeq>1</TestItemSeq>
    <AnalysisSeq>1</AnalysisSeq>
    <QCUnitSeq>1</QCUnitSeq>
    <TestValue />
    <SMTestResult>0</SMTestResult>
    <IsSpecial>0</IsSpecial>
    <EmpSeq>0</EmpSeq>
    <TestDate>20160614</TestDate>
    <RegDate>20160614</RegDate>
    <RegTime>17:24</RegTime>
    <RegEmpSeq>2028</RegEmpSeq>
    <RegEmpName>이재천</RegEmpName>
    <LastDate>2016-06-15 10:42:34</LastDate>
    <LastEmpName>이재천</LastEmpName>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037459,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030582

rollback 


