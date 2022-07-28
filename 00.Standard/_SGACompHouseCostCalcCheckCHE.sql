
IF OBJECT_ID('_SGACompHouseCostCalcCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcCheckCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료항목별계산 : 체크  
 작성일 - 20110315  
 작성자 - 천경민  
************************************************************/  
CREATE PROC _SGACompHouseCostCalcCheckCHE  
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
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostCalcInfo'  
    IF @@ERROR <> 0 RETURN   
  
  
    -------------------------------------------  
    -- 확정여부체크    
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1083                  , -- 확정(승인)된 자료는 수정/삭제할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%확정%')    
                          @LanguageSeq       ,     
                          0,''  
  
    UPDATE #TGAHouseCostCalcInfo    
       SET Result        = @Results,  
           MessageType   = @MessageType,    
           Status        = @Status  
      FROM #TGAHouseCostCalcInfo AS A  
           JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq  
                                                 AND A.CalcYm     = B.CalcYm  
                                                 AND A.HouseClass = B.HouseClass  
                                                 AND B.CfmYn      = '1'  
     WHERE A.Status = 0  
  
  
    SELECT * FROM #TGAHouseCostCalcInfo  
  
RETURN  