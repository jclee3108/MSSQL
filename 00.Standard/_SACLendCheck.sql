
IF OBJECT_ID('_SACLendCheck') IS NOT NULL 
    DROP PROC _SACLendCheck 
GO

-- v.2013.12.19 

-- �뿩�ݵ��(üũ) by����õ
CREATE PROC _SACLendCheck
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
    
    CREATE TABLE #TACLend (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TACLend'

/*
	-- �ʼ��Է� Message �޾ƿ���
	EXEC dbo._SCOMMessage @MessageType OUTPUT,
						  @Status      OUTPUT,
						  @Results     OUTPUT,
						  1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
						  @LanguageSeq       , 
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

	-- �ʼ��Է� Check 
--	UPDATE #TACLend
--	   SET Result        = @Results,
--		   MessageType   = @MessageType,
--		   Status        = @Status
--	  FROM #TACLend AS A
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
  --                    FROM #TACLend AS A   
  --                         LEFT OUTER JOIN _TACLend AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                                       AND ( A.LendSeq       = B.LendSeq ) 
                          
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
  --       UPDATE #TACLend  
  --          SET Result        = @Results,  
  --              MessageType   = @MessageType,  
  --              Status        = @Status  
  --      FROM #TACLend AS A   
  --            LEFT OUTER  JOIN _TACLend AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
  --                                                           AND ( A.LendSeq       = B.LendSeq ) 
                          
  --      WHERE A.WorkingTag IN ('U', 'D')
  --            and b.Ű�� IS NULL 
  --  END   
               
  ---------------------------
	-- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
	---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TACLend', '#TACLend','Ű��'  

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
--	UPDATE #TACLend
--	   SET Result        = @Results,
--		     MessageType   = @MessageType,
--		     Status        = @Status
--	  FROM #TACLend AS A
--	 WHERE A.WorkingTag IN ('A','U')
--	   AND A.Status = 0
  -- guide : �̰��� �ߺ�üũ ������ ��������.
  -- e.g.  : 
  --   AND ��Ī  IN (
  --                      SELECT ��Ī
  --                       FROM (
  --                              SELECT A.��Ī  
  --                                FROM #TACLend AS A 
  --                               WHERE WorkingTag IN ('A', 'U')
  --                                 AND Status   = 0 
  --                              UNION ALL     
  --                              SELECT A.��Ī 
  --                                FROM _TACLend AS A
  --                               WHERE CompanySeq = @CompanySeq
  --                                 AND A.Ű��  NOT IN (
  --                                                     SELECT Ű�� 
  --                                                       FROM #TACLend
  --                                                      WHERE WorkingTag = 'U'
  --                                                        AND Status   = 0)
  --                                                                     
  --                                 ) AS A  
  --                       GROUP BY ��Ī 
  --                       Having COUNT(1) > 1 )   
  --        
  --
  */
	-- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
--guide : '������ Ű ����' --------------------------
    DECLARE @MaxSeq          INT,
            @Count           INT, 
            @RePayOptSerl    INT, 
            @InterestOptSerl INT, 
            @PlanSerl        INT, 
            @SuretySerl      INT
            
            
    SELECT @Count = Count(1) FROM #TACLend WHERE WorkingTag = 'A' AND Status = 0
    IF @Count >0 
    BEGIN
    EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, '_TACLend','LendSeq',@Count --rowcount  
        UPDATE #TACLend             
           SET LendSeq  = @MaxSeq + DataSeq   
         WHERE WorkingTag = 'A'            
	       AND Status = 0 
	 END  
    
    SELECT * FROM #TACLend 
    
    RETURN 
GO
exec _SACLendCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <LendSeq>0</LendSeq>
    <BizUnit>1</BizUnit>
    <SMLendType>4556001</SMLendType>
    <UMLendKind>4103001</UMLendKind>
    <LendNo>test111</LendNo>
    <AccSeq>1303</AccSeq>
    <LendDate>20131219</LendDate>
    <ExpireDate>20131219</ExpireDate>
    <LendAmt>100000</LendAmt>
    <CustSeq>38177</CustSeq>
    <EmpSeq>1852</EmpSeq>
    <Remark>dfdsgasdg</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392