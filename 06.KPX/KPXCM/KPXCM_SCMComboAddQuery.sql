IF OBJECT_ID('KPXCM_SCMComboAddQuery') IS NOT NULL 
    DROP PROC KPXCM_SCMComboAddQuery
GO 

-- v2016.03.02 


/************************************************************  
 설  명 - 데이터-콤보추가_KPXCM : 조회  
 작성일 - 20150716  
 작성자 - 이배식  
 수정자 -   
************************************************************/  
  
CREATE PROC [dbo].[KPXCM_SCMComboAddQuery]                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    DECLARE @docHandle      INT,  
            @Para1     NVARCHAR(100) ,  
            @ComboSeq  INT ,  
            @Para2     NVARCHAR(100) ,  
            @Para3     NVARCHAR(100) ,  
            @Para4     NVARCHAR(100)    
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @ComboSeq  = ComboSeq   ,  
           @Para1     = Isnull(Para1,'')      ,  
           @Para2     = Isnull(Para2,'')      ,  
           @Para3     = Isnull(Para3,'')      ,  
           @Para4     = Isnull(Para4,'')        
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (ComboSeq   INT ,  
            Para1      NVARCHAR(100) ,  
            Para2      NVARCHAR(100) ,  
            Para3      NVARCHAR(100) ,  
            Para4      NVARCHAR(100) )  
              
    If @ComboSeq = 1   
    begin  
        SELECT distinct A.WorkCenterName     AS MinorName            
     ,A.WorkCenterSeq               AS MinorSeq         
     --,A.SMWorkCenterType   AS SMWorkCenterType         
     --,A.CustSeq            AS CustSeq            
     --,(SELECT MinorName FROM _TDASMinor WHERE CompanySeq = 2 AND MinorSeq = A.SMWorkCenterType) AS SMWorkCenterTypeName           
     --,(SELECT CustName  FROM _TDACust   WHERE CompanySeq = 2 AND CustSeq = A.CustSeq)           AS CustName                       
     --,(SELECT DeptName  FROM _TDADept   WHERE CompanySeq = 2 AND DeptSeq = A.DeptSeq)           AS DeptName                       
     --, A.DeptSeq  
     --,(SELECT FactUnitName FROM _TDAFactUnit WHERE CompanySeq = 2 AND FactUnit = A.FactUnit)    AS  FactUnitName                 
     --,A.FactUnit        
    from _TPDBaseWorkCenter   AS  A With(Nolock)      
      Join _TPDROUItemProcWC  AS  B With(nolock) ON A.CompanySeq = B.CompanySeq And A.WorkCenterSeq = B.WorkCenterSeq      
    WHERE A.CompanySeq = @CompanySeq    
    AND ( B.ItemSeq = convert(int,@Para1))  --사외외주,해외외주    
    and A.WorkCenterSeq in (select C.ValueSeq   
                            From _TDAUMinorValue      AS C With(Nolock)      
                                          Join _TDAUMinorValue AS D with(Nolock) ON D.CompanySeq = @CompanySeq And D.MajorSeq = 1011346 And C.MinorSeq = D.MinorSeq  and D.Serl = 1000004 And D.ValueText = '1' --처리  
                                    where  C.CompanySeq = @CompanySeq and C.MajorSeq = 1011346 And C.Serl = 1000001  )                  
    end  
    If @ComboSeq = 2 
    begin 
        select D.PatternRev+'['+convert(nvarchar,round(convert(Int,D.ProdQty),0))+'}' as MinorName
              ,D.PatternRev as MinorSeq
          from KPX_TPDProdProc AS D (Nolock)
         where D.CompanySeq = @CompanySeq
           and D.ItemSeq in (select distinct AssyItemSeq
                               from _TPDROUItemProcMat AS A With(nolock)
                                    Join _TPDROUItemProcWC AS B With(Nolock) ON A.CompanySeq = B.CompanySeq And A.ItemSeq = B.ItemSeq And A.BOMRev = B.BOMRev And A.ProcSeq = B.ProcSeq
                              where B.CompanySeq = @CompanySeq
                                and B.ItemSeq = @Para1
                                and B.WorkCenterSeq = @Para2)
           and isnull(D.UseYn,'0') = '0'

    
    
    end
    


RETURN


GO


exec KPXCM_SCMComboAddQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030905,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029271