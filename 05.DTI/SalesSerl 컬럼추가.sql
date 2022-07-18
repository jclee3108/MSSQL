if not exists (select 1 from syscolumns where id = object_id('DTI_TSLInterBillingItemEmp') and name = 'SalesSerl')
begin
    ALTER TABLE DTI_TSLInterBillingItemEmp ADD SalesSerl INT
    ALTER TABLE DTI_TSLInterBillingItemEmpLog ADD SalesSerl INT
end