  
IF OBJECT_ID('KPXCM_SHRBasCertificateRptCheck') IS NOT NULL   
    DROP PROC KPXCM_SHRBasCertificateRptCheck  
GO  
  
-- v2015.10.20 
  
-- 증명서발행(담당자)-출력체크 by 이재천 
CREATE PROC KPXCM_SHRBasCertificateRptCheck  
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
      
    CREATE TABLE #THRBasCertificate( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THRBasCertificate'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET Result = '전자결재 진행 후 출력이 가능 합니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #THRBasCertificate AS A 
      LEFT OUTER JOIN _THRBasCertificate_Confirm AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.EmpSeq AND C.CfmSerl = A.CertiSeq ) 
     WHERE ISNULL(C.CfmCode,0) = 0 
    
    SELECT * FROM #THRBasCertificate   
      
    RETURN  
GO
exec KPXCM_SHRBasCertificateRptCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>138</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CertiSeq>1</CertiSeq>
    <EmpSeq>2029</EmpSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>139</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CertiSeq>1</CertiSeq>
    <EmpSeq>2063</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031048,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026904



--select * From _THRBasCertificate_Confirm where cfmseq = 1501