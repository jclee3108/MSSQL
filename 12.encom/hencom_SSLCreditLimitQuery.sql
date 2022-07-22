IF OBJECT_ID('hencom_SSLCreditLimitQuery') IS NOT NULL
    DROP PROC hencom_SSLCreditLimitQuery
GO 

-- v2017.02.02
/************************************************************  
 설  명 - 데이터-여신등록_hencom : 조회  
 작성일 - 20150916  
 작성자 - 영림원  
 수정자 -   
************************************************************/  
  
CREATE PROC dbo.hencom_SSLCreditLimitQuery                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    DECLARE @docHandle      INT,  
            @CustSeq        INT, 
            @DeptSeqSub     INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @CustSeq        = ISNULL(CustSeq,0), 
           @DeptSeqSub     = ISNULL(DeptSeqSub,0)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            CustSeq         INT,
            DeptSeqSub      INT
           )  
    
    -- 조회조건1 사업소 담기 
    -- 2017.02.02 추가 by이재천
    SELECT DISTINCT A.CLSeq 
      INTO #CLSeq
      FROM hencom_TSLCreditLimitM AS A 
      LEFT OUTER JOIN hencom_TSLCreditLimitD AS B ON ( B.CompanySeq = @CompanySeq AND B.CLSeq = A.CLSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
       AND ( @DeptSeqSub = 0 OR B.DeptSeq = @DeptSeqSub ) 


    SELECT  A.CLSeq               AS CLSeq ,  
            A.CustSeq             AS CustSeq ,  
            A.CurrSeq             AS CurrSeq ,  
            A.TotalCreditAmt      AS TotalCreditAmt ,  
            A.IsContainBill       AS IsContainBill ,  
            A.Remark              AS Remark ,  
            A.LastUserSeq         AS LastUserSeq ,  
            A.LastDateTime        AS LastDateTime  ,  
            B.CustName            AS CustName,  
            B.BizNo               AS BizNo,  
            (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName,  
            (SELECT UserName FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = A.LastUserSeq) AS LastUserName,  
            (SELECT UserName FROM _TCAUser WHERE CompanySeq = @CompanySeq   
                                AND UserSeq = (CASE WHEN (SELECT COUNT(1) FROM hencom_TSLCreditLimitMLog  WHERE CompanySeq = @CompanySeq AND CLSeq = A.CLSeq)>0   
                                                THEN (SELECT Top 1 LastUserSeq FROM hencom_TSLCreditLimitMLog  WHERE CompanySeq = @CompanySeq AND CLSeq = A.CLSeq ORDER BY LogSeq )  
                                                ELSE A.LastUserSeq END) ) AS RegUserName, --최초등록자  
            CASE WHEN (SELECT COUNT(1) FROM hencom_TSLCreditLimitMLog  WHERE CompanySeq = @CompanySeq AND CLSeq = A.CLSeq)>0   
                THEN (SELECT Top 1 LastDateTime FROM hencom_TSLCreditLimitMLog  WHERE CompanySeq = @CompanySeq AND CLSeq = A.CLSeq ORDER BY LogSeq )  
                ELSE A.LastDateTime END AS RegDateTime, --최초등록일  
            CA.CLAAAmt AS CLAAAmt --추가승인금액
    FROM hencom_TSLCreditLimitM AS A WITH (NOLOCK)   
    LEFT OUTER JOIN _TDACust AS B ON B.CompanySeq = @CompanySeq   
                                 AND B.CustSeq = A.CustSeq 
    LEFT OUTER JOIN(SELECT A.CustSeq,SUM(B.CLAAAmt) AS CLAAAmt 
                    FROM hencom_TSLCrditLimitAddReq AS A
                    JOIN hencom_TSLCreditLimitApproval AS B ON B.CompanySeq = A.CompanySeq 
                    AND B.CLARSeq = A.CLARSeq
                    WHERE A.CompanySeq = @CompanySeq AND B.IsApproval = '1'
                    GROUP BY A.CustSeq 
                    ) AS CA ON CA.CustSeq = A.CustSeq
    WHERE A.CompanySeq = @CompanySeq  
    --AND (@CustSeq = 0 OR A.CustSeq = @CustSeq )      
    AND EXISTS (SELECT 1 FROM #CLSeq WHERE CLSeq = A.CLSeq) -- 2017.02.02 추가 by이재천
  
  
      
RETURN

go
exec hencom_SSLCreditLimitQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CustSeq />
    <DeptSeqSub>28</DeptSeqSub>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032089,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026593