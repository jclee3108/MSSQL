  
IF OBJECT_ID('KPX_SEQChangeRequestRecvJumpQuery') IS NOT NULL   
    DROP PROC KPX_SEQChangeRequestRecvJumpQuery  
GO  
  
-- v2014.01.21  
  
-- 변경요구접수등록-점프 조회 by이재천 
CREATE PROC KPX_SEQChangeRequestRecvJumpQuery  
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
    
    DECLARE @docHandle              INT, 
            @ChangeRequestRecvSeq   INT 
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @ChangeRequestRecvSeq = ISNULL(ChangeRequestRecvSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (ChangeRequestRecvSeq INT)  
    
    -- 최종조회   
    SELECT B.ChangeRequestSeq, 
           B.ChangeRequestNo, 
           B.BaseDate, 
           B.DeptSeq, 
           C.DeptName, 
           B.EmpSeq,  
           D.EmpName,  
           ISNULL(E.CfmDate  ,'') AS CfmDate, 
           B.Title, 
           B.UMChangeType, 
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName, 
           B.UMChangeReson, 
           ISNULL(G.MinorName  ,'') AS UMChangeResonName, 
           B.UMPlantType, 
           ISNULL(H.MinorName  ,'') AS UMPlantTypeName, 
           B.Remark, 
           B.Purpose,
           B.Effect, 
           B.FileSeq AS ReqFileSeq, 
           CASE WHEN ISNULL(I.TaskOrderSeq,0) = 0 THEN '0' ELSE '1' END AS IsProg  
           
      FROM KPX_TEQChangeRequestRecv                     AS A 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE           AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDADept                          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp                           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE_Confirm   AS E ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = B.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType ) 
      LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMChangeReson )  
      LEFT OUTER JOIN _TDAUMinor                        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMPlantType ) 
      LEFT OUTER JOIN KPX_TEQTaskOrderCHE               AS I ON ( I.CompanySeq = @CompanySeq AND I.ChangeRequestSeq = B.ChangeRequestSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @ChangeRequestRecvSeq = A.ChangeRequestRecvSeq ) 
    
    RETURN  
GO 
exec KPX_SEQChangeRequestRecvJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ChangeRequestSeq>7</ChangeRequestSeq>
    <ChangeRequestRecvSeq>15</ChangeRequestRecvSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026418,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021384