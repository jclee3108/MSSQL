  
IF OBJECT_ID('mnpt_SPJTShipDetailChangeDlgCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTShipDetailChangeDlgCheck  
GO  
    
-- v2017.09.27
  
-- (Dlg)이안입력-체크 by 이재천   
CREATE PROC mnpt_SPJTShipDetailChangeDlgCheck  
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
            @Results        NVARCHAR(250), 
            @MaxShipSubSerl INT 
    
    ------------------------------------------------------------------------------
    -- 체크1, 접안이 있는경우에만 이안을 등록 할 수 있습니다.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '접안이 있는 경우에만 이안을 등록 할 수 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       --AND ISNULL(A.ApproachDate,'') + ISNULL(A.ApproachTime,'') > ISNULL(A.ChangeDate,'') + ISNULL(A.ChangeTime,'')
       AND ISNULL(A.ApproachDate,'') = '' 
       AND ISNULL(A.ChangeDate,'') <> '' 
    ------------------------------------------------------------------------------
    -- 체크1, END
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- 체크2, 일자, 시각 모두 입력하시기 바랍니다.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '일자, 시각 모두 입력하시기 바랍니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND ( (ISNULL(A.ApproachDate,'') = '' AND ISNULL(A.ApproachTime, '') <> '') 
          OR (ISNULL(A.ApproachTime,'') = '' AND ISNULL(A.ApproachDate, '') <> '') 
          OR (ISNULL(A.ChangeDate,'') = '' AND ISNULL(A.ChangeTime, '') <> '') 
          OR (ISNULL(A.ChangeTime,'') = '' AND ISNULL(A.ChangeDate, '') <> '') 
           ) 
    ------------------------------------------------------------------------------
    -- 체크2, END
    ------------------------------------------------------------------------------

    
    --SubSerl 채번 
    SELECT @MaxShipSubSerl = MAX(A.ShipSubSerl) 
      FROM mnpt_TPJTShipDetailChange AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
     GROUP BY A.ShipSeq, A.ShipSerl 
    
    UPDATE A 
       SET ShipSubSerl = ISNULL(@MaxShipSubSerl,0) + A.IDX_NO
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE Status = 0 
       AND WorkingTag = 'A' 
      
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( 
                ( ShipSeq = 0 OR ShipSeq IS NULL ) OR 
                ( ShipSerl = 0 OR ShipSerl IS NULL ) OR 
                ( ShipSubSerl = 0 OR ShipSubSerl IS NULL ) 
           )
    
    RETURN  
    