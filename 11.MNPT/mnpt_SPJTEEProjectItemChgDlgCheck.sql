     
IF OBJECT_ID('mnpt_SPJTEEProjectItemChgDlgCheck') IS NOT NULL       
    DROP PROC mnpt_SPJTEEProjectItemChgDlgCheck      
GO      
      
-- v2018.02.12
      
-- 청구항목변경-체크 by 이재천 
CREATE PROC mnpt_SPJTEEProjectItemChgDlgCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    UPDATE #BIZ_OUT_DataBlock1
	   SET Status	= 1,
		   Result	= '중복된 청구항목이 입력되었습니다..'
	  FROM #BIZ_OUT_DataBlock1 AS A
		   INNER JOIN (
						SELECT S.ItemSeq
						  FROM (
									SELECT ItemSeq 
									  FROM _TPJTProjectDelivery AS A
									 WHERE NOT EXISTS (
														SELECT 1
														  FROM #BIZ_OUT_DataBlock1
														 WHERE Status		= 0
														   AND WorkingTag	IN ('A', 'U')
														   AND PJTSeq		= A.PJTSeq
														   AND DelvSerl		= A.DelvSerl
													)
									   AND EXISTS (
													SELECT 1
													  FROM #BIZ_OUT_DataBlock1
													 WHERE Status		= 0
													   AND WorkingTag	IN ('A', 'U')
													   AND PJTSeq		= A.PJTSeq
												)
									UNION ALL
									SELECT DISTINCT ItemSeq	
									  FROM #BIZ_OUT_DataBlock1
									 WHERE Status		= 0
									   AND WorkingTag	IN ('A', 'U')
							) AS S
						  GROUP BY S.ItemSeq
						  HAVING COUNT(1) > 1
					) AS B 
				   ON B.ItemSeq = A.ItemSeq
	 WHERE Status		= 0
	   AND WorkingTag In ('A', 'U')
    
    RETURN  
