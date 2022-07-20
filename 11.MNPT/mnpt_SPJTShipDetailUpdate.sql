IF OBJECT_ID('mnpt_SPJTShipDetailUpdate') IS NOT NULL 
    DROP PROC mnpt_SPJTShipDetailUpdate
GO 

-- 운영정보System Update (입항,접안,출항) 

-- v2017.12.04 by이재천 
CREATE PROC mnpt_SPJTShipDetailUpdate
    @CompanySeq     INT 
AS 
    
    -- ERP 모선항차 입항,접안,출항 데이터를 운영정보System에 반영한다.
    UPDATE A
       SET A.ATA = B.InDateTime, 
           A.ATB = B.ApproachDateTime, 
           A.ATD = B.OutDateTime
      FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSEL ') AS A 
      JOIN mnpt_TPJTShipDetail                          AS B ON ( B.CompanySeq = @CompanySeq 
                                                              AND B.IFShipCode = A.VESSEL 
                                                              AND LEFT(B.ShipSerlNo,4) = A.VES_YY 
                                                              AND CONVERT(INT,RIGHT(B.ShipSerlNo,3)) = A.VES_SEQ 
                                                                ) 
     WHERE A.ATA <> B.InDateTime          -- 입항일시
        OR A.ATB <> B.ApproachDateTime    -- 잡안일시 
        OR A.ATD <> B.OutDateTime         -- 출항일시 
    

RETURN 

GO 

