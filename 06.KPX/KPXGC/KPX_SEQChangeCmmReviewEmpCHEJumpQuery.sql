  
IF OBJECT_ID('KPX_SEQChangeCmmReviewEmpCHEJumpQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeCmmReviewEmpCHEJumpQuery  
GO  
  
-- v2015.01.22  
  
-- 변경위원회회의록등록-점프 조회 by이재천 
CREATE PROC KPX_SEQChangeCmmReviewEmpCHEJumpQuery  
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
            @ReviewSeq  INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ReviewSeq   = ISNULL( ReviewSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ReviewSeq   INT)    
    
    -- 최종조회   
    SELECT B.ChangeRequestSeq, 
           B.ChangeRequestNo, 
           B.BaseDate, 
           B.Title, 
           B.Remark, 
           B.Purpose,
           B.Effect, 
           B.UMChangeType, 
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName, 
           CASE WHEN ISNULL(G.FinalReportSeq,0) = 0 THEN '0' ELSE '1' END AS IsProg  
      FROM KPX_TEQChangeCmmReviewCHE AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE           AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType ) 
      LEFT OUTER JOIN KPX_TEQChangeFinalReport          AS G ON ( G.CompanySeq = @CompanySeq AND G.ChangeRequestSeq = A.ChangeRequestSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.ReviewSeq = @ReviewSeq )   
    
    RETURN  
GO 
exec KPX_SEQChangeCmmReviewEmpCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReviewSeq>21</ReviewSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026713,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021388