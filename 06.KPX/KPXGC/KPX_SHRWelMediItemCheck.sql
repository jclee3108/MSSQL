  
IF OBJECT_ID('KPX_SHRWelMediItemCheck') IS NOT NULL   
    DROP PROC KPX_SHRWelMediItemCheck  
GO  
  
-- v2014.12.02  
  
-- 의료비신청- 품목 체크 by 이재천   
CREATE PROC KPX_SHRWelMediItemCheck  
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
            @Results        NVARCHAR(250), 
            @Seq            INT 
      
    CREATE TABLE #KPX_THRWelMediItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelMediItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 확정 된 데이터는 삭제할 수 없습니다.
    
    UPDATE A
       SET Result = '확정 된 데이터는 삭제할 수 없습니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_THRWelMediItem                  AS A 
      LEFT OUTER JOIN KPX_THRWelMedi_Confirm    AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.WelMediSeq ) 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
       AND ISNULL(B.CfmCode,'0') = '1'
    
    -- 체크1, END 
    
    
    
    SELECT @Seq = (SELECT TOP 1 WelMediSeq FROM #KPX_THRWelMediItem WHERE WorkingTag = 'A')
    
    -- 번호+코드 따기 :           
    DECLARE @MaxSerl    INT
    
    SELECT @MaxSerl = (SELECT MAX(WelMediSerl) FROM KPX_THRWelMediItem WHERE CompanySeq = @CompanySeq AND WelMediSeq = @Seq) 
    
    UPDATE A 
       SET WelMediSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #KPX_THRWelMediItem AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #KPX_THRWelMediItem   
    
    RETURN  
GO 
begin tran 
exec KPX_SHRWelMediItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FamilyName>11</FamilyName>
    <UMRelName>부</UMRelName>
    <UMRelSeq>1010450001</UMRelSeq>
    <MedicalName>1</MedicalName>
    <BegDate>20141211</BegDate>
    <EndDate>20141211</EndDate>
    <MediAmt>15000</MediAmt>
    <NonPayAmt>500</NonPayAmt>
    <HEmpAmt>14500</HEmpAmt>
    <WelMediSeq>27</WelMediSeq>
    <WelMediSerl>1</WelMediSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105

rollback 