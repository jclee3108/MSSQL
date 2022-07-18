IF OBJECT_ID('KPXCM_TPDSFCMatInputFIFORelation') IS NULL
BEGIN 
    CREATE TABLE KPXCM_TPDSFCMatInputFIFORelation
    (
        CompanySeq      INT 	    NOT NULL, 
        Seq             INT         NOT NULL, 
        WorkReportSeq   INT 	    NOT NULL, 
        ItemSerl        INT         NOT NULL, 
        InOutType       INT 	    NULL, 
        InOutSeq        INT         NULL, 
        LastUserSeq     INT 	    NULL, 
        LastDateTime    DATETIME    NULL
    ) 
    create unique clustered index idx_KPXCM_TPDSFCMatInputFIFORelation on KPXCM_TPDSFCMatInputFIFORelation(CompanySeq,Seq) 

END 


