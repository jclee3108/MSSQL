
IF OBJECT_ID('KPX_SDAItemRemarkQuery') IS NOT NULL
    DROP PROC KPX_SDAItemRemarkQuery
GO 

-- v2014.11.04 

-- 비고조회 by이재천
/*********************************************************************************************************************  
    화면명 : 품목등록_비고조회  
    SP Name: _SDAItemRemarkQuery  
    작성일 : 2010.04.14 : CREATEd by 정혜영      
    수정일 :   
********************************************************************************************************************/  
CREATE PROCEDURE KPX_SDAItemRemarkQuery    
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS         
    DECLARE @docHandle    INT,   
            @ItemSeq      INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
  
    SELECT  @ItemSeq = ItemSeq   
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (ItemSeq INT)    
  
  
/***********************************************************************************************************************************************/  
    SELECT ItemRemark    AS ItemRemark  
      FROM KPX_TDAItemRemark WITH(NOLOCK)  
     WHERE CompanySeq  = @CompanySeq   
       AND ItemSeq     = @ItemSeq  
       
    RETURN    
  
  