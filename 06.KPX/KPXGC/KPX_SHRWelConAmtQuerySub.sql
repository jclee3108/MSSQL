  
IF OBJECT_ID('KPX_SHRWelConAmtQuerySub') IS NOT NULL   
    DROP PROC KPX_SHRWelConAmtQuerySub  
GO  
  
-- v2014.11.27  
  
-- 경조사지급기준등록-SS2 조회 by 이재천   
CREATE PROC KPX_SHRWelConAmtQuerySub  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @SMConMutual    INT, 
            @ConSeq         INT, 
            @IsNoUseInclude INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SMConMutual     = ISNULL(SMConMutual, 0 ),  
           @ConSeq          = ISNULL(ConSeq, 0 ),  
           @IsNoUseInclude  = ISNULL(IsNoUseInclude, '0' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            SMConMutual    INT,
            ConSeq     INT,
            IsNoUseInclude INT
           )
    
    -- 최종조회   
    SELECT B.ItemName AS WkItemName, 
           A.WkItemSeq, 
           A.Numerator, 
           A.Denominator, 
           A.WkItemSeq AS WkItemSeqOld
      FROM KPX_THRWelConAmt             AS A 
      LEFT OUTER JOIN _TPRBasPayItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.WkItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.SMConMutual = @SMConMutual ) 
       AND ( A.ConSeq = @ConSeq ) 
      
    RETURN  