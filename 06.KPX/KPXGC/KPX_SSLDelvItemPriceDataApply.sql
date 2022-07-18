  
IF OBJECT_ID('KPX_SSLDelvItemPriceDataApply') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceDataApply  
GO  
  
-- v2015.02.02
  
-- 거래처별납품처단가등록-적용일 적용 by 이재천
CREATE PROC KPX_SSLDelvItemPriceDataApply  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            @DVItemPriceSeq INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DVItemPriceSeq   = ISNULL( DVItemPriceSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (DVItemPriceSeq INT)    
        
    
    CREATE TABLE #TEMP   
    (  
        IDX_NO          INT IDENTITY,   
        DVItemPriceSeq  INT,   
        SDate           NCHAR(8),   
        EDate           NCHAR(8),   
        StdDate         NCHAR(8)   
    )  
    INSERT INTO #TEMP(DVItemPriceSeq, SDate, EDate, StdDate)  
    SELECT A.DVItemPriceSeq, A.SDate, A.EDate, A.StdDate   
      FROM KPX_TSLDelvItemPrice AS A   
     WHERE EXISTS (SELECT 1   
                     FROM KPX_TSLDelvItemPrice AS Z   
                    WHERE Z.CompanySeq = @CompanySeq   
                      AND Z.DVItemPriceSeq = @DVItemPriceSeq  
                      AND Z.CustSeq = A.CustSeq   
                      AND Z.DVPlaceSeq = A.DVPlaceSeq  
                      AND Z.ItemSeq = A.ItemSeq   
                      AND Z.UnitSeq = A.UnitSeq   
                      AND Z.CurrSeq = A.CurrSeq   
                  )   
     ORDER BY StdDate   
      
    UPDATE A   
       SET SDate = StdDate   
      FROM #TEMP AS A   
       
    DECLARE @Cnt INT   
      
    SELECT @Cnt = 1   
      
    WHILE ( 1 = 1 )   
    BEGIN  
          
        UPDATE A   
           SET A.EDate = ISNULL(B.EDate, '99991231')  
          FROM #TEMP AS A   
          OUTER APPLY (SELECT CONVERT(NCHAR(8),DATEADD(Day, -1, Z.StdDate),112) AS EDate   
                         FROM #TEMP AS Z  
                        WHERE Z.IDX_NO = @Cnt + 1   
                      ) AS B   
         WHERE IDX_NO = @Cnt   
        
        IF @Cnt = (SELECT MAX(IDX_NO) FROM #TEMP)  
        BEGIN  
            BREAK   
        END  
        ELSE   
        BEGIN  
            SELECT @Cnt = @Cnt + 1   
        END    
          
    END   
    
    UPDATE B   
       SET B.SDate = A.SDate,   
           B.EDate = A.EDate   
      FROM #TEMP AS A   
      JOIN KPX_TSLDelvItemPrice AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DVItemPriceSeq = A.DVItemPriceSeq )   
        
    RETURN  