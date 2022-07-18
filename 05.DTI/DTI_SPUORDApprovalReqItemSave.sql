    
IF OBJECT_ID('DTI_SPUORDApprovalReqItemSave') IS NOT NULL
    DROP PROC DTI_SPUORDApprovalReqItemSave
    
GO
-- v2013.06.12

-- 구매품의입력세부저장_DTI by이재천
CREATE PROC DTI_SPUORDApprovalReqItemSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10) = '',    
    @CompanySeq     INT = 0,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    

    DECLARE @docHandle  INT  
    
    -- 서비스 마스타 등록 생성  
    IF @WorkingTag <> 'AUTO'  
    BEGIN  
        CREATE TABLE #TPUORDApprovalReqItem (WorkingTag NCHAR(1) NULL)  
        EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDApprovalReqItem'  
    END    
   
    IF @@ERROR <> 0 RETURN      
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog @CompanySeq,  
                  @UserSeq,  
                  '_TPUORDApprovalReqItem',   
                  '#TPUORDApprovalReqItem',  
                  'ApproReqSeq, ApproReqSerl',  
                  'CompanySeq,ApproReqSeq,ApproReqSerl,ItemSeq,MakerSeq,UnitSeq,Qty,Price,CurAmt,CustSeq,Remark,ExRate,CurrSeq,DomAmt,StdUnitSeq,StdUnitQty,DelvDate,SMImpType,DCRate,OriginPrice,SMPayType,ElectronicSeq,PJTSeq,WBSSeq,CurVAT,DomPrice,DomVAT,IsVAT,LastUserSeq,LastDateTime, BOMSerl, IsStop, StopDate, StopEmpSeq, StopRemark, WHSeq, SourceType, SourceSeq, SourceSerl'  
    
    -- DELETE                                                                                                    
    IF EXISTS (SELECT 1 FROM #TPUORDApprovalReqItem WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN      
        DELETE _TPUORDApprovalReqItem      
          FROM _TPUORDApprovalReqItem AS A   
          JOIN #TPUORDApprovalReqItem AS B ON ( A.CompanySeq = @CompanySeq AND A.ApproReqSeq = B.ApproReqSeq AND A.ApproReqSerl = B.ApproReqSerl ) 
         WHERE B.WorkingTag = 'D' AND B.Status = 0    
           AND A.CompanySeq = @CompanySeq  
               
        IF @@ERROR <> 0 RETURN     
    END           
    -- Update                                                                                                     
    IF EXISTS (SELECT 1 FROM #TPUORDApprovalReqItem WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN       
        -- 데이터 업데이트  
        UPDATE _TPUORDApprovalReqItem      
           SET ItemSeq      = B.ItemSeq,  
               MakerSeq     = B.MakerSeq,  
               UnitSeq      = B.UnitSeq,  
               Qty          = B.Qty,  
               Price        = B.Price,  
               DomAmt       = B.DomAmt,  
               CurAmt       = B.CurAmt,  
               CustSeq      = B.CustSeq,  
               Remark       = B.Remark,  
               ExRate       = B.ExRate,  
               CurrSeq      = B.CurrSeq,  
               DelvDate     = B.DelvDate,  
               SMImpType    = B.SMImpType,  
               DCRate       = B.DCRate,  
               OriginPrice  = B.OriginPrice,  
               SMPayType    = B.SMPayType,    
               PJTSeq       = B.PJTSeq,  
               WBSSeq       = B.WBSSeq,      
               CurVAT       = B.CurVAT,  
               DomPrice     = B.DomPrice,    
               DomVAT       = B.DomVAT,  
               IsVAT        = B.IsVAT,      
               WHSeq        = B.WHSeq,  
               SourceType   = B.SourceType,  
               SourceSeq    = B.SourceSeq,  
               SourceSerl   = B.SourceSerl,  
               Memo1        = B.BKCustSeq,
               Memo2        = B.EndUserSeq, 
               Memo3        = B.Memo3,  
               Memo4        = B.Memo4,  
               Memo5        = B.Memo5,  
               Memo6        = B.Memo6,  
               LastUserSeq  = @UserSeq,   
               LastDateTime = GETDATE()  
          FROM _TPUORDApprovalReqItem AS A   
          JOIN #TPUORDApprovalReqItem AS B ON ( A.ApproReqSeq = B.ApproReqSeq AND A.ApproReqSerl = B.ApproReqSerl )      
         WHERE B.WorkingTag = 'U' AND B.Status = 0    
           AND A.CompanySeq = @CompanySeq  
             
        IF @@ERROR <> 0 RETURN      
    END    
    -- INSERT                                                                                                     
    IF EXISTS (SELECT 1 FROM #TPUORDApprovalReqItem WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN  
        -- 서비스 INSERT     
    INSERT INTO _TPUORDApprovalReqItem (CompanySeq, ApproReqSeq  , ApproReqSerl, ItemSeq     , MakerSeq   ,    
                                        UnitSeq   , Qty          , Price       , CurAmt      , CustSeq    ,    
                                        Remark    , ExRate       , CurrSeq     , DomAmt      , StdUnitSeq ,    
                                        StdUnitQty, DelvDate     , SMImpType   , DCRate      , OriginPrice,    
                                        SMPayType , ElectronicSeq, PJTSeq      , WBSSeq      , CurVAT     ,    
                                        DomPrice  , DomVAT       , IsVAT       , LastUserSeq , LastDateTime,    
                                        BOMSerl   , IsStop       , StopDate    , StopEmpSeq  , StopRemark  ,    
                                        WHSeq     , SourceType   , SourceSeq   , SourceSerl  , Memo1       ,  
                                        Memo2     , Memo3        , Memo4       , Memo5       , Memo6       )    
         SELECT @CompanySeq , ApproReqSeq  , ApproReqSerl, ItemSeq , MakerSeq   ,    
                UnitSeq     , Qty          , Price       , CurAmt  , CustSeq    ,    
                Remark      , ExRate       , CurrSeq     , DomAmt  , StdUnitSeq ,     
                StdUnitQty  , DelvDate     , SMImpType   , DCRate  , OriginPrice,    
                SMPayType   , 0            , PJTSeq      , WBSSeq  , CurVAT     ,     
                DomPrice    , DomVAT       , IsVAT       , @UserSeq, GETDATE()  ,    
                0           , '0'          , ''          , 0       , ''         ,     
                WHSeq       , SourceType   , SourceSeq   , SourceSerl, BKCustSeq,  
                EndUserSeq  , Memo3        , Memo4       , Memo5     , Memo6    
           FROM #TPUORDApprovalReqItem        
          WHERE WorkingTag = 'A' AND Status = 0      
             
        IF @@ERROR <> 0 RETURN    
    END    
    
    IF @WorkingTag <> 'AUTO'  
    BEGIN  
        SELECT * FROM #TPUORDApprovalReqItem    
    END       
    
    RETURN    
GO
exec DTI_SPUORDApprovalReqItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <VATRate>10</VATRate>
    <TotCurAmt>1062</TotCurAmt>
    <TotDomAmt>1062</TotDomAmt>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ApproReqSeq>16563</ApproReqSeq>
    <ApproReqSerl>1</ApproReqSerl>
    <ItemName>@공장건축공사</ItemName>
    <ItemNo>200901010001</ItemNo>
    <Spec />
    <ItemSeq>14033</ItemSeq>
    <MakerName />
    <MakerSeq>0</MakerSeq>
    <UnitName>EA</UnitName>
    <UnitSeq>2</UnitSeq>
    <Qty>23.00000</Qty>
    <Price>42.00000</Price>
    <CurAmt>966.00000</CurAmt>
    <CurVAT>96.00000</CurVAT>
    <CustName>(삭제된 코드)(삭제된 코드)우신컴정보</CustName>
    <CustSeq>863</CustSeq>
    <Remark />
    <ExRate>1.00000</ExRate>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <DomAmt>966.00000</DomAmt>
    <DomPrice>42.00000</DomPrice>
    <DomVAT>96.00000</DomVAT>
    <IsVAT>0</IsVAT>
    <STDUnitName>EA</STDUnitName>
    <STDUnitSeq>2.00000</STDUnitSeq>
    <STDUnitQty>23.00000</STDUnitQty>
    <DelvDate>20130613</DelvDate>
    <SMImpType>8008001</SMImpType>
    <DCRate>0.00000</DCRate>
    <OriginPrice>0.00000</OriginPrice>
    <SMPayType>0</SMPayType>
    <WHName>성신가공(위탁창고)</WHName>
    <WHSeq>1169</WHSeq>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <SourceType xml:space="preserve"> </SourceType>
    <SourceSeq>0</SourceSeq>
    <SourceSerl>0</SourceSerl>
    <BKCustName>(사)경기경영자총협회</BKCustName>
    <EndUserName>(사)국제조명위원회 한국위원회</EndUserName>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015926,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013785