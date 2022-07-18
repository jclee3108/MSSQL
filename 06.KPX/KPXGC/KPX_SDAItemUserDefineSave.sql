
IF OBJECT_ID('KPX_SDAItemUserDefineSave') IS NOT NULL 
    DROP PROC KPX_SDAItemUserDefineSave
GO 

-- v2014.11.04 

-- 추가정보저장 by이재천 
/*********************************************************************************************************************
     화면명 : 품목등록 - 추가정보조회
     SP Name: _SDAItemUserDefineSave
     작성일 : 2009.10.27 : CREATEd by 정혜영    
     수정일 : 
 ********************************************************************************************************************/
 CREATE PROC KPX_SDAItemUserDefineSave
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     
     -- 서비스 마스타 등록 생성  _TDACard        
     CREATE TABLE #KPX_TDAItemUserDefine (WorkingTag NCHAR(1) NULL)        
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemUserDefine'         
            
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)        
     EXEC _SCOMLog  @CompanySeq,      
                    @UserSeq,      
                    'KPX_TDAItemUserDefine'     ,   -- 원테이블명       
                    '#KPX_TDAItemUserDefine'     ,   -- 템프테이블명    
                    'ItemSeq, MngSerl', -- 키가 여러개일 경우는 , 로 연결한다.     
                    'CompanySeq, ItemSeq, MngSerl, MngValSeq, MngValText, LastUserSeq, LastDateTime'    
     IF @@ERROR <> 0   RETURN             
   
   
  -- DELETE          
  -- Table일괄 삭제  
     IF EXISTS (SELECT TOP 1 1 FROM #KPX_TDAItemUserDefine WHERE WorkingTag = 'D' AND Status = 0  )        
     BEGIN        
         DELETE KPX_TDAItemUserDefine        
           FROM KPX_TDAItemUserDefine A   
                JOIN #KPX_TDAItemUserDefine B ON A.ItemSeq = B.ItemSeq   
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq  
         
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
     END        
  
     -- 데이터가 숫자형일 경우, ',' 제거 :: 20140821 박성호 추가
     UPDATE #KPX_TDAItemUserDefine
        SET MngValName = REPLACE(MngValName, ',', '')
      WHERE SMInputType = 1027002 -- 숫자
   
    --select * from #KPX_TDAItemUserDefine
   --return
     -- Update          
     IF EXISTS (SELECT 1 FROM #KPX_TDAItemUserDefine WHERE WorkingTag = 'U' AND Status = 0  )        
     BEGIN        
         
         -- ※ 속도가 너무 느리면 #KPX_TDAItemUserDefine.SMInputType의 값으로 판단을 해도 됨 
         UPDATE KPX_TDAItemUserDefine 
            SET MngValSeq    = (CASE WHEN F.SMInputType IN (1027003,1027005) THEN B.MngValSeq ELSE 0 END),         
                MngValText   = (CASE WHEN F.SMInputType IN (1027003,1027005) THEN '' ELSE B.MngValName END), --CASE WHEN ISNULL(B.MngValSeq,0) = 0 THEN B.MngValName ELSE '' END,         
                LastUserSeq  = @UserSeq,     
                LastDateTime = GETDATE(),
                PgmSeq       = @PgmSeq
           FROM KPX_TDAItemUserDefine   AS A WITH(NOLOCK)
           JOIN #KPX_TDAItemUserDefine  AS B              ON ( A.ItemSeq = B.ItemSeq AND A.MngSerl = B.MngSerl )
           JOIN KPX_TDAItem             AS C WITH(NOLOCK) ON ( A.ItemSeq = C.ItemSeq AND A.CompanySeq = C.CompanySeq )
           JOIN _TDAItemAsset           AS D WITH(NOLOCK) ON ( C.AssetSeq = D.AssetSeq AND C.CompanySeq = D.CompanySeq )
           JOIN _TDASMinor              AS E WITH(NOLOCK) ON ( D.SMAssetGrp = E.MinorSeq AND D.CompanySeq = E.CompanySeq )
           JOIN _TCOMUserDefine         AS F WITH(NOLOCK) ON ( F.TableName = '_TDAItem' AND F.DefineUnitSeq = (CASE ISNULL(E.MinorValue,'0') WHEN '0' THEN 8010001 ELSE 8010002 END) AND F.TitleSerl = B.MngSerl AND F.CompanySeq = E.CompanySeq )
          WHERE B.WorkingTag  = 'U' 
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq     
        
         IF @@ERROR <> 0 RETURN          
         
     END         
         
     -- INSERT          
     IF EXISTS (SELECT 1 FROM #KPX_TDAItemUserDefine WHERE WorkingTag = 'A' AND Status = 0  )        
 BEGIN        
         INSERT INTO KPX_TDAItemUserDefine (CompanySeq, ItemSeq, MngSerl, MngValSeq, MngValText, 
                                         LastUserSeq, LastDateTime, PgmSeq) 
         SELECT @CompanySeq, ItemSeq, MngSerl, MngValSeq, CASE WHEN ISNULL(MngValSeq,0) = 0 THEN MngValName ELSE '' END, 
                @UserSeq, GetDate(), @PgmSeq    
          FROM #KPX_TDAItemUserDefine   
         WHERE WorkingTag = 'A' 
           AND Status = 0          
       
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END           
     END         
          
     SELECT * FROM #KPX_TDAItemUserDefine         
   
     RETURN