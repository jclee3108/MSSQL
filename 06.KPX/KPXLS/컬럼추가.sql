if not exists (select 1 from syscolumns where id = object_id('KPXLS_TQCCOAPrint') and name = 'FromPgmSeq')
begin
    ALTER TABLE KPXLS_TQCCOAPrint ADD FromPgmSeq INT NULL 
    ALTER TABLE KPXLS_TQCCOAPrintLog ADD FromPgmSeq INT NULL 
end

if not exists (select 1 from syscolumns where id = object_id('KPXLS_TQCCOAPrint') and name = 'SourceSeq')
begin
    ALTER TABLE KPXLS_TQCCOAPrint ADD SourceSeq INT NULL 
    ALTER TABLE KPXLS_TQCCOAPrintLog ADD SourceSeq INT NULL 
end

if not exists (select 1 from syscolumns where id = object_id('KPXLS_TQCCOAPrint') and name = 'SourceSerl')
begin
    ALTER TABLE KPXLS_TQCCOAPrint ADD SourceSerl INT NULL 
    ALTER TABLE KPXLS_TQCCOAPrintLog ADD SourceSerl INT NULL 
end

