  
IF OBJECT_ID('mnpt_SPJTShipIFListIF') IS NOT NULL   
    DROP PROC mnpt_SPJTShipIFListIF
GO  
    
-- v2017.09.06
  
-- 모선조회-IF by 이재천
CREATE PROC mnpt_SPJTShipIFListIF  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0 
AS    
    
    exec mnpt_SPJTShipMasterIF @CompanySeq, @UserSeq, @PgmSeq
    
    RETURN  
