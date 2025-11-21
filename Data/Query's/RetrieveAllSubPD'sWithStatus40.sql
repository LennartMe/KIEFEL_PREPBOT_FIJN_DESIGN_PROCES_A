Select
       PHT.OrdNr
,	   p.classnr
,	   PHT.ProdHeaderDossierCode
,      PHT.PartCode
,      PHT.Description
,      PHT.ProdStatusCode
,      PHT.ProdStatusDescription
,      PHT.StartDate
,      PHT.EndDate
,      PHT.LastUpdatedOn
,      PHT.Qty

From ProductionHeaderTree PHT
LEFT JOIN  [T_ProductionHeader] PHmain on PHmain.prodheaderdossiercode = (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PHT.ProdHeaderDossiercode)
LEFT JOIN [T_Part] p on p.PartCode = PHmain.PartCode

Where 1=1
AND PHT.ProdStatusCode IN ('40','41') --status = Gereed voor werkvoorbereiding
AND OrdNr <> '' --Must be in an order
--AND PHT.ORDNr = '20252508    '
--AND PHT.description LIKE '%tussenlijst boven%'
--and PHT.Qty = 19
--AND PHT.ProdHeaderDossierCode IN ('0000219457')
--AND PHT.ProdHeaderDossierCode IN ('0000219457')
--'0000218037',
--'0000216054',
--'0000206171'
--'0000216054',
--'0000216219',
--'0000216904',
--'0000216675',
--'0000216685',
--'0000216689',
--'0000216679'
--)
--AND OrdNr = '20252417'
AND (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PHT.ProdHeaderDossiercode) IS NOT NULL --Only sub pd's
Order By OrdNr, PHmain.ProdHeaderDossierCode, PHT.ProdHeaderDossierCode