
IF OBJECT_ID('KPX_SDAItemClassSave') IS NOT NULL 
    DROP PROC KPX_SDAItemClassSave
GO 

-- 2014.11.04 

-- 품목분류 저장 by이재천
/*************************************************************************************************          
 설  명 - 품목분류 저장          
 작성일 - 2008.6. : CREATED BY JMKIM             
*************************************************************************************************/          
CREATE PROCEDURE KPX_SDAItemClassSave        
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
    CREATE TABLE #KPX_TDAItemClass (WorkingTag NCHAR(1) NULL)          
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemClass'          
    
    UPDATE  #KPX_TDAItemClass      
       SET  UMajorItemClass = CONVERT(INT, UMItemClass / 1000)      
     WHERE  ISNULL(UMajorItemClass, 0) = 0      
           
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)          
    EXEC _SCOMLog  @CompanySeq   ,          
                   @UserSeq      ,          
                   'KPX_TDAItemClass', -- 원테이블명          
                   '#KPX_TDAItemClass', -- 템프테이블명          
                   'ItemSeq,UMajorItemClass' , -- 키가 여러개일 경우는 , 로 연결한다.           
                   'CompanySeq,ItemSeq,UMajorItemClass,UMItemClass,LastUserSeq,LastDateTime'              
        
    
    -- DELETE            
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemClass WHERE WorkingTag = 'D' AND Status = 0  )          
    BEGIN          
        DELETE KPX_TDAItemClass        
        FROM #KPX_TDAItemClass AS A          
             JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq          
                                                  AND B.ItemSeq     = A.ItemSeq        
                                                  AND B.UMajorItemClass = A.UMajorItemClass        
        WHERE A.WorkingTag = 'D' AND A.Status = 0        
            
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
    END        
        
    -- Update            
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemClass WHERE WorkingTag = 'U' AND Status = 0  )          
    BEGIN           
        UPDATE KPX_TDAItemClass          
           SET  UMItemClass = ISNULL(A.UMItemClass,0),        
                LastUserSeq  = @UserSeq,        
                LastDateTime = GETDATE(), 
                PgmSeq = @PgmSeq 
          FROM #KPX_TDAItemClass AS A          
               JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq          
                                                    AND B.ItemSeq = A.ItemSeq        
                                                    AND B.UMajorItemClass = A.UMajorItemClass        
         WHERE A.WorkingTag = 'U' AND A.Status = 0        
           
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
        
        INSERT INTO KPX_TDAItemClass(          
             CompanySeq        
            ,ItemSeq        
            ,UMajorItemClass        
            ,UMItemClass        
            ,LastUserSeq        
            ,LastDateTime
            ,PgmSeq )        
        SELECT        
             @CompanySeq          
            ,ISNULL(A.ItemSeq,0)        
            ,ISNULL(A.UMajorItemClass,0)        
            ,ISNULL(A.UMItemClass,0)        
            ,@UserSeq          
            ,GETDATE()   
            ,@PgmSeq     
          FROM #KPX_TDAItemClass AS A          
               LEFT OUTER JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq          
                                                               AND B.ItemSeq = A.ItemSeq        
                                                                 AND B.UMajorItemClass = A.UMajorItemClass        
         WHERE A.WorkingTag = 'U' AND A.Status = 0         
           AND ISNULL(B.UMajorItemClass,'') = ''        
          
        IF @@ERROR <> 0            
  BEGIN            
            ROLLBACK TRAN            
            RETURN            
        END             
    END          
             
    -- INSERT            
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemClass WHERE WorkingTag = 'A' AND Status = 0  )          
    BEGIN          
        
        INSERT INTO KPX_TDAItemClass(          
             CompanySeq,        
             ItemSeq,        
             UMajorItemClass,        
             UMItemClass,        
             LastUserSeq,        
             LastDateTime, 
             PgmSeq )        
        SELECT        
             @CompanySeq,        
             ISNULL(ItemSeq,0),        
             ISNULL(UMajorItemClass,0),        
             ISNULL(UMItemClass,0),        
             @UserSeq,        
             GETDATE(), 
             @PgmSeq       
          FROM #KPX_TDAItemClass           
         WHERE WorkingTag = 'A' AND Status = 0         
          
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END             
    END              
            
    SELECT *          
      FROM #KPX_TDAItemClass          
          
RETURN          
    /**************************************************************************************************/  