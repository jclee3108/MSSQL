  
IF OBJECT_ID('KPX_SPDMRPMonthItemCheck') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthItemCheck  
GO  
  
-- v2014.12.16 
  
-- 월별자재소요계산- 품목 체크 by 이재천   
CREATE PROC KPX_SPDMRPMonthItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDMRPMonthItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDMRPMonthItem'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET Serl = DataSeq 
      FROM #KPX_TPDMRPMonthItem AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #KPX_TPDMRPMonthItem 
    
    RETURN  
GO 
exec KPX_SPDMRPMonthItemCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0</Total>
    <Value>-368072</Value>
    <TITLE_IDX0_SEQ>201501</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>소요량</KindName>
    <KindSeq>2</KindSeq>
    <Total>591272</Total>
    <Value>368072</Value>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>소요량</KindName>
    <KindSeq>2</KindSeq>
    <Total>591272</Total>
    <Value>223200</Value>
    <TITLE_IDX0_SEQ>201501</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>부족량</KindName>
    <KindSeq>3</KindSeq>
    <Total>-591272</Total>
    <Value>-368072</Value>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>부족량</KindName>
    <KindSeq>3</KindSeq>
    <Total>-591272</Total>
    <Value>-591272</Value>
    <TITLE_IDX0_SEQ>201501</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>201412</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>3</ROW_IDX>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0</Total>
    <Value>-64072</Value>
    <TITLE_IDX0_SEQ>201501</TITLE_IDX0_SEQ>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026809,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021412