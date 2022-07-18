  
IF OBJECT_ID('yw_SPJTToolTestResultSave') IS NOT NULL   
    DROP PROC yw_SPJTToolTestResultSave  
GO  
  
-- v2014.07.02  
  
-- 금형테스트이력등록_YW(저장) by 이재천   
CREATE PROC yw_SPJTToolTestResultSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #yw_TPJTToolResult (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTToolResult'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('yw_TPJTToolResult')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'yw_TPJTToolResult'    , -- 테이블명        
                  '#yw_TPJTToolResult'    , -- 임시 테이블명        
                  'PJTSeq,ToolSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTToolResult WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #yw_TPJTToolResult   AS A   
          JOIN yw_TPJTToolResult    AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ToolSeq = A.ToolSeq AND B.Serl = A.Serl ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTToolResult WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.Results        = A.Results,  
               B.RevResults     = A.RevResults, 
               B.RevDate        = A.RevDate, 
               B.RevEndDate     = A.RevEndDate, 
               B.TestRegDate    = A.TestRegDate, 
               B.EmpSeq         = A.EmpSeq, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE() 
          FROM #yw_TPJTToolResult   AS A   
          JOIN yw_TPJTToolResult    AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ToolSeq = A.ToolSeq AND B.Serl = A.Serl ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTToolResult WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO yw_TPJTToolResult  
        (   
            CompanySeq, PJTSeq, ToolSeq, Serl, Results, 
            RevResults, RevDate, RevEndDate, TestRegDate, EmpSeq, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.PJTSeq, A.ToolSeq, A.Serl, A.Results, 
               A.RevReSults, A.RevDate, A.RevEndDate, A.TestRegDate, A.EmpSeq, 
               @UserSeq, GETDATE() 
          FROM #yw_TPJTToolResult AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    END     
    
    SELECT * FROM #yw_TPJTToolResult   
      
    RETURN  
GO
begin tran 
exec yw_SPJTToolTestResultSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmpSeq>2028</EmpSeq>
    <PJTSeq>1</PJTSeq>
    <Results>23545</Results>
    <RevDate>20140702</RevDate>
    <RevEndDate>20140701</RevEndDate>
    <RevResults>345345</RevResults>
    <Serl>34</Serl>
    <TestRegDate>20140701</TestRegDate>
    <ToolSeq>1</ToolSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023444,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019676
rollback 