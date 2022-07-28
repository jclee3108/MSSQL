
IF OBJECT_ID('_SACLendRePayOptCheck') IS NOT NULL 
    DROP PROC _SACLendRePayOptCheck 
GO 

-- v2013.12.19 

-- 대여금등록(상환조건체크) by이재천
CREATE PROC _SACLendRePayOptCheck
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
    
    CREATE TABLE #TACLendRePayOpt (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TACLendRePayOpt'
    --select * from #TACLendRePayOpt 
    
/*		
	---------------------------
	-- 필수입력 체크
	---------------------------
	
	-- 필수입력 Message 받아오기
	EXEC dbo._SCOMMessage @MessageType OUTPUT,
						  @Status      OUTPUT,
						  @Results     OUTPUT,
						  1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')
						  @LanguageSeq       , 
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

	-- 필수입력 Check 
--	UPDATE #TACLendRePayOpt
--	   SET Result        = @Results,
--		   MessageType   = @MessageType,
--		   Status        = @Status
--	  FROM #TACLendRePayOpt AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
	-- guide : 이곳에 필수입력 체크 할 항목을 조건으로 넣으세요.
	-- e.g.   :
	-- AND (A.DBPatchSeq           = 0
	--      OR A.DBWorkSeq          = 0
	--      OR A.DBPatchListName    = '')
	
	--------------------------------------------------------------------------------------  
  -- 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존재하지 않으면 에러처리  
  --------------------------------------------------------------------------------------  
  --   IF  EXISTS (SELECT 1   
  --                    FROM #TACLendRePayOpt AS A   
  --                         LEFT OUTER JOIN _TACLendRePayOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                                       AND ( A.LendSeq       = B. ) 
                         AND ( A.Serl          = B. ) 
                          
  --                   WHERE A.WorkingTag IN ('U', 'D')
  --                     AND B.키값 IS NULL )  
  --   BEGIN  
  --       EXEC dbo._SCOMMessage @MessageType OUTPUT,  
  --                             @Status      OUTPUT,  
  --                             @Results     OUTPUT,  
  --                             7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
  --                             @LanguageSeq       ,   
  --                             '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
  --
  --       UPDATE #TACLendRePayOpt  
  --          SET Result        = @Results,  
  --              MessageType   = @MessageType,  
  --              Status        = @Status  
  --      FROM #TACLendRePayOpt AS A   
  --            LEFT OUTER  JOIN _TACLendRePayOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                           AND ( A.LendSeq       = B. ) 
                         AND ( A.Serl          = B. ) 
                          
  --      WHERE A.WorkingTag IN ('U', 'D')
  --            and b.키값 IS NULL 
  --  END   
               
  ---------------------------
	-- 삭제코드  체크:마스터 성 테이블일 경우 삭제시 사용 테이블 체크 sp입니다.
	---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TACLendRePayOpt', '#TACLendRePayOpt','키값'  

	---------------------------
	-- 중복여부 체크
	---------------------------  
	-- 중복체크 Message 받아오기    
	EXEC dbo._SCOMMessage @MessageType OUTPUT,    
						  @Status      OUTPUT,    
						  @Results     OUTPUT,    
						  6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
						  @LanguageSeq       ,     
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'    
      
	-- 중복여부 Check
--	UPDATE #TACLendRePayOpt
--	   SET Result        = @Results,
--		     MessageType   = @MessageType,
--		     Status        = @Status
--	  FROM #TACLendRePayOpt AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
  -- guide : 이곳에 중복체크 조건을 넣으세요.
  -- e.g.  : 
  --   AND 명칭  IN (
  --                      SELECT 명칭
  --                       FROM (
  --                              SELECT A.명칭  
  --                                FROM #TACLendRePayOpt AS A 
  --                               WHERE WorkingTag IN ('A', 'U')
  --                                 AND Status   = 0 
  --                              UNION ALL     
  --                              SELECT A.명칭 
  --                                FROM _TACLendRePayOpt AS A
  --                               WHERE CompanySeq = @CompanySeq
  --                                 AND A.키값  NOT IN (
  --                                                     SELECT 키값 
  --                                                       FROM #TACLendRePayOpt
  --                                                      WHERE WorkingTag = 'U'
  --                                                        AND Status   = 0)
  --                                                                     
  --                                 ) AS A  
  --                       GROUP BY 명칭 
  --                       Having COUNT(1) > 1 )   
  --        
  --
	-- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
--guide : '마스터 키 생성' --------------------------
  -- DECLARE @MaxSeq INT,
  --         @Count  INT 
  -- SELECT @Count = Count(1) FROM #TACLendRePayOpt WHERE WorkingTag = 'A' AND Status = 0
  -- if @Count >0 
  -- BEGIN
  --   EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, '_TACLendRePayOpt','키값',@Count --rowcount  
  --        UPDATE #TACLendRePayOpt             
  --           SET 키값  = @MaxSeq + DataSeq   
  --         WHERE WorkingTag = 'A'            
	--           AND Status = 0 
	-- END  

--guide : '디테일 키 생성' --------------------------
--   DECLARE @MaxSeq      INT ,
--           @Count       INT
--   
--
--   SELECT @Count = Count(1) FROM  #TACLendRePayOpt    WHERE WorkingTag = 'A' AND Status = 0
--   IF @Count >0 
--   BEGIN
--
--        SELECT @MaxSeq =ISNULL( Max('디테일키값'),0)
--          FROM _TACLendRePayOpt   AS A
--               JOIN   #TACLendRePayOpt    AS B ON  A.'마스터키값'= B.'마스터키값'
--         WHERE A.CompanySeq  = @CompanySeq 
--           AND B.WorkingTag = 'A'            
--           AND B.Status = 0 
--        
--        UPDATE  #TACLendRePayOpt                
--           SET '디테일키값'  = @MaxSeq + DataSeq   
--         WHERE WorkingTag = 'A'            
--           AND Status = 0 
--   END             
*/
    
    DECLARE @Serl   INT, 
            @Count  INT 
            
    SELECT @Serl = ISNULL((SELECT MAX(B.Serl) 
                             FROM #TACLendRePayOpt AS A 
                             JOIN _TACLendRePayOpt AS B WITH(NOLOCK) ON (B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq )  
                          ),0)
    
    SELECT @Count = Count(1) FROM #TACLendRePayOpt WHERE WorkingTag = 'A' AND Status = 0
    IF @Count > 0 
    BEGIN
        UPDATE A
           SET A.Serl = @Serl + A.DataSeq 
          FROM #TACLendRePayOpt AS A 
         WHERE A.WorkingTag = 'A'            
           AND A.Status = 0 
    END 
    
    SELECT * FROM #TACLendRePayOpt 
    
    RETURN    
GO
exec _SACLendRePayOptCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FrDate>20131219</FrDate>
    <RepayCnt>1</RepayCnt>
    <ToDate>20131219</ToDate>
    <SMRepayType>4079001</SMRepayType>
    <Serl>0</Serl>
    <LendSeq>9</LendSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392