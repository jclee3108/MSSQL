  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHEJumpQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHEJumpQuery  
GO  
  
-- v2015.01.21 
  
-- 변경위험성평가등록- 점프조회 by 이재천 
CREATE PROC KPX_SEQChangeRiskRstCHEJumpQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @RiskRstSeq INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @RiskRstSeq = ISNULL( RiskRstSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (RiskRstSeq   INT)    
      
    SELECT B.ChangeRequestSeq, 
           B.Title AS ChangeTitle, 
           B.Remark AS ReqRemark, 
           B.Purpose,
           B.Effect, 
           B.UMChangeType, 
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName, 
           I.Remark AS Contents5, 
           I.RiskRstDate AS Date5, 
           K.DeptName AS DeptName5, 
           L.*, 
           CASE WHEN ISNULL(M.ReviewSeq,0) = 0 THEN '0' ELSE '1' END AS IsProg  

      FROM KPX_TEQChangeRiskRstCHE AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE           AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType ) 
      LEFT OUTER JOIN KPX_TEQChangeRiskRstCHE           AS I ON ( I.CompanySeq = @CompanySeq AND I.ChangeRequestSeq = B.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TCAUser                          AS J ON ( J.CompanySeq = @CompanySeq AND J.UserSeq = I.LastUserSeq ) 
      LEFT OUTER JOIN _TDADept                          AS K ON ( K.CompanySeq = @CompanySeq AND K.DeptSeq = J.DeptSeq ) 
      LEFT OUTER JOIN KPX_TEQTaskOrderCHE               AS L ON ( L.CompanySeq = @CompanySeq AND L.ChangeRequestSeq = B.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPX_TEQChangeCmmReviewCHE         AS M ON ( M.CompanySeq = @CompanySeq AND M.ChangeRequestSeq = B.ChangeRequestSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.RiskRstSeq = @RiskRstSeq
      
    RETURN  
    
GO 
exec KPX_SEQChangeRiskRstCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RiskRstSeq>6</RiskRstSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351