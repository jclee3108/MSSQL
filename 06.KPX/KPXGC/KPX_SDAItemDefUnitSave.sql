
IF OBJECT_ID('KPX_SDAItemDefUnitSave') IS NOT NULL 
    DROP PROC KPX_SDAItemDefUnitSave
GO 

-- v2014.11.04 

-- 품목기본단위 저장 by이재천
/*************************************************************************************************    
 설  명 - 품목기본단위 저장    
 작성일 - 2008.6. : CREATED BY 김준모       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemDefUnitSave  
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
            @MaxSeq             INT,    
            @ItemSeq            INT  
    
    -- 마스타 등록 생성    
    CREATE TABLE #KPX_TDAItemDefUnit (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemDefUnit'    
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemDefUnit', -- 원테이블명    
                   '#KPX_TDAItemDefUnit', -- 템프테이블명    
                   'ItemSeq,UMModuleSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ItemSeq,UMModuleSeq,STDUnitSeq,LastUserSeq,LastDateTime'        
  
    
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemDefUnit  
        FROM #KPX_TDAItemDefUnit AS A    
             JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                    AND B.ItemSeq     = A.ItemSeq  
                                                    AND B.UMModuleSeq  = A.UMModuleSeq  
        WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemDefUnit    
           SET  STDUnitSeq   = ISNULL(A.STDUnitSeq,0),  
                LastUserSeq  = @UserSeq,  
                LastDateTime = GETDATE()  
          FROM #KPX_TDAItemDefUnit AS A    
               JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                      AND B.ItemSeq     = A.ItemSeq  
                                                      AND B.UMModuleSeq   = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
     
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemDefUnit(    
             CompanySeq,  
             ItemSeq,  
             UMModuleSeq,  
             StdUnitSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UMModuleSeq,0),  
             ISNULL(A.STDUnitSeq,0),  
             @UserSeq,  
             GETDATE()  
         FROM #KPX_TDAItemDefUnit AS A    
              LEFT OUTER JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                                AND B.ItemSeq     = A.ItemSeq  
                                                                AND B.UMModuleSeq   = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
           AND ISNULL(B.UMModuleSeq,'') = ''  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
--         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit A   
--                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
--                                                                          AND A.ItemSeq    = B.ItemSeq  
--                                                                          AND A.STDUnitSeq = B.UnitSeq)  
--         BEGIN  
  --             INSERT INTO _TDAItemUnit(  
--                 CompanySeq,  
--                 ItemSeq,  
--                 UnitSeq,  
--                 BarCode,  
--                 ConvNum,  
--                 ConvDen,  
--                 LastUserSeq,  
--                 LastDateTime)  
--             SELECT   
--                 @CompanySeq,  
--                 ItemSeq,  
--                 STDUnitSeq,  
--                 '',  
--                 1,  
--                 1,  
--                 @UserSeq,    
--                 GETDATE()  
--               FROM #KPX_TDAItemDefUnit     
--              WHERE WorkingTag = 'U' AND Status = 0   
--              GROUP BY ItemSeq, STDUnitSeq  
--   
--             IF @@ERROR <> 0      
--             BEGIN      
--                 RETURN      
--             END       
--         END  
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemDefUnit(    
             CompanySeq,  
             ItemSeq,  
             UMModuleSeq,  
             StdUnitSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(ItemSeq,0),  
             ISNULL(UMModuleSeq,0),  
             ISNULL(STDUnitSeq,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemDefUnit     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
--         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit A   
--                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
--                                                                          AND A.ItemSeq    = B.ItemSeq  
--                                                                          AND A.STDUnitSeq = B.UnitSeq)  
--         BEGIN  
--             INSERT INTO _TDAItemUnit(  
--                 CompanySeq,  
--                 ItemSeq,  
--                 UnitSeq,  
--                 BarCode,  
--                 ConvNum,  
--                 ConvDen,  
--                 LastUserSeq,  
--                 LastDateTime)  
--             SELECT   
--                 @CompanySeq,  
--                 ItemSeq,  
--                 STDUnitSeq,  
--                 '',  
--                 1,  
--                 1,  
--                 @UserSeq,    
--                 GETDATE()  
--               FROM #KPX_TDAItemDefUnit     
--              WHERE WorkingTag = 'A' AND Status = 0   
--              GROUP BY ItemSeq, UnitSeq  
--   
--             IF @@ERROR <> 0      
--             BEGIN      
--                 RETURN      
--             END       
--         END  
    END        
  
    SELECT *    
      FROM #KPX_TDAItemDefUnit    
    
RETURN    
/**************************************************************************************************/    
  