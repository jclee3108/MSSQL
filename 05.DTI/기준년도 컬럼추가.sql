if not exists (select 1 from syscolumns where id = object_id('DTI_TPNCostItem') and name = 'STDYear')
begin
    ALTER TABLE DTI_TPNCostItem ADD STDYear NCHAR(4)
    ALTER TABLE DTI_TPNCostItemLog ADD STDYear NCHAR(4)
end
if not exists (select 1 from syscolumns where id = object_id('DTI_TPNCostItem') and name = 'CostNameSort')
begin
    ALTER TABLE DTI_TPNCostItem ADD CostNameSort INT
        ALTER TABLE DTI_TPNCostItemLog ADD CostNameSort INT
end