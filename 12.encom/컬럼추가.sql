if not exists (select 1 from syscolumns where id = object_id('hencom_TPNPJT') and name = 'UMDistanceDegree')
begin
    ALTER TABLE hencom_TPNPJT ADD UMDistanceDegree INT 
    ALTER TABLE hencom_TPNPJTLog ADD UMDistanceDegree INT 
end
