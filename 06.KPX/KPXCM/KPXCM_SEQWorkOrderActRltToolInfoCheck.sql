  
IF OBJECT_ID('KPXCM_SEQWorkOrderActRltToolInfoCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQWorkOrderActRltToolInfoCheck  
GO  
  
-- v2015.07.22 
  
-- 작업실적등록(일반)-설비정보체크 by 이재천 
CREATE PROC KPXCM_SEQWorkOrderActRltToolInfoCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPXCM_TEQWorkOrderActRltToolInfo( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQWorkOrderActRltToolInfo'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A
       SET WorkingTag = 'A'
      FROM #KPXCM_TEQWorkOrderActRltToolInfo AS A 
     WHERE A.WorkingTag = 'U' 
       AND NOT EXISTS (
                        SELECT 1 
                          FROM KPXCM_TEQWorkOrderActRltToolInfo 
                          WHERE CompanySeq = @CompanySeq 
                            AND ReceiptSeq = A.ReceiptSeq 
                            AND WOReqSeq = A.WOReqSeq 
                            AND WOReqSerl = A.WOReqSerl
                      ) 
    
    SELECT * FROM #KPXCM_TEQWorkOrderActRltToolInfo   
      
    RETURN  