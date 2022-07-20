     
IF OBJECT_ID('mnpt_SPJTOperatorPriceItemQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTOperatorPriceItemQuery      
GO      
      
-- v2017.09.19
      
-- 운전원노임단가입력-SS2조회 by 이재천  
CREATE PROC mnpt_SPJTOperatorPriceItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StdSeq  INT 
      
    SELECT @StdSeq   = ISNULL( StdSeq, 0 )
      FROM #BIZ_IN_DataBlock1    
    
    
    -- 최종조회
    SELECT A.StdSeq, 
           A.StdSerl, 
           A.UMToolType, 
           B.MinorName AS UMToolTypeName, 
           C.ValueText AS UMEnToolTypeName, 
           ISNULL(D.PJTTypeCnt,0) AS PJTTypeCnt -- 입력된 화태건수
      FROM mnpt_TPJTOperatorPriceItem   AS A  
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMToolType ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN ( 
                        SELECT StdSeq, StdSerl, COUNT(1) AS PJTTypeCnt 
                          FROM mnpt_TPJTOperatorPriceSubItem 
                         WHERE CompanySeq = @CompanySeq 
                         GROUP BY StdSeq, StdSerl
                      ) AS D ON ( D.StdSeq = A.StdSeq AND D.StdSerl = A.StdSerl ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.StdSeq = @StdSeq 
    
    RETURN     


    
    go
