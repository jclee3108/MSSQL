if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'SaveComplete5')
begin
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD SaveComplete5 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD SaveComplete5 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD SaveComplete4 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD SaveComplete4 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD SaveComplete3 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD SaveComplete3 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD SaveComplete2 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD SaveComplete2 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD SaveComplete1 NCHAR(1) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD SaveComplete1 NCHAR(1) NULL 
end


if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'TeamLeaderDate5')
begin
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderDate5 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderDate5 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderDate4 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderDate4 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderDate3 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderDate3 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderDate2 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderDate2 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderDate1 NCHAR(8) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderDate1 NCHAR(8) NULL 
end

if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'TeamLeaderRemark5')
begin
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderRemark5 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderRemark5 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderRemark4 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderRemark4 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderRemark3 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderRemark3 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderRemark2 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderRemark2 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderRemark1 NVARCHAR(500) NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderRemark1 NVARCHAR(500) NULL 
end


if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'TeamLeaderSeq5')
begin
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderSeq5 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderSeq5 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderSeq4 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderSeq4 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderSeq3 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderSeq3 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderSeq2 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderSeq2 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD TeamLeaderSeq1 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD TeamLeaderSeq1 INT NULL 
end

if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'ResultSeq5')
begin
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD ResultSeq5 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD ResultSeq5 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD ResultSeq4 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD ResultSeq4 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD ResultSeq3 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD ResultSeq3 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD ResultSeq2 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD ResultSeq2 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHE ADD ResultSeq1 INT NULL 
    ALTER TABLE KPXCM_TEQTaskOrderCHELog ADD ResultSeq1 INT NULL 
end