IF OBJECT_ID('KPXCM_SPUORDPOItemSave') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOItemSave
GO 

-- v2015.09.23 

-- MES연동 실시간하기 위한 사이트용 by이재천 
/*************************************************************************************************      
  FORM NAME           -       FrmPPUORDPO     
  DESCRIPTION         -     구매발주 디테일 저장    
  CREAE DATE          -       2008.10.09     CREATE BY: 김현    
  LAST UPDATE  DATE   -       2008.10.09     UPDATE BY: 김현    
                              2010.11.18     UPDATE BY: 이정숙  - 2차납품기일(DelvDate2) 추가  
                              2013.07.10     UPDATE BY: 천경민  - Memo1~8 컬럼 추가
 *************************************************************************************************/      
 CREATE PROCEDURE KPXCM_SPUORDPOItemSave    
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
     
 AS         
     DECLARE @docHandle          INT,    
             @Serl               INT,    
             @CustSeq            INT    
    
 IF @WorkingTag <> 'DelBatch'
  BEGIN 
   
     -- 서비스 마스타 등록 생성    
     CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)    
     ExEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOItem'    
    
     IF @@ERROR <> 0 RETURN      
  END
          
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
     EXEC _SCOMLog  @CompanySeq,    
                    @UserSeq,    
                    '_TPUORDPOItem',     
                    '#TPUORDPOItem',    
                    'POSeq, POSerl',    
                    'CompanySeq,POSeq,POSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,MakerSeq,DelvDate,DomAmt,Remark1,Remark2,SMPriceType,SMPayType,POAmd,WhSeq,DelvTime,POReqSeq,POReqSerl,StdUnitSeq,StdUnitQty,SourceType,SourceSeq,SourceSerl,UnitAssySeq,IsConfirm,
                     ConfirmDate,ConfirmEmpSeq,ChgDelvDate,PJTSeq,WBSSeq,CurVAT,DomPrice,DomVAT,IsVAT,IsStop,Lastuserseq,Lastdatetime,Memo1,Memo2,Memo3,Memo4,Memo5,Memo6,Memo7,Memo8'
     
     -- 납품창고 입력 안했을 경우 기본으로 품목별 구매정보의 창고를 넣어줌    
 --     SELECT @CustSeq = B.CustSeq     
 --       FROM #TPUORDPOItem  AS A    
 --            JOIN _TPUORDPO AS B ON A.POSeq = B.POSeq    
 --      WHERE B.CompanySeq = @CompanySeq    
             
     -- DELETE      
     IF EXISTS (SELECT TOP 1 1 FROM #TPUORDPOItem WHERE WorkingTag = 'D' AND Status = 0  )    
     BEGIN    
         DELETE _TPUORDPOItem    
           FROM _TPUORDPOItem      AS A     
                JOIN #TPUORDPOItem AS B ON A.POSeq  = B.POSeq     
                                       AND A.POSerl = B.POSerl    
          WHERE B.WorkingTag = 'D' AND B.Status = 0      
            AND A.CompanySeq = @CompanySeq    
     
         IF @@ERROR <> 0 RETURN      
     END        
     -- Update      
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag = 'U' AND Status = 0  )    
     BEGIN     
         UPDATE _TPUORDPOItem SET    
                 ItemSeq  = B.ItemSeq        ,     
                 UnitSeq     = B.UnitSeq        ,          
                 Qty         = B.Qty            ,    
                 Price       = B.Price          ,    
                 CurAmt      = B.CurAmt         ,    
                 MakerSeq    = B.MakerSeq       ,    
                 DelvDate    = B.DelvDate       ,   
                 DelvDate2   = B.DelvDate2      ,    
                 DomAmt      = B.DomAmt         ,          
                 Remark1     = B.Remark1        ,    
                 Remark2     = B.Remark2        ,    
                 SMPriceType = B.SMPriceType    ,    
                 SMPayType   = B.SMPayType      ,    
                 POAmd      = B.POAmd          ,          
                 DelvTime    = B.DelvTime       ,    
                 WHSeq       = B.WHSeq          ,    
                 PJTSeq      = B.PJTSeq         ,    
                 WBSSeq      = B.WBSSeq         ,    
                 CurVAT      = B.CurVAT         ,    
                 DomPrice    = B.DomPrice       ,    
               DomVAT      = B.DomVAT         ,    
                 IsVAT       = B.IsVAT          ,    
                 --IsStop      = B.IsStop         ,    -- 2011. 10. 11 hkim 
                 STDUnitSeq  = B.STDUnitSeq     ,    
                 STDUnitQty  = B.STDUnitQty     ,    
                 Memo1       = B.Memo1,
                 Memo2       = B.Memo2,
                 Memo3       = B.Memo3,
                 Memo4       = B.Memo4,
                 Memo5       = B.Memo5,
                 Memo6       = B.Memo6,
                 Memo7       = B.Memo7,
                 Memo8       = B.Memo8,
                 LastUserSeq = @UserSeq         ,     
                 LastDateTime= GETDATE()  
           FROM _TPUORDPOItem      AS A     
                JOIN #TPUORDPOItem AS B ON A.POSeq  = B.POSeq     
                                       AND A.POSerl = B.POSerl    
          WHERE B.WorkingTag = 'U' AND B.Status = 0      
            AND A.CompanySeq  = @CompanySeq    
     
         IF @@ERROR <> 0 RETURN      
    END     
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
        -- 서비스 INSERT    
        INSERT INTO _TPUORDPOItem(CompanySeq    , POSeq      , POSerl      , ItemSeq       , UnitSeq     ,    
                                   Qty           , Price      , CurAmt      , MakerSeq      , DelvDate    , DelvDate2    ,   
                                   DelvTime      , DomAmt     , Remark1     , Remark2       , SMPriceType ,     
                                   SMPaytype     , POAmd      , WHSeq       , POReqSeq      , POReqSerl   ,    
                                   StdUnitSeq    , StdUnitQty , SourceType  , SourceSeq     , SourceSerl  ,     
                                   UnitAssySeq   , IsConfirm  , ConfirmDate , ConfirmEmpSeq , ChgDelvDate ,     
                                   PJTSeq        , WBSSeq     , CurVAT      , DomPrice      , DomVAT      ,     
                                   IsVAT         , IsStop     , LastUserSeq , LastDateTime  , Memo1       ,
                                   Memo2         , Memo3      , Memo4       , Memo5         , Memo6       ,
                                   Memo7         , Memo8)    
          SELECT @CompanySeq   , B.POSeq     , B.POSerl  , B.ItemSeq  , B.UnitSeq     ,    
                    B.Qty         , B.Price     , B.CurAmt  , B.MakerSeq , B.DelvDate    , B.DelvDate2    ,   
                    B.DelvTime    , B.DomAmt    , B.Remark1 , B.Remark2  , B.SMPriceType ,    
                    B.SMPaytype   , B.POAmd     , B.WHSeq   , 0          , 0             ,    
                    B.StdUnitSeq  , B.StdUnitQty, 0         , 0          , 0             ,    
                    0             , 0           , 0         , 0          , 0             ,    
                    B.PJTSeq      , B.WBSSeq    , B.CurVAT  , B.DomPrice , B.DomVAT      ,     
                    B.IsVAT       , '0'         , @UserSeq  , GETDATE()  , B.Memo1       ,
                    B.Memo2       , B.Memo3     , B.Memo4   , B.Memo5    , B.Memo6       ,
                    B.Memo7       , B.Memo8
            FROM #TPUORDPOItem AS B     
           WHERE B.WorkingTag = 'A' AND B.Status = 0     
              
        IF @@ERROR <> 0 RETURN      
    END     

    
    
    
    -- I/F Table 반영 
    DECLARE @POSeq      INT, 
            @BizUnit    INT, 
            @Exists     INT -- 상품,원자재,부자재 존재여부  1 : 존재  0 : 존재하지않음
    
    SELECT @POSeq = (SELECT MAX(POSeq) FROM #TPUORDPOItem) 
    
    
    SELECT @BizUnit = (SELECT TOP 1 BizUnit
                         FROM (SELECT BizUnit
                                 FROM KPX_TPUORDPOAdd 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq
                               
                               UNION 
                               
                               SELECT BizUnit 
                                 FROM KPX_TPUORDPOAddLog 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq 
                              ) AS A
                      ) 
    
    IF @BizUnit = 26 AND EXISTS (SELECT 1 
                                   FROM #TPUORDPOItem            AS A 
                                   LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
                                   LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
                                  WHERE C.SMAssetGrp IN ( 6008001, 6008006, 6008007 ) 
                                )
                                
    BEGIN 
        
        CREATE TABLE #TPUORDPO 
        (
            POSeq       INT, 
            PONo        NVARCHAR(100), 
            PODate      NCHAR(8), 
            CustSeq     INT, 
            SMImpType   INT 
        )
        
        
        INSERT INTO #TPUORDPO ( POSeq, PONo, PODate, CustSeq, SMImpType ) 
        SELECT TOP 1 A.POSeq, A.PONo, A.PODate, A.CustSeq, A.SMImpType
          FROM (
                SELECT Z.POSeq, Z.PONo, 99999999 AS LogSeq, Z.PODate, Z.CustSeq, Z.SMImpType
                  FROM _TPUORDPO AS Z 
                 WHERE Z.POSeq = @POSeq 
                   AND Z.CompanySeq = @CompanySeq 
                        
                UNION ALL 
                        
                SELECT Z.POSeq, Z.PONo, Z.LogSeq, Z.PODate, Z.CustSeq, Z.SMImpType
                  FROM _TPUORDPOLog AS Z 
                 WHERE Z.POSeq = @POSeq 
                   AND Z.CompanySeq = @CompanySeq 
               ) AS A 
         ORDER BY A.LogSeq DESC 
        
        
        
        SELECT @CompanySeq AS CompanySeq, 
               @BizUnit AS BizUnit, 
               A.POSeq, 
               A.POSerl, 
               B.PONo,
               B.PODate, 
               C.CustName, 
               D.ItemNo, 
               D.Spec, 
               E.UnitName, 
               ISNULL(CONVERT(FLOAT,G.MngValText ),0) AS LotUnitQty, 
               CONVERT(INT,A.StdUnitQty) AS LotQty, 
               A.WorkingTag, 
               '0'               AS ProcYn,
               'N'               AS ConfirmFlag,   
               GetDate()         AS CreateTime,  
               ''                AS UpdateTime, 
               ''                AS ConfirmTime,
               ''                AS ErrorMessage,
               CASE WHEN B.SmImpType = 8008001   THEN '0' ELSE '1' END AS ImpType 
          INTO #IF_PUDelv_MES     
          FROM #TPUORDPOItem                AS A 
          LEFT OUTER JOIN #TPUORDPO         AS B WITH(NOLOCK) ON ( B.POSeq = A.POSeq ) 
          LEFT OUTER JOIN _TDACust          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq ) 
          LEFT OUTER JOIN _TDAItem          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = D.UnitSeq ) 
          LEFT OUTER JOIN _TDAItemUserDefine AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq And G.ItemSeq = D.ItemSeq And G.MngSerl = '1000012' ) 
          OUTER APPLY (SELECT Z.BizUnit
                         FROM KPX_TPUORDPOAdd AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      
                       UNION 
                       
                       SELECT Z.BizUnit
                         FROM KPX_TPUORDPOAddLog AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      ) AS H 
         WHERE H.BizUnit = 26 
    
        
        INSERT INTO IF_PUDelv_MES
        (
            CompanySeq,BizUnit,POSeq,PONo,POSerl,PODate,CustName, 
            ItemNo,Spec,UnitName,LotUnitQty,LotQty,WorkingTag,ProcYn, 
            ConfirmFlag,CreateTime,UpdateTime,ConfirmTime,ErrorMessage,ImpType
        )  
        SELECT CompanySeq, BizUnit, POSeq, PONo, POSerl, PODate, CustName, 
               ItemNo, Spec, UnitName, LotUnitQty, LotQty, WorkingTag, ProcYn, 
               ConfirmFlag, CreateTime, UpdateTime, ConfirmTime, ErrorMessage, ImpType 
          FROM #IF_PUDelv_MES  
    END -- MES 반영 end 
    
    
    SELECT * FROM #TPUORDPOItem
      
     
 RETURN    
 go
 begin tran 
exec KPXCM_SPUORDPOItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <POSeq>38519244</POSeq>
    <POSerl>1</POSerl>
    <ItemSeq>14527</ItemSeq>
    <ItemName>@asdfasdfasdf</ItemName>
    <SMPriceTypeName />
    <ItemNo>@asdfasdfasdf</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <Qty>1.00000</Qty>
    <Price>2.00000</Price>
    <CurVAT>0.00000</CurVAT>
    <CurAmt>2.00000</CurAmt>
    <MakerSeq>0</MakerSeq>
    <MakerName />
    <DomPrice>2.00000</DomPrice>
    <DomVAT>0.00000</DomVAT>
    <DomAmt>2.00000</DomAmt>
    <IsVAT>0</IsVAT>
    <STDUnitSeq>2</STDUnitSeq>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>1.00000</STDUnitQty>
    <Remark1 />
    <Remark2 />
    <SMPriceType>0</SMPriceType>
    <SMPayType>0</SMPayType>
    <POAmd>0</POAmd>
    <WHSeq>1</WHSeq>
    <WHName>케이비엠d</WHName>
    <DelvTime xml:space="preserve">    </DelvTime>
    <DelvDate>20150926</DelvDate>
    <DelvDate2 xml:space="preserve">        </DelvDate2>
    <TotCurAmt>2.00000</TotCurAmt>
    <TotDomAmt>2.00000</TotDomAmt>
    <VATRate>0.00000</VATRate>
    <Memo1 />
    <Memo2 />
    <Memo3 />
    <Memo4 />
    <Memo5>1011254001</Memo5>
    <Memo6>1011255001</Memo6>
    <Memo7>0.00000</Memo7>
    <Memo8>0.00000</Memo8>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031398,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025115
rollback 