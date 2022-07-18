IF NOT EXISTS (select 1 from syscolumns where id = object_id('DTI_TLGLongStockItem') and name = 'ContractSeq')
BEGIN 
    ALTER TABLE DTI_TLGLongStockItem ADD ContractSeq INT NULL
    ALTER TABLE DTI_TLGLongStockItem ADD ContractSerl INT NULL
    ALTER TABLE DTI_TLGLongStockItemlog ADD ContractSeq INT NULL
    ALTER TABLE DTI_TLGLongStockItemlog ADD ContractSerl INT NULL
END