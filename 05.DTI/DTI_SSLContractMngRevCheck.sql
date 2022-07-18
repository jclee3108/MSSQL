
IF OBJECT_ID('DTI_SSLContractMngRevCheck') IS NOT NULL 
    DROP PROC DTI_SSLContractMngRevCheck
GO 

-- v2013.12.27 

-- 계약관리등록이력등록_DTI(체크) by이재천
CREATE PROC dbo.DTI_SSLContractMngRevCheck
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
    
    CREATE TABLE #DTI_TSLContractMngRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngRev'
    
    -- 체크1, Amd등록 할 수 있는 권한이 없습니다.
    IF (SELECT Status FROM #DTI_TSLContractMngRev) = 0
    BEGIN
        UPDATE #DTI_TSLContractMngRev
           SET Result = N'Amd등록 할 수 있는 권한이 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM _TCAUser AS A
         WHERE A.UserSeq = @UserSeq 
           AND (
                A.DeptSeq NOT IN (SELECT DeptSeq FROM DTI_TCOMEnvContractEmp WHERE CompanySeq = @CompanySeq) OR
                A.EmpSeq NOT IN (SELECT EmpSeq FROM DTI_TCOMEnvContractEmp WHERE CompanySeq = @CompanySeq)
               )
    END
    -- 체크1, END
    
    -- 체크2, 구매팀 확정이 되지 않은 건은 AMD등록을 할 수 없습니다.
    UPDATE A
       SET Result = N'구매팀 확정이 되지 않은 건은 AMD등록을 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #DTI_TSLContractMngRev AS A 
      JOIN DTI_TSLContractMng     AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
     WHERE ISNULL(A.IsCfm,'0') = '0'
       AND A.Status = 0 
    -- 체크2, END   
    
    -- 체크3, 변경이유를 등록해 주세요. 
    UPDATE A
       SET Result = N'변경이유를 등록해 주세요.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #DTI_TSLContractMngRev AS A 
     WHERE LTRIM(RTRIM(A.RevRemark)) = '' 
       AND A.Status = 0 
    -- 체크3, END
    
    SELECT * FROM #DTI_TSLContractMngRev 
    
    RETURN    
GO
