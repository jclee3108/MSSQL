  
IF OBJECT_ID('KPXCM_SEQRegInspectChgCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectChgCheck  
GO  
  
-- v2015.07.01  
  
-- 정기검사계획조정등록-체크 by 이재천   
CREATE PROC KPXCM_SEQRegInspectChgCheck  
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
    
    CREATE TABLE #KPXCM_TEQRegInspectChg( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspectChg'   
    IF @@ERROR <> 0 RETURN     
    
    ----------------------------------------------------------------------
    -- 체크1, 점검내역이 등록되어 수정,삭제 할 수 없습니다. 
    ----------------------------------------------------------------------
    
    UPDATE A
       SET Result = '점검내역이 등록되어 수정,삭제 할 수 없습니다. ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQRegInspectChg AS A 
      JOIN KPXCM_TEQRegInspectRst AS B ON ( B.CompanySeq = @CompanySeq AND B.QCDate = A.ReplaceDateOld AND B.RegInspectSeq = A.RegInspectSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
      
    ----------------------------------------------------------------------
    -- 체크1, END 
    ----------------------------------------------------------------------  
    
    
    SELECT * FROM #KPXCM_TEQRegInspectChg   
      
    RETURN  
GO 

exec KPXCM_SEQRegInspectChgCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RegInspectSeq>6</RegInspectSeq>
    <QCPlanDate>20150825</QCPlanDate>
    <ReplaceDate>20150729</ReplaceDate>
    <Remark />
    <ReplaceDateOld />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030624,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025548