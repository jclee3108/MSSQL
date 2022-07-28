
IF OBJECT_ID('_SACLendInterestOptCheck') IS NOT NULL 
    DROP PROC _SACLendInterestOptCheck 
GO 

-- v2013.12.19 

-- �뿩�ݵ��(���ڳ�������üũ) by����õ
CREATE PROC _SACLendInterestOptCheck
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
    
    CREATE TABLE #TACLendInterestOpt (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TACLendInterestOpt'
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
--	UPDATE #TACLendInterestOpt
--	   SET Result        = @Results,
--		   MessageType   = @MessageType,
--		   Status        = @Status
--	  FROM #TACLendInterestOpt AS A
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
  --                    FROM #TACLendInterestOpt AS A   
  --                         LEFT OUTER JOIN _TACLendInterestOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                                       AND ( A.LendSeq         = B.LendSeq ) 
                         AND ( A.Serl            = B.Serl ) 
                          
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
  --       UPDATE #TACLendInterestOpt  
  --          SET Result        = @Results,  
  --              MessageType   = @MessageType,  
  --              Status        = @Status  
  --      FROM #TACLendInterestOpt AS A   
  --            LEFT OUTER  JOIN _TACLendInterestOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                           AND ( A.LendSeq         = B.LendSeq ) 
                         AND ( A.Serl            = B.Serl ) 
                          
  --      WHERE A.WorkingTag IN ('U', 'D')
  --            and b.Ű�� IS NULL 
  --  END   
               
  ---------------------------
	-- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
	---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TACLendInterestOpt', '#TACLendInterestOpt','Ű��'  

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
--	UPDATE #TACLendInterestOpt
--	   SET Result        = @Results,
--		     MessageType   = @MessageType,
--		     Status        = @Status
--	  FROM #TACLendInterestOpt AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
  -- guide : �̰��� �ߺ�üũ ������ ��������.
  -- e.g.  : 
  --   AND ��Ī  IN (
  --                      SELECT ��Ī
  --                       FROM (
  --                              SELECT A.��Ī  
  --                                FROM #TACLendInterestOpt AS A 
  --                               WHERE WorkingTag IN ('A', 'U')
  --                                 AND Status   = 0 
  --                              UNION ALL     
  --                              SELECT A.��Ī 
  --                                FROM _TACLendInterestOpt AS A
  --                               WHERE CompanySeq = @CompanySeq
  --                                 AND A.Ű��  NOT IN (
  --                                                     SELECT Ű�� 
  --                                                       FROM #TACLendInterestOpt
  --                                                      WHERE WorkingTag = 'U'
  --                                                        AND Status   = 0)
  --                                                                     
  --                                 ) AS A  
  --                       GROUP BY ��Ī 
  --                       Having COUNT(1) > 1 )   
  --        
  --
  */
    DECLARE @Serl   INT, 
            @Count  INT 
            
    SELECT @Serl = ISNULL((SELECT MAX(B.Serl) 
                             FROM #TACLendInterestOpt AS A 
                             JOIN _TACLendInterestOpt AS B WITH(NOLOCK) ON (B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq )  
                          ),0)
    
    SELECT @Count = Count(1) FROM #TACLendInterestOpt WHERE WorkingTag = 'A' AND Status = 0
    IF @Count > 0 
    BEGIN
        UPDATE A
           SET A.Serl = @Serl + A.DataSeq 
          FROM #TACLendInterestOpt AS A 
         WHERE A.WorkingTag = 'A'            
           AND A.Status = 0 
    END 
    
    SELECT * FROM #TACLendInterestOpt 
    
    RETURN 
			