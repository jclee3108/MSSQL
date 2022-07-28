
IF OBJECT_ID('_SACLendRePayOptCheck') IS NOT NULL 
    DROP PROC _SACLendRePayOptCheck 
GO 

-- v2013.12.19 

-- �뿩�ݵ��(��ȯ����üũ) by����õ
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
--	UPDATE #TACLendRePayOpt
--	   SET Result        = @Results,
--		   MessageType   = @MessageType,
--		   Status        = @Status
--	  FROM #TACLendRePayOpt AS A
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
  --                    FROM #TACLendRePayOpt AS A   
  --                         LEFT OUTER JOIN _TACLendRePayOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                                       AND ( A.LendSeq       = B. ) 
                         AND ( A.Serl          = B. ) 
                          
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
  --       UPDATE #TACLendRePayOpt  
  --          SET Result        = @Results,  
  --              MessageType   = @MessageType,  
  --              Status        = @Status  
  --      FROM #TACLendRePayOpt AS A   
  --            LEFT OUTER  JOIN _TACLendRePayOpt AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                           AND ( A.LendSeq       = B. ) 
                         AND ( A.Serl          = B. ) 
                          
  --      WHERE A.WorkingTag IN ('U', 'D')
  --            and b.Ű�� IS NULL 
  --  END   
               
  ---------------------------
	-- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
	---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TACLendRePayOpt', '#TACLendRePayOpt','Ű��'  

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
--	UPDATE #TACLendRePayOpt
--	   SET Result        = @Results,
--		     MessageType   = @MessageType,
--		     Status        = @Status
--	  FROM #TACLendRePayOpt AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
  -- guide : �̰��� �ߺ�üũ ������ ��������.
  -- e.g.  : 
  --   AND ��Ī  IN (
  --                      SELECT ��Ī
  --                       FROM (
  --                              SELECT A.��Ī  
  --                                FROM #TACLendRePayOpt AS A 
  --                               WHERE WorkingTag IN ('A', 'U')
  --                                 AND Status   = 0 
  --                              UNION ALL     
  --                              SELECT A.��Ī 
  --                                FROM _TACLendRePayOpt AS A
  --                               WHERE CompanySeq = @CompanySeq
  --                                 AND A.Ű��  NOT IN (
  --                                                     SELECT Ű�� 
  --                                                       FROM #TACLendRePayOpt
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
  -- SELECT @Count = Count(1) FROM #TACLendRePayOpt WHERE WorkingTag = 'A' AND Status = 0
  -- if @Count >0 
  -- BEGIN
  --   EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, '_TACLendRePayOpt','Ű��',@Count --rowcount  
  --        UPDATE #TACLendRePayOpt             
  --           SET Ű��  = @MaxSeq + DataSeq   
  --         WHERE WorkingTag = 'A'            
	--           AND Status = 0 
	-- END  

--guide : '������ Ű ����' --------------------------
--   DECLARE @MaxSeq      INT ,
--           @Count       INT
--   
--
--   SELECT @Count = Count(1) FROM  #TACLendRePayOpt    WHERE WorkingTag = 'A' AND Status = 0
--   IF @Count >0 
--   BEGIN
--
--        SELECT @MaxSeq =ISNULL( Max('������Ű��'),0)
--          FROM _TACLendRePayOpt   AS A
--               JOIN   #TACLendRePayOpt    AS B ON  A.'������Ű��'= B.'������Ű��'
--         WHERE A.CompanySeq  = @CompanySeq 
--           AND B.WorkingTag = 'A'            
--           AND B.Status = 0 
--        
--        UPDATE  #TACLendRePayOpt                
--           SET '������Ű��'  = @MaxSeq + DataSeq   
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