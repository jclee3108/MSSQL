IF OBJECT_ID('KPXCM_SDAPORT_ILS') IS NOT NULL 
    DROP PROC KPXCM_SDAPORT_ILS
GO 

-- v2015.09.15 

/************************************************************
 설  명 - ILS연동-항구
 작성일 - 2014.12.29
 작성자 - 전경만
************************************************************/
CREATE PROC KPXCM_SDAPORT_ILS

AS
    DECLARE @CompanySeq     INT,
            @Cnt            INT,
            @MaxCnt         INT,
            @MinorSeq       INT, 
            @MaxMinorSeq    INT 
    

    --SELECT IDENTITY(INT, 1,1) AS IDX, CompanySeq
    --  INTO #Company
    --  FROM _TCACompany
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    
    --SELECT @CompanySeq = CompanySeq FROM #Company WHERE IDX = @Cnt 
    
    SELECT @CompanySeq = 2  
    
    SELECT @MaxMinorSeq = MAX(MinorSeq) 
      FROM _TDAUMinor 
     WHERE CompanySeq = @CompanySeq 
       AND MajorSeq = 8207  
    
    
    SELECT @CompanySeq AS CompanySeq,  
           Cust_GRP,
           COMM_ID, COMM_NM, Work_Flag,
           CONVERT(INT, 0)          AS MinorSeq,
           CONVERT(INT, 0)          AS Serl, 
           CONVERT(NCHAR(1), 'U')   AS WorkingTag, 
           CONVERT(INT, 0)          AS Cnt 
      INTO #Port 
      FROM PORT_IF 
     WHERE Send_Flag = '0' 
       AND RTRIM(LTRIM(CUST_GRP)) = '10' 
    
    UPDATE A
       SET MinorSeq = V.MinorSeq,
           Serl     = D.TitleSerl,
           WorkingTag = CASE WHEN ISNULL(V.MinorSeq, 0) = 0 THEN 'A'
                             ELSE 'U' END
      FROM #Port AS A
           LEFT OUTER JOIN _TCOMUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq 
                                                            AND D.TableName = '_TDAUMajor'
                                                            AND D.DefineUnitSeq = 8207
                                                            AND D.QrySort = 1 
           LEFT OUTER JOIN _TDAUMinorValue AS V ON V.CompanySeq = A.CompanySeq 
                                              AND V.MajorSeq = 8207 
                                              AND V.Serl = D.TitleSerl 
                                              AND RTRIM(V.ValueText) = RTRIM(A.COMM_ID) 

--select * from _TDAUMinorValue where Companyseq = 1 and majorseq = 8207 and serl = 1000001
    SELECT *,  Row_NUMBER() OVER(ORDER BY COMM_ID ) AS IDX
      INTO #Loc
      FROM #Port
     WHERE ISNULL(MinorSeq, 0) = 0 
       AND CompanySeq = @CompanySeq 
--print 1

    UPDATE A
       SET Cnt = B.IDX,
           MinorSeq = @MaxMinorSeq + B.IDX
      FROM #Port AS A
           JOIN #Loc AS B ON B.COMM_ID = A.COMM_ID 
     WHERE A.CompanySeq = @CompanySeq 
    
           
--select * from #Loc
--select * from #Port
--return
    --UPDATE A
    --   SET MinorSeq

    
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    --WHILE(1=1)
    --BEGIN
    
    UPDATE A
       SET MinorName = B.COMM_NM,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinor AS A
           JOIN #Port AS B ON B.MinorSeq = A.MinorSeq
                          AND B.WorkingTag = 'U' 
                          AND B.CompanySeq = A.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq 
           
    INSERT INTO _TDAUMinor(CompanySeq, MinorSeq, MajorSeq, MinorName, 
                           MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse)
    SELECT A.CompanySeq, A.MinorSeq, 8207, A.COMM_NM,
           CONVERT(INT, RIGHT(CONVERT(NVARCHAR(100), A.MinorSeq), 3)), '', 0, 1, GETDATE(), '1'
      FROM #Port AS A
     WHERE A.WorkingTag = 'A' 
       AND A.CompanySeq = @CompanySeq 
    
    UPDATE A
       SET ValueText = B.COMM_ID,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinorValue AS A
           JOIN #Port AS B ON B.MinorSeq = A.MinorSeq
                          AND B.Serl = A.Serl
                          AND B.WorkingTag = 'U' 
                          AND B.CompanySeq = A.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq  
      
    INSERT INTO _TDAUMinorValue(CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime)
         SELECT A.CompanySeq, A.MinorSeq, A.Serl, 8207, 0, A.COMM_ID, 1, GETDATE()
           FROM #Port AS A
          WHERE A.WorkingTag = 'A' 
            AND A.CompanySeq = @CompanySeq 
    
    UPDATE A
       SET SEND_FLAG = '1'
      FROM PORT_IF AS A 
           JOIN #Port AS B ON B.COMM_ID = A.COMM_ID AND A.Cust_GRP = B.Cust_GRP
           
    UPDATE A
       SET SEND_FLAG = '1'
      FROM KPXERP.DBO.PORT_IF AS A 
           JOIN #Port AS B ON B.COMM_ID = A.COMM_ID AND A.Cust_GRP = B.Cust_GRP
           
RETURN
GO 