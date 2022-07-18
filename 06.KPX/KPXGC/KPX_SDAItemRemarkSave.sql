
IF OBJECT_ID('KPX_SDAItemRemarkSave') IS NOT NULL 
    DROP PROC KPX_SDAItemRemarkSave
GO 

-- v2014.11.04 

-- 비고저장 by이재천 
/*********************************************************************************************************************  
    화면명 : 품목등록_비고저장  
    SP Name: KPX_SDAItemRemarkSave  
    작성일 : 2010.4.14 : CREATEd by 정혜영      
    수정일 :   
********************************************************************************************************************/  
  
CREATE PROCEDURE KPX_SDAItemRemarkSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE @docHandle  INT  
  
  
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #KPX_TDAItemRemark (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemRemark'    
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'KPX_TDAItemRemark', -- 원테이블명  
                   '#KPX_TDAItemRemark', -- 템프테이블명  
                   'ItemSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq, ItemSeq, ItemRemark, LastUserSeq, LastDateTime'   
         
    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE KPX_TDAItemRemark    
          FROM KPX_TDAItemRemark AS A  
                JOIN #KPX_TDAItemRemark AS B ON A.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  
    END    
    
    -- Update                                                                                                   
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN     
        UPDATE KPX_TDAItemRemark    
           SET ItemRemark   = B.ItemRemark,   
               LastUserSeq  = @UserSeq,     
               LastDateTime = GETDATE()    
          FROM KPX_TDAItemRemark AS A   
                 JOIN #KPX_TDAItemRemark AS B ON A.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
         WHERE B.WorkingTag = 'U'   
           AND B.Status = 0  
           
        IF @@ERROR <> 0 RETURN    
    END     
    -- INSERT                                                                                                   
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
  
        -- 서비스 INSERT    
        INSERT INTO KPX_TDAItemRemark (CompanySeq, ItemSeq, ItemRemark, LastUserSeq, LastDateTime)  
            SELECT @CompanySeq, ItemSeq, ItemRemark, @UserSeq, GETDATE()     
              FROM #KPX_TDAItemRemark    
             WHERE WorkingTag = 'A'   
               AND Status = 0    
           
        IF @@ERROR <> 0 RETURN  
    END  
      
    SELECT * FROM #KPX_TDAItemRemark   
    
    RETURN    
  