
IF OBJECT_ID('_SACLendSuretyCheck') IS NOT NULL 
    DROP PROC _SACLendSuretyCheck 
GO 

-- v2013.12.19 

-- �뿩�ݵ��(�㺸����üũ) by����õ
CREATE PROC _SACLendSuretyCheck
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
    
AS   
    
	DECLARE @MessageType    INT,
			@Status         INT,
			@Results        NVARCHAR(250)
    
    CREATE TABLE #TACLendSurety (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock5', '#TACLendSurety'
    /*
	---------------------------
	-- �ʼ��Է� üũ
	---------------------------
	
	-- �ʼ��Է� Message �޾ƿ���
	EXEC dbo._SCOMMessage @MessageType OUTPUT,
						  @Status      OUTPUT,
						  @Results     OUTPUT,
						  1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
						  @LanguageSeq       , 
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

	-- �ʼ��Է� Check 
--	UPDATE #TACLendSurety
--	   SET Result        = @Results,
--		   MessageType   = @MessageType,
--		   Status        = @Status
--	  FROM #TACLendSurety AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
	-- guide : �̰��� �ʼ��Է� üũ �� �׸��� �������� ��������.
	-- e.g.   :
	-- AND (A.DBPatchSeq           = 0
	--      OR A.DBWorkSeq          = 0
	--      OR A.DBPatchListName    = '')
	
	--------------------------------------------------------------------------------------  
  -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��  
  --------------------------------------------------------------------------------------  
  --   IF  EXISTS (SELECT 1   
  --                    FROM #TACLendSurety AS A   
  --                         LEFT OUTER JOIN _TACLendSurety AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                                       AND ( A.LendSeq       = B.LendSeq ) 
                         AND ( A.Serl          = B.Serl ) 
                          
  --                   WHERE A.WorkingTag IN ('U', 'D')
  --                     AND B.Ű�� IS NULL )  
  --   BEGIN  
  --       EXEC dbo._SCOMMessage @MessageType OUTPUT,  
  --                             @Status      OUTPUT,  
  --                             @Results     OUTPUT,  
  --                             7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
  --                             @LanguageSeq       ,   
  --                             '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
  --
  --       UPDATE #TACLendSurety  
  --          SET Result        = @Results,  
  --              MessageType   = @MessageType,  
  --              Status        = @Status  
  --      FROM #TACLendSurety AS A   
  --            LEFT OUTER  JOIN _TACLendSurety AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                           AND ( A.LendSeq       = B.LendSeq ) 
                         AND ( A.Serl          = B.Serl ) 
                          
  --      WHERE A.WorkingTag IN ('U', 'D')
  --            and b.Ű�� IS NULL 
  --  END   
               
  ---------------------------
	-- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
	---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TACLendSurety', '#TACLendSurety','Ű��'  

	---------------------------
	-- �ߺ����� üũ
	---------------------------  
	-- �ߺ�üũ Message �޾ƿ���    
	EXEC dbo._SCOMMessage @MessageType OUTPUT,    
						  @Status      OUTPUT,    
						  @Results     OUTPUT,    
						  6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
						  @LanguageSeq       ,     
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
      
	-- �ߺ����� Check
--	UPDATE #TACLendSurety
--	   SET Result        = @Results,
--		     MessageType   = @MessageType,
--		     Status        = @Status
--	  FROM #TACLendSurety AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
  -- guide : �̰��� �ߺ�üũ ������ ��������.
  -- e.g.  : 
  --   AND ��Ī  IN (
  --                      SELECT ��Ī
  --                       FROM (
  --                              SELECT A.��Ī  
  --                                FROM #TACLendSurety AS A 
  --                               WHERE WorkingTag IN ('A', 'U')
  --                                 AND Status   = 0 
  --                              UNION ALL     
  --                              SELECT A.��Ī 
  --                                FROM _TACLendSurety AS A
  --                               WHERE CompanySeq = @CompanySeq
  --                                 AND A.Ű��  NOT IN (
  --                                                     SELECT Ű�� 
  --                                                       FROM #TACLendSurety
  --                                                      WHERE WorkingTag = 'U'
  --                                                        AND Status   = 0)
  --                                                                     
  --                                 ) AS A  
  --                       GROUP BY ��Ī 
  --                       Having COUNT(1) > 1 )   
  --        
  --
	-- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
--guide : '������ Ű ����' --------------------------
  -- DECLARE @MaxSeq INT,
  --         @Count  INT 
  -- SELECT @Count = Count(1) FROM #TACLendSurety WHERE WorkingTag = 'A' AND Status = 0
  -- if @Count >0 
  -- BEGIN
  --   EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, '_TACLendSurety','Ű��',@Count --rowcount  
  --        UPDATE #TACLendSurety             
  --           SET Ű��  = @MaxSeq + DataSeq   
  --         WHERE WorkingTag = 'A'            
	--           AND Status = 0 
	-- END  

--guide : '������ Ű ����' --------------------------
--   DECLARE @MaxSeq      INT ,
--           @Count       INT
--   
--
--   SELECT @Count = Count(1) FROM  #TACLendSurety    WHERE WorkingTag = 'A' AND Status = 0
--   IF @Count >0 
--   BEGIN
--
--        SELECT @MaxSeq =ISNULL( Max('������Ű��'),0)
--          FROM _TACLendSurety   AS A
--               JOIN   #TACLendSurety    AS B ON  A.'������Ű��'= B.'������Ű��'
--         WHERE A.CompanySeq  = @CompanySeq 
--           AND B.WorkingTag = 'A'            
--           AND B.Status = 0 
--        
--        UPDATE  #TACLendSurety                
--           SET '������Ű��'  = @MaxSeq + DataSeq   
--         WHERE WorkingTag = 'A'            
--           AND Status = 0 
--   END             
*/
    DECLARE @Serl   INT, 
            @Count  INT 
            
    SELECT @Serl = ISNULL((SELECT MAX(B.Serl) 
                             FROM #TACLendSurety AS A 
                             JOIN _TACLendSurety AS B WITH(NOLOCK) ON (B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq )  
                          ),0)
    
    SELECT @Count = Count(1) FROM #TACLendSurety WHERE WorkingTag = 'A' AND Status = 0
    IF @Count > 0 
    BEGIN
        UPDATE A
           SET A.Serl = @Serl + A.DataSeq 
          FROM #TACLendSurety AS A 
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0 
    END 
    
    SELECT * FROM #TACLendSurety 
    
    RETURN    
			