
IF OBJECT_ID('DTI_SSLInterTransferServiceSave ') IS NOT NULL
    DROP PROC DTI_SSLInterTransferServiceSave 
    
GO

-- v2013.06.20

-- 사내대체등록(서비스)저장_DTI By 이재천
CREATE PROC DTI_SSLInterTransferServiceSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS  
    
    CREATE TABLE #DTI_TSLInterTransferService (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLInterTransferService'     
    IF @@ERROR <> 0 RETURN  

    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog @CompanySeq   ,
                  @UserSeq      ,
                  'DTI_TSLInterTransferService', -- 원테이블명
                  '#DTI_TSLInterTransferService', -- 템프테이블명
                  'TransSeq      ' , -- 키가 여러개일 경우는 , 로 연결한다. 
                  'CompanySeq, TransYM     ,ItemSeq     ,Remark      ,TransSeq    ,SndDeptSeq  ,RcvDeptSeq  ,TransAmt  ,
                  LastUserSeq,LastDateTime',
                  '',
                  @PgmSeq

    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TSLInterTransferService WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE DTI_TSLInterTransferService
          FROM #DTI_TSLInterTransferService A 
          JOIN DTI_TSLInterTransferService B ON ( A.TransSeq = B.TransSeq ) 

         WHERE B.CompanySeq  = @CompanySeq
           AND A.WorkingTag = 'D' 
           AND A.Status = 0    
        IF @@ERROR <> 0  RETURN
    END  
    
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TSLInterTransferService WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE DTI_TSLInterTransferService
           SET TransYM     = A.TransYM     ,
               ItemSeq     = A.ItemSeq     ,
               Remark      = A.Remark      ,
               SndDeptSeq  = A.SndDeptSeq  ,
               RcvDeptSeq  = A.RcvDeptSeq  ,
               TransAmt    = A.TransAmt    ,
               LastUserSeq = @UserSeq      ,
               LastDateTime = GetDate()
          FROM #DTI_TSLInterTransferService AS A 
          JOIN DTI_TSLInterTransferService AS B ON ( A.TransSeq = B.TransSeq ) 
        
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    

        IF @@ERROR <> 0  RETURN
    END  
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TSLInterTransferService WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO DTI_TSLInterTransferService (CompanySeq, TransYM     ,ItemSeq     ,Remark      ,TransSeq    ,SndDeptSeq  ,
                                                 RcvDeptSeq  ,TransAmt   ,LastUserSeq, LastDateTime ) 
             SELECT @CompanySeq, TransYM     ,ItemSeq     ,Remark      ,TransSeq    ,SndDeptSeq  ,
                    RcvDeptSeq  ,TransAmt    ,@UserSeq , GetDate() 
               FROM #DTI_TSLInterTransferService AS A   
              WHERE A.WorkingTag = 'A' 
                AND A.Status = 0    
        IF @@ERROR <> 0 RETURN
    END   

    SELECT * FROM #DTI_TSLInterTransferService 
    
    RETURN    
Go
exec DTI_SSLInterTransferServiceSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <TransSeq>4</TransSeq>
    <TransYM>2     </TransYM>
    <SndDeptSeq>42</SndDeptSeq>
    <ItemSeq>23</ItemSeq>
    <RcvDeptSeq>222</RcvDeptSeq>
    <TransAmt>24.00000</TransAmt>
    <Remark>24</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016156,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013904