
IF OBJECT_ID('_SGACompHouseCostChargeCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeCheckCHE
GO 

/************************************************************    
 설  명 - 데이터-사택료등록 : 체크    
 작성일 - 20110315    
 작성자 - 천경민    
************************************************************/    
CREATE PROC _SGACompHouseCostChargeCheckCHE    
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
    CREATE TABLE #TGAHouseCostChargeItem (WorkingTag NCHAR(1) NULL)     
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostChargeItem'    
    IF @@ERROR <> 0 RETURN     
    
    
    ----------------------------------------------------    
    -- 확정여부체크      
    ----------------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1083                  , -- 확정(승인)된 자료는 수정/삭제할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%확정%')      
                          @LanguageSeq       ,       
                          0,''    
    
    UPDATE #TGAHouseCostChargeItem      
       SET Result        = @Results,    
           MessageType   = @MessageType,      
           Status        = @Status    
      FROM #TGAHouseCostChargeItem AS A    
           JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq    
                                                 AND A.CalcYm     = B.CalcYm    
                                                 AND A.HouseClass = B.HouseClass    
                                                 AND B.CfmYn      = '1'    
     WHERE A.Status = 0    
    
    
    ----------------------------------------------------    
    -- 사택료항목계산(상하수도료, 일반관리비) 여부 체크    
    ----------------------------------------------------    
    UPDATE #TGAHouseCostChargeItem    
       SET Result        = LEFT(A.CalcYm, 4) + '년 ' + RIGHT(A.CalcYm, 2) + '월 사택료항목계산 데이터가 없습니다.',    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #TGAHouseCostChargeItem AS A    
     WHERE NOT EXISTS (SELECT * FROM _TGACompHouseMaster AS S1    
                                     JOIN _TGAHouseCostCalcInfo AS S2 ON S1.CompanySeq = S2.CompanySeq    
                                                                          AND S1.HouseSeq   = S2.HouseSeq    
                               WHERE S1.CompanySeq = @CompanySeq    
                                 AND S1.HouseClass = A.HouseClass    
                                 AND S2.CalcYm     = A.CalcYm)    
       AND A.Status = 0    
    
    
    ----------------------------------------------------    
    -- 합계 업데이트    
    ----------------------------------------------------    
    UPDATE A    
       SET TotalAmt = A.WaterCost + A.GeneralCost + (SELECT SUM(ChargeAmt) FROM #TGAHouseCostChargeItem WHERE CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq)    
      FROM #TGAHouseCostChargeItem AS A    
     WHERE A.Status = 0    
    
    
    SELECT * FROM #TGAHouseCostChargeItem    
    
RETURN    
  