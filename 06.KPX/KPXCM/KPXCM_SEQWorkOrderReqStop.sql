  
IF OBJECT_ID('KPXCM_SEQWorkOrderReqStop') IS NOT NULL   
    DROP PROC KPXCM_SEQWorkOrderReqStop  
GO  
  
-- v2015.10.13  
  
-- 작업요청조회(일반)-중단 by 이재천 
CREATE PROC KPXCM_SEQWorkOrderReqStop  
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
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQWorkOrderReqMasterCHEIsStop')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQWorkOrderReqMasterCHEIsStop'    , -- 테이블명        
                  '#KPXCM_TEQWorkOrderReqMasterCHEIsStop'    , -- 임시 테이블명        
                  'WOReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    UPDATE A 
       SET IsStop = CASE WHEN A.IsStop = '0' THEN '1' ELSE '0' END 
      FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop AS A
     WHERE A.Status = 0 
    
    --select * from #KPXCM_TEQWorkOrderReqMasterCHEIsStop 
    --return
    
    UPDATE B
       SET IsStop = A.IsStop, 
           StopDate = CASE WHEN A.IsStop = '1' THEN A.StopDate ELSE '' END, 
           StopEmpSeq = CASE WHEN A.IsStop = '1' THEN A.StopEmpSeq ELSE 0 END, 
           StopReason = CASE WHEN A.IsStop = '1' THEN A.StopReason ELSE '' END, 
           LastUserSeq = @UserSeq, 
           LastDateTime = GETDATE(), 
           PgmSeq = @PgmSeq 
      FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop    AS A 
      JOIN KPXCM_TEQWorkOrderReqMasterCHEIsStop     AS B ON ( B.CompanySeq = @CompanySeq AND B.WOReqSeq = A.WOReqSeq ) 
     WHERE A.Status = 0 
    
    IF @@ERROR <> 0 RETURN  
    
    INSERT INTO KPXCM_TEQWorkOrderReqMasterCHEIsStop  
    (   
        CompanySeq, WOReqSeq, IsStop, StopDate, StopEmpSeq, 
        StopReason, LastUserSeq, LastDateTime, PgmSeq
    )   
    SELECT @CompanySeq, WOReqSeq, IsStop, CASE WHEN A.IsStop = '1' THEN A.StopDate ELSE '' END, CASE WHEN A.IsStop = '1' THEN A.StopEmpSeq ELSE 0 END, 
           CASE WHEN A.IsStop = '1' THEN A.StopReason ELSE '' END, @UserSeq, GETDATE(), @PgmSeq
      FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop AS A   
     WHERE A.Status = 0      
       AND NOT EXISTS (SELECT 1 FROM KPXCM_TEQWorkOrderReqMasterCHEIsStop WHERE CompanySeq = @CompanySeq AND WOReqSeq = A.WOReqSeq ) 
      
    IF @@ERROR <> 0 RETURN  
    
    SELECT * FROM #KPXCM_TEQWorkOrderReqMasterCHEIsStop 
    
    RETURN 
    go
    begin tran 
exec KPXCM_SEQWorkOrderReqStop @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <WOReqSeq>62</WOReqSeq>
    <IsStop>1</IsStop>
    <StopDate>20151013</StopDate>
    <StopReason>asdsdfgsdfg</StopReason>
    <StopEmpSeq>2028</StopEmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031202,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025841
select * from KPXCM_TEQWorkOrderReqMasterCHEIsStop 
rollback 