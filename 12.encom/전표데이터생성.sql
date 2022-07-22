select * from _TESMCProdSlipM where companyseq = 1 and transSeq = 3132
select * From _TESMCProdSlipD where companyseq = 1 and transSeq = 3132

select * From _TACSlip where SlipMstSeq = 176765 
select * From _TACSlipRow where SlipMstSeq = 176765
select * from _TACSlipRem where SlipSeq IN ( select SlipSeq From _TACSlipRow where SlipMstSeq = 176765 )  
select * from _TACSlipCost where SlipSeq IN ( select SlipSeq From _TACSlipRow where SlipMstSeq = 176765 )  
select * From _TACSlipAutoTempEnvKey where slipkindno = 'FrmESMCProdCostSlip' and KeyColumn1 = '3132'
select * From _TACSlip_Confirm where CfmSeq = 176765 
select * from _TACSlipSetData where SlipMstSeq = 176765 


