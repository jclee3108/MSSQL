  
IF OBJECT_ID('KPX_SPRBasWelFareCodeCreate') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeCreate  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-기간생성 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeCreate  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle          INT,  
            -- 조회조건   
            @YY                 NCHAR(4), 
            @SubWelCodeName     NVARCHAR(100), 
            @SMRegType          INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YY  = ISNULL( YY, '' ), 
           @SubWelCodeName = ISNULL( SubWelCodeName, '' ), 
           @SMRegType = ISNULL( SMRegType, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            YY                 NCHAR(4), 
            SubWelCodeName     NVARCHAR(100),
            SMRegType          INT 
           )   
    
    IF @SMRegType = 3226001 
    BEGIN
        SELECT @YY AS YY, 
               @YY + ' 1월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 1 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 2월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo,
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 2 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 3월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 3 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 4월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 4 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 5월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 5 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 6월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 6 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 7월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 7 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 8월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 8 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 9월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 9 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 10월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 10 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 11월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 11 
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 12월 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                  FROM _TCOMCalendar AS Z 
                 WHERE Z.SYear = @YY 
                   AND Z.SMonth = 12 
               ) AS A 
    END 
    ELSE 
    BEGIN 
        SELECT @YY AS YY, 
               @YY + ' 1분기 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                 FROM _TCOMCalendar AS Z 
                WHERE Z.SYear = @YY 
                  AND Z.SQuarter0 = 1
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 2분기 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                 FROM _TCOMCalendar AS Z 
                WHERE Z.SYear = @YY 
                  AND Z.SQuarter0 = 2
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 3분기 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                 FROM _TCOMCalendar AS Z 
                WHERE Z.SYear = @YY 
                  AND Z.SQuarter0 = 3
               ) AS A 
        
        UNION ALL
        
        SELECT @YY AS YY, 
               @YY + ' 4분기 ' + @SubWelCodeName AS RegName, 
               A.DateFr, 
               A.DateTo, 
               0 AS Status 
          FROM (SELECT MIN(Solar) DateFr, MAX(Solar) DateTo 
                 FROM _TCOMCalendar AS Z 
                WHERE Z.SYear = @YY 
                  AND Z.SQuarter0 = 4
               ) AS A  
    END 
    
    RETURN  
GO 
exec KPX_SPRBasWelFareCodeCreate @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <SubWelCodeName>11</SubWelCodeName>
    <SubWelCodeSeq>9</SubWelCodeSeq>
    <YY>2014</YY>
    <SMRegType>3226002</SMRegType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026356,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021406