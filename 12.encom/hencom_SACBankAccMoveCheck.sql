  
IF OBJECT_ID('hencom_SACBankAccMoveCheck') IS NOT NULL   
    DROP PROC hencom_SACBankAccMoveCheck 
GO  
  
-- v2017.05.15
  
-- 계좌간이동입력-체크 by 이재천
CREATE PROC hencom_SACBankAccMoveCheck  
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
    
    CREATE TABLE #hencom_TACBankAccMove( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACBankAccMove'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 전표가 생성 된 내역은 수정/삭제 할 수 없습니다. 
    UPDATE A
       SET Result = '전표가 생성 된 내역은 수정/삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACBankAccMove           AS A 
      LEFT OUTER JOIN hencom_TACBankAccMove AS B ON ( B.CompanySeq = @CompanySeq AND B.MoveSeq = A.MoveSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND ISNULL(B.SlipSeq,0) <> 0
    -- 체크1, END 

    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_TACBankAccMove WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TACBankAccMove', 'MoveSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #hencom_TACBankAccMove  
           SET MoveSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_TACBankAccMove   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_TACBankAccMove  
     WHERE Status = 0  
       AND ( MoveSeq = 0 OR MoveSeq IS NULL )  
      
    SELECT * FROM #hencom_TACBankAccMove   
      
    RETURN  
