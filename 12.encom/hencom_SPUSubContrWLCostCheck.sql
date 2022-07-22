IF OBJECT_ID('hencom_SPUSubContrWLCostCheck') IS NOT NULL 
    DROP PROC hencom_SPUSubContrWLCostCheck
GO 

-- v2017.07.31 

/************************************************************
 설  명 - 데이터-WL사용정산처리_hencom : 체크
 작성일 - 20151002
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SPUSubContrWLCostCheck
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	DECLARE @MessageType	INT,
					@Status				INT,
					@Results			NVARCHAR(250)
  					
  CREATE TABLE #hencom_TPUSubContrWL (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPUSubContrWL'
    /*비용항목 설정화면의 구분값 가져온다. (WL정산에 사용된 비용항목구분)*/
	DECLARE @SMKindSeq INT,@CostSeq INT
	
    -- 시스템제공 추가정보로 추가 
	SELECT @CostSeq = MAX(B.ValueSeq), 
           @SMKindSeq = MAX(A.MinorSeq)
	FROM _TDASMinor AS A 
    JOIN _TDASMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 )
	WHERE A.CompanySeq = @CompanySeq AND A.MajorSeq = 4503 AND A.MinorName LIKE '%WL%' -- <<명칭으로 찾음.
    

    IF @CostSeq IS NULL OR @CostSeq = 0 
    BEGIN     
        SELECT @CostSeq = MAX(A.CostSeq) FROM _TARCostAcc AS A 
        WHERE A.CompanySeq = @CompanySeq AND A.SMKindSeq = @SMKindSeq
    END 
    -- 시스템제공 추가정보로 추가 
    
    UPDATE #hencom_TPUSubContrWL
    SET CostSeq = @CostSeq
    WHERE WorkingTag IN ('A','U')
	   AND Status = 0
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
	UPDATE #hencom_TPUSubContrWL
	   SET Result        = 'WL정산에 사용할 비용항목이 등록되지 않았습니다.',
		   MessageType   = @MessageType,
		   Status        = @Status
	  FROM #hencom_TPUSubContrWL AS A
	 WHERE A.WorkingTag IN ('A','U')
	   AND A.Status = 0 AND ISNULL(@CostSeq,0) = 0 
  
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
--	UPDATE #TPDOSPDelvInSubItem 
--	   SET Status = 6,      -- 중복된 @1 @2가(이) 입력되었습니다.      
--		   result = @Results      
--	  FROM #TPDOSPDelvInSubItem A      
--	 WHERE A.WorkingTag IN ('A', 'U')
--	   AND A.Status = 0
  -- guide : 이곳에 중복체크 조건을 넣으세요.
  -- e.g.  : 
  -- AND EXISTS (SELECT TOP 1 1 FROM _TPDOSPDelvInItemMat   
  --                           WHERE CompanySeq = @CompanySeq   
  --                             AND OSPDelvInSeq = B.OSPDelvInSeq     
  --                             AND OSPDelvInSerl = B.OSPDelvInSerl   
  --                             AND ItemSeq = B.ItemSeq  )    
          
	-- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #hencom_TPUSubContrWL WHERE WorkingTag = 'A' AND Status = 0
    IF @Count >0 
    BEGIN
    EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TPUSubContrWL','WLReqSeq',@Count --rowcount  
          UPDATE #hencom_TPUSubContrWL             
             SET WLReqSeq  = @MaxSeq + DataSeq   
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  
	SELECT * FROM #hencom_TPUSubContrWL 
RETURN

go 

exec hencom_SPUSubContrWLCostCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <DeptName>음성</DeptName>
    <WLDate>20170701</WLDate>
    <WLComment />
    <ContrAmt>100</ContrAmt>
    <UMOTTypeName />
    <OTAmt>0</OTAmt>
    <UMAddPayTypeName />
    <AddPayAmt>0</AddPayAmt>
    <UMDeductionTypeName />
    <DeductionAmt>0</DeductionAmt>
    <CurVAT>10</CurVAT>
    <CostName />
    <Remark />
    <DeptSeq>45</DeptSeq>
    <WLReqSeq>0</WLReqSeq>
    <CostSeq>0</CostSeq>
    <UMOTType>0</UMOTType>
    <UMAddPayType>0</UMAddPayType>
    <UMDeductionType>0</UMDeductionType>
    <SubContrCarSeq>321</SubContrCarSeq>
    <CarNo>7302</CarNo>
    <CustSeq />
    <CustName />
    <UMCarClass>8030001</UMCarClass>
    <UMCarClassName>자차</UMCarClassName>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032408,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026829