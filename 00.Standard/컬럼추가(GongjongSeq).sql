IF NOT EXISTS (SELECT 1 FROM SYSCOLUMNS WHERE id = object_id('_TDAUMToolKindTreeCHE') and name = 'GongjongSeq'  )
BEGIN 
    ALTER TABLE _TDAUMToolKindTreeCHE ADD GongjongSeq INT Null 
END   
IF NOT EXISTS (SELECT 1 FROM SYSCOLUMNS WHERE id = object_id('_TDAUMToolKindTreeCHELog') and name = 'GongjongSeq'  )
BEGIN 
    ALTER TABLE _TDAUMToolKindTreeCHELog ADD GongjongSeq INT Null 
END   