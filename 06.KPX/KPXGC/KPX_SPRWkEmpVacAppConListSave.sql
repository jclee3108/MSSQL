
IF OBJECT_ID('KPX_SPRWkEmpVacAppConListSave') IS NOT NULL 
    DROP PROC KPX_SPRWkEmpVacAppConListSave
GO 

-- v2014.11.27 

-- 휴가신청(경조사내역데이터생성) by이재천 
CREATE PROC KPX_SPRWkEmpVacAppConListSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #TPRWkEmpVacApp (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPRWkEmpVacApp'     
    IF @@ERROR <> 0 RETURN  
    
    ALTER TABLE #TPRWkEmpVacApp ADD Seq INT NULL 
    
    IF (SELECT TOP 1 IsConfirm FROM #TPRWkEmpVacApp) = '1'
    BEGIN 
        
        DECLARE @Seq    INT 
    
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_THRWelConEmp', 'Seq', 1
        -- Temp Talbe 에 생성된 키값 UPDATE
        UPDATE #TPRWkEmpVacApp
           SET Seq = @Seq + DataSeq
         WHERE Status = 0 
    
        INSERT INTO _THRWelConEmp 
        (
            CompanySeq, EmpSeq, Seq, ConDate, ConSeq, 
            FamilyName, FamilyResidID, UMRelSeq, IsConAmt, IsMutualAmt, 
            ConAmt, LastUserSeq, LastDateTime 
            
        ) 
        SELECT @CompanySeq, B.EmpSeq, A.Seq, B.WkFrDate, B.CCSeq,
               C.EmpName, '', D.UMConClass, D.IsConAmt, D.IsMutualAmt, 
               A.ConAmt, @UserSeq, GETDATE()
          FROM #TPRWkEmpVacApp          AS A 
          JOIN _TPRWkEmpVacApp          AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq AND B.VacSeq = A.VacSeq ) 
          LEFT OUTER JOIN _TDAEmp       AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.EmpSeq ) 
          LEFT OUTER JOIN _THRWelCon    AS D ON ( D.CompanySeq = @CompanySeq AND D.ConSeq = B.CCSeq ) 
        
        INSERT INTO KPX_TPRWkEmpVacAppConEmpRelation 
        (
            CompanySeq,VacEmpSeq,VacSeq,ConEmpSeq,ConSeq, 
            LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, A.EmpSeq, A.VacSeq, A.EMpSeq, A.Seq, 
               @UserSeq, GETDATE()
          FROM #TPRWkEmpVacApp AS A 
    END 
    ELSE
    BEGIN 
        UPDATE A 
           SET Seq = B.ConSeq, 
               WorkingTag = 'D' 
          FROM #TPRWkEmpVacApp AS A 
          JOIN KPX_TPRWkEmpVacAppConEmpRelation AS B ON ( B.CompanySeq = @CompanySeq AND B.VacEmpSeq = A.EmpSeq AND B.VacSeq = A.VacSeq ) 
                
        -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
        EXEC _SCOMLog  @CompanySeq   ,  
                       @UserSeq      ,  
                       '_THRWelConEmp', -- 원테이블명  
                       '#TPRWkEmpVacApp', -- 템프테이블명  
                       'EmpSeq, Seq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                       'CompanySeq,EmpSeq,Seq,ConDate,ConSeq,FamilyName,FamilyResidID,UMRelSeq,IsConAmt,IsMutualAmt,ConAmt,IsFlower,FlowerAmt,PayDate,PbYm,PbSeq,AppSeq,LastUserSeq,LastDateTime, IsPay, Addr, AttachFileSeq, AttachFileName'   
        
        DELETE B
          FROM #TPRWkEmpVacApp AS A 
          JOIN _THRWelConEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq AND B.Seq = A.Seq ) 
        
        -- 로그 남기기  (연결테이블) 
        DECLARE @TableColumns NVARCHAR(4000)    
          
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRWkEmpVacAppConEmpRelation')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPRWkEmpVacAppConEmpRelation'    , -- 테이블명        
                      '#TPRWkEmpVacApp'    , -- 임시 테이블명        
                      'ConEmpSeq,ConSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , 'EmpSeq,Seq', @PgmSeq  -- 테이블 모든 필드명   
        DELETE B
          FROM #TPRWkEmpVacApp AS A 
          JOIN KPX_TPRWkEmpVacAppConEmpRelation   AS B ON ( B.CompanySeq = @CompanySeq AND B.ConEmpSeq = A.EmpSeq AND B.ConSeq = A.Seq ) 
        
        
    END 
    
    SELECT * FROM #TPRWkEmpVacApp 
    
    RETURN 
GO 
begin tran 
exec KPX_SPRWkEmpVacAppConListSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <EmpSeq>2028</EmpSeq>
    <VacSeq>1000553</VacSeq>
    <ConAmt>0</ConAmt>
    <IsConfirm>0</IsConfirm>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026265,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022017
--select * from _THRWelConEmp where empseq = 2028 

--select * from KPX_TPRWkEmpVacAppConEmpRelation 
--select * from _THRWelConEmpLog where companyseq = 1 and empseq = 2028 and seq = 1000021
--select * from KPX_TPRWkEmpVacAppConEmpRelation 
--select * from KPX_TPRWkEmpVacAppConEmpRelationLog
rollback 


--select * From _THRWelConEmp
--select * from _THRWelConEmpLog 


--ALTER TABLE 