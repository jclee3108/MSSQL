  
IF OBJECT_ID('mnpt_SACEEBgtAdjCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjCheck  
GO  
    
-- v2017.12.18
  
-- 경비예산입력-체크 by 이재천   
CREATE PROC mnpt_SACEEBgtAdjCheck  
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
            @EnvValue       INT 
    
    UPDATE A
       SET AccUnit = B.AccUnit,
           StdYear = B.StdYear 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TACEEBgtAdj     AS B ON ( B.CompanySeq = @CompanySeq AND B.AdjSeq = A.AdjSeq ) 
     WHERE A.WorkingTag = 'D'   
       AND A.Status = 0   

    
    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008

    UPDATE #BIZ_OUT_DataBlock1
       SET DeptSeq = CASE WHEN  @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,
           CCtrSeq = CASE WHEN  @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END
     WHERE Status   = 0


	--------------------------------------------------------------------------------------
	-- 체크1, (-)금액 입력 불가하도록 
	--------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1342               ,	-- @1 @2 @3 는(은) 저장 할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1342)
                          @LanguageSeq       , 
						  31931,	N'-'	 ,	-- SELECT * FROM _TCADictionary WHERE WordSeq = 31931
                          290,		N'금액'		-- SELECT * FROM _TCADictionary WHERE WordSeq = 290
    UPDATE #BIZ_OUT_DataBlock1
       SET Result        = REPLACE(@Results, '@3', ''),
           MessageType   = @MessageType,
           Status        = @Status
	  FROM #BIZ_OUT_DataBlock1 AS A
	 WHERE A.Status		= 0
	   AND A.WorkingTag IN ('A','U')
	   AND (A.Month01	< 0
	    OR  A.Month02	< 0
		OR	A.Month03	< 0
		OR	A.Month04	< 0
		OR	A.Month05	< 0
		OR	A.Month06	< 0
		OR	A.Month07	< 0
		OR	A.Month08	< 0
		OR  A.Month09	< 0
		OR	A.Month10	< 0
		OR	A.Month11	< 0
		OR	A.Month12	< 0)
	--------------------------------------------------------------------------------------
	-- 체크1, END
	--------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------
    -- 체크2, 년예산마감체크
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          5                  , -- 이미 @1가(이) 완료된 @2입니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)  
                          @LanguageSeq       ,   
                          0,'년예산마감 ',   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
                          0,'자료'  
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
                JOIN _TACBgtClosing AS B WITH(NOLOCK) ON A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit   
      WHERE B.CompanySeq = @CompanySeq   
        AND B.IsCfm = '1'  
        AND Status = 0  
    --------------------------------------------------------------------------------------
    -- 체크2, END
    --------------------------------------------------------------------------------------  
    --------------------------------------------------------------------------------------
    -- 체크3, 법인관리 결산연도에 예산을 편성하려는 연도가 등록되어 있지 않았을 때 
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND FiscalYear IN (SELECT StdYear FROM #BIZ_OUT_DataBlock1))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1170                  , -- @1에 @2이(가) 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%등록%')    
                              @LanguageSeq       ,     
                              27121,'법인관리 ',   -- SELECT * FROM _TCADictionary WHERE Word like '%법인%'    
                              1749,'예산연도' -- SELECT * FROM _TCADictionary WHERE Word like '%예산연도%'    
  
        UPDATE #BIZ_OUT_DataBlock1    
           SET Result        = @Results,    
               MessageType   = @MessageType,    
               Status        = @Status  
    END  
    --------------------------------------------------------------------------------------
    -- 체크3, END 
    --------------------------------------------------------------------------------------
    --select 123, *from #BIZ_OUT_DataBlock1 
    --return 
    --------------------------------------------------------------------------------------
    -- 체크4, 중복여부 체크 
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.StdYear, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.UMCostType
              FROM (SELECT A1.StdYear, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.UMCostType
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.StdYear, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.UMCostType
                      FROM mnpt_TACEEBgtAdj AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND AdjSeq = A1.AdjSeq   
                                      )  
                   ) AS S  
             GROUP BY S.StdYear, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.UMCostType
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.StdYear = B.StdYear
                   AND A.AccUnit = B.AccUnit
                   AND A.DeptSeq = B.DeptSeq
                   AND A.CCtrSeq = B.CCtrSeq
                   AND A.AccSeq = B.AccSeq
                   AND A.UMCostType = B.UMCostType
                     )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    --------------------------------------------------------------------------------------
    -- 체크4, END 
    --------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------
    -- 체크5, 예산계정과목만 저장 할 수 있습니다.
    --------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '예산계정과목만 저장 할 수 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND B.SMBgtType <> 4005001 
    --------------------------------------------------------------------------------------
    -- 체크5, END 
    --------------------------------------------------------------------------------------    

    
    --return 
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TACEEBgtAdj', 'AdjSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET AdjSeq = @Seq + DataSeq   
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
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
       AND ( AdjSeq = 0 OR AdjSeq IS NULL )  
    
    --update #BIZ_OUT_DataBlock1
    --   set status = 1234 
      
    RETURN  

    go
