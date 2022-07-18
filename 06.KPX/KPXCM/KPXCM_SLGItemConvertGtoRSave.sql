IF OBJECT_ID('KPXCM_SLGItemConvertGtoRSave') IS NOT NULL 
    DROP PROC KPXCM_SLGItemConvertGtoRSave
GO

-- v2016.05.25 

-- KPXCM용 개발 by이재천 
/************************************************************
 설  명 - 데이터-제품 원재료대체처리(사업부문간)_KPX : 저장
 작성일 - 20150817
 작성자 - 민형준
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SLGItemConvertGtoRSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #KPX_TLGItemConvertGtoR (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TLGItemConvertGtoR'     
    IF @@ERROR <> 0 RETURN  

    CREATE TABLE #KPX_TLGItemConvertGtoRItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TLGItemConvertGtoRItem'     
    IF @@ERROR <> 0 RETURN  
    
    --환경설정_kpx에 있는 출고구분값을 받아서 넣어줌
    DECLARE @InKindDetail INT,
            @OutKindDetail INT
            
    SELECT  @InKindDetail = 0,
            @OutKindDetail  = 0
            
    SELECT @InKindDetail = EnvValue 
      FROM KPX_TCOMEnvItem WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq
       AND EnvSeq = 46  --제품 원재료대체 입고유형

    SELECT @OutKindDetail = EnvValue 
      FROM KPX_TCOMEnvItem WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq
       AND EnvSeq = 47  --제품 원재료대체 출고유형
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   'KPX_TLGItemConvertGtoR', -- 원테이블명
                   '#KPX_TLGItemConvertGtoR', -- 템프테이블명
                   'ConvertSeq    ' , -- 키가 여러개일 경우는 , 로 연결한다. 
                   'CompanySeq,
                    ConvertSeq,
                    OutBizUnit,
                    InBizUnit,
                    OutWhSeq,
                    InWhSeq,
                    InOutDate,
                    InOutNo,
                    DeptSeq,
                    EmpSeq,
                    Remark,
                    Memo,
                    LastUserSeq,
                    LastDateTime',
                   '',
                   @PgmSeq

    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   'KPX_TLGItemConvertGtoRItem', -- 원테이블명
                   '#KPX_TLGItemConvertGtoRItem', -- 템프테이블명
                   'ConvertSeq,ConvertSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                   'CompanySeq,
                    ConvertSeq,
                    ConvertSerl,
                    ItemSeq,
                    Spec,
                    UnitSeq,
                    OutQty,
                    STDUnitSeq,
                    STDUnitQty,
                    LotNo,
                    Remark,
                    ConvertItemSeq,
                    ConvertItemSpec,
                    OutWHSeq,
                    ConvertUnitSeq,
                    ConvertQty,
                    ConvertSTDUnitSeq,
                    ConvertSTDUnitQty,
                    ConvertLotNo,
                    ConvertRemark,
                    InWHSeq,
                    InSeq,
                    InSerl,
                    InNo,
                    OutSeq,
                    OutSerl,
                    OutNo,                    
                    LastUserSeq,
                    LastDateTime',
                   '',
                   @PgmSeq

    IF @WorkingTag = 'D'
    BEGIN
        UPDATE #KPX_TLGItemConvertGtoRItem
           SET WorkingTag = 'D'
    END

    --DataBlock1
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT

    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPX_TLGItemConvertGtoR WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN    
    
            DELETE B
              FROM #KPX_TLGItemConvertGtoR      AS A 
                   JOIN KPX_TLGItemConvertGtoR AS B ON ( A.ConvertSeq    = B.ConvertSeq ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
               
               
            DELETE B
              FROM #KPX_TLGItemConvertGtoR          AS A 
                   JOIN KPX_TLGItemConvertGtoRItem  AS B ON ( A.ConvertSeq    = B.ConvertSeq ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
         
             IF @@ERROR <> 0  RETURN
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
            UPDATE KPX_TLGItemConvertGtoR
               SET Memo        = A.Memo        ,
                   InOutDate   = A.InOutDate   ,
                   Remark      = A.Remark      ,
                   InWHSeq     = A.InWHSeq     ,
                   InBizUnit   = A.InBizUnit   ,
                   OutBizUnit  = A.OutBizUnit  ,
                   DeptSeq     = A.DeptSeq     ,
                   EmpSeq      = A.EmpSeq      ,
                   InOutNo     = A.InOutNo     ,
                   OutWHSeq    = A.OutWHSeq   ,
                   LastUserSeq  = @UserSeq,
                   LastDateTime = GetDate()
              FROM #KPX_TLGItemConvertGtoR      AS A 
                   JOIN KPX_TLGItemConvertGtoR AS B ON ( A.ConvertSeq    = B.ConvertSeq ) 
                         
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'U' 
               AND A.Status     = 0    
   
            IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
            INSERT INTO KPX_TLGItemConvertGtoR 
                   (CompanySeq,
                    ConvertSeq,
                    OutBizUnit,
                    InBizUnit,
                    OutWhSeq,
                    InWhSeq,
                    InOutDate,
                    InOutNo,
                    DeptSeq,
                    EmpSeq,
                    Remark,
                    Memo,
                    LastUserSeq,
                    LastDateTime) 
            SELECT  @CompanySeq,
                    ConvertSeq,
                    OutBizUnit,
                    InBizUnit,
                    OutWhSeq,
                    InWhSeq,
                    InOutDate,
                    InOutNo,
                    DeptSeq,
                    EmpSeq,
                    Remark,
                    Memo,
                    @UserSeq,
                    GETDATE()
              FROM #KPX_TLGItemConvertGtoR AS A   
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0    

            IF @@ERROR <> 0 RETURN
    END   

    DECLARE @XmlData NVARCHAR(MAX)
    
    CREATE TABLE #Temp1 (WorkingTag NCHAR(1) NULL)                           
     EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp1'             
            
    -- M 대체처리(기타출고 : 30)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.OutSeq,0) AS InOutSeq,           
                                                           A.OutBizUnit AS BizUnit,                   
                                                           '' AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,                   
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           30 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp1                 
          EXEC _SLGInOutDailySave                
               @xmlDocument  = @XmlData,                   
               @xmlFlags     = 2,                   
               @ServiceSeq   = 2619,                   
               @WorkingTag   = '',                   
               @CompanySeq   = @CompanySeq,                   
               @LanguageSeq  = 1,                   
               @UserSeq      = @UserSeq,                   
               @PgmSeq       = @PgmSeq               
              
           
    
    --초기화
        DELETE FROM #Temp1
        SELECT @XmlData = ''
    -- M 대체처리(자재기타입고 : 41)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.InSeq,0) AS InOutSeq,           
                                                           A.InBizUnit AS BizUnit,                   
                                                           '' AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,                   
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           41 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp1                 
          EXEC _SLGInOutDailySave                
               @xmlDocument  = @XmlData,                   
               @xmlFlags     = 2,                   
               @ServiceSeq   = 2619,                   
               @WorkingTag   = '',                   
               @CompanySeq   = @CompanySeq,                   
               @LanguageSeq  = 1,                   
               @UserSeq      = @UserSeq,                   
               @PgmSeq       = @PgmSeq    


    --DataBlock2
    
        CREATE TABLE #Temp2 (WorkingTag NCHAR(1) NULL)                                       
        EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp2'                                    
                        
          ALTER TABLE #Temp2 ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부                      
          ALTER TABLE #Temp2 ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부                      
          ALTER TABLE #Temp2 ADD IsLot        NCHAR(1) ---- Lot관리여부                      
          ALTER TABLE #Temp2 ADD IsSerial     NCHAR(1) ---- 시리얼관리여부                      
          ALTER TABLE #Temp2 ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크                      
          ALTER TABLE #Temp2 ADD InOutDate    NCHAR(8) ----  체크                      
          ALTER TABLE #Temp2 ADD CustSeq    INT ----  체크                      
          ALTER TABLE #Temp2 ADD SalesCustSeq    INT ----  체크                      
          ALTER TABLE #Temp2 ADD IsTrans    NCHAR(1) ----  체크                      
                                                       
                                                       
             
        SELECT @XmlData = ''           
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                       
                                                           A.IDX_NO,                       
                                                           A.DataSeq,                       
                                                           1 AS Selected,                       
                                                           0 AS Status,                       
                                                           A.OutSeq AS InOutSeq,                       
                                                           A.OutSerl AS InOutSerl,                       
                                                           30 AS InOutType,                 
                                                           --A.ItemSeq AS ItemSeq,              
                                                           A.UnitSeq AS UnitSeq ,                   
                                                           A.ItemSeq AS ItemSeq,                       
                                                           A2.OutBizUnit AS BizUnit,                       
                                                           '' AS InOutNo,              
                                                           A.LotNo AS LotNo,              
                                                           A2.DeptSeq AS DeptSeq,                       
                                                           A2.EmpSeq AS EmpSeq,                       
                                                           A2.InOutDate,                       
                                                           A.InWHSeq AS InWHSeq,                       
                                                           A.OutWHSeq AS OutWHSeq,                    
                                                           A.UnitSeq AS OriUnitSeq,                
                                                           A.OutQty AS Qty,                       
                                                           A.OutQty AS OriQty,                 
                                                           A.STDUnitQty AS STDQty,                    
                                                           A.ItemSeq As OriItemSeq,              
                                                           A.STDUnitQty AS OriSTDQty,                       
                                                           8023003 AS InOutKind,    --기타출고                     
                                                           A.LotNo AS OriLotNo,                       
                                                           ----A.RealLotNo AS LotNo,                       
                                                           ISNULL(@OutKindDetail,0) AS InOutDetailKind,                   
                                                           0 AS Amt 
                                       
                                                       FROM #KPX_TLGItemConvertGtoRItem AS A LEFT OUTER JOIN #KPX_TLGItemConvertGtoR AS A2 ON A.ConvertSeq = A2.ConvertSeq
                                                       LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )                                                                          
                                                      FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS                         
                                                       ))                      
                                
                     
         INSERT INTO #Temp2                            
         EXEC _SLGInOutDailyItemSave                        
              @xmlDocument  = @XmlData,                               
              @xmlFlags     = 2,                     
              @ServiceSeq   = 2619,                               
              @WorkingTag    = '',                               
              @CompanySeq   = @CompanySeq,                               
              @LanguageSeq  = 1,                               
              @UserSeq      = @UserSeq,                               
              @PgmSeq       = @PgmSeq                                  
                

    --자재기타입고(41)   
    DELETE FROM #Temp2             
    SELECT @XmlData = ''           
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                       
                                                           A.IDX_NO,                       
                                                           A.DataSeq,                       
                                                           1 AS Selected,                       
                                                           0 AS Status,                       
                                                           A.InSeq AS InOutSeq,                       
                                                           A.InSerl AS InOutSerl,                       
                                                           41 AS InOutType,                 
                                                           --A.ItemSeq AS ItemSeq,              
                                                           A.ConvertUnitSeq AS UnitSeq ,                   
                                                           A.ConvertItemSeq AS ItemSeq,                       
                                                           A2.InBizUnit AS BizUnit,                       
                                                           '' AS InOutNo,              
                                                           A.ConvertLotNo AS LotNo,              
                                                           A2.DeptSeq AS DeptSeq,                       
                                                           A2.EmpSeq AS EmpSeq,                       
                                                           A2.InOutDate,                       
                                                           A.InWHSeq AS InWHSeq,                       
                                                           A.OutWHSeq AS OutWHSeq,                    
                                                           A.UnitSeq AS OriUnitSeq,                
                                                           A.ConvertQty AS Qty,                       
                                                           A.OutQty AS OriQty,                 
                                                           A.ConvertSTDUnitQty AS STDQty,                    
                                                           A.ItemSeq As OriItemSeq,              
                                                           A.ConvertSTDUnitQty AS OriSTDQty,                       
                                                           8023004 AS InOutKind,    --기타입고                     
                                                           A.LotNo AS OriLotNo,                       
                                                           ----A.RealLotNo AS LotNo,                       
                                                           ISNULL(@InKindDetail,0) AS InOutDetailKind,                   
                                                           0 AS Amt                       
                                                       FROM #KPX_TLGItemConvertGtoRItem AS A LEFT OUTER JOIN #KPX_TLGItemConvertGtoR AS A2 ON A.ConvertSeq = A2.ConvertSeq
                                                       LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )                                                                            
                                                      FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS                         
                                                       ))                      
                                
                     
         INSERT INTO #Temp2                            
         EXEC _SLGInOutDailyItemSave                        
              @xmlDocument  = @XmlData,                               
              @xmlFlags     = 2,                     
              @ServiceSeq   = 2619,                               
              @WorkingTag    = '',                               
              @CompanySeq   = @CompanySeq,                               
              @LanguageSeq  = 1,                               
              @UserSeq      = @UserSeq,                               
              @PgmSeq       = @PgmSeq             
            
   --UPDATE #KPX_TLGItemConvertGtoRItem                                
   --   SET InOutSeq = B.InOutSeq                             
   --  FROM #KPX_TLGItemConvertGtoRItem AS A           
   --  JOIN KPX_TLGItemConvertGtoRItem AS B ON B.CompanySeq =@CompanySeq AND A.ConvertSeq = B.ConvertSeq AND A.ConvertSerl = B. ConvertSerl          
   -- WHERE WorkingTag IN ('D','U')            
   --   AND Status = 0    
    
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPX_TLGItemConvertGtoRItem WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
            DELETE KPX_TLGItemConvertGtoRItem
              FROM #KPX_TLGItemConvertGtoRItem      AS A 
                   JOIN KPX_TLGItemConvertGtoRItem AS B ON ( A.ConvertSeq    = B.ConvertSeq 
                                                       AND   A.ConvertSerl   = B.ConvertSerl) 
                         
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
         
             IF @@ERROR <> 0  RETURN
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
            UPDATE KPX_TLGItemConvertGtoRItem
               SET  ItemSeq             = A.ItemSeq,
                    Spec                = A.Spec,
                    UnitSeq             = A.UnitSeq,
                    OutQty              = A.OutQty,
                    STDUnitSeq          = A.STDUnitSeq,
                    STDUnitQty          = A.STDUnitQty,
                    LotNo               = A.LotNo,
                    Remark              = A.Remark,
                    ConvertItemSeq      = A.ConvertItemSeq,
                    ConvertItemSpec     = A.ConvertItemSpec,
                    OutWHSeq            = A.OutWHSeq,
                    ConvertUnitSeq      = A.ConvertUnitSeq,
                    ConvertQty          = A.ConvertQty,
                    ConvertSTDUnitSeq   = A.ConvertSTDUnitSeq,
                    ConvertSTDUnitQty   = A.ConvertSTDUnitQty,
                    ConvertLotNo        = A.ConvertLotNo,
                    ConvertRemark       = A.ConvertRemark,
                    InWHSeq             = A.InWHSeq,
                    InSeq               = A.InSeq,
                    InSerl              = A.InSerl,
                    InNo                = A.InNo,    
                    OutSeq              = A.OutSeq,
                    OutSerl             = A.OutSerl,
                    OutNo               = A.OutNo,                                      
                    LastUserSeq         = @UserSeq,
                    LastDateTime        = GETDATE()
              FROM #KPX_TLGItemConvertGtoRItem      AS A 
                   JOIN KPX_TLGItemConvertGtoRItem AS B ON ( A.ConvertSeq    = B.ConvertSeq 
                                                       AND   A.ConvertSerl   = B.ConvertSerl) 
                         
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'U' 
               AND A.Status     = 0    
   
            IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
            INSERT INTO KPX_TLGItemConvertGtoRItem 
                   (CompanySeq,
                    ConvertSeq,
                    ConvertSerl,
                    ItemSeq,
                    Spec,
                    UnitSeq,
                    OutQty,
                    STDUnitSeq,
                    STDUnitQty,
                    LotNo,
                    Remark,
                    ConvertItemSeq,
                    ConvertItemSpec,
                    OutWHSeq,
                    ConvertUnitSeq,
                    ConvertQty,
                    ConvertSTDUnitSeq,
                    ConvertSTDUnitQty,
                    ConvertLotNo,
                    ConvertRemark,
                    InWHSeq,
                    InSeq,
                    InSerl,
                    InNo,
                    OutSeq,
                    OutSerl,
                    OutNo,                   
                    LastUserSeq,
                    LastDateTime) 
            SELECT  @CompanySeq,
                    ConvertSeq,
                    ConvertSerl,
                    ItemSeq,
                    Spec,
                    UnitSeq,
                    OutQty,
                    STDUnitSeq,
                    STDUnitQty,
                    LotNo,
                    Remark,
                    ConvertItemSeq,
                    ConvertItemSpec,
                    OutWHSeq,
                    ConvertUnitSeq,
                    ConvertQty,
                    ConvertSTDUnitSeq,
                    ConvertSTDUnitQty,
                    ConvertLotNo,
                    ConvertRemark,
                    InWHSeq,
                    InSeq,
                    InSerl,
                    InNo,
                    OutSeq,
                    OutSerl,
                    OutNo,                  
                    @UserSeq,
                    GETDATE()
              FROM #KPX_TLGItemConvertGtoRItem AS A   
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0    

            IF @@ERROR <> 0 RETURN
    END   
    
    INSERT INTO _TLGLotMaster 
    (
        CompanySeq, LotNo, ItemSeq, SourceLotNo, UnitSeq, 
        Qty, CreateDate, CreateTime, ValiDate, ValidTime, 
        RegDate, RegUserSeq, CustSeq, Remark, OriLotNo, 
        OriItemSeq, LastUserSeq, LastDateTime, InNo, SupplyCustSeq, 
        PgmSeqModifying
    )
    SELECT @CompanySeq, A.ConvertLotNo, A.ConvertItemSeq, A.ConvertLotNo, A.ConvertUnitSeq, 
           B.Qty, B.CreateDate, B.CreateTime, B.ValiDate, B.ValidTime, 
           B.RegDate, @UserSeq, B.CustSeq, '제품 원자재대체처리(사업부문) 생성', B.OriLotNo, 
           B.OriItemSeq, @UserSeq, GETDATE(), '', B.SupplyCustSeq, 
           @PgmSeq
      FROM #KPX_TLGItemConvertGtoRItem  AS A 
      LEFT OUTER JOIN _TLGLotMaster     AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U' , 'A' ) 
       AND NOT EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = B.CompanySeq AND ItemSeq = A.ConvertItemSeq AND LotNo = A.ConvertLotNo) 
    
    SELECT * FROM #KPX_TLGItemConvertGtoR 
    SELECT * FROM #KPX_TLGItemConvertGtoRItem 
    
    RETURN
GO



begin tran 
exec KPXCM_SLGItemConvertGtoRSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ItemName>Lot품목1_이재천</ItemName>
    <ItemNo>Lot품목1_이재천</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <OutQty>1.00000</OutQty>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>1.00000</STDUnitQty>
    <LotNo>test_lotno1</LotNo>
    <Remark />
    <ConvertItemName>세호LOT자재</ConvertItemName>
    <ConvertItemNo>세호LOT자재</ConvertItemNo>
    <ConvertItemSpec />
    <ConvertUnitName>Kg</ConvertUnitName>
    <ConvertQty>1.00000</ConvertQty>
    <ConvertSTDUnitName>Kg</ConvertSTDUnitName>
    <ConvertSTDUnitQty>1.00000</ConvertSTDUnitQty>
    <ConvertLotNo>test_lotno1</ConvertLotNo>
    <ConvertRemark />
    <ConvertSeq>20</ConvertSeq>
    <ConvertSerl>1</ConvertSerl>
    <ItemSeq>27367</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <STDUnitSeq>2</STDUnitSeq>
    <ConvertItemSeq>25031</ConvertItemSeq>
    <ConvertUnitSeq>2</ConvertUnitSeq>
    <ConvertSTDUnitSeq>2</ConvertSTDUnitSeq>
    <OutWHSeq>11</OutWHSeq>
    <InWHSeq>7534</InWHSeq>
    <InSeq>100002562</InSeq>
    <InSerl>1</InSerl>
    <InNo>201605260005        </InNo>
    <OutSeq>100002561</OutSeq>
    <OutSerl>1</OutSerl>
    <OutNo>201605260004        </OutNo>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <OutBizUnit>1</OutBizUnit>
    <InBizUnit>2</InBizUnit>
    <OutWHName>박종금</OutWHName>
    <InWHName>T일반창고1_이재천</InWHName>
    <InOutDate>20160526</InOutDate>
    <DeptName>사업개발팀2</DeptName>
    <InOutNo>201605260002</InOutNo>
    <EmpName>이재천</EmpName>
    <Remark />
    <Memo />
    <ConvertSeq>20</ConvertSeq>
    <OutWHSeq>11</OutWHSeq>
    <InWHSeq>7534</InWHSeq>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <InSeq>100002562</InSeq>
    <OutSeq>100002561</OutSeq>
    <InNo>201605260005        </InNo>
    <OutNo>201605260004        </OutNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037198,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030471

--select * From _TLGInoutDaily where companyseq = 1 and inoutseq = 100002562 -- = '201605260003'
--select * From _TLGInoutDailyItem where companyseq = 1 and inoutseq = 100002562 -- = '201605260003'

--select * From _TLGInoutDaily where companyseq = 1 and inoutseq = 100002561 -- = '201605260003'
--select * From _TLGInoutDailyItem where companyseq = 1 and inoutseq = 100002561 -- = '201605260003'
rollback 