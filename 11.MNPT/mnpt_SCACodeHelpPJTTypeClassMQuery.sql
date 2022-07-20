IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SCACodeHelpPJTTypeClassMQuery'))
DROP PROCEDURE dbo.mnpt_SCACodeHelpPJTTypeClassMQuery
GO  
  /************************************************************
 설  명		- 계약조회화면의 화태 중분류 코드도움 
 작성일		- 2017년 9월 12일  
 작성자		- 방혁
 수정사항		- 
 ************************************************************/
CREATE PROCEDURE mnpt_SCACodeHelpPJTTypeClassMQuery
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     
    
    DECLARE @PJTTypeClassLSeq INT 
    SELECT @PJTTypeClassLSeq = EnvValue 
      FROM mnpt_TCOMEnv 
     WHERE CompanySeq = @CompanySeq 
       AND EnvSeq = 18 

	SELECT DISTINCT 
           A.ItemClassLName		AS PJTTypeClassLName,	--화태대분류
		   A.ItemClassMName		AS PJTTypeClassMName,	--화태중분류
		   A.ItemClassLSeq		AS PJTTypeClassLSeq,	--화태대분류코드
		   A.ItemClassMSeq		AS PJTTypeClassMSeq		--화태중분류코드
	  FROM _VDAItemClass AS A 
	 WHERE A.CompanySeq	= @CompanySeq
	   AND (@Keyword	= '' OR A.ItemClassMName LIKE @Keyword)
       AND A.ItemClassLSeq = @PJTTypeClassLSeq 
	   AND EXISTS (
					SELECT 1
					  FROM _TPJTType
					 WHERE CompanySeq	= @CompanySeq
					   AND ItemClassSeq	= A.ItemClassSSeq
				)
     ORDER BY A.ItemClassLName, A.ItemClassMName 