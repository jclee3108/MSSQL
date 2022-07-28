
IF OBJECT_ID('_SEQWorkOrderActRltItemSaveCHE') IS NOT NUll    
    DROP PROC _SEQWorkOrderActRltItemSaveCHE
GO 

-- v2015.02.12 
/************************************************************
  설  명 - 데이터-작업실적Item : 실적저장D
  작성일 - 20110516
  작성자 - 신용식
 ************************************************************/
 CREATE PROC dbo._SEQWorkOrderActRltItemSaveCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #capro_TEQWorkOrderActRltItem (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#capro_TEQWorkOrderActRltItem'
     IF @@ERROR <> 0 RETURN
                 
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    'capro_TEQWorkOrderActRltItem', -- 원테이블명
                    '#capro_TEQWorkOrderActRltItem', -- 템프테이블명
                    'ActRltSeq     ,ReceiptSeq    ,ReceiptSerl   ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq    ,ActRltSeq     ,ReceiptSeq       ,WOReqSeq      ,WOReqSerl    ,
                     ProgType      ,LastDateTime  ,LastUserSeq '
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     --IF EXISTS (SELECT TOP 1 1 FROM #capro_TEQWorkOrderActRltItem WHERE WorkingTag = 'D' AND Status = 0)
     --BEGIN
     --    DELETE capro_TEQWorkOrderActRltItem
     --      FROM capro_TEQWorkOrderActRltItem A
     --        JOIN #capro_TEQWorkOrderActRltItem B ON ( A.ActRltSeq     = B.ActRltSeq ) 
     --                     AND ( A.ReceiptSeq    = B.ReceiptSeq ) 
     --                     AND ( A.ReceiptSerl   = B.ReceiptSerl ) 
                         
     --     WHERE A.CompanySeq  = @CompanySeq
     --       AND B.WorkingTag = 'D'
     --       AND B.Status = 0
      --     IF @@ERROR <> 0  RETURN
     --END
      -- UPDATE
     --IF EXISTS (SELECT 1 FROM #capro_TEQWorkOrderActRltItem WHERE WorkingTag = 'U' AND Status = 0)
     --BEGIN
     --    UPDATE capro_TEQWorkOrderActRltItem
     --       SET RltProgType      = A.RltProgType    
     --      FROM capro_TEQWorkOrderActRltItem AS A
     --        JOIN #capro_TEQWorkOrderActRltItem AS B ON ( A.ActRltSeq     = B.ActRltSeq ) 
     --                     AND ( A.ReceiptSeq    = B.ReceiptSeq ) 
     --                     AND ( A.ReceiptSerl   = B.ReceiptSerl ) 
                         
     --     WHERE A.CompanySeq = @CompanySeq
     --       AND B.WorkingTag = 'U'
     --       AND B.Status = 0
      --    IF @@ERROR <> 0  RETURN
     --END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #capro_TEQWorkOrderActRltItem WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO capro_TEQWorkOrderActRltItem ( CompanySeq    ,ActRltSeq        ,ReceiptSeq       ,WOReqSeq       ,WOReqSerl    ,
                                                    RltProgType   ,LastDateTime  ,LastUserSeq      )
             SELECT @CompanySeq   ,ActRltSeq        ,ReceiptSeq       ,WOReqSeq      ,WOReqSerl     ,
                    20109006    ,GETDATE()        ,@UserSeq   
               FROM #capro_TEQWorkOrderActRltItem AS A
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #capro_TEQWorkOrderActRltItem
      RETURN