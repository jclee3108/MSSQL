IF OBJECT_ID('KPXCM_SDALOCATION_ILS') IS NOT NULL 
    DROP PROC KPXCM_SDALOCATION_ILS
GO 

-- v2015.09.15 

/************************************************************
 설  명 - ILS연동-배송지역
 작성일 - 2014.12.29
 작성자 - 전경만
************************************************************/
CREATE PROC KPXCM_SDALOCATION_ILS
    
AS
    DECLARE @CompanySeq     INT,
            @MaxCnt         INT,
            @MinorSeq       INT
    

    --SELECT IDENTITY(INT, 1,1) AS IDX, CompanySeq
    --  INTO #Company
    --  FROM _TCACompany
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    
    --SELECT @CompanySeq = CompanySeq FROM #Company WHERE IDX = @Cnt 
    SELECT @CompanySeq = 2 
    
    SELECT @MinorSeq = MAX(MinorSeq) FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8006
    
    SELECT Loc_CD, Loc_NM, Work_Flag,
           CONVERT(INT, 0)          AS MinorSeq,
           CONVERT(INT, 0)          AS Serl,
           CONVERT(NCHAR(1), 'U')   AS WorkingTag,
           CONVERT(INT, 0)          AS Cnt
      INTO #Location
      FROM LOCATION_IF
     WHERE Send_Flag = '0' 
    
    
    UPDATE A
       SET MinorSeq = V.MinorSeq,
           Serl     = D.TitleSerl,
           WorkingTag = CASE WHEN ISNULL(V.MinorSeq, 0) = 0 THEN 'A'
                             ELSE 'U' END
      FROM #Location AS A
           LEFT OUTER JOIN _TCOMUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                            AND D.TableName = '_TDAUMajor'
                                                            AND D.DefineUnitSeq = 8006
                                                            AND D.QrySort = 1
           LEFT OUTER JOIN _TDAUMinorValue AS V ON V.CompanySeq = @CompanySeq
                                              AND V.MajorSeq = 8006
                                              AND V.Serl = D.TitleSerl
                                              AND RTRIM(V.ValueText) = RTRIM(A.Loc_CD)

--select * from _TDAUMinorValue where Companyseq = @companyseq and majorseq = 8006 and serl = 1000001
    SELECT *,  Row_NUMBER() OVER(ORDER BY Loc_CD ) AS IDX
      INTO #Loc
      FROM #Location
     WHERE ISNULL(MinorSeq, 0) = 0
    
    UPDATE A
       SET Cnt = B.IDX,
           MinorSeq = @MinorSeq+B.IDX
      FROM #Location AS A
           JOIN #Loc AS B ON B.Loc_Cd = A.Loc_Cd
--select * from #Loc
--select * from #Location
    
    --UPDATE A
    --   SET MinorSeq

    
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    --WHILE(1=1)
    --BEGIN
    
    UPDATE A
       SET MinorName = B.Loc_NM,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinor AS A
           JOIN #Location AS B ON B.MinorSeq = A.MinorSeq
                              AND B.WorkingTag = 'U' 
     WHERE A.CompanySeq = @CompanySeq 
           
    INSERT INTO _TDAUMinor(CompanySeq, MinorSeq, MajorSeq, MinorName, 
                           MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse)
         SELECT @CompanySeq, A.MinorSeq, 8006, A.Loc_NM,
                CONVERT(INT, RIGHT(CONVERT(NVARCHAR(100), A.MinorSeq), 3)), '', 0, 1, GETDATE(), '1'
           FROM #Location AS A
          WHERE A.WorkingTag = 'A'
    
    UPDATE A
       SET ValueText = B.Loc_CD,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinorValue AS A
           JOIN #Location AS B ON B.MinorSeq = A.MinorSeq
                              AND B.Serl = A.Serl
                              AND B.WorkingTag = 'U'
     WHERE A.CompanySeq = @CompanySeq 
      
    INSERT INTO _TDAUMinorValue(CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime)
         SELECT @CompanySeq, A.MinorSeq, A.Serl, 8006, 0, A.Loc_CD, 1, GETDATE()
           FROM #Location AS A
          WHERE A.WorkingTag = 'A'
    
    UPDATE A
       SET SEND_FLAG = '1'
      FROM LOCATION_IF AS A
           JOIN #Location AS B ON B.LOC_CD = A.LOC_CD --AND A.Cust_GRP = B.Cust_GRP
    
RETURN
GO