
IF OBJECT_ID('KPX_SDAItemApplyCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemApplyCheck
GO 

-- v2014.11.05 

-- 확정(패키지반영체크) by이재천
CREATE PROC KPX_SDAItemApplyCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TDAItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItem'     
    
    IF @@ERROR <> 0 RETURN      
    
    DECLARE @MessageType INT, 
            @Status      INT, 
            @Results     NVARCHAR(200) 
      
    IF EXISTS (SELECT 1
                FROM #KPX_TDAItem AS A 
                JOIN _TDAItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
              )
    BEGIN 
    
        UPDATE A
           SET Result = '확정 된 데이터입니다. 다시 조회 해주세요.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TDAItem AS A 
    END 
    
    SELECT * FROM #KPX_TDAItem 
    
    RETURN 
GO 
