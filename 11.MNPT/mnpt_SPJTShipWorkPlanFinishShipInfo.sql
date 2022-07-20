  
IF OBJECT_ID('mnpt_SPJTShipWorkPlanFinishShipInfo') IS NOT NULL   
    DROP PROC mnpt_SPJTShipWorkPlanFinishShipInfo  
GO  
    
-- v2017.10.12
  
-- 본선작업계획완료입력-모선정보 by 이재천 
CREATE PROC mnpt_SPJTShipWorkPlanFinishShipInfo  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @ShipSeq    INT, 
            @ShipSerl   INT  
      
    SELECT @ShipSeq     = ISNULL( ShipSeq  , 0 ),   
           @ShipSerl    = ISNULL( ShipSerl , 0 )   
      FROM #BIZ_IN_DataBlock1    
    
    SELECT LEFT(A.InDateTime,8) AS InDate, 
           RIGHT(A.InDateTime,4) AS InTime, 
           LEFT(A.ApproachDateTime,8) AS ApproachDate, 
           RIGHT(A.ApproachDateTime,4) AS ApproachTime, 
           LEFT(A.OutDateTime,8) AS OutDate, 
           RIGHT(A.OutDateTime,4) AS OutTime, 
           J.ChangeCnt
      FROM mnpt_TPJTShipDetail AS A 
      LEFT OUTER JOIN (
                        SELECT ShipSeq, ShipSerl, COUNT(1) AS ChangeCnt
                          FROM mnpt_TPJTShipDetailChange 
                         WHERE CompanySeq = @CompanySeq
                         GROUP BY ShipSeq, ShipSerl 
                      ) AS J ON ( J.ShipSeq = A.ShipSeq AND J.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ShipSeq = @ShipSeq 
       AND A.ShipSerl = @ShipSerl 
    
    RETURN     