  
IF OBJECT_ID('mnpt_SPJTShipDetailChangeDlgSave') IS NOT NULL   
    DROP PROC mnpt_SPJTShipDetailChangeDlgSave  
GO  
    
-- v2017.09.27
  
-- (Dlg)이안입력-저장 by 이재천   
CREATE PROC mnpt_SPJTShipDetailChangeDlgSave  
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
    
    -- 접안시간 Update 
    UPDATE A
       SET DiffApproachTime =   ROUND(DATEDIFF(MI,
                                                STUFF(STUFF(LEFT(A.ApproachDate,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ApproachTime,4),3,0,':') + ':00.000', 
                                                CASE WHEN A.ChangeDate = '' 
                                                     THEN STUFF(STUFF(LEFT(B.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(B.OutDateTime,4),3,0,':') + ':00.000' -- 출항일 
                                                     ELSE STUFF(STUFF(LEFT(A.ChangeDate,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ChangeTime,4),3,0,':') + ':00.000'  -- 이안일 
                                                     END 
                                            ) / 60.
                                   ,1), 
           OutDate = CASE WHEN A.ChangeDate = '' THEN LEFT(B.OutDateTime,8) ELSE '' END, 
           OutTime = CASE WHEN A.ChangeDate = '' THEN RIGHT(B.OutDateTime,4) ELSE '' END

      FROM #BIZ_OUT_DataBlock1 AS A 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'A' )
       AND (A.ChangeDate <> '' OR B.OutDateTime <> '') 
    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetailChange')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTShipDetailChange'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'ShipSeq, ShipSerl, ShipSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTShipDetailChange    AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND A.ShipSeq = B.ShipSeq 
                                                  AND A.ShipSerl = B.ShipSerl 
                                                  AND A.ShipSubSerl = B.ShipSubSerl
                                                     )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN   
        
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ApproachDate       = A.ApproachDate,  
               B.ApproachTime       = A.ApproachTime,  
               B.ChangeDate         = A.ChangeDate,  
               B.ChangeTime         = A.ChangeTime,  
               B.DiffApproachTime   = A.DiffApproachTime,  
               B.LastUserSeq        = @UserSeq,  
               B.LastDateTime       = GETDATE(),  
               B.PgmSeq             = @PgmSeq    
                 
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTShipDetailChange    AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND A.ShipSeq = B.ShipSeq 
                                                  AND A.ShipSerl = B.ShipSerl 
                                                  AND A.ShipSubSerl = B.ShipSubSerl
                                                     )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    --select *From mnpt_TPJTShipDetailChange 
    --where ShipSeq = 7 and shipserl = 328 
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTShipDetailChange  
        (   
            CompanySeq, ShipSeq, ShipSerl, ShipSubSerl, ApproachDate, 
            ApproachTime, ChangeDate, ChangeTime, DiffApproachTime, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq

        )   
        SELECT @CompanySeq, A.ShipSeq, A.ShipSerl, A.ShipSubSerl, A.ApproachDate, 
               A.ApproachTime, A.ChangeDate, A.ChangeTime, A.DiffApproachTime,  @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq   
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    
    -------------------------------------------------------------------------------------
    -- 모선항차 접안시간 Update
    -------------------------------------------------------------------------------------    
    DECLARE @IsExists NCHAR(1) 

    SELECT DISTINCT
           A.Status, 
           'U' AS WorkingTag, 
           CASE WHEN A.WorkingTag = 'D' AND B.DiffApproachTime IS NULL THEN '0' ELSE '1' END AS IsExists, 
           A.ShipSeq, 
           A.ShipSerl, 
           B.DiffApproachTime, 
           B.ApproachDateTime, 
           C.IFShipCode + '-' + LEFT(C.ShipSerlNo,4) + '-' + RIGHT(C.ShipSerlNo,3) AS ShipSerlNo 
      INTO #mnpt_TPJTShipDetailLog
      FROM #BIZ_OUT_DataBlock1                  AS A 
      OUTER APPLY (
                  SELECT ISNULL(CEILING(SUM(DiffApproachTime)),0) AS DiffApproachTime, MIN(Z.ApproachDate + Z.ApproachTime) AS ApproachDateTime
                      FROM  mnpt_TPJTShipDetailChange AS Z 
                      WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.ShipSeq = A.ShipSeq
                      AND Z.ShipSerl = A.ShipSerl 
                  ) AS B 
      LEFT OUTER JOIN mnpt_TPJTShipDetail       AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
    
     
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetail')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                    @UserSeq      ,        
                    'mnpt_TPJTShipDetail'    , -- 테이블명        
                    '#mnpt_TPJTShipDetailLog'    , -- 임시 테이블명        
                    'ShipSeq,ShipSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                    @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
    --모선항차 접안시간 Update
    UPDATE A
       SET DiffApproachTime = CASE WHEN B.IsExists = '1' THEN B.DiffApproachTime ELSE 0 END, 
           ApproachDateTime = CASE WHEN B.IsExists = '1'THEN B.ApproachDateTime ELSE '' END 
      FROM mnpt_TPJTShipDetail      AS A 
      JOIN #mnpt_TPJTShipDetailLog  AS B ON ( B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    /*
    분산트랜잭션으로 인해 스케쥴링으로 작업 
    */
    ---- 운영정보System Update
    --IF DB_NAME() LIKE 'MNPT%' 
    --BEGIN 
    --    UPDATE A
    --        SET ATB = C.ApproachDateTime
    --        FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSEL ') AS A 
    --        JOIN #BIZ_OUT_DataBlock1                          AS B ON (
    --                                                                    A.VESSEL = LEFT(B.ShipSerlNo,4) 
    --                                                                AND A.VES_YY = SUBSTRING(B.ShipSerlNo,6,4) 
    --                                                                AND A.VES_SEQ = CONVERT(INT,RIGHT(B.ShipSerlNo,3))
    --                                                                )
    --        JOIN mnpt_TPJTShipDetail                          AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
    --        WHERE B.Status = 0 
    --END 

    -------------------------------------------------------------------------------------
    -- 모선항차 접안시간 Update, END 
    -------------------------------------------------------------------------------------    
    
    UPDATE A
       SET SourceDiffApproachTime = CASE WHEN B.IsExists = '1' THEN B.DiffApproachTime ELSE 0 END, 
           SourceApproachDateTime = CASE WHEN B.IsExists = '1'THEN STUFF(STUFF(LEFT(B.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(B.ApproachDateTime,4),3,0,':') ELSE '' END 
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN #mnpt_TPJTShipDetailLog  AS B ON ( B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
    

    RETURN  
