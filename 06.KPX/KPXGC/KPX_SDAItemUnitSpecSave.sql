
IF OBJECT_ID('KPX_SDAItemUnitSpecSave') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSpecSave
GO 

-- v2014.11.04 

-- 품목단위속성 저장 by이재천
/*************************************************************************************************    
 설  명 - 품목단위속성 저장    
 작성일 - 2008.7. : CREATED BY 김준모       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemUnitSpecSave  
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
            @ItemSeq            INT,  
            @UnitSeq            INT  
  
  
    -- 마스타 등록 생성    
    CREATE TABLE #KPX_TDAItemUnitSpec (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnitSpec'    
    IF @@ERROR <> 0 RETURN   
  
      
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnitSpec', -- 원테이블명    
                   '#KPX_TDAItemUnitSpec', -- 템프테이블명    
                   'ItemSeq, UnitSeq, UMSpecCode' , -- 키가 여러개일 경우는 , 로 연결한다.    
                   'CompanySeq,ItemSeq,UnitSeq,UMSpecCode,SpecUnit,Value,LastUserSeq,LastDateTime'  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnitSpec AS A  
               JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq      = @CompanySeq    
                                         AND B.ItemSeq         = A.ItemSeq  
                                         AND B.UnitSeq         = A.UnitSeq  
                                         AND B.UMSpecCode      = A.UMSpecCode  
         WHERE A.WorkingTag = 'D' AND A.Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemUnitSpec    
           SET  SpecUnit       = ISNULL(A.SpecUnit,''),  
                Value          = ISNULL(A.Value,0),  
                LastUserSeq    = @UserSeq,  
                LastDateTime   = GETDATE()  
          FROM #KPX_TDAItemUnitSpec AS A    
               JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq = @CompanySeq    
                                         AND B.ItemSeq    = A.ItemSeq  
                                         AND B.UnitSeq    = A.UnitSeq  
                                         AND B.UMSpecCode = A.UMSpecCode  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN  
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemUnitSpec  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMSpecCode,  
            SpecUnit,  
            Value,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMSpecCode,0),  
                ISNULL(A.SpecUnit,''),  
                ISNULL(A.Value,0),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnitSpec AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq = @CompanySeq    
                                                    AND B.ItemSeq    = A.ItemSeq  
                                                    AND B.UnitSeq    = A.UnitSeq  
                                                    AND B.UMSpecCode = A.UMSpecCode  
         WHERE WorkingTag = 'U' AND Status = 0   
           AND B.UnitSeq IS NULL  
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
    INSERT INTO KPX_TDAItemUnitSpec  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMSpecCode,  
            SpecUnit,  
            Value,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(ItemSeq,0),  
                ISNULL(UnitSeq,0),  
                ISNULL(UMSpecCode,0),  
                ISNULL(SpecUnit,''),  
                ISNULL(Value,0),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnitSpec     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT * FROM #KPX_TDAItemUnitSpec    
    
RETURN    
/**************************************************************************************************/    
  