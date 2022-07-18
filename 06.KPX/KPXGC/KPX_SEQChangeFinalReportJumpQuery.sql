  
IF OBJECT_ID('KPX_SEQChangeFinalReportJumpQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeFinalReportJumpQuery  
GO  
  
-- v2015.01.22  
  
-- 변경수행결과-점프 조회 by이재천 
CREATE PROC KPX_SEQChangeFinalReportJumpQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @FinalReportSeq INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FinalReportSeq   = ISNULL( FinalReportSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (FinalReportSeq   INT)    
    
    -- 최종조회   
    SELECT B.ChangeRequestSeq, 
           B.ChangeRequestNo,
           B.Title, 
           B.BaseDate, 
           CASE WHEN ISNULL(C.ExReportSerl,0) = 0 THEN '0' ELSE '1' END AS IsProg  
      FROM KPX_TEQChangeFinalReport             AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE   AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      OUTER APPLY (SELECT TOP 1 ExReportSerl
                     FROM KPX_TEQChangeFinalExReport AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.ChangeRequestSeq = B.ChangeRequestSeq 
                  ) AS C 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.FinalReportSeq = @FinalReportSeq )   
    
    RETURN  
    
    
    