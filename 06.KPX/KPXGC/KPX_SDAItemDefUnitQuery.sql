
IF OBJECT_ID('KPX_SDAItemDefUnitQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemDefUnitQuery
GO 

-- v2014.11.04 

-- 품목기본단위 저장 by이재천
/*************************************************************************************************        
 설  명 - 품목기본단위 조회    
 작성일 - 2008.6.  : CREATED BY JMKIM    
 수정일 - 2011.06.24 by 김철웅  
  1) _TDAUMinor이 사전 테이블과 join하지 않아서 다국어 지원하지 않음 - 수정   
*************************************************************************************************/        
CREATE PROCEDURE KPX_SDAItemDefUnitQuery  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE   @docHandle      INT,      
              @ItemSeq        INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @ItemSeq     = ISNULL(ItemSeq, '')  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH ( ItemSeq  INT )          
  
    SELECT @ItemSeq  = ISNULL(LTRIM(RTRIM(@ItemSeq)),   0)  
  
    SELECT   ''  AS BizFuncName,  
   ISNULL( ISNULL( Z.Word, A.MinorName ), '' ) AS ModuleName, -- 업무기능상세  
   ISNULL(A.MinorSeq,0) AS UMModuleSeq, -- 업무기능상세코드  
            ISNULL(C.UnitName,'') AS STDUnitName, -- 기본단위  
            ISNULL(B.STDUnitSeq,0) AS STDUnitSeq  -- 기본단위코드  
     FROM _TDAUMinor A With(Nolock)    
     LEFT OUTER JOIN _TCADictionary AS Z WITH(NOLOCK) ON ( Z.LanguageSeq = @LanguageSeq AND A.WordSeq = Z.WordSeq )  
     LEFT OUTER JOIN KPX_TDAItemDefUnit B With(Nolock) ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.UMModuleSeq AND B.ItemSeq = @ItemSeq  
     LEFT OUTER JOIN _TDAUnit C With(Nolock) ON B.CompanySeq = C.CompanySeq AND B.STDUnitSeq = C.UnitSeq  
    WHERE 1 = 1    
      AND (A.CompanySeq = @CompanySeq)  
      AND MajorSeq = 1003  
    Order by A.MinorSeq  
  
 RETURN      