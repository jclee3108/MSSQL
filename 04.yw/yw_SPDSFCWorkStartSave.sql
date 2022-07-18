 
IF OBJECT_ID('yw_SPDSFCWorkStartSave') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartSave 
GO 
    
-- v2013.08.01 
  
-- 공정개시입력(현장)_YW(저장) by이재천   
CREATE PROC yw_SPDSFCWorkStartSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #YW_TPDSFCWorkStart (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDSFCWorkStart')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPDSFCWorkStart'    , -- 테이블명        
                  '#YW_TPDSFCWorkStart'    , -- 임시 테이블명        
                  'WorkCenterSeq,WorkOrderSeq,Serl,EmpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'WorkCenterSeq,WorkOrderSeq,Serl,EmpSeqOld', @PgmSeq  -- 테이블 모든 필드명   

    -- 작업순서 : DELETE -> UPDATE -> INSERT   
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        IF @WorkingTag <> 'Delete'
        BEGIN
            DELETE B   
              FROM #YW_TPDSFCWorkStart AS A   
              JOIN YW_TPDSFCWorkStart  AS B ON ( B.CompanySeq = @CompanySeq AND A.EmpSeqOld = B.EmpSeq AND A.Serl = B.Serl )    
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END
        
        IF @WorkingTag = 'Delete'
        BEGIN
            DELETE B   
              FROM #YW_TPDSFCWorkStart AS A   
              JOIN YW_TPDSFCWorkStart AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.WorkOrderSeq = B.WorkOrderSeq )
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'U' AND Status = 0 ) 
    BEGIN
        IF @WorkingTag <> 'EndTime'
        BEGIN  
            UPDATE B   
               SET B.EmpSeq   = A.EmpSeq,  
                   B.LastUserSeq  = @UserSeq,  
                   B.LastDateTime = GETDATE()   
              FROM #YW_TPDSFCWorkStart AS A   
              JOIN YW_TPDSFCWorkStart AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq  AND A.EmpSeqOld = B.EmpSeq AND A.Serl = B.Serl ) 
             WHERE A.WorkingTag = 'U'   
               AND A.Status = 0      
              
            IF @@ERROR <> 0  RETURN  
              
        END    
    END

    -- 투입종료 시간 UPDATE
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'U' AND Status = 0 ) 
    BEGIN
        IF @WorkingTag = 'EndTime' 
        BEGIN  
            UPDATE B   
               SET B.EndTime = CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),  
                   B.Serl = A.Serl, 
                   B.LastUserSeq  = @UserSeq,  
                   B.LastDateTime = GETDATE()   
              FROM #YW_TPDSFCWorkStart AS A   
              JOIN YW_TPDSFCWorkStart AS B ON ( B.CompanySeq = @CompanySeq AND A.EmpSeqOld = B.EmpSeq  AND A.WorkCenterSeq = B.WorkCenterSeq AND A.WorkOrderSeq = B.WorkOrderSeq ) 
             WHERE A.WorkingTag = 'U'   
               AND A.Status = 0      
              
            IF @@ERROR <> 0  RETURN  
              
        END 
    END 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO YW_TPDSFCWorkStart  
        (   
            CompanySeq, WorkCenterSeq, WorkOrderSeq, Serl, EmpSeq, 
            StartTime, EndTime, LastUserSeq, LastDateTime

        )   
        SELECT @CompanySeq, ISNULL(A.WorkCenterSeq,0), ISNULL(A.WorkOrderSeq,0), A.Serl, A.EmpSeq, 
               CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4), '', @UserSeq, GETDATE()
          FROM #YW_TPDSFCWorkStart AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  

    END 

        IF @WorkingTag <> 'EndTime'
        BEGIN
            UPDATE #YW_TPDSFCWorkStart
               SET StartTime = STUFF(STUFF(STUFF(STUFF(CONVERT(NVARCHAR(10),GETDATE(),112) + 
                                                       LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),5,0,'-'
                                                      ),8,0,'-'
                                                ),11,0,' '
                                          ),14,0,':'
                                    ), 
                   EmpSeqOld = EmpSeq,
                   Serl = Serl
              FROM #YW_TPDSFCWorkStart 
             WHERE WorkingTag = 'A'   
               AND Status = 0  
        END     

        IF @WorkingTag = 'EndTime'
        BEGIN
            UPDATE #YW_TPDSFCWorkStart
               SET EndTime = STUFF(STUFF(STUFF(STUFF(CONVERT(NVARCHAR(10),GETDATE(),112) + 
                                                     LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),5,0,'-'
                                                    ),8,0,'-'
                                               ),11,0,' '
                                        ),14,0,':'
                                  ) 
              FROM #YW_TPDSFCWorkStart
             WHERE WorkingTag = 'U'   
               AND Status = 0  
        END
     
    SELECT * FROM #YW_TPDSFCWorkStart   
      
    RETURN  
GO
exec yw_SPDSFCWorkStartSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EndTime xml:space="preserve">                </EndTime>
    <Sel>1</Sel>
    <Serl>111</Serl>
    <StartTime>2013-08-01 09:45</StartTime>
    <WorkCenterSeq>2</WorkCenterSeq>
    <WorkOrderSeq>131292</WorkOrderSeq>
    <EmpSeqOld>2028</EmpSeqOld>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmpName>이지은</EmpName>
    <EmpSeq>2029</EmpSeq>
    <EndTime xml:space="preserve">                </EndTime>
    <Sel>1</Sel>
    <Serl>111</Serl>
    <StartTime>2013-08-01 09:45</StartTime>
    <WorkCenterSeq>2</WorkCenterSeq>
    <WorkOrderSeq>131292</WorkOrderSeq>
    <EmpSeqOld>2029</EmpSeqOld>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016755,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014297