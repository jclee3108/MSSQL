
IF OBJECT_ID('DTI_SSLContractMngRevSave') IS NOT NULL 
    DROP PROC DTI_SSLContractMngRevSave
GO 

-- v2013.12.24 

-- 계약관리등록이력등록_DTI(저장) by이재천
CREATE PROC DTI_SSLContractMngRevSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #DTI_TSLContractMngRev (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngRev'     
    IF @@ERROR <> 0 RETURN  
    --select * from #DTI_TSLContractMngRev 
    --return 
    DECLARE @ContractRev INT
     
    SELECT @ContractRev = (SELECT MAX(B.ContractRev) 
                            FROM #DTI_TSLContractMngRev AS A
                            JOIN DTI_TSLContractMng     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )
                          ) 
    
    INSERT INTO DTI_TSLContractMngRev ( 
                                        CompanySeq, ContractSeq, ContractRev, RevRemark, ContractMngNo,
                                        ContractNo, BizUnit , ContractDate, SDate, EDate,
                                        CustSeq, BKCustSeq, EndUserSeq, UMContractKind, UMSalesCond, 
                                        ContractEndDate, DeptSeq, EmpSeq, Remark, FileSeq, 
                                        IsCfm, CfmDate, CfmEmpSeq, LastUserSeq, LastDateTime
                                      ) 
    SELECT @CompanySeq, A.ContractSeq, @ContractRev, B.RevRemark, A.ContractMngNo,
           A.ContractNo, A.BizUnit, A.ContractDate, A.SDate, A.EDate,
           A.CustSeq, A.BKCustSeq, A.EndUserSeq, A.UMContractKind, A.UMSalesCond, 
           A.ContractEndDate, A.DeptSeq, A.EmpSeq, A.Remark, A.FileSeq, 
           A.IsCfm, A.CfmDate, A.CfmEmpSeq, @UserSeq, GETDATE()
      FROM #DTI_TSLContractMngRev AS B
      JOIN DTI_TSLContractMng     AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq ) 
      
    IF @@ERROR <> 0  RETURN
    
    DELETE B
      FROM #DTI_TSLContractMngRev AS A
      JOIN DTI_TSLContractMng     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      
    IF @@ERROR <> 0  RETURN
    
    INSERT INTO DTI_TSLContractMng ( 
                                     CompanySeq, ContractSeq, ContractRev, RevRemark, ContractMngNo,
                                     ContractNo, BizUnit , ContractDate, SDate, EDate,
                                     CustSeq, BKCustSeq, EndUserSeq, UMContractKind, UMSalesCond, 
                                     ContractEndDate, DeptSeq, EmpSeq, Remark, FileSeq, 
                                     IsCfm, CfmDate, CfmEmpSeq, LastUserSeq, LastDateTime
                                   ) 
    SELECT @CompanySeq, A.ContractSeq, @ContractRev + 1, '', A.ContractMngNo,
           A.ContractNo, A.BizUnit, A.ContractDate, A.SDate, A.EDate,
           A.CustSeq, A.BKCustSeq, A.EndUserSeq, A.UMContractKind, A.UMSalesCond, 
           A.ContractEndDate, A.DeptSeq, A.EmpSeq, A.Remark, A.FileSeq, 
           A.IsCfm, A.CfmDate, A.CfmEmpSeq, @UserSeq, GETDATE()
      FROM #DTI_TSLContractMngRev AS A 
    
    IF @@ERROR <> 0  RETURN
    
    UPDATE #DTI_TSLContractMngRev
       SET ContractRev = B.ContractRev, 
           RevRemark = B.RevRemark 
      FROM #DTI_TSLContractMngRev AS A 
      JOIN DTI_TSLContractMng     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      
    SELECT * FROM #DTI_TSLContractMngRev 
    
    RETURN    
GO
