  SELECT MG.MachGrpCode
 
  FROM   dbo.T_MachGrp MG  
  WHERE  MG.MachGrpCode > N''  
  AND MG.DeptCode IN ('BAFR','DRAA','EX','FREZ','MA01','MA02','ZG','TEK2')
  AND MG.MachGrpCode NOT IN ('PLM','SGVK','VER')
  ORDER BY 1  
