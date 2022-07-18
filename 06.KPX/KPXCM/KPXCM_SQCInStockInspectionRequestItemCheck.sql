IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestItemCheck
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 재고검사의뢰-Item체크
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestItemCheck
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
	DECLARE @MessageType	INT,
			@Status			INT,
			@Results		NVARCHAR(250),
			@Seq            INT,
			@Count          INT,
			@MaxNo          NVARCHAR(20),
			@BaseDate       NCHAR(8),
			@MaxSerl        INT,
			@ReqSeq         INT
  					
    CREATE TABLE #QCInStockItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#QCInStockItem'
    
    SELECT @ReqSeq = ReqSeq FROM #QCInStockItem

	-------------------------------------------      
	-- 수량 0 체크
	-------------------------------------------      
	EXEC dbo._SCOMMessage @MessageType OUTPUT,      
						  @Status      OUTPUT,      
						  @Results     OUTPUT,      
						  1001                  , -- @1이(가) 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1001)      
						  @LanguageSeq       ,       
						  0,'검사의뢰수량'     -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'              
	UPDATE A
	   SET Result        = REPLACE(@Results,'이(가)', '이'),
		   MessageType   = @MessageType,
		   Status        = @Status 
	  FROM #QCInStockItem AS A
	 WHERE ISNULL(ReqQty ,0) = 0
    
    ------------------------------------------------------------------------
    -- 체크1, LotNo와 LotNo2는 동시에 입력 할 수 없습니다. 
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo와 LotNo2는 동시에 입력 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem AS A 
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND LotNo <> '' 
       AND Memo1 <> '' 
    ------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------
    
    ------------------------------------------------------------------------
    -- 체크2, LotNo관리 대상품목이 아니면 LotNo2는 필수입니다.
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo관리 대상품목이 아니면 LotNo2는 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem   AS A 
      JOIN _TDAItemStock    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )     
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND ISNULL(B.IsLotMng,'0') = '0' 
       AND Memo1 = '' 
    ------------------------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------------------------
    
    ------------------------------------------------------------------------
    -- 체크3, LotNo관리 대상품목은 LotNo는 필수입니다.
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo관리 대상품목은 LotNo는 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem   AS A 
      JOIN _TDAItemStock    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )     
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND ISNULL(B.IsLotMng,'0') = '1' 
       AND LotNo = '' 
    ------------------------------------------------------------------------
    -- 체크3, END 
    ------------------------------------------------------------------------
    
    

    -- 순번update---------------------------------------------------------------------------------------------------------------    
    SELECT @MaxSerl = ISNULL(MAX(ReqSerl), 0)    
      FROM KPX_TQCTestRequestItem     
     WHERE CompanySeq = @CompanySeq  
       AND ReqSeq = @ReqSeq    

    UPDATE A    
       SET ReqSerl = @MaxSerl + IDX_NO    
      FROM #QCInStockItem AS A    
     WHERE WorkingTag = 'A'     
       AND Status = 0    

    SELECT * FROM #QCInStockItem

RETURN
GO

begin tran 
exec KPXCM_SQCInStockInspectionRequestItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <QCTypeName />
    <ItemName>Lot_다시한번테스트_이재천</ItemName>
    <ItemNo>Lot_다시한번테스트No_이재천</ItemNo>
    <Spec />
    <LotNo />
    <Memo1>333</Memo1>
    <WHName>T일반창고1_이재천</WHName>
    <BizUnitName>아산공장</BizUnitName>
    <ReqQty>1</ReqQty>
    <UnitName>EA</UnitName>
    <RegDate />
    <CreateDate />
    <SupplyName />
    <Remark />
    <ReqSeq>84</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <QCType>5</QCType>
    <ItemSeq>1052403</ItemSeq>
    <WHSeq>7534</WHSeq>
    <UnitSeq>4</UnitSeq>
    <SupplyCustSeq>0</SupplyCustSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037318,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030558
rollback 