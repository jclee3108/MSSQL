IF OBJECT_ID('_SCOMGroupWareStatus_hyei') IS NOT NULL 
    DROP PROC _SCOMGroupWareStatus_hyei
GO 

-- v2017.01.04
-- Status 후처리 
CREATE PROC _SCOMGroupWareStatus_hyei
    @pWorkingTag      NCHAR(1),    
    @CompanySeq       INT = 1,        
    @LanguageSeq      INT = 1,        
    @UserSeq          INT = 0,        
    @WorkKind         NVARCHAR(40) = '',     
    @TblKey           NVARCHAR(40) = '', -- 넘겨준 키를 그대로 보낸다.    
    @TopUserName      NVARCHAR(50) = '',    
    @TopUserPosition  NVARCHAR(50) = '',    
    @RevUserName      NVARCHAR(50) = '',    
    @RevUserPosition  NVARCHAR(50) = '',    
    @DocID            NVARCHAR(MAX) = '',      
    @MessageType      INT  OUTPUT,      
    @Status           INT  OUTPUT,      
    @Results          NVARCHAR(250) OUTPUT     
AS     
    
    IF @pWorkingTag = 'E' AND @WorkKind = 'Cust_hye' 
    BEGIN   
        
        UPDATE A
           SET SMCustStatus = 2004998
          FROM _TDACust AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.CustSeq = CONVERT(INT,@TblKey)
            
        SELECT @Results = '', @Status = 0, @MessageType = 0     
    
    END 
    ELSE 
    BEGIN
        SELECT @Results = '', @Status = 0, @MessageType = 0     
    END 
      
    RETURN  
    