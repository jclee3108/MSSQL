
IF OBJECT_ID('_SPDToolCheckCHE') IS NOT NULL 
    DROP PROC _SPDToolCheckCHE
GO 

/************************************************************  
  설  명 - 설비등록 마스터 체크  
  작성일 - 2011/03/17  
  작성자 - shpark  
 ************************************************************/  
 CREATE PROC dbo._SPDToolCheckCHE  
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
           
   CREATE TABLE #TPDTool (WorkingTag NCHAR(1) NULL)    
   EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTool'       
   IF @@ERROR <> 0 RETURN    
     
     
   IF (SELECT ISNULL(ToolSeq,0) AS ToolSeq FROM #TPDTool ) > 0  
   BEGIN  
         UPDATE #TPDTool  
            SET WorkingTag = 'U'  
   END  
     
    -------------------------------------------    
    -- 중복여부체크    
    -------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,''  
    UPDATE #TPDTool  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #TPDTool AS A JOIN            ( SELECT S.ToolNo  
                                             FROM (  
                                                   SELECT A1.ToolNo  
                                                     FROM #TPDTool AS A1    
                                                    WHERE A1.WorkingTag IN ('A', 'U')  
                                                      AND A1.Status = 0  
                                                   UNION ALL  
                                                   SELECT A1.ToolNo  
                                                     FROM _TPDTool AS A1 WITH(NOLOCK)  
                                                    WHERE A1.CompanySeq = @CompanySeq  
                                                      AND A1.ToolSeq NOT IN (SELECT ToolSeq   
                                                                               FROM #TPDTool  
                                                                              WHERE WorkingTag IN ('U', 'D')  
                                                                                AND Status = 0)  
                                                  ) AS S  
                                            GROUP BY S.ToolNo  
                                            HAVING COUNT(1) > 1  
                                          ) AS B ON A.ToolNo  = B.ToolNo  
     
     --==========================================  
     --  자동내부순번  
     --==========================================  
   IF EXISTS (SELECT 1 FROM #TPDTool WHERE WorkingTag = 'A' AND Status = 0)    
   BEGIN      
         SELECT @Seq = ISNULL(MAX(ToolSeq),0)  
           FROM _TPDTool AS A  
          WHERE A.CompanySeq = @CompanySeq  
   END  
  
   UPDATE #TPDTool  
      SET ToolSeq = @Seq + DataSeq  
    WHERE Status = 0  
      AND WorkingTag = 'A'   
                      
  SELECT * FROM #TPDTool   
    
   RETURN