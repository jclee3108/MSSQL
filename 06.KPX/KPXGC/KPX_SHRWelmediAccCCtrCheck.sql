
IF OBJECT_ID('KPX_SHRWelmediAccCCtrCheck') IS NOT NULL
    DROP PROC KPX_SHRWelmediAccCCtrCheck
GO 

-- v2014.12.08 

-- 의료비계정등록(활동센터)-체크 by이재천
 CREATE PROCEDURE KPX_SHRWelmediAccCCtrCheck  
     @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML로 전달  
     @xmlFlags    INT = 0         ,    -- 해당 XML의 Type  
     @ServiceSeq  INT = 0         ,    -- 서비스 번호  
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag  
     @CompanySeq  INT = 1         ,    -- 회사 번호  
     @LanguageSeq INT = 1         ,    -- 언어 번호  
     @UserSeq     INT = 0         ,    -- 사용자 번호  
     @PgmSeq      INT = 0              -- 프로그램 번호  
 AS  
    
    -- 사용할 변수를 선언한다.  
    DECLARE @MessageType  INT,  
            @Status       INT,  
            @Results      NVARCHAR(250)
    
    -- 서비스 마스터 등록 생성  
    CREATE TABLE #KPX_THRWelmediAccCCtr (WorkingTag NCHAR(1) NULL)    -- 사용할 임시테이블을 생성한다.  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelmediAccCCtr'  
    IF @@ERROR <> 0 RETURN    -- 에러가 발생하면 리턴  
    
    SELECT * FROM #KPX_THRWelmediAccCCtr 
    
    RETURN