  
IF OBJECT_ID('costel_SSLDelvContractCfmSave') IS NOT NULL   
    DROP PROC costel_SSLDelvContractCfmSave
GO  
  
-- v2013.09.09 
  
-- 납품계약등록_costel(확정) by이재천  
CREATE PROC costel_SSLDelvContractCfmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #costel_TSLDelvContract (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#costel_TSLDelvContract'   
    IF @@ERROR <> 0 RETURN   
    
    UPDATE A
       SET Result = N'진행된 데이터는 확정 취소를 할 수 없습니다.', 
           Status = 1234
      FROM #costel_TSLDelvContract AS A 
     WHERE EXISTS (SELECT Dummy6 FROM _TSLOrderItem AS B WHERE B.CompanySeq = @CompanySeq AND B.Dummy6 = A.ContractSeq)
    
    UPDATE B   
       SET B.IsCfm = A.IsCfm,  
           B.CfmDate = CASE WHEN A.IsCfm = 1 THEN CONVERT(NVARCHAR(8),GETDATE(),112) ELSE '' END 
      FROM #costel_TSLDelvContract AS A   
      JOIN costel_TSLDelvContract  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq ) 
     WHERE Status = 0  

    IF @@ERROR <> 0  RETURN   
    
    UPDATE A 
       SET IsCfm = B.IsCfm, 
           CfmDate = B.CfmDate, 
           Result = CASE WHEN A.IsCfm = 1 THEN N'확정처리 되었습니다.' ELSE N'확정취소 되었습니다.' END,
           SMStatusSeq = CASE WHEN B.IsStop = 1 
                              THEN 7027002 
                              WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = B.ContractSeq) = 
                                   (SELECT COUNT(1) FROM costel_TSLDelvContractItem AS X WHERE X.CompanySeq = @CompanySeq AND X.ContractSeq = B.ContractSeq)
                              THEN 7027004 
                              WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WITH(NOLOCK) WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = B.ContractSeq) <> 0 AND
                                   (SELECT COUNT(1) FROM _TSLOrderItem AS Z WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = B.ContractSeq) < 
                                   (SELECT COUNT(1) FROM costel_TSLDelvContractItem AS X WHERE X.CompanySeq = @CompanySeq AND X.ContractSeq = B.ContractSeq) 
                              THEN 7027005 
                              WHEN B.IsCfm = 1 
                              THEN 7027003 
                              WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = B.ContractSeq) = 0
                              THEN 7027001
                              END 
      FROM #costel_TSLDelvContract AS A
      JOIN costel_TSLDelvContract  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )  
     WHERE Status = 0
    
    SELECT * FROM #costel_TSLDelvContract   
      
    RETURN  
GO
exec costel_SSLDelvContractCfmSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ContractSeq>45</ContractSeq>
    <IsCfm>0</IsCfm>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985



--select * from _TDASMinor where companyseq = 1 and majorseq = 7027