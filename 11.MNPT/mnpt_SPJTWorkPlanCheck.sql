  
IF OBJECT_ID('mnpt_SPJTWorkPlanCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanCheck  
GO  
    
-- v2017.09.13
  
-- 작업계획입력-SS1체크 by 이재천
CREATE PROC mnpt_SPJTWorkPlanCheck      
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
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  

        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTWorkPlan', 'WorkPlanSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET WorkPlanSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    ------------------------------------------------------------------
    -- 체크1, 승인처리가 되어 신규/수정/삭제를 할 수 없습니다. 
    ------------------------------------------------------------------
    DECLARE @WorkDate NCHAR(8) 
    SELECT @WorkDate = CASE WHEN A.WorkingTag = 'A' THEN A.WorkDate ELSE B.WorkDate END 
      FROM #BIZ_OUT_DataBlock1  AS A 
      LEFT OUTER JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq ) 
    
    UPDATE A
       SET Result = '승인처리가 되어 신규/수정/삭제를 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTWorkPlan AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WorkDate = @WorkDate
                      AND Z.IsCfm = '1' 
                   )
    ------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크2, 작업제외시간이 올바르지 않습니다.
    ------------------------------------------------------------------
    DECLARE @EnvTime NCHAR(4) 

    SELECT @EnvTime = REPLACE(A.EnvValue,':','')
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 5

    SELECT CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + B.ValueText AS SrtTime, 
           CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + C.ValueText AS EndTime
      INTO #UMinorTime
      from _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015905
    
    IF EXISTS (SELECT 1 from #UMinorTime WHERE SrtTime > EndTime ) 
    BEGIN 
        UPDATE #BIZ_OUT_DataBlock1   
           SET Result        = '작업제외시간이 올바르지 않습니다.',      
               MessageType   = 1234,      
               Status        = 1234      
          FROM #BIZ_OUT_DataBlock1  
         WHERE Status = 0  
           AND WorkingTag IN ( 'A', 'U' ) 
    END 
    ------------------------------------------------------------------
    -- 체크2, End
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크3, 작업시간이 올바르지 않습니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '작업시간이 올바르지 않습니다.',      
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
       AND CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':','') > 
           CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
    ------------------------------------------------------------------
    -- 체크3, End
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크4, 작업실적에서 생성된 내역은 수정/삭제를 할 수 없습니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '작업실적에서 생성된 내역은 수정/삭제를 할 수 없습니다.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkReport WHERE CompanySeq = @CompanySeq AND WorkPlanSeq = A.WorkPlanSeq) 
    ------------------------------------------------------------------
    -- 체크4, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크5, 모선별청구인 작업항목인 경우는 모선항차가 필수입니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '모선별청구인 작업항목인 경우는 모선항차가 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTProjectMapping  AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWorkType = A.UMWorkType ) 
      JOIN _TPJTProjectDelivery     AS C ON ( C.companyseq = @CompanySeq AND C.pjtseq = B.pjtseq and B.itemseq = c.itemseq ) 
      JOIN mnpt_TPJTProjectDelivery AS D ON ( D.companyseq = @CompanySeq AND D.PJTSeq = C.PJTSeq AND D.DelvSerl = C.DelvSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.ShipSerl = 0 
       AND D.IsShipCharge = '1'
    ------------------------------------------------------------------
    -- 체크5, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크6, 모선별청구가 아닌 작업항목인 경우는 모선항차를 입력 할 수 없습니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '모선별청구가 아닌 작업항목인 경우는 모선항차를 입력 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTProjectMapping  AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWorkType = A.UMWorkType ) 
      JOIN _TPJTProjectDelivery     AS C ON ( C.companyseq = @CompanySeq AND C.pjtseq = B.pjtseq and B.itemseq = c.itemseq ) 
      JOIN mnpt_TPJTProjectDelivery AS D ON ( D.companyseq = @CompanySeq AND D.PJTSeq = C.PJTSeq AND D.DelvSerl = C.DelvSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND D.IsShipCharge = '0'
       AND A.ShipSerl <> 0 
    ------------------------------------------------------------------
    -- 체크6, END 
    ------------------------------------------------------------------
    

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
       AND ( WorkPlanSeq = 0 OR WorkPlanSeq IS NULL )  
    

    RETURN  
 