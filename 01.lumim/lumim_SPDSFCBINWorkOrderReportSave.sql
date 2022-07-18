
IF OBJECT_ID('lumim_SPDSFCBINWorkOrderReportSave') IS NOT NULL
    DROP PROC lumim_SPDSFCBINWorkOrderReportSave
GO

-- v2013.08.06 

-- BIN비움작업및조회_lumim(저장) by이재천
CREATE PROC lumim_SPDSFCBINWorkOrderReportSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    CREATE TABLE #lumim_TPDSFCBINWorkOrder (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#lumim_TPDSFCBINWorkOrder'     
    IF @@ERROR <> 0 RETURN  

    --select * from #lumim_TPDSFCBINWorkOrder
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000) 
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('lumim_TPDSFCBINWorkOrder') 
    
	-- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'lumim_TPDSFCBINWorkOrder', -- 원테이블명
   				   '#lumim_TPDSFCBINWorkOrder', -- 템프테이블명
   				   'BINWorkOrderSeq' , -- 키가 여러개일 경우는 , 로 연결한다. 
   				   @TableColumns, '', @PgmSeq

    -- 작업순서 : DELETE -> UPDATE -> INSERT  

    -- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #lumim_TPDSFCBINWorkOrder WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
        DELETE lumim_TPDSFCBINWorkOrder
          FROM #lumim_TPDSFCBINWorkOrder A 
	           JOIN lumim_TPDSFCBINWorkOrder B ON ( A.BINWorkOrderSeq  = B.BINWorkOrderSeq ) 
                     
         WHERE B.CompanySeq  = @CompanySeq
           AND A.WorkingTag = 'D' 
           AND A.Status = 0    
        IF @@ERROR <> 0  RETURN
	END  

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #lumim_TPDSFCBINWorkOrder WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE lumim_TPDSFCBINWorkOrder
			   SET EmpSeq          = A.EmpSeq          ,
                   ItemSeq         = A.ItemSeq         ,
                   ProdPlanSeq     = A.ProdPlanSeq     , 
                   BINNo           = A.BINNo           ,
                   Qty             = A.Qty             ,
                   THTool          = A.THTool ,
			       LastUserSeq = @UserSeq,
			       LastDateTime = GetDate()
			  FROM #lumim_TPDSFCBINWorkOrder AS A 
              JOIN lumim_TPDSFCBINWorkOrder AS B ON ( B.CompanySeq = @CompanySeq AND A.BINWorkOrderSeq = B.BINWorkOrderSeq ) 
                         
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0 
			   
            IF @@ERROR <> 0  RETURN
	END  

	-- INSERT
	IF EXISTS (SELECT 1 FROM #lumim_TPDSFCBINWorkOrder WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
        INSERT INTO lumim_TPDSFCBINWorkOrder 
        (
         CompanySeq , BINWorkOrderSeq , BINWorkOrderNo, ProdPlanSeq , THTool      ,
         BINNo      , EmpSeq          , Qty           , ItemSeq     , LastUserSeq , LastDateTime
        ) 
        SELECT @CompanySeq , BINWorkOrderSeq , BINWorkOrderNo , ProdPlanSeq , THTool   , 
               BINNo       , EmpSeq          , Qty            , ItemSeq     , @UserSeq , GetDate() 
          FROM #lumim_TPDSFCBINWorkOrder AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
    
        IF @@ERROR <> 0 RETURN
	END   
    
    -- 비운시간 보여주기
    UPDATE A
       SET A.LastDateTime = CONVERT(NVARCHAR(20),B.LastDateTime,20)
      FROM #lumim_TPDSFCBINWorkOrder AS A
      JOIN lumim_TPDSFCBINWorkOrder AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BINWorkOrderSeq = A.BINWorkOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ('A','U')
    
    SELECT * FROM #lumim_TPDSFCBINWorkOrder 
    
    RETURN    
GO
begin tran
exec lumim_SPDSFCBINWorkOrderReportSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BINNo>001</BINNo>
    <BINWorkOrderNo />
    <EmpName>백봉욱</EmpName>
    <EmpId>20020102</EmpId>
    <LastDateTime>1900-01-01T00:00:00</LastDateTime>
    <ItemName>test_이재천(제품)</ItemName>
    <Position>생산조장</Position>
    <ProdPlanNo>201307260013</ProdPlanNo>
    <ProgramName>test5</ProgramName>
    <Qty>0.00000</Qty>
    <Rank>4K1E-1L7A-2V9</Rank>
    <THTool>AAA001</THTool>
    <BINWorkOrderSeq>0</BINWorkOrderSeq>
    <EmpSeq>45</EmpSeq>
    <ItemSeq>1000491</ItemSeq>
    <ProdPlanSeq>1000034</ProdPlanSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016984,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014493
rollback tran



