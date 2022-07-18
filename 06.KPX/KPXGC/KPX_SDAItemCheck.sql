IF OBJECT_ID('KPX_SDAItemCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemCheck
GO 

-- v2014.11.04 

-- 품목등록(기본_영업정보)체크 by이재천
/************************************************************
      Ver.20140212
  설  명 - 품목등록 체크
 작성일 - 2008년 6월  
 작성자 - 김준모
 수정일 - 20110511 by 김철웅
   1) 자재등록에서 재공품인 경우 Lot관리 및 Serial관리는 하지 못하도록 적용하였음
 ************************************************************/
 CREATE PROC KPX_SDAItemCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
    DECLARE @Count   INT,
            @Seq   INT,
            @MessageType INT,
            @Status   INT,
            @ItemName  NVARCHAR(200),
            @TrunName  NVARCHAR(200),
            @Results  NVARCHAR(250),
            @ItemNameCheck NCHAR(1),
            @ItemNoCheck NCHAR(1),
            @SpecCheck  NCHAR(1), 
            @DataSeq  INT, 
            @MaxDataSeq  INT,
            @IsLotMng  NCHAR(1),
            @IsSerialMng NCHAR(1),
            @AssetSeq  INT,
            @UpdateUseItemCheck INT
    
    -- 서비스 마스타 등록 생성
    CREATE TABLE #KPX_TDAItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItem'     
    IF @@ERROR <> 0 RETURN 
    
    
    -- 체크, 확정된 데이터는 삭제 할 수 없습니다.
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1083               , -- @1는(은) @2(을)를 할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%처리할 수 없습니다%')
                          @LanguageSeq       , 
                          0 
    
    UPDATE A
       SET Result = @Results, 
           Status = @Status, 
           MessageType = @MessageType
      FROM #KPX_TDAItem AS A 
     WHERE A.Status = 0 
       AND EXISTS (SELECT 1 FROM KPX_TDAItem_Confirm WHERE CompanySeq = @CompanySeq AND CfmSeq = A.ItemSeq AND CfmCode = 1)
     -- 체크, END 
    
    SELECT @ItemName = ISNULL(ItemName, ''),
           @IsLotMng = IsLotMng,
           @IsSerialMng = IsSerialMng,
           @AssetSeq = AssetSeq
      FROM #KPX_TDAItem
    
    -- 자재등록에서 재공품인 경우 Lot관리 및 Serial관리는 하지 못하도록 적용
    IF EXISTS ( SELECT * FROM _TDAItemAsset WHERE CompanySeq = @CompanySeq AND AssetSeq = @AssetSeq AND SMAssetGrp = 6008005 ) -- 재공품 
    BEGIN
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          19               , -- @1는(은) @2(을)를 할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%없습니다.')
                          @LanguageSeq       , 
                          22654,'재공품'   -- SELECT * FROM _TCADictionary WHERE Word like '%Serial관리%'
    IF @IsLotMng = 1 
    UPDATE #KPX_TDAItem
       SET Result        = REPLACE(@Results,'@2', (SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 14046)),
        MessageType   = @MessageType,
        Status        = @Status
   ELSE IF @IsSerialMng = 1
    UPDATE #KPX_TDAItem
       SET Result        = REPLACE(@Results,'@2', (SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 14156)),
        MessageType   = @MessageType,
        Status        = @Status
                
  END
  
     --품명 중복체크     
     EXEC dbo._SCOMEnv @CompanySeq,1001,@UserSeq,@@PROCID,@ItemNameCheck  OUTPUT  
      --품번 중복체크     
     EXEC dbo._SCOMEnv @CompanySeq,1002,@UserSeq,@@PROCID,@ItemNoCheck  OUTPUT  
      --품명+규격 중복체크     
     EXEC dbo._SCOMEnv @CompanySeq,1003,@UserSeq,@@PROCID,@SpecCheck  OUTPUT  
     
     -- 품명/품번 수정 시, 사용여부 체크
     EXEC dbo._SCOMEnv @CompanySeq,28,@UserSeq,@@PROCID,@UpdateUseItemCheck  OUTPUT  
  
  
      IF ISNULL(@ItemNameCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- 품명중복여부체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'품명'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemName),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemName
                                          FROM (
                        SELECT A1.ItemName
                                                  FROM #KPX_TDAItem AS A1
                              WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemName
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemName
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemName = B.ItemName)
     END
      IF ISNULL(@ItemNoCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- 품번중복여부체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'품번'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemNo),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemNo
                                          FROM (
                                                SELECT A1.ItemNo
                                                  FROM #KPX_TDAItem AS A1
                                                 WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemNo
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemNo
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemNo = B.ItemNo)
     END
      IF ISNULL(@SpecCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- 품명 + 규격중복여부체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'품명 + 규격'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemName + ' + ' + A.Spec),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemName, S.Spec
                                 FROM (
                                                SELECT A1.ItemName, A1.Spec
                                                  FROM #KPX_TDAItem AS A1
                                                 WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemName, A1.Spec
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemName, S.Spec
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemName = B.ItemName)
                                             AND (A.Spec     = B.Spec)
     END
    
      -------------------------------------------  
     -- 사용여부체크 
     -------------------------------------------  
     IF EXISTS (SELECT 1 FROM #KPX_TDAItem WHERE WorkingTag = 'D')
     BEGIN
         EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
     END
    
    
    ------------------------------------------------------------
    -- 기준단위 & 품목자산분류 수정여부체크 20130604 박성호 수정
    ------------------------------------------------------------
     
     -- 기준단위 & 품목자산분류 UPDATE 되는지 체크
     IF EXISTS (SELECT 1 
                  FROM #KPX_TDAItem AS A
                       JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND A.ItemSeq    = B.ItemSeq
                 WHERE A.WorkingTag = 'U' 
                   AND A.Status = 0
                   AND (A.UnitSeq <> B.UnitSeq OR A.AssetSeq <> B.AssetSeq))
     BEGIN       
          -- 공통SP 사용을 위해 WorkingTag UPDATE
         UPDATE #KPX_TDAItem SET WorkingTag = 'D'
     
         EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
          -- 공통SP 리턴 후 사용된 테이블이 없으면, 다시 WorkingTag를 UPDATE    
         IF ( SELECT Status FROM #KPX_TDAItem ) = 0
         BEGIN
             UPDATE #KPX_TDAItem SET WorkingTag = 'U'
         END
      END
  
  
      -----------------------------------------------------------------------------------
     --사용중인 품목에 대해 품명/품번 수정가능여부 설정 20140212 by sdlee
     --미사용중인 품목은 모두 수정이 가능하며, 사용중인 경우에만 설정에 따라 품명/품번을 수정할 수 있도록 설정합니다.
     --8121001  품명 수정가능/품번 수정가능 : 미체크
     --8121002  품명 수정가능/품번 수정불가
     --8121003  품명 수정불가/품번 수정가능
     --8121004  품명 수정불가/품번 수정불가
     -----------------------------------------------------------------------------------
     IF @UpdateUseItemCheck IN (8121002,8121003,8121004)
     BEGIN
          -- 사용여부체크
         SELECT *
           INTO #TEMP_Check_TDAItem
           FROM #KPX_TDAItem
  
  
         -- 품명 수정가능/품번 수정불가
         IF @UpdateUseItemCheck = 8121002
         BEGIN
              -- 품번 체크
             IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND A.ItemNo <> B.ItemNo)
             BEGIN
             -- 사용여부 체크
                 -- 공통SP 사용을 위해 WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- 공통SP 리턴 후 사용된 테이블이 없으면, 다시 WorkingTag를 UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
                  --EXEC dbo._SCOMMessage   @MessageType OUTPUT,
                 --                        @Status      OUTPUT,
                 --                        @Results     OUTPUT,
                 --                        1366               ,    -- @1을(를) 수정할수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1366)
                 --                        @LanguageSeq       , 
                 --                        2091,'품번'             -- 품번(SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2091)
                 --UPDATE #KPX_TDAItem
                 --   SET Result        = @Results,
                 --       MessageType   = @MessageType,
                 --       Status        = @Status
                 --  FROM #KPX_TDAItem
                 -- WHERE WorkingTag = 'U'
                 --   AND Status = 0
             END
         END
          -- 품명 수정불가/품번 수정가능
         IF @UpdateUseItemCheck = 8121003
         BEGIN
              IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND A.ItemName <> B.ItemName)
             BEGIN
                  -- 사용여부 체크
                 -- 공통SP 사용을 위해 WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- 공통SP 리턴 후 사용된 테이블이 없으면, 다시 WorkingTag를 UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
  
                 --EXEC dbo._SCOMMessage   @MessageType OUTPUT,
                 --                        @Status      OUTPUT,
                 --                        @Results     OUTPUT,
                 --                        1366               ,    -- @1을(를) 수정할수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1366)
                 --                        @LanguageSeq       , 
                 --                        2090,'품명'             -- 품명(SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2090)
                 --UPDATE #KPX_TDAItem
                 --   SET Result        = @Results,
                 --       MessageType   = @MessageType,
                 --       Status        = @Status
                 --  FROM #KPX_TDAItem
                 -- WHERE WorkingTag = 'U'
                 --   AND Status = 0
             END
         END
          -- 품명 수정불가/품번 수정불가
         IF @UpdateUseItemCheck = 8121004
         BEGIN
              IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND (A.ItemName <> B.ItemName OR A.ItemNo <> B.ItemNo))
             BEGIN
                  -- 사용여부 체크
                 -- 공통SP 사용을 위해 WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- 공통SP 리턴 후 사용된 테이블이 없으면, 다시 WorkingTag를 UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
  

             END
         END
      END
    
     --------------------------------------------------------------------  
     -- 세트품목일경우 -- 품목자산분류 상품만 등록가능 2012.02.27 jhpark
     --------------------------------------------------------------------
     IF Exists (SELECT TOP 1 1 FROM #KPX_TDAItem WHERE IsSet = 1)
     BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1291               , -- @1은 @2을 @3으로 등록해야 합니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1291)
                               @LanguageSeq       , 
                               1615,''    ,-- SELECT * FROM _TCADictionary WHERE Word like '%상품%'
                               3259,''    ,-- SELECT * FROM _TCADictionary WHERE Word like '%상품%'
                               3069,''     -- SELECT * FROM _TCADictionary WHERE Word like '%상품%'
         UPDATE #KPX_TDAItem
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A
                 JOIN _TDAItemAsset AS B WITH (NOLOCK) ON A.AssetSeq   = B.AssetSeq
                                                      AND B.CompanySeq = @CompanySeq
                                                      AND B.SMAssetGrp <> 6008001 -- 상품
          WHERE A.WorkingTag <> 'D' 
            AND A.Status = 0
      END
      -------------------------------------------
     -- 공백제거
     -------------------------------------------
  SELECT @MaxDataSeq = COUNT(1) + 1 FROM #KPX_TDAItem WHERE WorkingTag IN ('A', 'U') AND Status = 0
  
  SET @DataSeq = 1  
  
  WHILE (@DataSeq < @MaxDataSeq) 
  BEGIN
   SELECT @ItemName = ItemName
     FROM #KPX_TDAItem
    WHERE DataSeq = @DataSeq
    
   EXEC _SDATrSpace  @ItemName, @TrunName OUTPUT
    UPDATE #KPX_TDAItem
      SET TrunName = @TrunName
     FROM #KPX_TDAItem
       WHERE DataSeq = @DataSeq
       
       SET @DataSeq = @DataSeq + 1
  END
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
     SELECT @Count = COUNT(1) FROM #KPX_TDAItem WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)
     IF @Count > 0
     BEGIN  
         -- 키값생성코드부분 시작  
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TDAItem', 'ItemSeq', @Count
         -- Temp Talbe 에 생성된 키값 UPDATE
         UPDATE #KPX_TDAItem
            SET ItemSeq = @Seq + DataSeq
          WHERE WorkingTag = 'A'
            AND Status = 0
     END   
      UPDATE #KPX_TDAItem
        SET ItemSeq = ItemSeqOLD
      WHERE WorkingTag = 'A'
        AND ItemSeq = 0
        AND Status <> 0
  
     SELECT * FROM #KPX_TDAItem   
  
    RETURN
GO 
begin tran 
exec KPX_SDAItemCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq>1051541</ItemSeq>
    <TrunName>TEST123456</TrunName>
    <ModelName />
    <ModelSeq>0</ModelSeq>
    <STDItemName />
    <ItemSeqOLD>1051541</ItemSeqOLD>
    <IsInherit>0</IsInherit>
    <ItemName>test123456</ItemName>
    <UnitSeq>2</UnitSeq>
    <UnitName>EA</UnitName>
    <AssetSeq>15</AssetSeq>
    <AssetName>상품</AssetName>
    <ItemNo>test123456</ItemNo>
    <DeptSeq>0</DeptSeq>
    <DeptName />
    <SMInOutKind>8007001</SMInOutKind>
    <SMStatus>2001001</SMStatus>
    <Spec />
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <SMABC>2002001</SMABC>
    <ItemClassLName>test5</ItemClassLName>
    <ItemClassMName>1111</ItemClassMName>
    <RegUser>이재천</RegUser>
    <RegDate>20141105</RegDate>
    <LastUser />
    <LastDate />
    <UMItemClassS>2001040</UMItemClassS>
    <ItemClassSName>TEST</ItemClassSName>
    <ItemSName />
    <ItemEngName />
    <ItemEngSName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025570,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310

rollback 