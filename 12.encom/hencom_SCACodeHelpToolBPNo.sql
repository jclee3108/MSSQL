IF OBJECT_ID('hencom_SCACodeHelpToolBPNo') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpToolBPNo
GO 

-- v2017.03.09 

-- BPNo CodeHelp by이재천             
CREATE PROCEDURE hencom_SCACodeHelpToolBPNo
    @WorkingTag     NVARCHAR(1),                              
    @LanguageSeq    INT,                              
    @CodeHelpSeq    INT,                              
    @DefQueryOption INT, -- 2: direct search                              
    @CodeHelpType   TINYINT,                              
    @PageCount      INT = 20,                   
    @CompanySeq     INT = 1,                             
    @Keyword        NVARCHAR(50) = '',                              
    @Param1         NVARCHAR(50) = '',                  
    @Param2         NVARCHAR(50) = '',                  
    @Param3         NVARCHAR(50) = '',                  
    @Param4         NVARCHAR(50) = ''                  
AS     
        
    SET ROWCOUNT @PageCount                            
    
    --select * from _TDASMinor where majorseq = 6023 

    SELECT B.MngValText AS BPNo, 
           A.ToolSeq, 
           A.ToolName, 
           A.ToolNo, 
           A.Spec, 
           A.Capacity 
           
      FROM _TPDTool                     AS A 
      LEFT OUTER JOIN _TPDToolUserDefine AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq AND B.MngSerl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DeptSeq = CONVERT(INT,@Param1)
       AND ( @Keyword = '' OR B.MngValText LIKE '%' + @Keyword + '%')
       AND A.SMStatus = 6023001 -- 상태가 정산인건
    
    SET ROWCOUNT 0           
               
RETURN
GO
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1021795',@Keyword=N'%%',@Param1=N'42',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'',@BizUnit=0,@FactUnit=0,@DeptSeq=0,@WkDeptSeq=0,@EmpSeq=1,@UserSeq=1