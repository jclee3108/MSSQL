IF OBJECT_ID('KPXCM_SLGItemConvertGtoRCheck') IS NOT NULL 
    DROP PROC KPXCM_SLGItemConvertGtoRCheck
GO

-- v2016.05.25 

-- KPXCM용 개발 by이재천 
/************************************************************
 설  명 - 데이터-제품 원재료대체처리(사업부문간)_KPX : 확인
 작성일 - 20150817
 작성자 - 민형준
 수정자 - 
************************************************************/
CREATE PROC dbo.KPXCM_SLGItemConvertGtoRCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250),
            @XmlData     NVARCHAR(MAX)
  
    CREATE TABLE #KPX_TLGItemConvertGtoR (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TLGItemConvertGtoR'

    CREATE TABLE #KPX_TLGItemConvertGtoRItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TLGItemConvertGtoRItem'

    
    --각 사업부문의 수불 마감 체크 
    -- 출고 사업부문은 제품 마감 체크
    -- 입고 사업부문은 자재 마감 체크
	EXEC dbo._SCOMMessage @MessageType OUTPUT,    
						  @Status      OUTPUT,    
						  @Results     OUTPUT,    
						  2                  , -- @1 @2가(이) 마감 되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%마감%')    
						  @LanguageSeq       ,     
						  0,'',   -- SELECT * FROM _TCADictionary WHERE Word like '%업무%'    
						  7161, '업무'    

    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = REPLACE(@Results, '@1', '사업부문('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN _TDABizUnit AS B WITH(NOLOCK) ON A.InBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A.InBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --수불
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 1
     WHERE A.Status = 0

    --기존 실테이블과 join
    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = REPLACE(@Results, '@1', '사업부문('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN KPX_TLGItemConvertGtoR AS A2 WITH(NOLOCK) ON A2.CompanySeq = @CompanySeq AND A.ConvertSeq  = A2.ConvertSeq
                                        JOIN _TDABizUnit AS B WITH(NOLOCK) ON A2.InBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A2.InBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A2.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --수불
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 1
     WHERE A.Status = 0


    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = REPLACE(@Results, '@1', '사업부문('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN _TDABizUnit AS B WITH(NOLOCK) ON A.OutBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A.OutBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --수불
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 2
     WHERE A.Status = 0

    --기존 실테이블과 join
    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = REPLACE(@Results, '@1', '사업부문('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN KPX_TLGItemConvertGtoR AS A2 WITH(NOLOCK) ON A2.CompanySeq = @CompanySeq AND A.ConvertSeq  = A2.ConvertSeq
                                        JOIN _TDABizUnit AS B WITH(NOLOCK) ON A2.OutBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A2.OutBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A2.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --수불
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 2
     WHERE A.Status = 0

     
    --동일한 사업부문인 경우 오류 처리
    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = '동일한 사업부문이 입력되었습니다.',
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A 
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A','U')
       AND A.InBizUnit = A.OutBizUnit

    --동일한 품목인 경우 오류 처리
    UPDATE A
	   SET A.Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.      
		   A.Result = '동일한 품목이 입력되었습니다.',
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoRItem AS A 
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A','U')
       AND A.ItemSeq = A.ConvertItemSeq
    
    /* 
    -- 대체처리 품목의 LotNo가 존재합니다. LotMaster를 확인 하시기 바랍니다. 
    UPDATE A 
       SET A.Status = 1234,
		   A.Result = '대체처리 품목의 LotNo가 존재합니다. LotMaster를 확인 하시기 바랍니다. ',
		   A.MessageType = 1234 
      FROM #KPX_TLGItemConvertGtoRItem AS A 
     WHERE EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ConvertItemSeq AND LotNo = A.ConvertLotNo) 
       AND A.WorkingTag IN ( 'U', 'A' ) 
       AND A.Status = 0 
    */
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0) OR EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
    

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


     UPDATE #KPX_TLGItemConvertGtoR                            
        SET InSeq = C.InSeq ,
            InNo    = C.InNo                         
       FROM #KPX_TLGItemConvertGtoR AS A       
       JOIN KPX_TLGItemConvertGtoR  AS B ON B.CompanySeq =@CompanySeq AND A.ConvertSeq = B.ConvertSeq 
      CROSS APPLY (SELECT TOP 1 InSeq  , InNo   
                     FROM KPX_TLGItemConvertGtoRItem AS Z     
                    WHERE  Z.ConvertSeq = B.ConvertSeq    
                   ) AS C     
      WHERE  A.WorkingTag IN ('D','U')        
        AND  A.Status = 0   
    
     UPDATE #KPX_TLGItemConvertGtoR                            
        SET OutSeq = C.OutSeq ,
            OutNo   = C.OutNo                        
       FROM #KPX_TLGItemConvertGtoR AS A       
       JOIN KPX_TLGItemConvertGtoR  AS B ON B.CompanySeq =@CompanySeq AND A.ConvertSeq = B.ConvertSeq 
      CROSS APPLY (SELECT TOP 1 OutSeq, OutNo    
                     FROM KPX_TLGItemConvertGtoRItem AS Z     
                    WHERE  Z.ConvertSeq = B.ConvertSeq    
                   ) AS C     
      WHERE  A.WorkingTag IN ('D','U')        
        AND  A.Status = 0  
            
    CREATE TABLE #Temp11 (WorkingTag NCHAR(1) NULL)                             
     EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp11'               
              
    -- M 대체처리(기타출고 : 30)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.OutSeq,0) AS InOutSeq,           
                                                           A.OutBizUnit AS BizUnit,                   
                                                           A.OutNo AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,            
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           30 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp11                   
          EXEC _SLGInOutDailyCheck                  
               @xmlDocument  = @XmlData,                     
               @xmlFlags     = 2,                     
               @ServiceSeq   = 2619,                     
               @WorkingTag   = '',                     
               @CompanySeq   = @CompanySeq,                     
               @LanguageSeq  = 1,                     
               @UserSeq      = @UserSeq,                     
               @PgmSeq       = @PgmSeq              
              
           

     
       UPDATE A          
          SET A.OutSeq = B.InOutSeq,
              A.OutNo   = B.InOutNo,   
              A.Status    = B.Status     ,
              A.MessageType = B.MessageType ,
              A.Result     = B.Result                  
         FROM #KPX_TLGItemConvertGtoR AS A          
         JOIN #Temp11 AS B ON  A.IDX_NO = B.IDX_NO        
    
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
    
    --초기화
        DELETE FROM #Temp11
        SELECT @XmlData = ''
-- M 대체처리(자재기타입고 : 41)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.InSeq,0) AS InOutSeq,           
                                                           A.InBizUnit AS BizUnit,                   
                                                           A.InNo AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,                   
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           41 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp11                   
          EXEC _SLGInOutDailyCheck                  
               @xmlDocument  = @XmlData,                     
               @xmlFlags     = 2,                     
               @ServiceSeq   = 2619,                     
               @WorkingTag   = '',                     
               @CompanySeq   = @CompanySeq,                     
               @LanguageSeq  = 1,                     
               @UserSeq      = @UserSeq,                     
               @PgmSeq       = @PgmSeq              
              
     
       UPDATE A          
          SET A.InSeq   = B.InOutSeq,
              A.InNo    = B.InOutNo  ,   
              A.Status    = B.Status     ,
              A.MessageType = B.MessageType ,
              A.Result     = B.Result                    
         FROM #KPX_TLGItemConvertGtoR AS A          
         JOIN #Temp11 AS B ON  A.IDX_NO = B.IDX_NO      
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END    
    
---- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
----guide : '마스터 키 생성' --------------------------
    DECLARE @MaxSeq INT,
            @Count  INT,
            @InOutDate  NCHAR(8),
            @InOutNo    NVARCHAR(200)
            
    SELECT @Count = Count(1) FROM #KPX_TLGItemConvertGtoR WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
        SELECT @InOutDate = InOutDate FROM #KPX_TLGItemConvertGtoR     
        
        EXEC dbo._SCOMCreateNo 'SITE', 'KPX_TLGItemConvertGtoR', @CompanySeq, 0, @InOutDate, @InOutNo OUTPUT  
    
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TLGItemConvertGtoR','ConvertSeq',@Count --rowcount  
        
          UPDATE #KPX_TLGItemConvertGtoR             
             SET ConvertSeq  = @MaxSeq + DataSeq   ,
                 InOutNo     = @InOutNo
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  
    
    --#KPX_TLGItemConvertGtoRItem 에 반영
    IF EXISTS (SELECT 1 ConvertSeq FROM #KPX_TLGItemConvertGtoR)
    BEGIN 
        UPDATE #KPX_TLGItemConvertGtoRItem
          SET ConvertSeq = (SELECT TOP 1 ConvertSeq FROM #KPX_TLGItemConvertGtoR),
              OutWHSeq  = (SELECT TOP 1 OutWHSeq FROM #KPX_TLGItemConvertGtoR),
              InWHSeq   = (SELECT TOP 1 InWHSeq FROM #KPX_TLGItemConvertGtoR),
              InSeq = (SELECT TOP 1 InSeq FROM #KPX_TLGItemConvertGtoR),
              OutSeq = (SELECT TOP 1 OutSeq FROM #KPX_TLGItemConvertGtoR),
              InNo = (SELECT TOP 1 InNo FROM #KPX_TLGItemConvertGtoR),
              OutNo = (SELECT TOP 1 OutNo FROM #KPX_TLGItemConvertGtoR)          
    END 
          
           
           
    --DataBlock2
      CREATE TABLE #Temp3 (WorkingTag NCHAR(1) NULL)                                 
      EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp3'               

         
      --기타출고(30)
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
                               
               
         INSERT INTO #Temp3                      
         EXEC KPXCM_SLGInOutDailyItemCheck                   
              @xmlDocument  = @XmlData,                         
              @xmlFlags     = 2,                         
              @ServiceSeq   = 2619,                         
              @WorkingTag   = '',                         
              @CompanySeq   = @CompanySeq,                         
              @LanguageSeq  = 1,                         
              @UserSeq      = @UserSeq,                         
              @PgmSeq       = @PgmSeq                  
               
                 
--select '#Temp3', * from #Temp3                  
                     
          UPDATE A            
            SET  A.OutSerl = B.InOutSerl  ,
                 A.Status    = B.Status     ,
                 A.MessageType = B.MessageType ,
                 A.Result     = B.Result   
           FROM  #KPX_TLGItemConvertGtoRItem AS A            
           JOIN  #Temp3 AS B ON  A.IDX_NO = B.IDX_NO              

    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
            
    --자재기타입고(41)
        --초기화
      DELETE FROM #Temp3
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
                               
               
         INSERT INTO #Temp3                      
         EXEC KPXCM_SLGInOutDailyItemCheck                   
              @xmlDocument  = @XmlData,                  
              @xmlFlags     = 2,                         
              @ServiceSeq   = 2619,                         
              @WorkingTag   = '',                         
              @CompanySeq   = @CompanySeq,                         
              @LanguageSeq  = 1,                         
              @UserSeq      = @UserSeq,                         
              @PgmSeq       = @PgmSeq                  
               
                 
                  
                     
          UPDATE A            
            SET  A.InSerl = B.InOutSerl  ,
                 A.Status    = B.Status     ,
                 A.MessageType = B.MessageType ,
                 A.Result     = B.Result   
           FROM  #KPX_TLGItemConvertGtoRItem AS A            
           JOIN  #Temp3 AS B ON  A.IDX_NO = B.IDX_NO           
    
    
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END

    SELECT @MaxSeq  = 0,
           @Count   = 0 

    SELECT @Count = Count(1) FROM  #KPX_TLGItemConvertGtoRItem    WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
      SELECT @MaxSeq =ISNULL( Max(A.ConvertSerl),0)
        FROM KPX_TLGItemConvertGtoRItem         AS A
             JOIN #KPX_TLGItemConvertGtoRItem    AS B ON  A.ConvertSeq = B.ConvertSeq
       WHERE A.CompanySeq  = @CompanySeq 
         AND B.WorkingTag = 'A'            
         AND B.Status = 0 
          
      UPDATE #KPX_TLGItemConvertGtoRItem                
         SET ConvertSerl  = @MaxSeq + DataSeq   
       WHERE WorkingTag = 'A'            
         AND Status = 0 
    END             
           
                           
    SELECT * FROM #KPX_TLGItemConvertGtoR 
    SELECT * FROM #KPX_TLGItemConvertGtoRItem
RETURN
GO
begin tran 
exec KPXCM_SLGItemConvertGtoRCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName>Lot품목1_이재천</ItemName>
    <ItemNo>Lot품목1_이재천</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <OutQty>1</OutQty>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>1</STDUnitQty>
    <LotNo>qwer22</LotNo>
    <Remark />
    <ConvertItemName>Lot_다시한번테스트_이재천</ConvertItemName>
    <ConvertItemNo>Lot_다시한번테스트No_이재천</ConvertItemNo>
    <ConvertItemSpec />
    <ConvertUnitName>EA</ConvertUnitName>
    <ConvertQty>1</ConvertQty>
    <ConvertSTDUnitName>EA</ConvertSTDUnitName>
    <ConvertSTDUnitQty>1</ConvertSTDUnitQty>
    <ConvertLotNo>다시한번_Lot1</ConvertLotNo>
    <ConvertRemark />
    <ConvertSeq>18</ConvertSeq>
    <ConvertSerl>1</ConvertSerl>
    <ItemSeq>27367</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <STDUnitSeq>2</STDUnitSeq>
    <ConvertItemSeq>1052403</ConvertItemSeq>
    <ConvertUnitSeq>4</ConvertUnitSeq>
    <ConvertSTDUnitSeq>4</ConvertSTDUnitSeq>
    <InSeq>100002558</InSeq>
    <InSerl>1</InSerl>
    <InNo>201605250009</InNo>
    <OutSeq>100002557</OutSeq>
    <OutSerl>1</OutSerl>
    <OutNo>201605250008</OutNo>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037198,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030471
rollback 