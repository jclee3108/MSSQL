
IF OBJECT_ID('DTI_SSLContractPurPlanJumpCheck') IS NOT NULL 
    DROP PROC DTI_SSLContractPurPlanJumpCheck
GO

-- v2014.01.07 

-- 매입계획대상조회_DTI(점프체크) by이재천
CREATE PROC dbo.DTI_SSLContractPurPlanJumpCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #DTI_TSLContractMngItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngItem'
    
    IF EXISTS (SELECT 1 
                 FROM #DTI_TSLContractMngItem AS A
                 JOIN _TPUORDApprovalReqItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND CONVERT(INT,Memo3) = A.ContractSeq AND CONVERT(INT,Memo4) = A.ContractSerl ) 
              )
    BEGIN 
        UPDATE A 
           SET Result = N'매입으로 진행 된 데이터입니다.',
               MessageType = 1234, 
               Status = 1234
          FROM #DTI_TSLContractMngItem AS A 
    END 
    
    SELECT * FROM #DTI_TSLContractMngItem 
    
    RETURN    
GO
