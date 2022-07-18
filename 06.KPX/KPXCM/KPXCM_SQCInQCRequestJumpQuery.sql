IF OBJECT_ID('KPXCM_SQCInQCRequestJumpQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCRequestJumpQuery
GO 

-- v2016.06.14 

-- 체크로직 추가 by이재천 
/************************************************************
 설  명 - 데이터-수입품검사의뢰_KPX : 점프조회
 작성일 - 20150203
 작성자 - 박상준
 수정자 - 
************************************************************/

CREATE PROC KPXCM_SQCInQCRequestJumpQuery
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    CREATE TABLE #KPX_TQCTestRequest (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestRequest'     
    IF @@ERROR <> 0 RETURN  
    
    
    -- 체크1, 수입검사대상품목등록 화면에 수입검사품목으로 등록 되지 않은 품목입니다.
    UPDATE A 
       SET Result = '수입검사대상품목등록 화면에 수입검사품목으로 등록 되지 않은 품목입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TQCTestRequest  AS A 
      LEFT OUTER JOIN KPX_TQcInReceiptItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE ISNULL(B.IsInQC,'0') = '0'
       AND A.Status = 0 
    -- 체크1, END 
    
    
    -- 체크2, 품목검사규격등록 화면에 검사규격이 등록 되지 않은 품목입니다.'
    UPDATE A 
       SET Result = '품목검사규격등록 화면에 검사규격이 등록 되지 않은 품목입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TQCTestRequest  AS A 
     WHERE A.Status = 0 
       AND NOT EXISTS (
                        SELECT 1 
                          FROM KPX_TQCQASpec AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.QCType IN ( SELECT QCType FROM KPX_TQCQAProcessQCType WHERE CompanySeq = @CompanySeq AND InQC = 1000498001 ) 
                           AND Z.ItemSeq = A.ItemSeq 
                      ) 
                      
    -- 체크2, END 
    
    
    SELECT A.*,
           C.UnitName 
      FROM #KPX_TQCTestRequest AS A 
      LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )
      LEFT OUTER JOIN _TDAUnit AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = B.UnitSeq ) 
    
    RETURN
GO


begin tran 
exec KPXCM_SQCInQCRequestJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnitName>우레탄부문</BizUnitName>
    <CustName>KPX CHEMICAL (NANJING) CO.,LTD</CustName>
    <ItemName>KE-810P(KE-810 WITH PC-15)</ItemName>
    <ItemNo>41290055</ItemNo>
    <UnitName>KG</UnitName>
    <Qty>16800</Qty>
    <LotNo>6030001</LotNo>
    <SourceSeq>2621</SourceSeq>
    <SourceSerl>1</SourceSerl>
    <CustSeq>3684</CustSeq>
    <ItemSeq>83289</ItemSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027781,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=5564
rollback 