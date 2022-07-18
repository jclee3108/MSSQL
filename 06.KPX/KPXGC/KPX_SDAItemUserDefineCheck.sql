
IF OBJECT_ID('KPX_SDAItemUserDefineCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUserDefineCheck
GO 

-- v2014.11.04 

-- 추가정보체크 by이재천 

/*********************************************************************************************************************
     화면명 : 품목등록 - 추가정보체크
     SP Name: _SDAItemUserDefineCheck
     작성일 : 2009.10.27 : CREATEd by 정혜영    
     수정일 : 
 ********************************************************************************************************************/
 CREATE PROC KPX_SDAItemUserDefineCheck    
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
     
 AS        
     
     DECLARE @Count       INT,    
             @Seq         INT,    
             @MessageType INT,    
             @Status      INT,    
             @Results     NVARCHAR(250)
     
     -- 서비스 마스타 등록 생성    
     CREATE TABLE #KPX_TDAItemUserDefine (WorkingTag NCHAR(1) NULL)      
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemUserDefine'         
     IF @@ERROR <> 0 RETURN      
     
     
     -------------------------------------------    
     -- 중복여부체크(번호)    
     -------------------------------------------   
      
     -------------------------------------------    
     -- 저장시 WorkingTag변경    
     -------------------------------------------    
      IF @WorkingTag = 'D' 
         UPDATE #KPX_TDAItemUserDefine
            SET WorkingTag = @WorkingTag
  
     UPDATE #KPX_TDAItemUserDefine    
     SET WorkingTag = 'A'     
     FROM #KPX_TDAItemUserDefine AS A     
         LEFT OUTER JOIN KPX_TDAItemUserDefine AS B ON B.CompanySeq = @CompanySeq  
                                                AND A.ItemSeq    = B.ItemSeq     
                                                AND A.MngSerl    = B.MngSerl     
     WHERE A.WorkingTag = 'U'     
       AND A.Status = 0          
       AND B.MngSerl IS NULL    
    
      
     SELECT * FROM #KPX_TDAItemUserDefine       
     RETURN        
GO 
