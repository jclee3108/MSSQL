IF OBJECT_ID('daehan_SMESDataOpenQuery') IS NOT NULL 
    DROP PROC daehan_SMESDataOpenQuery
GO 

-- v2018.05.25 

-- 날짜 기간으로 조회 될 수 있도록 반영 by이재천 

CREATE PROC daehan_SMESDataOpenQuery(@CompanySeq INT, @WorkDateFr NCHAR(8), @WorkDateTo NCHAR(8))
 AS     
 declare @Sql nvarchar(3000), @OpenSql nvarchar(2000), @DateFr  NVARCHAR(20), @DateTo NVARCHAR(20)
     
 --set @WorkDate = '20160102'    
 SELECT @DateFr = LEFT(@WorkDateFr,4)+'-'+SUBSTRING(@WorkDateFr,5,2)+'-'+RIGHT(@WorkDateFr,2)
 SELECT @DateTo = LEFT(@WorkDateTo,4)+'-'+SUBSTRING(@WorkDateTo,5,2)+'-'+RIGHT(@WorkDateTo,2)

SET @Sql = 'SELECT	A.HC01PGBN, C.CODEERP, C.TRADE, A.HC01DATE, A.HC01SEQ, A.HC01TRNM, A.HC01SPNM, A.HC01YQTY, D.HM01SZNM
                   , B.HC02SEQ, B.HC02TIME, B.HC02QTY, B.HC02ADDQTY, B.HC02CNT, B.HC02ADDCNT, B.HC02CRCD, B.HC02CRNO
            FROM   HSC001 A
            	LEFT OUTER JOIN HSC002 B ON A.HC01PGBN = HC02PGBN AND A.HC01DATE = B.HC02DATE AND A.HC01SEQ = B.HC02PLSEQ
				           JOIN REGIST C ON A.HC01PGBN = C.CODE
				LEFT OUTER JOIN HSM001 D ON A.HC01PGBN = D.HM01PGBN AND A.HC01SZCD = D.HM01CODE
            WHERE  A.HC01DATE BETWEEN ''''' + @DateFr + '''''' + 'AND ''''' + @DateTo + ''''''
     
     SET @OpenSql = 'SELECT * FROM OPENQUERY( NISSOG,'''+@Sql+'''   )'
     EXEC(@OpenSql)    
     
RETURN
