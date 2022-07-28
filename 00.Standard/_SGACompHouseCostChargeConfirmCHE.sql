
IF OBJECT_ID('_SGACompHouseCostChargeConfirmCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeConfirmCHE
GO 

/************************************************************  
 ��  �� - ������-���÷��� : Ȯ��  
 �ۼ��� - 20110315  
 �ۼ��� - õ���  
************************************************************/  
CREATE PROC _SGACompHouseCostChargeConfirmCHE
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
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TGAHouseCostChargeItem (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostChargeItem'  
    IF @@ERROR <> 0 RETURN   
  
  
    UPDATE #TGAHouseCostChargeItem  
       SET Result = 'Ȯ��ó���� �����Ͱ� �����ϴ�.',  
           Status = 99999  
      FROM #TGAHouseCostChargeItem AS A  
           LEFT OUTER JOIN _TGAHouseCostChargeItem AS B ON A.CalcYm     = B.CalcYm  
                                                            AND A.HouseClass = B.HouseClass  
     WHERE B.CalcYm IS NULL  
  
/*  
    UPDATE #TGAHouseCostChargeItem  
       SET Result = 'Ȯ��ó���� �� �����ϴ�.(���� �� Ȯ������ Ȯ��)',  
           Status = 99999  
      FROM #TGAHouseCostChargeItem AS A  
     WHERE A.Status = 0  
       AND EXISTS (SELECT 1 FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq  
                                                                AND CalcYm     < A.CalcYm  
                                                                AND HouseClass = A.HouseClass  
                                                                AND ISNULL(CfmYn, '0') = '0')  
  
  
    UPDATE #TGAHouseCostChargeItem  
       SET Result = 'Ȯ������� �� �����ϴ�.(���� �� Ȯ������ Ȯ��)',  
           Status = 99999  
      FROM #TGAHouseCostChargeItem AS A  
     WHERE A.Status = 0  
       AND EXISTS (SELECT 1 FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq  
                                                                AND CalcYm     > A.CalcYm  
                                                                AND HouseClass = A.HouseClass  
                                                                AND ISNULL(CfmYn, '0') = '1')  
*/  
  
    -- Ȯ��ó��  
    UPDATE _TGAHouseCostChargeItem  
       SET CfmYn = CASE WHEN ISNULL(A.CfmYn, '0') = '0' THEN '1' ELSE '0' END  
      FROM _TGAHouseCostChargeItem AS A  
           JOIN #TGAHouseCostChargeItem AS B ON A.CalcYm     = B.CalcYm  
                                                  AND A.HouseClass = B.HouseClass  
     WHERE B.Status = 0  
  
  
    -- ó����� �ݿ�  
    UPDATE #TGAHouseCostChargeItem  
       SET CfmYn = B.CfmYn  
      FROM #TGAHouseCostChargeItem AS A  
           JOIN _TGAHouseCostChargeItem AS B ON A.CalcYm     = B.CalcYm  
                                                 AND A.HouseClass = B.HouseClass  
     WHERE A.Status = 0  
  
  
    SELECT * FROM #TGAHouseCostChargeItem  
  
RETURN  