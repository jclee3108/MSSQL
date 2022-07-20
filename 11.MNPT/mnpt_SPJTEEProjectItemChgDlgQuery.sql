     
IF OBJECT_ID('mnpt_SPJTEEProjectItemChgDlgQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEEProjectItemChgDlgQuery      
GO      
      
-- v2018.02.12
      
-- 청구항목변경-조회 by 이재천  
CREATE PROC mnpt_SPJTEEProjectItemChgDlgQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @PJTSeq     INT   
      
    SELECT @PJTSeq = ISNULL(PJTSeq,0)
      FROM #BIZ_IN_DataBlock1    
    
    SELECT A.PJTSeq,
           A.DelvSerl, 
           A.ItemSeq, 
           B.ItemName, 
           A.ItemSeq AS ItemSeqOld, 
           B.ItemName AS ItemNameOld 
      FROM _TPJTProjectDelivery     AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
    
    RETURN     