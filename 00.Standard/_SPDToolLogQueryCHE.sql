
IF OBJECT_ID('_SPDToolLogQueryCHE') IS NOT NULL 
    DROP PROC _SPDToolLogQueryCHE
GO 

/************************************************************
  ��  �� - ������ �����̷� ��ȸ
  �ۼ��� - 2011/03/17
  �ۼ��� - shpark
 ************************************************************/
 CREATE PROC dbo._SPDToolLogQueryCHE         
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS 
  DECLARE @docHandle  INT,
             @ToolSeq    INT
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
      
      SELECT @ToolSeq    = ISNULL(LTRIM(RTRIM(ToolSeq)),0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)   
       WITH (ToolSeq     INT)  
     
      SELECT  A.LogDateTime, 
             A.LogUserSeq, 
             B.UserName
       FROM _TPDToolLog AS A LEFT OUTER JOIN _TCAUser AS B 
                               ON A.CompanySeq   = B.CompanySeq
                              AND A.LogUserSeq   = UserSeq
      WHERE A.CompanySeq = @CompanySeq
        AND A.ToolSeq    = @ToolSeq
        AND A.LogType    = 'U'
            
 RETURN