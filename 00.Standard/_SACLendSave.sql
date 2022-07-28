
IF OBJECT_ID('_SACLendSave') IS NOT NULL 
    DROP PROC _SACLendSave 
GO

-- v2013.12.19 

-- 대여금등록(저장) by이재천
CREATE PROC _SACLendSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS   
    
	CREATE TABLE #TACLend (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TACLend'     
	IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACLend')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACLend'    , -- 테이블명        
                  '#TACLend'    , -- 임시 테이블명        
                  'LendSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE        
    IF @WorkingTag <> 'SheetDel' 
    BEGIN

	    IF EXISTS (SELECT TOP 1 1 FROM #TACLend WHERE WorkingTag = 'D' AND Status = 0)  
	    BEGIN  
            DELETE B
              FROM #TACLend A 
	          JOIN _TACLend B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
                         
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0    
            
            IF @@ERROR <> 0  RETURN
        END  
    END

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #TACLend WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE B
           SET Amt          = A.Amt, 
               BizUnit      = A.BizUnit, 
               --SMKoOrFor    = A.SMKoOrFor, 
               --ExRateDate   = A.ExRateDate,
               --ForAmt       = A.ForAmt, 
               --CurrSeq      = A.CurrSeq, 
               AccSeq       = A.AccSeq, 
               LendNo       = A.LendNo, 
               UMLendKind   = A.UMLendKind, 
               CustSeq      = A.CustSeq, 
               ExpireDate   = A.ExpireDate, 
               EmpSeq       = A.EmpSeq, 
               Remark       = A.Remark, 
               SMLendType   = A.SMLendType, 
               LendDate     = A.LendDate, 
               LastUserSeq  = @UserSeq, 
               LastDateTime = GetDate() 
          FROM #TACLend AS A 
          JOIN _TACLend AS B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
                     
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
           
        IF @@ERROR <> 0  RETURN
	END  

	-- INSERT
	IF EXISTS (SELECT 1 FROM #TACLend WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
        INSERT INTO _TACLend (
                              CompanySeq  , Amt         , BizUnit     , AccSeq      , LendNo       ,
                              UMLendKind  , CustSeq     , ExpireDate  , LendSeq     , EmpSeq       , 
                              Remark      , SMLendType  , LendDate    , LastUserSeq , LastDateTime , 
                              PgmSeq 
                             ) 
        SELECT @CompanySeq , Amt     , BizUnit     , AccSeq      , LendNo      , 
               UMLendKind  , ISNULL(CustSeq,0)     , ExpireDate  , LendSeq     , ISNULL(EmpSeq,0)      , 
               Remark      , SMLendType  , LendDate    , @UserSeq    , GetDate()   , 
               @PgmSeq
          FROM #TACLend AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
	END   


	SELECT * FROM #TACLend 
    
    RETURN    
GO
begin tran

exec _SACLendSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <LendSeq>37</LendSeq>
    <BizUnit>1</BizUnit>
    <SMLendType>4556001</SMLendType>
    <UMLendKind>4103001</UMLendKind>
    <LendNo>etset</LendNo>
    <AccSeq>6</AccSeq>
    <LendDate>20131223</LendDate>
    <ExpireDate>20131230</ExpireDate>
    <Amt>1000.00000</Amt>
    <CustSeq>33761</CustSeq>
    <EmpSeq>1852</EmpSeq>
    <Remark>tesete</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392
select * from _TACLend 
rollback tran 