     
IF OBJECT_ID('mnpt_SPJTShipDetailChangeDlgQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTShipDetailChangeDlgQuery      
GO      
      
-- v2017.09.27
  
-- (Dlg)이안입력-조회 by 이재천   
CREATE PROC mnpt_SPJTShipDetailChangeDlgQuery      
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
      
    SELECT @ShipSeq     = ISNULL( ShipSeq, 0 ),   
           @ShipSerl    = ISNULL( ShipSerl, 0 )   
      FROM #BIZ_IN_DataBlock1    
    
    SELECT A.ShipSeq,   
           A.ShipSerl, 
           A.ShipSubSerl, 
           A.ApproachDate, 
           A.ApproachTime, 
           A.ChangeDate, 
           A.ChangeTime, 
           A.DiffApproachTime, 
           B.DiffApproachTime AS SourceDiffApproachTime, 
           STUFF(STUFF(LEFT(B.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(B.ApproachDateTime,4),3,0,':') AS SourceApproachDateTime, 
           CASE WHEN A.ChangeDate = '' THEN LEFT(C.OutDateTime,8) ELSE '' END AS OutDate, 
           CASE WHEN A.ChangeDate = '' THEN RIGHT(C.OutDateTime,4) ELSE '' END AS OutTime
      FROM mnpt_TPJTShipDetailChange AS A 
      LEFT OUTER JOIN (
                        SELECT ISNULL(CEILING(SUM(DiffApproachTime)),0) AS DiffApproachTime, MIN(Z.ApproachDate + Z.ApproachTime) AS ApproachDateTime
                          FROM mnpt_TPJTShipDetailChange AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.ShipSeq = @ShipSeq 
                           AND Z.ShipSerl = @ShipSerl 
                      ) AS B ON ( 1 = 1 ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ShipSeq = @ShipSeq 
       AND A.ShipSerl = @ShipSerl         
    
    RETURN     
GO



