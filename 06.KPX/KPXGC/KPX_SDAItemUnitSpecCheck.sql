
IF OBJECT_ID('KPX_SDAItemUnitSpecCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSpecCheck
GO 

-- v2014.11.04 

-- 품목단위속성 체크 by이재천

/************************************************************  
설  명 - 품목단위속성 체크  
작성일 - 2008년 7월    
작성자 - 김준모  
************************************************************/  
CREATE PROC KPX_SDAItemUnitSpecCheck  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
  
AS      
  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250)  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #KPX_TDAItemUnitSpec (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnitSpec'       
    IF @@ERROR <> 0 RETURN   
  
    -------------------------------------------  
    -- 중복여부체크  
    -------------------------------------------  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
--                           @LanguageSeq       ,   
--                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
--     UPDATE #TDAItem  
--        SET Result        = REPLACE(@Results,'@2',B.ItemSeq),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #TDAItem AS A JOIN ( SELECT S.ItemNo  
--                                      FROM (  
--                                            SELECT A1.ItemNo  
--                                              FROM #TDAItem AS A1  
--                                             WHERE A1.WorkingTag IN ('A', 'U')  
--                                               AND A1.Status = 0  
--                                            UNION ALL  
--                                            SELECT A1.ItemNo  
--                                              FROM _TDAItem AS A1  
--                                             WHERE A1.ItemSeq NOT IN (SELECT ItemSeq   
--                                                                            FROM #TDAItem   
--                                                                           WHERE WorkingTag IN ('U','D')   
--                                                                             AND Status = 0)  
--                                           ) AS S  
--                                     GROUP BY S.ItemNo  
--                                     HAVING COUNT(1) > 1  
--                                   ) AS B ON (A.ItemNo = B.ItemNo)  
  
    -- 사용여부체크  
    -------------------------------------------  
    -- 1.전표발행여부체크  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           8                  , -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)  
--                           @LanguageSeq       ,   
--                           9,'전표'             -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'  
--     UPDATE #TDAItemCard  
--        SET Result        = REPLACE(REPLACE(@Results,'@2',A.BillCardNo),'@3',dbo._FCOMMask(@CompanySeq,'SlipID',C.SlipID)),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #TDAItemCard AS A JOIN _TACSlipRem AS B ON(A.BillCardSeq = B.RemValSeq)  
--                              JOIN _TACSlipRow AS C ON(B.CompanySeq = C.CompanySeq AND B.SlipSeq = C.SlipSeq)  
--      WHERE B.CompanySeq = @CompanySeq  
--        AND C.CompanySeq = @CompanySeq  
--        AND B.RemSeq = 0 -- 확정안됨(^^)  
--        AND A.WorkingTag NOT IN ('D')   
--        AND A.Status = 0  
  
      -------------------------------------------  
    -- 마감여부체크  
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
    -------------------------------------------  
    -- 진행여부체크  
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
    -------------------------------------------  
    -- 확정여부체크  
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
    -------------------------------------------  
    -- INSERT 번호부여(맨 마지막 처리)  
    -------------------------------------------  
   
    SELECT * FROM #KPX_TDAItemUnitSpec     
    RETURN      
/*******************************************************************************************************************/  
  