IF OBJECT_ID('daehan_SMESDataOpenQuery_oracle') IS NOT NULL 
    DROP PROC daehan_SMESDataOpenQuery_oracle
GO 

-- v2018.05.25 

-- 날짜 기간으로 조회 될 수 있도록 반영 by이재천 
CREATE PROC daehan_SMESDataOpenQuery_oracle(@CompanySeq INT, @WorkDateFr NCHAR(8), @WorkDateTo NCHAR(8))
 AS     
 declare @Sql nvarchar(3000), @OpenSql nvarchar(2000), @DateFr       NVARCHAR(20), @DateTo NVARCHAR(20)
     
 --set @WorkDate = '20160102'    
 SELECT @DateFr = LEFT(@WorkDateFr,4)+'-'+SUBSTRING(@WorkDateFr,5,2)+'-'+RIGHT(@WorkDateFr,2)    
 SELECT @DateTo = LEFT(@WorkDateTo,4)+'-'+SUBSTRING(@WorkDateTo,5,2)+'-'+RIGHT(@WorkDateTo,2)    
SET @Sql = 'SELECT	A.COMPCODE, C.CODEERP, ''''한라엔컴(주)골재_''''||C.COMPNAME AS COMPNAME, TRIM(TO_CHAR(A.SALE_DATE, ''''YYYY-MM-DD'''')) AS SALEDATE, TRIM(TO_CHAR(A.PRESALE_SEQ, ''''000'''')) AS PRESALE_SEQ,
                    A.CUSTNAME, A.SITENAME, B.PRE_QTY, 
					A.SPECNAME, 
					TO_CHAR(A.SEND_NO, ''''000'''') AS SEND_NO, TO_CHAR(A.SALE_TIME, ''''HH24:MI'''') AS SALE_TIME, SALE_QTY,
					SUM(A.SALE_QTY) OVER (PARTITION BY A.COMPCODE, A.SALE_DATE, A.PRESALE_SEQ ORDER BY A.SEND_NO) AS SALE_SUM, 
					1, 
					SUM(1) OVER (PARTITION BY A.COMPCODE, A.SALE_DATE, A.PRESALE_SEQ ORDER BY A.SEND_NO) AS SALE_COUNT, 
					A.VEHICLE_CODE, A.VEHICLE_NO
            FROM    G_EXPORT_REALTIME A
            	LEFT OUTER JOIN G_ESTIMATE_REALTIME B ON A.COMPCODE = B.COMPCODE AND A.PRESALE_DATE = B.PRESALE_DATE AND A.PRESALE_SEQ = B.SEQ
				JOIN G_CODE_COMPANY C ON A.COMPCODE = C.COMPCODE AND C.REALTIME_ERP = ''''Y''''
            WHERE  A.SALE_DATE  BETWEEN ''''' + @DateFr + '''''' + 'AND ''''' + @DateTo + ''''''
     
     SET @OpenSql = 'SELECT * FROM OPENQUERY( TONGHAP_DAEHAN,'''+@Sql+'''   )'
     EXEC(@OpenSql)    
     
RETURN