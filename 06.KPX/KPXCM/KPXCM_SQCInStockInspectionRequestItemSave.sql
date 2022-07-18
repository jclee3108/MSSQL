IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestItemSave') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestItemSave
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 재고검사의뢰-Item저장
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestItemSave
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
  					
    CREATE TABLE #QCInStockItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#QCInStockItem'

    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   'KPX_TQCTestRequestItem', -- 원테이블명
                   '#QCInStockItem', -- 템프테이블명
                   'ReqSeq, ReqSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                   'CompanySeq,ReqSeq    ,ReqSerl   ,QCType    ,ItemSeq   ,LotNo     ,WHSeq     ,UnitSeq   ,
                    ReqQty    ,Remark    ,SMSourceType,SourceSeq   ,SourceSerl  ,LastUserSeq ,LastDateTime, Memo1',
   				   '',
   				   @PgmSeq                    
    
    --DEL
    IF EXISTS (SELECT 1 FROM #QCInStockItem WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE KPX_TQCTestRequestItem
          FROM #QCInStockItem AS A JOIN KPX_TQCTestRequestItem AS B ON B.CompanySeq = @CompanySeq
                                                                   AND B.ReqSeq     = A.ReqSeq
                                                                   AND B.ReqSerl    = A.ReqSerl
         WHERE A.WorkingTag = 'D'
           AND A.Status = 0
    END
    
    --UPDATE
    IF EXISTS (SELECT 1 FROM #QCInStockItem WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        UPDATE B
           SET QCType       = A.QCType,
               ItemSeq      = A.ItemSeq,
               LotNo        = A.LotNo,
               WHSeq        = A.WHSeq,
               UnitSeq      = A.UnitSeq,
               ReqQty       = A.ReqQty,
               Remark       = A.Remark,
               Memo1        = A.Memo1, 
               LastUserSeq  = @UserSeq,
               LastDateTime = GETDATE()
          FROM #QCInStockItem AS A JOIN KPX_TQCTestRequestItem AS B ON B.CompanySeq = @CompanySeq
                                                                   AND B.ReqSeq = A.ReqSeq
                                                                   AND B.ReqSerl    = A.ReqSerl
         WHERE A.WorkingTag = 'U'
           AND A.Status = 0
    END
    
    --SAVE
    IF EXISTS (SELECT 1 FROM #QCInStockItem WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPX_TQCTestRequestItem(
                                            CompanySeq, 
                                            ReqSeq, 
                                            ReqSerl, 
                                            QCType, 
                                            ItemSeq, 
                                            LotNo, 
                                            WHSeq,
                                            UnitSeq, 
                                            ReqQty, 
                                            Remark,
                                            SMSourceType, 
                                            SourceSeq,
                                            SourceSerl,
                                            LastUserSeq, 
                                            LastDateTime, 
                                            Memo1
                                          )
             SELECT @CompanySeq, 
                    ReqSeq, 
                    ReqSerl, 
                    QCType, 
                    ItemSeq, 
                    LotNo, 
                    WHSeq,
                    UnitSeq, 
                    ReqQty, 
                    Remark,
                    1000522001, -- 시스템정의 코드 '재고검사'
                    0,
                    0,
                    @UserSeq, 
                    GETDATE(), 
                    Memo1
               FROM #QCInStockItem
              WHERE WorkingTag = 'A'
                AND Status = 0
    END
    
    SELECT * FROM #QCInStockItem
    

RETURN

GO


