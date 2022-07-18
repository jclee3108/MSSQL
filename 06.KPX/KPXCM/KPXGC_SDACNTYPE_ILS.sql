IF OBJECT_ID('KPXGC_SDACNTYPE_ILS') IS NOT NULL 
    DROP PROC KPXGC_SDACNTYPE_ILS
GO 

-- v2015.09.15 

/************************************************************
 설  명 - ILS연동-컨테이너
 작성일 - 2014.12.29
 작성자 - 전경만
************************************************************/
CREATE PROC KPXGC_SDACNTYPE_ILS

AS
    DECLARE @CompanySeq     INT,
            @Cnt            INT,
            @MaxCnt         INT,
            @MinorSeq       INT
    

    --SELECT IDENTITY(INT, 1,1) AS IDX, CompanySeq
    --  INTO #Company
    --  FROM _TCACompany
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    
    SELECT @CompanySeq = 1 
    
    SELECT @MinorSeq = MAX(MinorSeq) FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 1010302
    
    SELECT CONTCD, CNTNM, Work_Flag,
           CONVERT(INT, 0)          AS MinorSeq,
           CONVERT(INT, 0)          AS Serl,
           CONVERT(NCHAR(1), 'U')   AS WorkingTag,
           CONVERT(INT, 0)          AS Cnt
      INTO #CNType
      FROM CN_TYPE_IF
     WHERE Send_Flag = '0'
    
    -- KPX케미칼 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXCM.dbo.CN_TYPE_IF 
    SELECT CONTCD, CNTNM, WORK_FLAG, SEND_FLAG
      FROM CN_TYPE_IF
     WHERE Send_Flag = '0'
    
    /*
    -- KPX라이프사이언스 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXLS.dbo.CN_TYPE_IF 
    SELECT CONTCD, CNTNM, WORK_FLAG, SEND_FLAG
      FROM CN_TYPE_IF
     WHERE Send_Flag = '0'
     
    -- KPX홀딩스 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXHD.dbo.CN_TYPE_IF 
    SELECT CONTCD, CNTNM, WORK_FLAG, SEND_FLAG
      FROM CN_TYPE_IF
     WHERE Send_Flag = '0'
    */
    
    UPDATE A
       SET MinorSeq = V.MinorSeq,
           Serl     = D.TitleSerl,
           WorkingTag = CASE WHEN ISNULL(V.MinorSeq, 0) = 0 THEN 'A'
                             ELSE 'U' END
      FROM #CNType AS A
           LEFT OUTER JOIN _TCOMUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                            AND D.TableName = '_TDAUMajor'
                                                            AND D.DefineUnitSeq = 1010302
                                                            AND D.QrySort = 1
           LEFT OUTER JOIN _TDAUMinorValue AS V ON V.CompanySeq = @CompanySeq
                                              AND V.MajorSeq = 1010302
                                              AND V.Serl = D.TitleSerl
                                              AND RTRIM(V.ValueText) = RTRIM(A.CONTCD)


    SELECT *,  Row_NUMBER() OVER(ORDER BY CONTCD ) AS IDX
      INTO #Loc
      FROM #CNType
     WHERE ISNULL(MinorSeq, 0) = 0
    
    UPDATE A
       SET Cnt = B.IDX,
           MinorSeq = @MinorSeq+B.IDX
      FROM #CNType AS A
           JOIN #Loc AS B ON B.CONTCD = A.CONTCD
--select * from #Loc
--select * from #CNType

    
    UPDATE A
       SET MinorName = B.CNTNM,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinor AS A
           JOIN #CNType AS B ON B.MinorSeq = A.MinorSeq
                              AND B.WorkingTag = 'U' 
     WHERE CompanySeq = @CompanySeq 
           
    INSERT INTO _TDAUMinor(CompanySeq, MinorSeq, MajorSeq, MinorName, 
                           MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse)
         SELECT @CompanySeq, A.MinorSeq, 1010302, A.CNTNM,
                CONVERT(INT, RIGHT(CONVERT(NVARCHAR(100), A.MinorSeq), 3)), '', 0, 1, GETDATE(), '1'
           FROM #CNType AS A
          WHERE A.WorkingTag = 'A'
    
    UPDATE A
       SET ValueText = B.CONTCD,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinorValue AS A
           JOIN #CNType AS B ON B.MinorSeq = A.MinorSeq
                              AND B.Serl = A.Serl
                              AND B.WorkingTag = 'U' 
     WHERE A.CompanySeq = @CompanySeq 
      
    INSERT INTO _TDAUMinorValue(CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime)
         SELECT @CompanySeq, A.MinorSeq, A.Serl, 1010302, 0, A.CONTCD, 1, GETDATE()
           FROM #CNType AS A
          WHERE A.WorkingTag = 'A'


    UPDATE A
       SET SEND_FLAG = '1'
      FROM CN_TYPE_IF AS A
           JOIN #CNType AS B ON B.CONTCD = A.CONTCD --AND A.Cust_GRP = B.Cust_GRP
    
RETURN
GO
