     
IF OBJECT_ID('mnpt_SPJTEECNTRReportListIF') IS NOT NULL       
    DROP PROC mnpt_SPJTEECNTRReportListIF      
GO      
      
-- v2017.11.07
      
-- 화면명-조회 by 이재천  
CREATE PROC mnpt_SPJTEECNTRReportListIF      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @IFOutDateFr  NCHAR(8), 
            @IFOutDateTo  NCHAR(8), 
            @IFWorkDateFr NCHAR(8), 
            @IFWorkDateTo NCHAR(8) 
      
    SELECT @IFOutDateFr = ISNULL( IFOutDateFr   , '' ),   
           @IFOutDateTo = ISNULL( IFOutDateTo   , '' ),   
           @IFWorkDateFr = ISNULL( IFWorkDateFr , '' ),   
           @IFWorkDateTo = ISNULL( IFWorkDateTo , '' )
      FROM #BIZ_IN_DataBlock1    

    exec mnpt_SPJTEECNTRReportIF 
        @CompanySeq = @CompanySeq, 
        @UserSeq = @UserSeq, 
        @PgmSeq = @PgmSeq, 
        @OutDateFr = @IFOutDateFr, 
        @OutDateTo = @IFOutDateTo, 
        @WorkDateFr = @IFWorkDateFr, 
        @WorkDateTo = @IFWorkDateTo 
    
    RETURN     