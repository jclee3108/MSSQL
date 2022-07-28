
IF OBJECT_ID('_SPDToolUserDefineRightCheckCHE') IS NOT NULL 
    DROP PROC _SPDToolUserDefineRightCheckCHE
GO 

/************************************************************
  설  명 - 설비등록 제원 오른쪽 체크
  작성일 - 2011/03/17
  작성자 - shpark
 ************************************************************/
 CREATE PROC dbo._SPDToolUserDefineRightCheckCHE
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 1,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0  
  AS   
   DECLARE @MessageType   INT,  
              @Status        INT,  
              @Results       NVARCHAR(300),
              @docHandle     INT,
              @Seq           INT
      -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPDToolUserDefine (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TPDToolUserDefine'       
     IF @@ERROR <> 0 RETURN    
      --============================================
     --  워킹태그 변경
     --============================================ 
     UPDATE A
        SET WorkingTag = 'A'
       FROM #TPDToolUserDefine AS A LEFT OUTER JOIN _TPDToolUserDefine AS B
                                      ON B.CompanySeq      = @CompanySeq
                                     AND A.TitleSerl       = B.MngSerl
                                     AND A.ToolSeq         = B.ToolSeq
      WHERE B.CompanySeq IS NULL
        AND A.WorkingTag = 'U'
        AND A.Status     = 0   
                   
  SELECT * FROM #TPDToolUserDefine 
 RETURN