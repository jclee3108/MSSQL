
IF OBJECT_ID('_SACLendSuretySave') IS NOT NULL 
    DROP PROC _SACLendSuretySave 
GO 

-- v2013.12.19 

-- 대여금등록(담보설정저장) by이재천
CREATE PROC _SACLendSuretySave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS   
    
	CREATE TABLE #TACLendSurety (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock5', '#TACLendSurety'     
	IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACLendSurety')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACLendSurety', -- 테이블명        
                  '#TACLendSurety', -- 임시 테이블명        
                  'LendSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 

	-- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #TACLendSurety WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        IF @WorkingTag = 'SheetDel' 
        BEGIN 
        
            DELETE B
              FROM #TACLendSurety A 
              JOIN _TACLendSurety B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0 
        END
        ELSE
        BEGIN
            DELETE B
              FROM #TACLendSurety A 
              JOIN _TACLendSurety B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0    
            END
        
        IF @@ERROR <> 0  RETURN
        
    END  
    -- UPDATE    
	IF EXISTS (SELECT 1 FROM #TACLendSurety WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE _TACLendSurety
           SET SuretyAmt   = A.SuretyAmt   ,
               SuretyDate  = A.SuretyDate  ,
               Remark      = A.Remark      ,
               SuretyName  = A.SuretyName  ,
               ExpireDate  = A.ExpireDate ,
               LastUserSeq = @UserSeq,
               LastDateTime = GetDate()
          FROM #TACLendSurety AS A 
          JOIN _TACLendSurety B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
           
        IF @@ERROR <> 0  RETURN
	END  
    
	-- INSERT
	IF EXISTS (SELECT 1 FROM #TACLendSurety WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
		INSERT INTO _TACLendSurety (
		                            CompanySeq, LendSeq, Serl, SuretyName, SuretyAmt, 
		                            SuretyDate, ExpireDate, Remark, LastUserSeq, LastDateTime, 
		                            PgmSeq
		                           ) 
		SELECT @CompanySeq, A.LendSeq, A.Serl, A.SuretyName, A.SuretyAmt, 
               A.SuretyDate, A.ExpireDate, A.Remark, @UserSeq, GETDATE(), 
               @PgmSeq
		  FROM #TACLendSurety AS A   
		 WHERE A.WorkingTag = 'A' 
		   AND A.Status = 0    
		
        IF @@ERROR <> 0 RETURN
    END   
    
    SELECT * FROM #TACLendSurety 
    
    RETURN    
GO
begin tran 
exec _SACLendSuretySave @xmlDocument=N'<ROOT>
  <DataBlock5>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <LendSeq>18</LendSeq>
    <Serl>1</Serl>
    <SuretyName>담보명</SuretyName>
    <SuretyAmt>11111.00000</SuretyAmt>
    <SuretyDate>20131213</SuretyDate>
    <ExpireDate>20131225</ExpireDate>
    <Remark>teste</Remark>
  </DataBlock5>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392
select * from _TACLendSurety where LendSeq = 18
rollback 