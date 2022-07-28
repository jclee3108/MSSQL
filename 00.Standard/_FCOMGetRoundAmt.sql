
IF OBJECT_ID('_FCOMGetRoundAmt') IS NOT NULL 
    DROP FUNCTION _FCOMGetRoundAmt
GO 

/****************************************************************************      
��  �� : �ݾ��� �ݿø� Function    
�۾��� : �����      
�۾��� : 2011.03.16      
*****************************************************************************/      
CREATE FUNCTION dbo._FCOMGetRoundAmt      
(         
    @pAmt       DECIMAL(19,5),  -- �ݾ�    
    @pDecPoint  INT     ,    
    --1023001 �Ҽ���5°�ڸ�����    
    --1023002 �Ҽ���4°�ڸ�����    
    --1023003 �Ҽ���3°�ڸ�����    
    --1023004 �Ҽ���2°�ڸ�����    
    --1023005 �Ҽ���1°�ڸ�����    
    --1023006 1 ��������    
    --1023007 10 ��������    
    --1023008 100 ��������    
    --1023009 1000 ��������    
    @pCutWay    INT         
    --1003001 �ݿø�    
    --1003002 ����    
    --1003003 �ø�    
)   RETURNS DECIMAL(19,5)      
AS      
BEGIN      
   DECLARE @ReturnAmt   DECIMAL(19,5),    
           @UnderPoint  INT,    
           @Point       INT,    
           @CurrData    VARCHAR(50)    
                
    SELECT @Point     = CASE WHEN @pDecPoint = 1023001 THEN  4    
                             WHEN @pDecPoint = 1023002 THEN  3    
                             WHEN @pDecPoint = 1023003 THEN  2    
                             WHEN @pDecPoint = 1023004 THEN  1    
                             WHEN @pDecPoint = 1023005 THEN  0    
                             WHEN @pDecPoint = 1023006 THEN -1    
                             WHEN @pDecPoint = 1023007 THEN -2   
                             WHEN @pDecPoint = 1023008 THEN -3    
                             WHEN @pDecPoint = 1023009 THEN -4    
                             END    
    --SELECT dbo.capro_FCOMGetRoundAmt(12000.123, 1023005, 1003002)                          
        
    SELECT @ReturnAmt = CASE WHEN @pCutWay =1003001 THEN ROUND(@pAmt, @Point)      
                             WHEN @pCutWay =1003002 THEN ROUND(@pAmt, @Point,2)  
                             WHEN @pCutWay =1003003 AND @Point >= 0 THEN CEILING(@pAmt * POWER(10,@Point)) / POWER(10,@Point)      
                             WHEN @pCutWay =1003003 AND @Point = -1 THEN CEILING(@pAmt * 0.1) * 10  
                             WHEN @pCutWay =1003003 AND @Point = -2 THEN CEILING(@pAmt * 0.01) * 100  
                             WHEN @pCutWay =1003003 AND @Point = -3 THEN CEILING(@pAmt * 0.001) * 1000  
                             WHEN @pCutWay =1003003 AND @Point = -4 THEN CEILING(@pAmt * 0.0001) * 10000  
                             END    
                                
    RETURN @ReturnAmt      
END          
  /*****************************************************************************/  