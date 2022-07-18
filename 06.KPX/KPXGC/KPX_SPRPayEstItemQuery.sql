  
IF OBJECT_ID('KPX_SPRPayEstItemQuery') IS NOT NULL   
    DROP PROC KPX_SPRPayEstItemQuery  
GO  
  
-- v2014.12.15  
  
-- 급여추정항목설정-조회 by 이재천   
CREATE PROC KPX_SPRPayEstItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq   = ISNULL( ItemSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ItemSeq   INT)    
    
    -- 최종조회   
    SELECT A.ItemSeq, 
           B.ItemName,
           A.IsBase, 
           A.IsFix, 
           A.IsWkLink, 
           A.IsEst, 
           A.ItemSeq AS ItemSeqOld 
      FROM KPX_TPRPayEstItem AS A 
      LEFT OUTER JOIN _TPRBasPayItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq )   
    
    RETURN  