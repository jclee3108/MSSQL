  
IF OBJECT_ID('KPXCM_SEQRegInspectRstQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectRstQuerySub  
GO  
  
-- v2015.07.03  
  
-- 정기검사내역등록-Sub조회 by 이재천   
CREATE PROC KPXCM_SEQRegInspectRstQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @QCDate         NCHAR(8), 
            @RegInspectSeq  INT 

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QCDate          = ISNULL( QCDate, '' ),  
           @RegInspectSeq   = ISNULL( RegInspectSeq, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            QCDate         NCHAR(8), 
            RegInspectSeq  INT 
           )    
    
    -- 최종조회   
    SELECT C.ToolName AS ToolNameSub, 
           C.ToolNo AS ToolNoSub, 
           C.ToolSeq AS ToolSeqSub, 
           A.RegInspectSeq, 
           A.QCDate, 
           A.FileSeq 
      FROM KPXCM_TEQRegInspectRst           AS A 
      LEFT OUTER JOIN KPXCM_TEQRegInspect   AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq ) 
      LEFT OUTER JOIN _TPDTool              AS C ON ( C.CompanySeq = @CompanySeq AND C.ToolSeq = B.ToolSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.RegInspectSeq = @RegInspectSeq 
       AND A.QCDate = @QCDate
    
    
    RETURN  
    go 
exec KPXCM_SEQRegInspectRstQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <QCDate>20150728</QCDate>
    <RegInspectSeq>6</RegInspectSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030662,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025556