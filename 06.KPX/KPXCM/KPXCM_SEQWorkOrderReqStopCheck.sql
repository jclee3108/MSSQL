  
IF OBJECT_ID('KPXCM_SEQWorkOrderReqStopCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQWorkOrderReqStopCheck  
GO  
  
-- v2015.10.13  
  
-- 작업요청조회(일반)-중단 체크 by 이재천 
CREATE PROC KPXCM_SEQWorkOrderReqStopCheck  
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
      
    CREATE TABLE #KPXCM_TEQWorkOrderReqMasterCHEIsStop( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQWorkOrderReqMasterCHEIsStop'   
    IF @@ERROR <> 0 RETURN     
    
    
    UPDATE A 
       SET Result = '중단 권한이 없습니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop        AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '')     AS B ON ( B.EmpSeq = A.StopEmpSeq ) 
     WHERE NOT EXISTS (SELECT 1 FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 61 AND EnvValue = A.StopEmpSeq) -- 담당자 권한 
       AND NOT EXISTS (SELECT 1 FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 62 AND EnvValue = B.DeptSeq ) -- 부서권한 
    
    
    SELECT * FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop 
    
    RETURN 
    go
    begin tran 
    exec KPXCM_SEQWorkOrderReqStopCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>0</IsStop>
    <WOReqSeq>63</WOReqSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <StopReason>ㅁㄴㅇㅎㅁㄴㅇㅎ</StopReason>
    <StopDate>20151013</StopDate>
    <StopEmpSeq>2028</StopEmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031202,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025841
rollback 