
IF OBJECT_ID('KPXCM_SEQTaskOrderCHECheck') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHECheck
GO 
    
-- v2015.06.11    
    
-- 변경기술검토등록-체크 by 이재천    
CREATE PROC KPXCM_SEQTaskOrderCHECheck    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    DECLARE @MessageType    INT,    
            @Status         INT,    
            @Results        NVARCHAR(250)     
      
    CREATE TABLE #KPXCM_TEQTaskOrderCHE( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQTaskOrderCHE'     
    IF @@ERROR <> 0 RETURN       
    
    -- 체크1, 진행 된 데이터는 수정/삭제 할 수 없습니다.   
      UPDATE A   
         SET Result = '진행 된 데이터는 수정/삭제 할 수 없습니다.',   
             Status = 1234,   
             MessageType = 1234    
        FROM #KPXCM_TEQTaskOrderCHE AS A   
       WHERE A.WorkingTag IN ( 'U', 'D' )   
         AND A.Status = 0   
         AND EXISTS (SELECT 1 FROM KPXCM_TEQChangeFinalReport WHERE CompanySeq = @CompanySeq AND ChangeRequestSeq = A.ChangeRequestSeq )   
    -- 체크1, END   
    
    ------------------------------------------------------------------------  
    -- 번호+코드 따기 :             
    ------------------------------------------------------------------------  
    DECLARE @Count  INT,    
            @Seq    INT     
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0    
        
    IF @Count > 0    
    BEGIN    
      
        -- 키값생성코드부분 시작    
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQTaskOrderCHE', 'TaskOrderSeq', @Count    
          
        -- Temp Talbe 에 생성된 키값 UPDATE    
        UPDATE #KPXCM_TEQTaskOrderCHE    
           SET TaskOrderSeq = @Seq + DataSeq  
         WHERE WorkingTag = 'A'    
           AND Status = 0    
      
    END -- end if     
      
    -- 내부코드 0값 일 때 에러처리     
    EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                          @Status      OUTPUT,        
                          @Results     OUTPUT,        
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)    
                          @LanguageSeq           
        
    UPDATE A      
       SET Result        = @Results,        
           MessageType   = @MessageType,        
           Status        = @Status        
      FROM #KPXCM_TEQTaskOrderCHE AS A 
     WHERE Status = 0    
       AND ( TaskOrderSeq = 0 OR TaskOrderSeq IS NULL )    
        
    SELECT * FROM #KPXCM_TEQTaskOrderCHE     
        
      RETURN   