
IF OBJECT_ID('KPX_SDAUMinorSave') IS NOT NULL 
    DROP PROC KPX_SDAUMinorSave
GO  

-- v2014.12.01 

-- 법인통합 by이재천

/***********************************************************
  설  명 - 사용자정의기타코드(소분류) 저장
  작성일 - 2008.7.30 :
  작성자 - CREATEd by 신국철
  수정자 - 
 ************************************************************/
  -- SP파라미터들
 CREATE PROCEDURE KPX_SDAUMinorSave
     @xmlDocument NVARCHAR(MAX)   ,    -- : 화면의 정보를 XML문서로 전달
     @xmlFlags    INT = 0         ,    -- : 해당 XML문서의 Type
     @ServiceSeq  INT = 0         ,    -- : 서비스 번호
     @WorkingTag  NVARCHAR(10)= '',    -- : WorkingTag
     @CompanySeq  INT = 1         ,    -- : 회사 번호
     @LanguageSeq INT = 1         ,    -- : 언어 번호
     @UserSeq     INT = 0         ,    -- : 사용자 번호
     @PgmSeq      INT = 0              -- : 프로그램 번호
  AS
      -- 서비스 마스터 등록 생성
     CREATE TABLE #TDAUMinor (WorkingTag NCHAR(1) NULL)
      -- 임시 테이블에 지정된 컬럼을 추가하고, XML문서로부터의 값을 INSERT한다.
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMinor'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- 에러가 발생하면 리턴
     END
  
  
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq ,
                    @UserSeq    ,
                    '_TDAUMinor',    -- 원테이블명
                    '#TDAUMinor',    -- 템프테이블명
                    'MinorSeq'  ,    -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq, MinorSeq, MajorSeq, MinorName, MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse'    -- 원테이블의 컬럼들
  
    
    IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        EXEC _SCOMLog  @CompanySeq      ,
                        @UserSeq         ,
                        '_TDAUMinorValue',    -- 원테이블명
                        '#TDAUMinor'     ,    -- 템프테이블명
                        'MinorSeq'       ,    -- 키가 여러개일 경우는 , 로 연결한다.
                        'CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime'    -- 원테이블의 컬럼들
      END
    
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
          -- 디테일 삭제
         DELETE _TDAUMinorValue
            FROM _TDAUMinorValue AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                         AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'D' AND B.Status = 0)
            --AND  A.CompanySeq = @CompanySeq
  
  
          -- 마스터 삭제
         DELETE _TDAUMinor
            FROM _TDAUMinor AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                    AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'D' AND B.Status = 0)
            --AND  A.CompanySeq = @CompanySeq
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- 에러가 발생하면 리턴
         END
      END
  
  
   
     -- UPDATE
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
          UPDATE _TDAUMinor
             SET MinorName    = B.MinorName, MinorSort = B.MinorSort, Remark      = B.Remark,    -- 소분류명, 순서    , 비고  ,
                IsUse        = B.IsUse    , WordSeq   = B.WordSeq  , LastUserSeq = @UserSeq,    -- 사용여부, 사전코드, 작업자,
                LastDateTime = GETDATE()                                                        -- 작업일시
            FROM _TDAUMinor AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                    AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'U' AND B.Status = 0)
            --AND A.CompanySeq = @CompanySeq
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- 에러가 발생하면 리턴
         END
      END
  
  
      -- INSERT
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'A' AND Status = 0)
        AND @WorkingTag <> 'D'   --쉬트삭제할때 아무것도 없는 데이터의 WorkingTag가 A인것이 들어올때가 있다
     BEGIN
          INSERT _TDAUMinor (CompanySeq, MinorSeq , MajorSeq   ,
                            MinorName , MinorSort, Remark     ,
                            Isuse     , WordSeq  , LastUserSeq,
            LastDateTime)
          SELECT DISTINCT
                B.CompanySeq          AS CompanySeq , ISNULL(MinorSeq ,  0) AS MinorSeq ,
                ISNULL(MajorSeq ,  0) AS MajorSeq   , ISNULL(MinorName, '') AS MinorName,
                ISNULL(MinorSort, '') AS MinorSort  , ISNULL(Remark   , '') AS Remark   ,
                '1'                   AS IsUse      , ISNULL(WordSeq  ,  0) AS WordSeq  ,
                @UserSeq              AS LastUserSeq, GETDATE()             AS LastDateTime
            FROM #TDAUMinor AS A 
            JOIN _TCACompany AS B ON ( 1 = 1 ) 
           WHERE (WorkingTag = 'A' AND Status = 0)
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- 에러가 발생하면 리턴
         END
    END
    
    SELECT * FROM #TDAUMinor    -- Output
    
    RETURN
GO 

begin tran 
exec KPX_SDAUMinorSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>0</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <MajorSeq>9016</MajorSeq>
    <MinorName>ttt</MinorName>
    <MinorSeq>9016001</MinorSeq>
    <MinorSort>1</MinorSort>
    <Remark />
    <WordSeq>0</WordSeq>
    <RowNum>0</RowNum>
    <IsUse>0</IsUse>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <MajorSeq>9016</MajorSeq>
    <MinorName>ttt1</MinorName>
    <MinorSeq>9016002</MinorSeq>
    <MinorSort>2</MinorSort>
    <Remark />
    <WordSeq>0</WordSeq>
    <RowNum>1</RowNum>
    <IsUse>0</IsUse>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026339,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020436

--select * from _TDAUMinor where majorseq = 9016 
rollback 