IF OBJECT_ID('KPXCM_SQCInQCIResultNoTestCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCIResultNoTestCheck
GO 

-- v2015.11.02 

-- 무검사처리 체크 by이재천 
 -- v2015.01.15 
 -- 테이블 수정 by 이재천
 /************************************************************  
  설  명 - 데이터-수입검사등록_KPX : 체크  
  작성일 - 20141219  
  작성자 - 박상준 
  수정자 - 20150828 CM용으로 종료체크 추가
 ************************************************************/  
 CREATE PROC KPXCM_SQCInQCIResultNoTestCheck
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
             @BaseDate  NCHAR(8)  
     
     CREATE TABLE #KPX_TQCTestResult (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'  
    
     -- 마스터 키 채번 
     DECLARE @MaxSeq INT,  
             @Count  INT,  
             @MaxNo  NVARCHAR(20)  
     
     SELECT @MaxNo = ''   
     
     SELECT @Count = Count(1) FROM #KPX_TQCTestResult WHERE ISNULL(InQCSeq,0) = 0 AND Status = 0  
    
     IF @Count >0   
     BEGIN  
     
         EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TQCTestResult','QCSeq',@Count --rowcount    
         
         -- 재고검사번호생성    
         SELECT @BaseDate = CONVERT(NCHAR(8), GETDATE(), 112)  
         
         EXEC _SCOMCreateNo 'SITE', 'KPX_TQCTestResult', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
         
         UPDATE #KPX_TQCTestResult               
            SET InQCSeq  = @MaxSeq + DataSeq  
               ,InQCNo   = @MaxNo     
          WHERE Status = 0   
            AND ISNULL(InQCSeq,0) = 0 
     END    
    
    
    
    UPDATE A      
       SET Result       = '이미 종료되었습니다.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult AS A      
      JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                              AND B.QCSeq = A.InQCSeq  
                                              AND B.IsEnd = '1'  
     WHERE ISNULL(A.Status,0) = 0  
       AND A.WorkingTag = 'A'   
    
    
    UPDATE A      
       SET Result       = '이미 종료취소가 되었습니다.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult AS A      
      JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                              AND B.QCSeq = A.InQCSeq  
                                              AND B.IsEnd = '0'  
     WHERE ISNULL(A.Status,0) = 0  
       AND A.WorkingTag = 'D'   
    
    
    --------------------------------------------------------------------------------------  
    -- 체크, 입고조정 된 데이터는 종료 취소 할 수 없습니다.   
    --------------------------------------------------------------------------------------  
    CREATE TABLE #ProgTable ( IDX_NO INT, DelvSeq INT, DelvSerl INT )   
    INSERT INTO #ProgTable ( IDX_NO, DelvSeq, DelvSerl )   
    SELECT A.IDX_NO, A.DelvSeq, A.DelvSerl   
      FROM #KPX_TQCTestResult                   AS A   
      LEFT OUTER JOIN KPX_TQCTestResult         AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.InQCSeq )   
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl )   
     WHERE A.WorkingTag = 'D'   
       AND A.Status = 0   
       AND C.SMSourceType = 1000522008   
      
    CREATE TABLE #TMP_ProgressTable   
    (  
        IDOrder   INT,   
        TableName NVARCHAR(100)  
    )   
  
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName)   
    SELECT 1, '_TPUDelvInItem'   -- 데이터 찾을 테이블  
  
    CREATE TABLE #TCOMProgressTracking  
    (  
        IDX_NO  INT,    
        IDOrder  INT,   
        Seq      INT,   
        Serl     INT,   
        SubSerl  INT,   
        Qty      DECIMAL(19,5),   
        StdQty   DECIMAL(19,5),   
          Amt      DECIMAL(19,5),   
        VAT      DECIMAL(19,5)  
    )   
   
    EXEC _SCOMProgressTracking   
            @CompanySeq = @CompanySeq,   
            @TableName = '_TPUDelvItem',    -- 기준이 되는 테이블  
            @TempTableName = '#ProgTable',  -- 기준이 되는 템프테이블  
            @TempSeqColumnName = 'DelvSeq',  -- 템프테이블의 Seq  
            @TempSerlColumnName = 'DelvSerl',  -- 템프테이블의 Serl  
            @TempSubSerlColumnName = ''    
      
      
    UPDATE A  
       SET Result = '입고조정 된 데이터는 종료 취소 할 수 없습니다.',   
           Status = 1234,   
           MessageType = 1234   
      FROM #KPX_TQCTestResult               AS A   
      JOIN #TCOMProgressTracking            AS B ON ( B.IDX_NO = A.IDX_NO )   
      JOIN KPX_TPUDelvInQuantityAdjust      AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvInSeq = B.Seq AND C.DelvInSerl = B.Serl )   
    --------------------------------------------------------------------------------------  
    -- 체크, END   
    --------------------------------------------------------------------------------------  
    
    UPDATE A      
       SET Result       = '이동처리를 위해 ' + CASE WHEN B.SMTestResult <> 1010418002 THEN '생산사업장의 구매기본창고' ELSE '추가개발Mapping정보의 수입검사DATA 불합격품 이동창고' END + '를 등록해주십시오.',     
           MessageType  = @MessageType,      
           Status       = @Status      
      FROM #KPX_TQCTestResult AS A      
      LEFT OUTER JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                         AND B.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequest AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq  
                                                          AND C.ReqSeq = B.ReqSeq  
     WHERE ISNULL(A.Status,0) = 0  
       AND ( (ISNULL(B.SMTestResult,0) <> 1010418002 AND (EXISTS (SELECT TOP 1 1 FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND BizUnit = C.BizUnit AND ISNULL(WHSeq,0) = 0)))  
            OR (ISNULL(B.SMTestResult,0) = 1010418002 AND  (EXISTS (SELECT TOP 1 1 
                                                                          FROM _TDAWH AS H WITH(NOLOCK)  
                                                                          JOIN KPX_TCOMEnvItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq  
                                                                                                                AND I.EnvSeq = 49  
                                                                                                                AND I.EnvValue = H.WHSeq   
                                                                         WHERE H.CompanySeq = @CompanySeq AND H.BizUnit = C.BizUnit AND ISNULL(H.WHSeq,0) = 0
                                                                       )
                                                           )
               ) 
           )  
    
    -- 체크, 창고별품목등록 화면에 등록되지 않아 입고할 수 없습니다.  
    UPDATE A      
       SET Result       = '창고별품목등록 화면에 등록되지 않아 처리할 수 없습니다.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult           AS A   
      LEFT OUTER JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq AND B.DelvSerl = A.DelvSerl )   
      LEFT OUTER JOIN _TUIImpDelv       AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = B.DelvSeq )   
      OUTER APPLY (  
                   SELECT COUNT(1) AS Cnt   
                     FROM _TDAWHItem AS Z   
                     LEFT OUTER JOIN _TDAWH AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WHSeq = Z.WHSeq )   
                    WHERE Z.CompanySeq = @CompanySeq   
                      AND Z.ItemSeq = B.ItemSeq   
                      AND Y.BizUnit = D.BizUnit   
                 ) AS C   
      LEFT OUTER JOIN KPX_TQCTestResult         AS F ON F.CompanySeq = @CompanySeq AND F.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS E ON E.CompanySeq = @CompanySeq AND E.ReqSeq = F.ReqSeq AND E.ReqSerl = F.ReqSerl  
     WHERE ISNULL(C.Cnt,0) = 0   
       AND ISNULL(A.Status,0) = 0   
       AND E.SMSourceType = 1000522007  
       AND A.WorkingTag = 'A' 
    -- 체크, END   
    
    -- 체크, 창고별품목등록 화면에 여러 창고에 중복으로 등록되어 입고할 수 없습니다.  
      UPDATE A      
         SET Result       = '창고별품목등록 화면에 여러 창고에 중복으로 등록되어 처리할 수 없습니다.',     
             MessageType  = 1234,      
             Status       = 1234      
      FROM #KPX_TQCTestResult           AS A   
      LEFT OUTER JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq AND B.DelvSerl = A.DelvSerl )   
      LEFT OUTER JOIN _TUIImpDelv       AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = B.DelvSeq )   
      OUTER APPLY (  
                   SELECT COUNT(1) AS Cnt   
                     FROM _TDAWHItem AS Z   
                     LEFT OUTER JOIN _TDAWH AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WHSeq = Z.WHSeq )   
                    WHERE Z.CompanySeq = @CompanySeq   
                      AND Z.ItemSeq = B.ItemSeq   
                      AND Y.BizUnit = D.BizUnit   
                 ) AS C   
      LEFT OUTER JOIN KPX_TQCTestResult         AS F ON F.CompanySeq = @CompanySeq AND F.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS E ON E.CompanySeq = @CompanySeq AND E.ReqSeq = F.ReqSeq AND E.ReqSerl = F.ReqSerl  
     WHERE ISNULL(C.Cnt,0) > 1   
       AND ISNULL(A.Status,0) = 0    
       AND E.SMSourceType = 1000522007 
       AND A.WorkingTag = 'A' 
    -- 체크, END   
    
    
     SELECT * FROM #KPX_TQCTestResult   
     
 RETURN      
  GO
begin tran 
exec KPXCM_SQCInQCIResultNoTestCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <InQCNo />
    <ReqNo>201508260001</ReqNo>
    <SMTestResult>1010418001</SMTestResult>
    <SMTestResultName>합격</SMTestResultName>
    <InQCSeq>0</InQCSeq>
    <ItemSeq>133</ItemSeq>
    <ReqSeq>546</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <DelvNo>201509010002</DelvNo>
    <ItemName>EO(ETHYLENE OXIDE)</ItemName>
    <ItemNo>41120001</ItemNo>
    <LotNo>탱크로리LotNo</LotNo>
    <QCTypeName>수입검사(원료,상품)</QCTypeName>
    <TestDate>20151102</TestDate>
    <DeptSeq>241</DeptSeq>
    <OKQty>10</OKQty>
    <BadQty>0</BadQty>
    <SourceType>1</SourceType>
    <Qty>10</Qty>
    <ReqDate>20150826</ReqDate>
    <EmpSeq>1</EmpSeq>
    <CustName>경원기업</CustName>
    <DelvDate>20150901</DelvDate>
    <InOutType>국내</InOutType>
    <QCType>11</QCType>
    <DelvSeq>190</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <SMSourceType>1000522008</SMSourceType>
    <IsNoTest>0</IsNoTest>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030782,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026257
rollback 