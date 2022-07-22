if objecT_id('hencom_SSLCreditDataAllCreate') is not null
    drop proc hencom_SSLCreditDataAllCreate
go 


create proc hencom_SSLCreditDataAllCreate

as 

    declare @count      int, 
            @seq        int, 
            @MaxSerl    int 
    
    create table #TSLReceipt_Cust 
    (
        idx_no          int identity, 
        CustSeq         INT 
    )

    insert into #TSLReceipt_Cust ( custseq ) 
    SELECT DISTINCT A.CustSeq
      FROM _TSLReceipt AS A 
     where not exists (Select 1 from hencom_TSLCreditLimitM where companyseq = 1 and custseq = a.custseq )  

    select @count = Count(1) from #TSLReceipt_Cust AS A 

    IF @Count > 0  
    BEGIN  

        --select @count 


        EXEC @seq = dbo._SCOMCreateSeq 1, 'hencom_TSLCreditLimitM', 'CLSeq', @count  

        insert into hencom_TSLCreditLimitM 
        select 1, @seq + idx_no, custseq, 1, 1, '1', '老褒 积己', 1, getdate()
          from #TSLReceipt_Cust 


    end 
    
    

    SELECT A.CLSeq, A.CustSeq, B.DeptSeq
      into #CLSerl 
      FROM hencom_TSLCreditLimitM AS A 
      LEFT OUTER JOIN hencom_TSLCreditLimitD AS B ON ( B.CompanySeq = 1 and b.clseq = a.clseq )
     where a.companyseq = 1 
     --GROUP BY A.CLSeq, A.CustSeq
    
    SELECT A.CLSeq, A.CustSeq, MAX(ISNULL(B.CLSerl,0)) AS CLSerl 
      into #MAXSerl  
      FROM hencom_TSLCreditLimitM AS A 
      LEFT OUTER JOIN hencom_TSLCreditLimitD AS B ON ( B.CompanySeq = 1 and b.clseq = a.clseq )
     where a.companyseq = 1 
     GROUP BY A.CLSeq, A.CustSeq



    create table #TSLReceipt_Dept 
    (
        idx_no          int identity, 
        CustSeq         INT, 
        DeptSeq         int 
    )

    insert into #TSLReceipt_Dept ( custseq, DeptSeq ) 
    SELECT DISTINCT A.CustSeq,DeptSeq
      FROM _TSLReceipt AS A 
     where not exists (Select 1 from #CLSerl where companyseq = 1 and custseq = a.custseq and deptseq = a.deptseq  )  


     select b.CLSeq, A.CustSeq, a.deptseq, row_number() over(partition by clseq order by clseq) as idx_no 
       into #temp 
       from #TSLReceipt_Dept AS A 
       left outer join hencom_TSLCreditLimitM as b on ( B.companyseq = 1 and b.custseq = a.custseq ) 
     
     
     insert into hencom_TSLCreditLimitD 
     select 1 as companyseq, 
            a.clseq, a.clserl + b.idx_no as clserl, 
            1 as creditamt, 
            '老褒 积己' as Remark,
            1 as LastuserSeq, 
            getdate() as lastdatetime, 
            b.deptseq 
       from #MAXSerl AS A 
       JOIN #temp As b on ( b.clseq = a.clseq ) 
    
return 
go
begin tran 
    exec hencom_SSLCreditDataAllCreate
rollback 