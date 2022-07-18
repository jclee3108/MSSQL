IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestSave') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestSave
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 재고검사의뢰-M저장
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestSave
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

    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   'KPX_TQCTestRequest', -- 원테이블명
                   '#QCInStock', -- 템프테이블명
                   'ReqSeq' , -- 키가 여러개일 경우는 , 로 연결한다. 
                   'CompanySeq, ReqSeq, BizUnit, ReqDate, ReqNo, DeptSeq, EmpSeq, CustSeq, LastUserSeq, LastDateTime',
   				   '',
   				   @PgmSeq                    
    
    
    --DEL
    IF EXISTS (SELECT 1 FROM #QCInStock WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE KPX_TQCTestRequest
          FROM #QCInStock AS A JOIN KPX_TQCTestRequest AS B ON B.CompanySeq = @CompanySeq
                                                           AND B.ReqSeq = A.ReqSeq
         WHERE A.WorkingTag = 'D'
           AND A.Status = 0
        
        DELETE KPX_TQCTestRequestItem
          FROM #QCInStock AS A JOIN KPX_TQCTestRequestItem AS B ON B.CompanySeq = @CompanySeq
                                                               AND B.ReqSeq = A.ReqSeq
         WHERE A.WorkingTag = 'D'
           AND A.Status = 0
    END
    
    --UPDATE
    IF EXISTS (SELECT 1 FROM #QCInStock WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        UPDATE B
           SET --BizUnit = A.BizUnit,
               ReqDate = A.ReqDate,
               DeptSeq = A.DeptSeq,
               EmpSeq = A.EmpSeq,
               LastUserSeq = @UserSeq,
               LastDateTime = GETDATE()
          FROM #QCInStock AS A JOIN KPX_TQCTestRequest AS B ON B.CompanySeq = @CompanySeq
                                                           AND B.ReqSeq = A.ReqSeq
         WHERE A.WorkingTag = 'U'
           AND A.Status = 0

        -- 검사공정 변경
        DECLARE @QCTypeOld        INT,
                @QCTypeCurr       INT
                
        SELECT @QCTypeOld = MAX(A.QCType)
            FROM KPX_TQCTestRequestItem A JOIN #QCInStock B ON A.CompanySeq = @CompanySeq
                                                           AND B.ReqSeq = A.ReqSeq
            WHERE 1=1
            AND A.CompanySeq = @CompanySeq

        SELECT @QCTypeCurr = QCType
          FROM #QCInStock
        
        IF @QCTypeOld <> @QCTypeCurr
        BEGIN
            UPDATE A
               SET QCType = @QCTypeCurr
              FROM KPX_TQCTestRequestItem A JOIN #QCInStock B ON A.CompanySeq = @CompanySeq
                                                            AND B.ReqSeq = A.ReqSeq
             WHERE 1=1 
               AND A.CompanySeq = @CompanySeq
        END 

    END
    
    --SAVE
    IF EXISTS (SELECT 1 FROM #QCInStock WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPX_TQCTestRequest(
                                        CompanySeq, 
                                        ReqSeq, 
                                        BizUnit, 
                                        ReqDate, 
                                        ReqNo,
                                        DeptSeq, 
                                        EmpSeq, 
                                        LastUserSeq, 
                                 LastDateTime
                                        )

             SELECT @CompanySeq,
                    ReqSeq, 
                    0, 
                    ReqDate, 
                    ReqNo,
                    DeptSeq, 
                    EmpSeq, 
                    @UserSeq, 
                    GETDATE()
               FROM #QCInStock
              WHERE WorkingTag = 'A'
                AND Status = 0
    END
    
    SELECT * FROM #QCinStock
    

RETURN

GO


