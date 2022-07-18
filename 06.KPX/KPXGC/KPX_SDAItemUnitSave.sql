
IF OBJECT_ID('KPX_SDAItemUnitSave') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSave
GO 

-- v2014.11.04 

-- 품목단위환산저장 by이재천
/*************************************************************************************************    
 설  명 - 품목단위환산 저장    
 작성일 - 2008.7. : CREATED BY 김준모           
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemUnitSave  
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
    CREATE TABLE #KPX_TDAItemUnit (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnit'    
  
      
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnit', -- 원테이블명    
                   '#KPX_TDAItemUnit', -- 템프테이블명    
                   'ItemSeq,UnitSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ItemSeq,UnitSeq,BarCode,ConvNum,ConvDen,TransConvQty,LastUserSeq,LastDateTime'    
  
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnitModule', -- 원테이블명    
                   '#KPX_TDAItemUnit', -- 템프테이블명    
                   'ItemSeq,UnitSeq,UMModuleSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ItemSeq,UnitSeq,UMModuleSeq,IsUsed,LastUserSeq,LastDateTime'    
  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemUnit  
          FROM #KPX_TDAItemUnit AS A    
                JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND B.ItemSeq    = A.ItemSeq  
                                                    AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
       
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        DELETE KPX_TDAItemUnitModule  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitModule AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                         AND B.ItemSeq    = A.ItemSeq  
                                                         AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                       AND B.ItemSeq    = A.ItemSeq  
                                                       AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemUnit    
           SET  UnitSeq = ISNULL(A.UnitSeq,0),  
                BarCode = ISNULL(A.BarCode,''),  
                ConvNum = ISNULL(A.ConvNum,0),  
                ConvDen = ISNULL(A.ConvDen,0),  
                TransConvQty = ISNULL(A.TransConvQty,0),  
                LastUserSeq  = @UserSeq,  
                LastDateTime = GETDATE()  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                   AND B.ItemSeq    = A.ItemSeq  
                                                     AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
     
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        -- 고정 단위환산 입력  
        INSERT INTO KPX_TDAItemUnit(    
             CompanySeq,  
             ItemSeq,  
             UnitSeq,  
             BarCode,  
             ConvNum,  
             ConvDen,  
             TransConvQty,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UnitSeq,0),  
             ISNULL(A.BarCode,''),  
             ISNULL(A.ConvNum,0),  
             ISNULL(A.ConvDen,0),  
             ISNULL(A.TransConvQty,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemUnit AS A   
               LEFT OUTER JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                              AND A.ItemSeq     = B.ItemSeq  
                                                              AND A.UnitSeq     = B.UnitSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
           AND B.UnitSeq IS NULL  
         GROUP BY A.ItemSeq, A.UnitSeq, A.BarCode, A.ConvNum, A.ConvDen, A.TransConvQty  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
        -- 가변 업무기능 수정  
        UPDATE KPX_TDAItemUnitModule    
           SET  UnitSeq        = ISNULL(A.UnitSeq,0),  
                IsUsed         = ISNULL(A.IsUsed,'0'),  
                LastUserSeq    = @UserSeq,  
                LastDateTime   = GETDATE()  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                           AND B.ItemSeq     = A.ItemSeq  
                                           AND B.UnitSeq     = A.UnitSeqOld  
                                           AND B.UMModuleSeq = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN  
            RETURN      
        END    
  
        -- 가변 단위업무기능 입력  
        INSERT INTO KPX_TDAItemUnitModule  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMModuleSeq,  
            IsUsed,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMModuleSeq,0),  
                ISNULL(A.IsUsed,'0'),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnit AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                                      AND B.ItemSeq     = A.ItemSeq  
                                                      AND B.UnitSeq     = A.UnitSeq  
                                                      AND B.UMModuleSeq = A.UMModuleSeq  
         WHERE WorkingTag = 'U' AND Status = 0   
           AND B.UMModuleSeq IS NULL  
           AND A.UMModuleSeq <> 0  
         GROUP BY A.ItemSeq,A.UnitSeq,A.UMModuleSeq,A.IsUsed  
  
        -- 키값 변경시 단위속성 테이블삭제  
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                       AND B.ItemSeq    = A.ItemSeq  
                                                       AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'U' AND Status = 0  
           AND A.UnitSeq <> A.UnitSeqOld  
           AND ISNULL(A.UnitSeqOld,0) <> 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        -- Old 값 변경  
        UPDATE #KPX_TDAItemUnit  
           SET UnitSeqOld = ISNULL(UnitSeq,0)  
         WHERE WorkingTag = 'U' AND Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
  -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        -- 고정 단위환산 입력  
        INSERT INTO KPX_TDAItemUnit(    
             CompanySeq,  
             ItemSeq,  
             UnitSeq,  
             BarCode,  
             ConvNum,  
             ConvDen,  
             TransConvQty,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UnitSeq,0),  
             ISNULL(A.BarCode,''),  
             ISNULL(A.ConvNum,0),  
             ISNULL(A.ConvDen,0),  
             ISNULL(A.TransConvQty,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemUnit AS A   
               LEFT OUTER JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                              AND A.ItemSeq     = B.ItemSeq  
                                                              AND A.UnitSeq     = B.UnitSeq  
         WHERE WorkingTag = 'A' AND Status = 0   
           AND B.UnitSeq IS NULL  
         GROUP BY A.ItemSeq, A.UnitSeq, A.BarCode, A.ConvNum, A.ConvDen, A.TransConvQty  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
        -- 가변 단위업무기능 입력  
        INSERT INTO KPX_TDAItemUnitModule  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMModuleSeq,  
            IsUsed,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMModuleSeq,0),  
                ISNULL(A.IsUsed,'0'),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnit AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                                      AND A.ItemSeq     = B.ItemSeq  
                                                      AND A.UnitSeq     = B.UnitSeq  
                                                      AND A.UMModuleSeq = B.UMModuleSeq  
         WHERE WorkingTag = 'A' AND Status = 0   
           AND B.UMModuleSeq IS NULL  
           AND A.UMModuleSeq <> 0  
         GROUP BY A.ItemSeq,A.UnitSeq,A.UMModuleSeq,A.IsUsed  
  
        UPDATE #KPX_TDAItemUnit  
           SET UnitSeqOld = ISNULL(UnitSeq,0)  
         WHERE WorkingTag = 'A' AND Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
  
    SELECT *    
      FROM #KPX_TDAItemUnit    
  
RETURN    
/**************************************************************************************************/    
  