
if object_id('KPXLS_TPDSFCMatInputRelation') is null
begin 

    CREATE TABLE KPXLS_TPDSFCMatInputRelation
    (
        CompanySeq      INT NOT NULL, 
        WorkReportSeq   INT NOT NULL, 
        ItemSerl        INT NOT NULL,
        InOutType       INT NOT NULL, 
        InOutSeq        INT NOT NULL, 
        LastUserSeq     INT NOT NULL, 
        LastDateTime    DATETIME NOT NULL 
    )

end 
