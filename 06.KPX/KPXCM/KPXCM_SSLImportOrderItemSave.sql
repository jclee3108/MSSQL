IF OBJECT_ID('KPXCM_SSLImportOrderItemSave') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderItemSave
GO 

-- v2015.09.24 

-- MES연동 실시간하기 위한 사이트용 by이재천 
/*************************************************************************************************    
     화면명 : 수입Order품목저장   
     SP Name: _SSLImportOrderItemSave    
     작성일 : 2009.01.05 : CREATEd by 천혜연        
     수정일 : 2009.08.24 BY 송경애 - 프로젝트 코드 추가
              2013.11.29 BY 서보영 - Memo컬럼추가
 *************************************************************************************************/   
 CREATE PROCEDURE KPXCM_SSLImportOrderItemSave  
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
             @Serl               INT  
   
     -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)  
     ExEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOItem'  
   
     IF @@ERROR <> 0 RETURN    
        
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq,    
                    @UserSeq,    
                    '_TPUORDPOItem',     
                    '#TPUORDPOItem',    
                    'POSeq, POSerl',    
                    'CompanySeq, POSeq, POSerl, ItemSeq, UnitSeq, Qty, Price, CurAmt, MakerSeq, DelvDate, DomAmt, Remark1, Remark2, SMPriceType, SMPayType, 
                     POAmd, WhSeq, DelvTime, POReqSeq, POReqSerl, StdUnitSeq, StdUnitQty, SourceType, SourceSeq, SourceSerl, UnitAssySeq, IsConfirm, 
                     ConfirmDate, ConfirmEmpSeq, ChgDelvDate, PJTSeq, WBSSeq, CurVAT, DomPrice, DomVAT, IsVAT, IsStop, LastUserSeq, LastDateTime,
                     Memo1, Memo2, Memo3, Memo4, Memo5, Memo6, Memo7, Memo8'    -- 20131129 BY 서보영 Memo컬럼추가
      -- DELETE    
     IF EXISTS (SELECT TOP 1 1 FROM #TPUORDPOItem WHERE WorkingTag = 'D' AND Status = 0  )  
     BEGIN  
         DELETE _TPUORDPOItem  
           FROM _TPUORDPOItem AS A JOIN #TPUORDPOItem AS B ON (A.POSeq = B.POSeq AND A.POSerl = B.POSerl)  
          WHERE B.WorkingTag = 'D' AND B.Status = 0    
            AND A.CompanySeq = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN    
     END      
     -- Update    
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag = 'U' AND Status = 0  )  
     BEGIN   
         UPDATE _TPUORDPOItem SET 
     ItemSeq  = ISNULL(B.ItemSeq, 0),  
     UnitSeq  = ISNULL(B.UnitSeq, 0), 
     Qty   = B.Qty, 
     Price  = B.Price, 
     CurAmt  = B.CurAmt, 
     MakerSeq = ISNULL(B.MakerSeq, 0), 
     DelvDate = ISNULL(B.DelvDate, ''),
     DomAmt  = B.DomAmt,
     Remark1  = ISNULL(B.Remark1,''),
     Remark2  = ISNULL(B.Remark2,''),
     SMPriceType = ISNULL(B.SMPriceType, 0),
     SMPayType = ISNULL(B.SMPayType, 0), 
     POAmd  = ISNULL(B.POAmd, 0), 
     WhSeq  = ISNULL(B.WhSeq, 0), 
     DelvTime = ISNULL(B.DelvTime, ''), 
     StdUnitSeq = ISNULL(B.StdUnitSeq, 0), 
     StdUnitQty = ISNULL(B.StdUnitQty, 0), 
     UnitAssySeq = ISNULL(B.UnitAssySeq, 0), 
     ChgDelvDate = ISNULL(B.ChgDelvDate, ''), 
     PJTSeq  = ISNULL(B.PJTSeq, 0), 
     WBSSeq  = ISNULL(B.WBSSeq, 0), 
     CurVAT  = B.CurVAT, 
     DomPrice = B.DomPrice, 
     DomVAT  = B.DomVAT, 
     IsVAT  = ISNULL(B.IsVAT, ''), 
     IsStop  = ISNULL(B.IsStop, ''),
                 DelvDate2 = ISNULL(B.DelvDate2, ''),
                 LastUserSeq = @UserSeq,   
                 LastDateTime= GETDATE(),
                 Memo1       = ISNULL(B.Memo1,''), -- 20131129 BY 서보영 Memo컬럼추가
                 Memo2       = ISNULL(B.Memo2,''),
                 Memo3       = ISNULL(B.Memo3,''),
                 Memo4       = ISNULL(B.Memo4,''),
                 Memo5       = ISNULL(B.Memo5,''),
                 Memo6       = ISNULL(B.Memo6,''),
                 Memo7       = ISNULL(B.Memo7, 0),
                 Memo8       = ISNULL(B.Memo8, 0)
            FROM _TPUORDPOItem AS A JOIN #TPUORDPOItem AS B ON (A.POSeq = B.POSeq AND A.POSerl = B.POSerl)  
          WHERE B.WorkingTag = 'U' AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq  
   
         IF @@ERROR <> 0 RETURN    
     END   
     -- INSERT    
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag = 'A' AND Status = 0  )  
     BEGIN  
         -- 서비스 INSERT  
         INSERT INTO _TPUORDPOItem(CompanySeq, POSeq,  POSerl,   ItemSeq,  UnitSeq, 
           Qty,   Price,  CurAmt,   MakerSeq,  DelvDate, 
           DomAmt,  Remark1, Remark2,  SMPriceType, SMPayType, 
           POAmd,  WhSeq,  DelvTime,  POReqSeq,  POReqSerl, 
           StdUnitSeq, StdUnitQty, SourceType,  SourceSeq,  SourceSerl, 
           UnitAssySeq, IsConfirm, ConfirmDate, ConfirmEmpSeq, ChgDelvDate, 
           PJTSeq,  WBSSeq,  CurVAT,   DomPrice,  DomVAT, 
           IsVAT,  IsStop,  DelvDate2,      LastUserSeq, LastDateTime,
                                   Memo1, Memo2, Memo3, Memo4, Memo5, Memo6, Memo7, Memo8)  -- 20131129 BY 서보영 Memo컬럼추가
          SELECT @CompanySeq,     B.POSeq,    B.POSerl,    B.ItemSeq,     ISNULL(B.UnitSeq, 0), 
     B.Qty,      B.Price,    B.CurAmt,    ISNULL(B.MakerSeq, 0),  B.DelvDate, 
        B.DomAmt,     ISNULL(B.Remark1, ''), ISNULL(B.Remark2, ''), ISNULL(B.SMPriceType, 0), ISNULL(B.SMPayType, 0), 
        ISNULL(B.POAmd, 0),   ISNULL(B.WhSeq, 0),  B.DelvTime,    0,       0, 
        ISNULL(B.StdUnitSeq, 0), B.StdUnitQty,   0,      0,       0, 
           ISNULL(B.UnitAssySeq, 0), '0',     '',      0,       ISNULL(B.ChgDelvDate, ''), 
        ISNULL(B.PJTSeq, 0),  ISNULL(B.WBSSeq, 0), B.CurVAT,    B.DomPrice,     B.DomVAT, 
        B.IsVAT,     '0',     ISNULL(B.DelvDate2,''),@UserSeq,        GETDATE(),
                 B.Memo1, B.Memo2, B.Memo3, B.Memo4, B.Memo5, B.Memo6, B.Memo7, B.Memo8  -- 20131129 BY 서보영 Memo컬럼추가
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
                                 FROM _TSLImpOrder 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq
                               
                               UNION 
                               
                               SELECT BizUnit 
                                 FROM _TSLImpOrderLog 
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
                         FROM _TSLImpOrder AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      
                       UNION 
                       
                       SELECT Z.BizUnit
                         FROM _TSLImpOrderLog AS Z 
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