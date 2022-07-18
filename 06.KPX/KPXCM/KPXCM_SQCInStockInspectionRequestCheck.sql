IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestCheck
GO 

-- v2016.06.02 

/************************************************************
 설  명 - 재고검사의뢰-M체크
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestCheck
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
	DECLARE @MessageType	INT,
			@Status			INT,
			@Results		NVARCHAR(250),
			@Seq            INT,
			@Count          INT,
			@MaxNo          NVARCHAR(20),
			@BaseDate       NCHAR(8)
  					
    CREATE TABLE #QCInStock (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#QCInStock'

    SELECT @BaseDate = ReqDate FROM #QCInStock
    
    SELECT @Count = COUNT(1) FROM #QCInStock WHERE WorkingTag = 'A' --@Count값수정 (AND Status = 0 제외)
    IF @Count > 0        
    BEGIN          
        -- 키값생성코드부분 시작          
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCTestRequest', 'ReqSeq', @Count
    
    -- 재고검사의뢰번호생성  
    EXEC _SCOMCreateNo 'SITE', 'KPX_TQCTestRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
    
    -- Temp Talbe 에 생성된 키값 UPDATE        
    UPDATE #QCInStock        
       SET ReqSeq = @Seq + DataSeq,
           ReqNo  = @MaxNo     
     WHERE WorkingTag = 'A'        
       AND Status = 0        
    END 

    SELECT * FROM #QCInStock
RETURN


GO


