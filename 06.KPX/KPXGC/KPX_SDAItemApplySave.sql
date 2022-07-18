
IF OBJECT_ID('KPX_SDAItemApplySave') IS NOT NULL 
    DROP PROC KPX_SDAItemApplySave
GO 

-- v2014.11.05 

-- 확정(패키지반영체크) by이재천
CREATE PROCEDURE KPX_SDAItemApplySave
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
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItem'  
    
    DECLARE @ItemSeq    INT 
    
    SELECT @ItemSeq = (SELECT TOP 1 ItemSeq FROM #KPX_TDAItem) 
    
    
    IF NOT EXISTS (SELECT 1 FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = @ItemSeq) 
    BEGIN 
    
        INSERT INTO _TDAItem 
        SELECT CompanySeq,      ItemSeq,        ItemName,           TrunName,           ItemNo,            
               AssetSeq,        SMStatus,       ItemSName,          ItemEngName,        ItemEngSName,
               Spec,            SMABC,          UnitSeq,            DeptSeq,            EmpSeq,            
               ModelSeq,        SMInOutKind,    LastUserSeq,        LastDateTime,       IsInherit,            
               @UserSeq,        GETDATE(),      LaunchDate,         PgmSeq
          FROM KPX_TDAItem           
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq 
        
        INSERT INTO _TDAItemClass 
        SELECT * 
          FROM KPX_TDAItemClass      
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemDefUnit
        SELECT * 
          FROM KPX_TDAItemDefUnit    
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemSales
        SELECT * 
          FROM KPX_TDAItemSales      
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemFile       
        SELECT * 
          FROM KPX_TDAItemFile       
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemUserDefine
        SELECT * 
          FROM KPX_TDAItemUserDefine 
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemRemark     
        SELECT * 
          FROM KPX_TDAItemRemark     
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemUnit
        SELECT * 
          FROM KPX_TDAItemUnit       
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemUnitModule
        SELECT * 
          FROM KPX_TDAItemUnitModule 
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
        
        INSERT INTO _TDAItemUnitSpec
        SELECT * 
          FROM KPX_TDAItemUnitSpec   
         WHERE CompanySeq = @CompanySeq 
           AND ItemSeq = @ItemSeq
    END 
    
    SELECT * FROM #KPX_TDAItem 
    
    RETURN 
GO 
begin tran 
exec KPX_SDAItemApplySave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ItemSeq>1051540</ItemSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310


rollback 