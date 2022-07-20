  
IF OBJECT_ID('mnpt_SARUsaulCostAmtOppAccUpdateCheck') IS NOT NULL   
    DROP PROC mnpt_SARUsaulCostAmtOppAccUpdateCheck  
GO  
    
-- v2018.01.12
  
-- 일반비용신청_mnpt-상대계정수정체크 by 이재천
CREATE PROC mnpt_SARUsaulCostAmtOppAccUpdateCheck  
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
      
    CREATE TABLE #TARUsualCostAmt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARUsualCostAmt'   
    IF @@ERROR <> 0 RETURN     

    -------------------------------------------------------
    -- 체크1, 전표가 생성되어 수정 할 수 없습니다. 
    -------------------------------------------------------
    UPDATE A
       SET Result = '전표가 생성되어 수정 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TARUsualCostAmt AS A 
      JOIN _TARUsualCost    AS B ON ( B.CompanySeq = @CompanySeq AND B.UsualCostSeq = A.UsualCostSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND B.SlipSeq <> 0 
    -------------------------------------------------------
    -- 체크1, End 
    -------------------------------------------------------

    -------------------------------------------------------
    -- 체크2, 저장 된 내역만 수정 할 수 있습니다.
    -------------------------------------------------------
    UPDATE A
       SET Result = '저장 된 내역만 수정 할 수 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TARUsualCostAmt AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND A.UsualCostSeq = 0 
    -------------------------------------------------------
    -- 체크2, End 
    -------------------------------------------------------
    


    SELECT * FROM #TARUsualCostAmt   
      
    RETURN  