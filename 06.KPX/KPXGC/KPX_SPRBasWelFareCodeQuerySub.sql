  
IF OBJECT_ID('KPX_SPRBasWelFareCodeQuerySub') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeQuerySub  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-Item조회 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @WelCodeSeq INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WelCodeSeq   = ISNULL( WelCodeSeq, 0 )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WelCodeSeq   INT)    
    
    -- 최종조회   
    SELECT A.WelCodeSeq, 
           A.WelCodeSerl, 
           A.YY, 
           A.RegName, 
           A.DateFr, 
           A.DateTo, 
           A.EmpAmt
      FROM KPX_THRWelCodeYearItem AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WelCodeSeq = @WelCodeSeq 
      ORDER BY A.WelCodeSerl  
    
    RETURN  