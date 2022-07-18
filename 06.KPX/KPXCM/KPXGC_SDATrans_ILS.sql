IF OBJECT_ID('KPXGC_SDATrans_ILS') IS NOT NULL 
    DROP PROC KPXGC_SDATrans_ILS
GO 

-- v2015.09.15 

/************************************************************
 설  명 - ILS연동-배정기준
 작성일 - 2014.12.29
 작성자 - 전경만
************************************************************/
CREATE PROC KPXGC_SDATrans_ILS

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
    
    SELECT @CompanySeq = 1 
    
    SELECT @MaxMinorSeq = MAX(MinorSeq) 
      FROM _TDAUMinor 
     WHERE CompanySeq = @CompanySeq 
       AND MajorSeq = 1010473  

    SELECT @CompanySeq AS CompanySeq,
           Cust_GRP,
           TransSeq, TransName, Work_Flag,
           CONVERT(INT, 0)          AS MinorSeq,
           CONVERT(INT, 0)          AS Serl,
           CONVERT(NCHAR(1), 'U')   AS WorkingTag,
           CONVERT(INT, 0)          AS Cnt
      INTO #Trans
      FROM Trans_IF
     WHERE Send_Flag = '0' 
       AND RTRIM(LTRIM(CUST_GRP)) = '30'  
    
    -- KPX케미칼 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXCM.dbo.Trans_IF 
    SELECT TransSeq, TransName, WORK_FLAG, SEND_FLAG, Cust_GRP
      FROM Trans_IF
     WHERE Send_Flag = '0' 
       AND RTRIM(LTRIM(CUST_GRP)) = '10'
    
    /*
    -- KPX라이프사이언스 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXLS.dbo.Trans_IF 
    SELECT TransSeq, TransName, WORK_FLAG, SEND_FLAG, Cust_GRP
      FROM Trans_IF
     WHERE Send_Flag = '0' 
       AND RTRIM(LTRIM(CUST_GRP)) = '40' 
     
    -- KPX홀딩스 DB 데이터 연동 -- 2015.09.15 이재천 추가 
    INSERT INTO KPXHD.dbo.Trans_IF 
    SELECT TransSeq, TransName, WORK_FLAG, SEND_FLAG, Cust_GRP
      FROM Trans_IF
     WHERE Send_Flag = '0' 
       AND RTRIM(LTRIM(CUST_GRP)) = '00' 
    */
    
    
    
    UPDATE A
       SET MinorSeq = V.MinorSeq,
           Serl     = D.TitleSerl,
           WorkingTag = CASE WHEN ISNULL(V.MinorSeq, 0) = 0 THEN 'A'
                             ELSE 'U' END
--select *
      FROM #Trans AS A
           LEFT OUTER JOIN _TCOMUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq
                                                            AND D.TableName = '_TDAUMajor'
                                                            AND D.DefineUnitSeq = 1010473
                                                            AND D.QrySort = 1
           LEFT OUTER JOIN _TDAUMinorValue AS V ON V.CompanySeq = A.CompanySeq
                                              AND V.MajorSeq = 1010473
                                              AND V.Serl = D.TitleSerl
                                              AND RTRIM(V.ValueText) = RTRIM(A.TransSeq)

--select * from _TDAUMinorValue where Companyseq = 1 and majorseq = 1010473 and serl = 1000001
    SELECT *,  Row_NUMBER() OVER(ORDER BY TransSeq ) AS IDX
      INTO #Loc
      FROM #Trans
     WHERE ISNULL(MinorSeq, 0) = 0 
       AND CompanySeq = @CompanySeq 
--print 1

    UPDATE A
       SET Cnt = B.IDX,
           MinorSeq = @MaxMinorSeq + B.IDX
      FROM #Trans AS A
           JOIN #Loc AS B ON B.TransSeq = A.TransSeq
     WHERE A.CompanySeq = @CompanySeq 
    
--select * from #Loc
--select * from #Trans
--return
    --UPDATE A
    --   SET MinorSeq

    
    --SELECT @Cnt = 1, @MaxCnt = MAX(IDX) FROM #Company
    --WHILE(1=1)
    --BEGIN
    
    UPDATE A
       SET MinorName = B.TransName,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinor AS A
           JOIN #Trans AS B ON B.MinorSeq = A.MinorSeq
                              AND B.WorkingTag = 'U' 
                              AND B.CompanySeq = A.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq 
           
    INSERT INTO _TDAUMinor(CompanySeq, MinorSeq, MajorSeq, MinorName, 
                       MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse)
    SELECT A.CompanySeq, A.MinorSeq, 1010473, A.TransName,
            CONVERT(INT, RIGHT(CONVERT(NVARCHAR(100), A.MinorSeq), 3)), '', 0, 1, GETDATE(), '1'
      FROM #Trans AS A
     WHERE A.WorkingTag = 'A' 
       AND A.CompanySeq = @CompanySeq 
    
    UPDATE A
       SET ValueText = B.TransSeq,
           LastUserSeq = 1,
           LastDateTime = GETDATE()
      FROM _TDAUMinorValue AS A
           JOIN #Trans AS B ON B.MinorSeq = A.MinorSeq
                              AND B.Serl = A.Serl
                              AND B.WorkingTag = 'U' 
                              AND B.CompanySeq = A.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq 
      
    INSERT INTO _TDAUMinorValue(CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime)
         SELECT A.CompanySeq, A.MinorSeq, A.Serl, 1010473, 0, A.TransSeq, 1, GETDATE()
           FROM #Trans AS A
          WHERE A. WorkingTag = 'A' 
            AND A.CompanySeq = @CompanySeq 
    
    
    UPDATE A
       SET SEND_FLAG = '1'
      FROM Trans_IF AS A
           JOIN #Trans AS B ON B.TransSeq = A.TransSeq AND A.Cust_GRP = B.Cust_GRP
RETURN

----alter table Trans_IF add Cust_GRP NCHAR(2)
--BEGIN TRAN
--insert into Trans_IF
--select '300', '서울시 강서', 'U','0','30'
--union all
--select '200', '서울시 강서1', 'U','0','30'
----union all
----select 111, '서울시', 'U','0'
--EXEC KPX_SDATrans_ILS

--select * from _TDAUMinor where companyseq =1 and majorseq = 1010473
--select * from _TDAUMinorvalue where companyseq = 1 and majorseq = 1010473
--ROLLBACK TRAN

----select * from Trans_IF

----select * from _TDAUmajor where companyseq = 1 and majorname like '%지역%'
--GO
