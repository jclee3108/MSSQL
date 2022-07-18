
IF OBJECT_ID('DTI_SSLReceiptConsignSave') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignSave
GO

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁저장) by이재천
CREATE PROCEDURE DTI_SSLReceiptConsignSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle  INT, 
            @ReceiptSeq INT, 
            @count      INT, 
            @BizUnit    INT, 
            @CurrDate   NCHAR(8), 
            @ReceiptNo  NCHAR(12) 
    
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #DTI_TSLReceiptConsign (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLReceiptConsign'   
    
    SELECT @ReceiptSeq = ReceiptSeq,   
           @BizUnit    = BizUnit  
      FROM #DTI_TSLReceiptConsign   
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'DTI_TSLReceiptConsign', -- 원테이블명  
                   '#DTI_TSLReceiptConsign', -- 템프테이블명  
                   'ReceiptSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq,ReceiptSeq,ReceiptNo,ReceiptDate,EmpSeq,DeptSeq,CustSeq,CurrSeq,ExRate,SlipSeq,OppAccSeq,LastUserSeq,LastDateTime,PgmSeq', '',@Pgmseq  
    
    
    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        EXEC _SCOMDeleteLog  @CompanySeq   ,    
                             @UserSeq      ,    
                             'DTI_TSLReceiptConsignDesc', -- 원테이블명    
                             '#DTI_TSLReceiptConsign', -- 템프테이블명    
                             'ReceiptSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                             'CompanySeq,ReceiptSeq,ReceiptSerl,UMReceiptKind,SMDrOrCr,CurAmt,DomAmt,BankSeq,BankAccSeq,CustSeq,Remark,LastUserSeq,LastDateTime,PgmSeq'    
  
        EXEC _SCOMDeleteLog  @CompanySeq   ,    
                             @UserSeq      ,    
                             'DTI_TSLReceiptConsignBill', -- 원테이블명    
                             '#DTI_TSLReceiptConsign', -- 템프테이블명    
                             'ReceiptSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                             'CompanySeq,ReceiptSeq,BillSeq,CurAmt,DomAmt,LastUserSeq,LastDateTime,PgmSeq' 
  
        DELETE A    
          FROM DTI_TSLReceiptConsign AS A  
          JOIN #DTI_TSLReceiptConsign AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq )
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0  
    
        IF @@ERROR <> 0 RETURN   
  
        DELETE A  
          FROM DTI_TSLReceiptConsignDesc    AS A  
          JOIN #DTI_TSLReceiptConsign       AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq ) 
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0  
    
        IF @@ERROR <> 0 RETURN   
  
        DELETE A  
          FROM DTI_TSLReceiptConsignBill AS A  
          JOIN #DTI_TSLReceiptConsign AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq )
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0  
    
        IF @@ERROR <> 0 RETURN   
    
    END     
    
    -- Update                                                                                                   
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN     
        UPDATE A     
           SET ReceiptNo    = B.ReceiptNo,  
               ReceiptDate  = B.ReceiptDate,  
               EmpSeq       = B.EmpSeq,  
               DeptSeq      = B.DeptSeq,   
               CustSeq      = B.CustSeq,   
               CurrSeq      = B.CurrSeq,   
               ExRate       = B.ExRate,   
               OppAccSeq    = B.OppAccSeq,   
               LastUserSeq  = @UserSeq,   
               LastDateTime = GETDATE()  ,  
               PgmSeq       = @PgmSeq  
          FROM DTI_TSLReceiptConsign AS A   
          JOIN #DTI_TSLReceiptConsign AS B ON A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq   
         WHERE B.WorkingTag = 'U'   
           AND B.Status = 0  
    
        IF @@ERROR <> 0 RETURN   
    END   
    
    -- INSERT                                                                                                   
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- 서비스 INSERT    
        INSERT INTO DTI_TSLReceiptConsign (
                                           CompanySeq   ,ReceiptSeq     ,ReceiptNo      ,ReceiptDate    ,EmpSeq,
                                           DeptSeq      ,CustSeq        ,CurrSeq        ,ExRate         ,SlipSeq,
                                           OppAccSeq    ,LastUserSeq    ,LastDateTime   ,PgmSeq
                                          )
        SELECT @CompanySeq  ,ReceiptSeq     ,ReceiptNo      ,ReceiptDate    ,EmpSeq,
               DeptSeq      ,CustSeq        ,CurrSeq        ,ExRate         ,0     ,
               OppAccSeq    ,@UserSeq       ,GETDATE()      ,@PgmSeq
          FROM #DTI_TSLReceiptConsign    
         WHERE WorkingTag = 'A' 
           AND Status = 0    
        
        IF @@ERROR <> 0 RETURN   
    END     
    
    --UPDATE A  
    --SET --A.BizUnitOld = B.BizUnit,   
    --    A.DeptSeqOld = B.DeptSeq,  
    --    A.DateOld = B.ReceiptDate   
    --  FROM #DTI_TSLReceiptConsign AS A     
    --  JOIN DTI_TSLReceiptConsign AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq )  
   
    SELECT * FROM #DTI_TSLReceiptConsign  
    
    RETURN    
Go
--begin tran
--exec DTI_SSLReceiptConsignSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>D</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <Status>0</Status>
--    <ReceiptSeq>15</ReceiptSeq>
--    <SMExpKind>8009001</SMExpKind>
--    <ReceiptNo>Receipt201405210015</ReceiptNo>
--    <ReceiptDate>20140521</ReceiptDate>
--    <EmpSeq>2018</EmpSeq>
--    <DeptSeq>1484</DeptSeq>
--    <CustSeq>30353</CustSeq>
--    <CurrSeq>1</CurrSeq>
--    <ExRate>1.000000</ExRate>
--    <SlipSeq>0</SlipSeq>
--    <OppAccSeq>22</OppAccSeq>
--    <SMExpKindName>내수</SMExpKindName>
--    <EmpName>강영택</EmpName>
--    <DeptName>KS_영업본부</DeptName>
--    <CustName>(사)청권사</CustName>
--    <CurrName>KRW</CurrName>
--    <OppAccName>외상매출금</OppAccName>
--    <SlipID />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019203
--select * from DTI_TSLReceiptConsign where companyseq =1 and receiptseq = 15 

--rollback 