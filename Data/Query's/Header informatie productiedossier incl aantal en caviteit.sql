SELECT

	h.ProdHeaderDossiercode, 
	PartCode, 
	Description, 
	Qty, 
	(SELECT CASE WHEN FORMAT(TRY_CAST(LEFT(h1.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL THEN FORMAT(TRY_CAST(LEFT(h1.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') 
				 WHEN FORMAT(TRY_CAST(LEFT(h1.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL THEN FORMAT(TRY_CAST(LEFT(h1.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') 
				 WHEN FORMAT(TRY_CAST(LEFT(h1.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL THEN FORMAT(TRY_CAST(LEFT(h1.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') 
			END AS  Cavities FROM T_ProductionHeader h1 WHERE ProdHeaderDossierCode = (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode)) [Cavities]
	
FROM T_ProductionHeader h
WHERE 1=1
AND h.ProdHeaderDossiercode = '{Prodheaderdossiercode}'