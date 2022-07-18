  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptListCHEMatJump') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptListCHEMatJump  
GO  
  
-- v2015.07.20 
  
-- 연차보수접수조회-자재점프 by 이재천 
CREATE PROC KPXCM_SEQYearRepairReceiptListCHEMatJump  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @ReceiptRegSeq  INT,  
            @ReceiptRegSerl INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReceiptRegSeq   = ISNULL( ReceiptRegSeq, 0 ), 
           @ReceiptRegSerl  = ISNULL( ReceiptRegSerl, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ReceiptRegSeq   INT, 
            ReceiptRegSerl  INT
           )    
    
    -- 최종조회   
    SELECT B.WONo, A.ReqSeq AS WOReqSeq, A.ReqSerl AS WOReqSerl, 2 AS Kind 
      FROM KPXCM_TEQYearRepairReceiptRegItemCHE             AS A 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegItemCHE      AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReceiptRegSeq = @ReceiptRegSeq 
       AND A.ReceiptRegSerl = @ReceiptRegSerl 
    
    RETURN  