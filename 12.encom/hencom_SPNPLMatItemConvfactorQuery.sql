 
IF OBJECT_ID('hencom_SPNPLMatItemConvfactorQuery') IS NOT NULL   
    DROP PROC hencom_SPNPLMatItemConvfactorQuery  
GO  
  
-- v2017.06.01
  
-- 사업계획자재단중등록-조회 by 이재천   
CREATE PROC hencom_SPNPLMatItemConvfactorQuery  
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
            @StdYear    NCHAR(4), 
            @DeptSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear = ISNULL(StdYear,''), 
           @DeptSeq = ISNULL(DeptSeq,0)
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYear NCHAR(4), 
            DeptSeq INT
           )    
    
    -- 최종조회   
    SELECT C.ItemName, 
           A.ConvFactor, 
           A.ItemSeq, 
           A.CFSeq, 
           A.Remark
      FROM hencom_TPNPLMatItemConvfactor    AS A 
      LEFT OUTER JOIN _TDADept              AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.StdYear = @StdYear 
       AND A.DeptSeq = @DeptSeq 
    
    RETURN  