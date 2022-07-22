IF OBJECT_ID('hencom_SSLWeatherSave') IS NOT NULL 
    DROP PROC hencom_SSLWeatherSave
GO 

-- v2017.03.23 

/************************************************************
 설  명 - 데이터-날씨등록_hencom : 저장
 작성일 - 20151013
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SSLWeatherSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TSLWeather (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLWeather'     
	IF @@ERROR <> 0 RETURN  
	    
	-- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TSLWeather', -- 원테이블명
   				   '#hencom_TSLWeather', -- 템프테이블명
   				   'WeatherRegSeq  ' , -- 키가 여러개일 경우는 , 로 연결한다. 
   				   'CompanySeq,  WeatherRegSeq  ,  WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,LastUserSeq    ,LastDateTime   ,DeptSeq, Temperature '

	-- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TSLWeather
			  FROM #hencom_TSLWeather A 
				   JOIN hencom_TSLWeather B ON ( A.WeatherRegSeq  = B.WeatherRegSeq ) 
                         
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE hencom_TSLWeather
			   SET WDate          = A.WDate          ,
                   UMWeather      = A.UMWeather      ,
                   WeatherStatus  = A.WeatherStatus  ,
                   Remark         = A.Remark         ,
                   LastUserSeq    = @UserSeq         ,
                   LastDateTime   = GETDATE()        ,
                   DeptSeq        = A.DeptSeq        , 
                   Temperature    = A.Temperature
			  FROM #hencom_TSLWeather AS A 
			       JOIN hencom_TSLWeather AS B ON ( A.WeatherRegSeq  = B.WeatherRegSeq ) 
                         
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
	-- INSERT
	IF EXISTS (SELECT 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
			INSERT INTO hencom_TSLWeather ( CompanySeq , WeatherRegSeq  ,WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,
                         LastUserSeq    ,LastDateTime   ,DeptSeq, Temperature        ) 
			SELECT @CompanySeq,  WeatherRegSeq  ,WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,
                  @UserSeq      ,GETDATE()      ,DeptSeq        ,Temperature
			  FROM #hencom_TSLWeather AS A   
			 WHERE A.WorkingTag = 'A' 
			   AND A.Status = 0    
			IF @@ERROR <> 0 RETURN
	END   

	SELECT * FROM #hencom_TSLWeather 
RETURN
