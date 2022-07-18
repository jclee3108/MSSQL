
IF OBJECT_ID('KPX_SDAItemSalesSave') IS NOT NULL 
    DROP PROC KPX_SDAItemSalesSave
GO 

-- v2014.11.04 

-- 품목영업정보 저장  by 이재천
/*************************************************************************************************    
 설  명 - 품목영업정보 저장    
 작성일 - 2008.6. : CREATED BY 김준모       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemSalesSave  
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
    CREATE TABLE #KPX_TDAItemSales (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemSales'    
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemSales', -- 원테이블명    
                   '#KPX_TDAItemSales', -- 템프테이블명    
                   'ItemSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ItemSeq,IsVat,SMVatKind,SMVatType,IsOption,IsSet,Guaranty,HSCode,LastUserSeq,LastDateTime'        
      
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemSales  
          FROM #KPX_TDAItemSales AS A    
               JOIN KPX_TDAItemSales AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                    AND B.ItemSeq = A.ItemSeq  
        WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemSales    
           SET   IsVat  =    ISNULL(A.IsVat,'0'),  -- 부가세포함여부  
                 SMVatKind = ISNULL(A.SMVatKind,0), -- 부가세구분  
                 SMVatType = ISNULL(A.SMVatType,0), -- 부가세종류  
                 IsOption = ISNULL(A.IsOption,'0'), -- 옵션여부  
                 IsSet = ISNULL(A.IsSet,'0'),  -- Set품목여부  
                 Guaranty = CASE WHEN ISNULL(D.IsVessel,'') = '1' THEN ISNULL(A.Guaranty,0) ELSE ISNULL(B.Guaranty,0) END,  
                 HSCode = ISNULL(A.HSCode, ''),  
                 LastUserSeq  = @UserSeq,  
                 LastDateTime = GETDATE()  
          FROM #KPX_TDAItemSales AS A    
               JOIN KPX_TDAItemSales AS B ON B.CompanySeq  = @CompanySeq    
                                      AND B.ItemSeq = A.ItemSeq  
               JOIN KPX_TDAItem AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq  
                                               AND B.ItemSeq    = C.ItemSeq  
               JOIN _TDAItemAsset AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq  
                                                    AND C.AssetSeq   = D.AssetSeq  
  
  
  
  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
  
        INSERT INTO KPX_TDAItemSales(    
             CompanySeq,  
             ItemSeq,  
             IsVat,  
             SMVatKind,  
             SMVatType,  
             IsOption,  
             IsSet,  
             Guaranty,  
             HSCode,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,  
             A.ItemSeq,  
             ISNULL(A.IsVat,'0'),  
             ISNULL(A.SMVatKind,2003001),  
             ISNULL(A.SMVatType,8028001),  
  
             ISNULL(A.IsOption,'0'),  
             ISNULL(A.IsSet,'0'),  
             ISNULL(A.Guaranty,0),  
             ISNULL(A.HSCode,''),  
             @UserSeq,  
             GETDATE()  
          FROM #KPX_TDAItemSales AS A   
                 LEFT OUTER JOIN KPX_TDAItemSales AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                               AND B.ItemSeq = A.ItemSeq  
  
  
  
  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
           AND ISNULL(B.ItemSeq, 0) = 0  
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemSales(    
             CompanySeq,  
             ItemSeq,  
             IsVat,  
             SMVatKind,  
             SMVatType,  
             IsOption,  
             IsSet,  
             Guaranty,  
             HSCode,  
             LastUserSeq,  
             LastDateTime, 
             PgmSeq )  
        SELECT  
             @CompanySeq,    
             ItemSeq,  
             ISNULL(IsVat,'0'),  
             ISNULL(SMVatKind,2003001),  
             ISNULL(SMVatType,8028001),  
             ISNULL(IsOption,'0'),  
             ISNULL(IsSet,'0'),  
             ISNULL(Guaranty,0),  
             ISNULL(HSCode,''),  
             @UserSeq,  
             GETDATE(), 
             @PgmSeq 
          FROM #KPX_TDAItemSales     
  
  
  
  
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT *    
      FROM #KPX_TDAItemSales    
    
RETURN    
/**************************************************************************************************/    
  