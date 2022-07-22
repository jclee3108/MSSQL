IF OBJECT_ID('hencom_SACSlipApprovalDeptSetting') IS NOT NULL   
    DROP PROC hencom_SACSlipApprovalDeptSetting
GO  
  
-- v2017.04.12
  
-- 전표승인처리(사업소)-승인/취소셋팅 by 이재천   
CREATE PROC hencom_SACSlipApprovalDeptSetting  
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
            @SlipKind   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SlipKind   = ISNULL( SlipKind, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (SlipKind   INT)    
    
    SELECT B.ValueText AS IsApproval, C.ValueText AS IsCancel
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000003 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015027 
       AND A.Serl = 1000001 
       AND A.ValueSeq = @SlipKind 
    
    RETURN  