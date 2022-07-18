
IF OBJECT_ID('DTI_SCMEnvSS2Check') IS NOT NULL 
    DROP PROC DTI_SCMEnvSS2Check 
GO 

-- v2013.12.27 

-- 환경설정_DTI(SS2체크) by이재천
CREATE PROC DTI_SCMEnvSS2Check 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TCOMEnvContractEmp (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#DTI_TCOMEnvContractEmp'
    --select * from #DTI_TCOMEnvContractEmp
    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    IF NOT EXISTS ( SELECT 1   
                      FROM #DTI_TCOMEnvContractEmp AS A   
                      JOIN DTI_TCOMEnvContractEmp  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeqOld AND B.DeptSeq = A.DeptSeqOld ) 
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #DTI_TCOMEnvContractEmp  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
      
    
    -- 중복여부 체크 :   
    UPDATE #DTI_TCOMEnvContractEmp  
       SET Result       = N'중복된 데이터가 있습니다.',  
           MessageType  = 1234,  
           Status       = 1234  
      FROM #DTI_TCOMEnvContractEmp AS A   
      JOIN (SELECT S.EmpSeq, S.DeptSeq
              FROM (SELECT A1.EmpSeq, A1.DeptSeq 
                      FROM #DTI_TCOMEnvContractEmp AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.EmpSeq, A1.DeptSeq  
                      FROM DTI_TCOMEnvContractEmp AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #DTI_TCOMEnvContractEmp   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND EmpSeq = A1.EmpSeq 
                                                 AND DeptSeq = A1.DeptSeq 
                                      )  
                   ) AS S  
             GROUP BY S.EmpSeq, S.DeptSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( B.EmpSeq = A.EmpSeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #DTI_TCOMEnvContractEmp 
    
    RETURN 
GO
exec DTI_SCMEnvSS2Check @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptSeq>19</DeptSeq>
    <EmpSeq>268</EmpSeq>
    <DeptSeqOld>0</DeptSeqOld>
    <EmpSeqOld>0</EmpSeqOld>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016063,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013862