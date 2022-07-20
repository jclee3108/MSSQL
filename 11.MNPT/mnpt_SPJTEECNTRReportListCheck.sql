  
IF OBJECT_ID('mnpt_SPJTEECNTRReportListCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEECNTRReportListCheck  
GO  
    
-- v2017.11.07
  
-- 컨테이너실적조회-체크 by 이재천   
CREATE PROC mnpt_SPJTEECNTRReportListCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    ----------------------------------------------------------------------------------------
    -- 체크1, 청구생성이 되어 삭제 할 수 없습니다.
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '청구생성이 되어 삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTEECNTRReport    AS B ON ( B.CompanySeq = @CompanySeq AND B.CNTRReportSeq = A.CNTRReportSeq ) 
      JOIN mnpt_TPJTShipDetail      AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND OldShipSeq = C.ShipSeq 
                      AND OldShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,8)
                  ) 
    ----------------------------------------------------------------------------------------
    -- 체크1, END 
    ----------------------------------------------------------------------------------------
    
    RETURN  
