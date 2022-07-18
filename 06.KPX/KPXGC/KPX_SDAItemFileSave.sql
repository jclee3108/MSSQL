
IF OBJECT_ID('KPX_SDAItemFileSave') IS NOT NULL 
    DROP PROC KPX_SDAItemFileSave
GO 

-- v2014.11.04 

-- 품목첨부파일 저장 by이재천
/*************************************************************************************************    
 설  명 - 품목첨부파일 저장    
 작성일 - 2008.10. : CREATED BY 김준모       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemFileSave  
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
    CREATE TABLE #KPX_TDAItemFile (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemFile'    
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemFile', -- 원테이블명    
                   '#KPX_TDAItemFile', -- 템프테이블명    
                   'ItemSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ItemSeq,FileSeq,LastUserSeq,LastDateTime'        
  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemFile  
          FROM #KPX_TDAItemFile AS A    
               JOIN KPX_TDAItemFile AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                   AND B.ItemSeq     = A.ItemSeq  
         WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemFile  
           SET FileSeq      = A.FileSeq,  
               LastUserSeq  = @UserSeq,  
               LastDateTime = GETDATE()  
          FROM #KPX_TDAItemFile AS A  
               JOIN KPX_TDAItemFile AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                   AND A.ItemSeq    = B.ItemSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemFile(    
             CompanySeq,  
             ItemSeq,  
             FileSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,  
             A.ItemSeq,  
             A.FileSeq,  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemFile AS A    
               LEFT OUTER JOIN KPX_TDAItemFile AS B WITH (NOLOCK)  ON B.CompanySeq  = @CompanySeq    
                                                               AND A.ItemSeq     = B.ItemSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
           AND B.ItemSeq IS NULL  
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemFile(    
             CompanySeq,  
             ItemSeq,  
             FileSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ItemSeq,  
             FileSeq,  
             @UserSeq,  
             GETDATE()  
          FROM #KPX_TDAItemFile     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT * FROM #KPX_TDAItemFile    
    
RETURN    
/**************************************************************************************************/    
  