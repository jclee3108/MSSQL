  
IF OBJECT_ID('KPX_SEQChangeCmmReviewEmpCHECheck') IS NOT NULL   
    DROP PROC KPX_SEQChangeCmmReviewEmpCHECheck  
GO  
  
-- v2014.12.12  
  
-- 변경위원회회의록등록-참석자 체크 by 이재천   
CREATE PROC KPX_SEQChangeCmmReviewEmpCHECheck  
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
    
    CREATE TABLE #KPX_TEQChangeCmmReviewEmpCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TEQChangeCmmReviewEmpCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE A  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TEQChangeCmmReviewEmpCHE AS A   
      JOIN (SELECT S.ReviewSeq, S.EmpSeq   
              FROM (SELECT A1.ReviewSeq, A1.EmpSeq   
                      FROM #KPX_TEQChangeCmmReviewEmpCHE AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ReviewSeq, A1.EmpSeq   
                      FROM KPX_TEQChangeCmmReviewEmpCHE AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TEQChangeCmmReviewEmpCHE   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ReviewSeq = A1.ReviewSeq 
                                                 AND EmpSeqOld = A1.EmpSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ReviewSeq, S.EmpSeq   
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ReviewSeq = B.ReviewSeq AND A.EmpSeq = B.EmpSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TEQChangeCmmReviewEmpCHE   
      
    RETURN  
GO 
exec KPX_SEQChangeCmmReviewEmpCHECheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <IsJoin>0</IsJoin>
    <EmpSeqOld>0</EmpSeqOld>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ReviewSeq>1</ReviewSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptSeq>1679</DeptSeq>
    <EmpSeq>2017</EmpSeq>
    <IsJoin>0</IsJoin>
    <EmpSeqOld>0</EmpSeqOld>
    <ReviewSeq>1</ReviewSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026713,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021388