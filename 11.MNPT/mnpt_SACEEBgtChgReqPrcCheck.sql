  
IF OBJECT_ID('mnpt_SACEEBgtChgReqPrcCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtChgReqPrcCheck  
GO  
    
-- v2018.02.06
  
-- 예산변경입력-체크 by 이재천
CREATE PROC mnpt_SACEEBgtChgReqPrcCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #mnpt_TACBgt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TACBgt'   
    IF @@ERROR <> 0 RETURN     
    

    DECLARE @EnvValue INT 

    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008
    
    UPDATE #mnpt_TACBgt
       SET DeptSeq = CASE WHEN  @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,
           CCtrSeq = CASE WHEN  @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END

    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #mnpt_TACBgt  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #mnpt_TACBgt AS A   
      JOIN (SELECT S.BgtYM, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.IniOrAmd, S.BgtSeq, S.UMCostType
              FROM (SELECT A1.BgtYM, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.IniOrAmd, A1.BgtSeq, A1.UMCostType
                      FROM #mnpt_TACBgt AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.BgtYM, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.IniOrAmd, A1.BgtSeq, A1.UMCostType 
                      FROM mnpt_TACBgt AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #mnpt_TACBgt   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ChgSeq = A1.ChgSeq 
                                      )  
                   ) AS S  
             GROUP BY S.BgtYM, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.IniOrAmd, S.BgtSeq, S.UMCostType
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.BgtYM = B.BgtYM 
                   AND A.AccUnit = B.AccUnit 
                   AND A.DeptSeq = B.DeptSeq 
                   AND A.CCtrSeq = B.CCtrSeq 
                   AND A.AccSeq = B.AccSeq 
                   AND A.IniOrAmd = B.IniOrAmd 
                   AND A.BgtSeq = B.BgtSeq 
                   AND A.UMCostType = B.UMCostType 
                     )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  

    --------------------------------------------------------------------------------------------------------------------------------------------------
    -- 비용 구분 체크
    --------------------------------------------------------------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT   ,  
                          @Status      OUTPUT   ,  
                          @Results     OUTPUT   ,  
                          2195                  , -- SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2195 -- @1 이(가) 존재하는 @2 입니다. @1 을(를) @3 하세요.
                          @LanguageSeq          ,   
                          652, '비용구분',
                          1737, '계정과목',
                          307, '입력'
                          
    UPDATE #mnpt_TACBgt  
       SET Result        = @Results,        -- 비용구분 이(가) 존재하는 예산과목 입니다. 비용구분 을(를) 입력 하세요.
           MessageType   = @MessageType,  
           Status        = @Status
     FROM #mnpt_TACBgt AS A 
     LEFT OUTER JOIN _TDAAccountCostType  AS C WITH(NOLOCK) ON ( C.CompanySeq  = @CompanySeq AND C.AccSeq = A.AccSeq ) 
    WHERE A.Status      = 0
      AND A.WorkingTag  IN ('A', 'U')
      AND ISNULL(A.UMCostType, 0)  = 0     -- 해당 예산과목과 연결된 계정과목이 비용구분이 있는데, 예산과목에 대한 비용구분이 공란으로 넘어오면 체크
      AND C.CompanySeq  IS NOT NULL 

    --------------------------------------------------------------------------------------------------------------------------------------------------
    -- 비용 구분 체크 ( 비용구분이 있는데 잘못 넘어오거나 비용구분이 없는데 값이 넘어오는 경우 )
    --------------------------------------------------------------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT   ,  
                          @Status      OUTPUT   ,  
                          @Results     OUTPUT   ,  
                          2062                  , -- @1되지 않은 @2(@3)이 입력되었습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2062)
                          @LanguageSeq          ,   
                          24260, '설정',
                          652, '비용구분',
                          0, ''
                          
    UPDATE #mnpt_TACBgt  
       SET Result        = REPLACE(@Results, '@3', UM.MinorName),        -- 설정되지 않은 비용구분( )이 입력되었습니다.
           MessageType   = @MessageType,  
           Status        = @Status
      FROM #mnpt_TACBgt AS A JOIN _TDAAccountCostType AS D WITH(NOLOCK)
                               ON D.CompanySeq     = @CompanySeq
                              AND D.AccSeq         = A.AccSeq   -- 계정과목에 설정된 비용구분이 존재할 때
                             LEFT OUTER JOIN _TDAUMinor AS UM WITH(NOLOCK)
                               ON UM.CompanySeq    = @CompanySeq
                              AND UM.MajorSeq      = 4001      -- 비용구분
                              AND UM.MinorSeq      = A.UMCostType
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A', 'U')
       AND ISNULL(A.UMCostType, 0) <> 0
       AND (A.UMCostType NOT IN ( SELECT DISTINCT D.UMCostType
                                            FROM #mnpt_TACBgt AS A JOIN _TDAAccountCostType AS D WITH(NOLOCK)
                                                                   ON D.CompanySeq    = @CompanySeq
                                                                  AND D.AccSeq        = A.AccSeq
                                )
            OR D.CompanySeq IS NULL
           )

    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #mnpt_TACBgt WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
      
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TACBgt', 'ChgSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #mnpt_TACBgt  
           SET ChgSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #mnpt_TACBgt   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #mnpt_TACBgt  
     WHERE Status = 0  
       AND ( ChgSeq = 0 OR ChgSeq IS NULL )  
      
    SELECT * FROM #mnpt_TACBgt   
    
    RETURN  
go
begin tran 
exec mnpt_SACEEBgtChgReqPrcCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptCCtrName>관리부서(전기)</DeptCCtrName>
    <AccName>상품</AccName>
    <BgtName>재료비_test</BgtName>
    <UMCostTypeName>제조</UMCostTypeName>
    <BgtYM>201801</BgtYM>
    <BfrBgtAmt>0</BfrBgtAmt>
    <BgtAmt>22</BgtAmt>
    <ChgBgtAmt>0</ChgBgtAmt>
    <UMChgType />
    <ChgBgtDesc />
    <AccSeq>36</AccSeq>
    <BgtSeq>11</BgtSeq>
    <DeptCCtrSeq>18</DeptCCtrSeq>
    <UMCostType>4001001</UMCostType>
    <ChgSeq>0</ChgSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PgmID>FrmACEEBgtChgReqPrc_mnpt</PgmID>
    <AccUnit>1</AccUnit>
    <IniOrAmd>1</IniOrAmd>
    <SMBgtChangeSource>4070003</SMBgtChangeSource>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820154,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820134
rollback 