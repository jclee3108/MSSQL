  
IF OBJECT_ID('KPXLS_SQCInQCIResultItemSave') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultItemSave  
GO  
  
-- v2015.12.15  
  
-- (검사품)수입검사등록-저장 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TQCTestResultItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestResultItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResultItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQCTestResultItem'    , -- 테이블명        
                  '#KPX_TQCTestResultItem'    , -- 임시 테이블명        
                  'QCSeq,QCSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TQCTestResultItem AS A   
          JOIN KPX_TQCTestResultItem AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq AND A.QCSerl = B.QCSerl ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.TestItemSeq    = A.TestItemSeq, 
               B.QAAnalysisType = A.QAAnalysisType, 
               B.QCUnit         = A.QCUnit, 
               B.TestValue      = A.TestValue, 
               B.SMTestResult   = A.SMTestResult, 
               B.IsSpecial      = A.IsSpecial, 
               B.TestDate       = A.QCDate, 
               B.Remark         = A.Remark, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE()
          FROM #KPX_TQCTestResultItem   AS A   
          JOIN KPX_TQCTestResultItem     AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq AND A.QCSerl = B.QCSerl ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN 
        
    END    
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResultItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TQCTestResultItem  
        (   
            CompanySeq, QCSeq, QCSerl, TestItemSeq, QAAnalysisType, 
            QCUnit, TestValue, SMTestResult, IsSpecial, TestDate, 
            Remark, SMSourceType, SourceSeq, SourceSerl, RegDate, 
            RegEmpSeq, LastUserSeq, LastDateTime 
        )   
        SELECT @CompanySeq, A.QCSeq, A.QCSerl, A.TestItemSeq, A.QAAnalysisType, 
               A.QCUnit, A.TestValue, A.SMTestResult, A.IsSpecial, A.QCDate, 
               A.Remark, C.SMSourceType, B.SourceSeq, B.SourceSerl, GETDATE(), 
               (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq), @UserSeq, GETDATE()
          FROM #KPX_TQCTestResultItem   AS A   
          LEFT OUTER JOIN KPXLS_TQCRequestItem     AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
          LEFT OUTER JOIN KPXLS_TQCRequest         AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = A.ReqSeq ) 
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
      
    SELECT * FROM #KPX_TQCTestResultItem   
      
    RETURN  
    go
    begin tran
exec KPXLS_SQCInQCIResultItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InTestItemName>테스트-사내</InTestItemName>
    <IsSpecial>0</IsSpecial>
    <LowerLimit>1</LowerLimit>
    <OutTestItemName>테스트-사외</OutTestItemName>
    <QAAnalysisName>분석-테스트</QAAnalysisName>
    <QAAnalysisType>1</QAAnalysisType>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <QCUnit>8</QCUnit>
    <QCUnitName>테스트</QCUnitName>
    <RegDate xml:space="preserve">        </RegDate>
    <RegEmpName />
    <RegEmpSeq>0</RegEmpSeq>
    <RegTime xml:space="preserve">    </RegTime>
    <Remark>test1</Remark>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>숫자</SMInputTypeName>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>합격</SMTestResultName>
    <TestItemSeq>31</TestItemSeq>
    <TestValue>1</TestValue>
    <UpdateDate xml:space="preserve">        </UpdateDate>
    <UpdateEmpName />
    <UpdateTime xml:space="preserve">    </UpdateTime>
    <UpperLimit />
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InTestItemName>외관</InTestItemName>
    <IsSpecial>0</IsSpecial>
    <LowerLimit>1</LowerLimit>
    <OutTestItemName>Appearance</OutTestItemName>
    <QAAnalysisName>WS-QA-01-01</QAAnalysisName>
    <QAAnalysisType>2</QAAnalysisType>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <QCUnit>9</QCUnit>
    <QCUnitName>-</QCUnitName>
    <RegDate xml:space="preserve">        </RegDate>
    <RegEmpName />
    <RegEmpSeq>0</RegEmpSeq>
    <RegTime xml:space="preserve">    </RegTime>
    <Remark>test2</Remark>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>숫자</SMInputTypeName>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>합격</SMTestResultName>
    <TestItemSeq>32</TestItemSeq>
    <TestValue>1</TestValue>
    <UpdateDate xml:space="preserve">        </UpdateDate>
    <UpdateEmpName />
    <UpdateTime xml:space="preserve">    </UpdateTime>
    <UpperLimit />
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InTestItemName>용액 외관</InTestItemName>
    <IsSpecial>0</IsSpecial>
    <LowerLimit>1</LowerLimit>
    <OutTestItemName>Appearance of solution</OutTestItemName>
    <QAAnalysisName>WS-QA-01-02</QAAnalysisName>
    <QAAnalysisType>3</QAAnalysisType>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <QCUnit>10</QCUnit>
    <QCUnitName>Area %</QCUnitName>
    <RegDate xml:space="preserve">        </RegDate>
    <RegEmpName />
    <RegEmpSeq>0</RegEmpSeq>
    <RegTime xml:space="preserve">    </RegTime>
    <Remark>test3</Remark>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>숫자</SMInputTypeName>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>합격</SMTestResultName>
    <TestItemSeq>33</TestItemSeq>
    <TestValue>1</TestValue>
    <UpdateDate xml:space="preserve">        </UpdateDate>
    <UpdateEmpName />
    <UpdateTime xml:space="preserve">    </UpdateTime>
    <UpperLimit />
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027993
select * from  KPX_TQCTestResultItem where qcseq = 20 
rollback 
