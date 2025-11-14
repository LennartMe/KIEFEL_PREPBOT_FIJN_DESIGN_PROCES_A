DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{Prodheaderdossiercode}';

SELECT top 1
	d.OrdNr,
	bm.ProdHeaderDossierCode [HeadPD],
	phmain.PartCode [HeadPD_Partcode],
	phmain.Description [OrderDescription],
	P.ClassNr,
	bm.ProdBOMLineNr,
	PHPBL.ProdHeaderDossierCode,
	CAST(PHPBL.Qty as int) Qty,
	PHsub.PartCode,
	bm.Description,
	--phmain.DesignCode,
	--phsub.DesignCode,
	(SELECT top 1 dm.DocPathName FROM [T_DocumentDetail] DD
	LEFT JOIN [T_DocumentMain] DM ON DM.DocId = DD.DocId
	WHERE DD.IsahPrimKey = phsub.ProdHeaderDossierCode
	AND dm.docPathName LIKE '%.pdf') [DocPathName],
	            CASE   
                        WHEN (  
                                 SELECT TOP(1) 1  
                                 FROM   [dbo].T_ProdBillOfMat t1,  
                                        [dbo].T_Part t2,  
                                        [dbo].T_ProdHeadProdBomLink t3  
                                 WHERE  t1.ProdHeaderDossierCode = BMsub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMsub.ProdBOMLineNr  
                                        AND t2.PartCode = t1.SubPartCode  
                                        AND t3.ProdBOMProdHeaderDossierCode = t1.ProdHeaderDossierCode  
                                        AND t3.ProdBOMLineNr = t1.ProdBOMLineNr  
                                        AND t2.Stand = N''  
                             ) IS NOT NULL THEN (  
                                 SELECT MIN(t3.Stand)  
                                 FROM   [dbo].T_ProdHeadProdBomLink t1,  
                                        [dbo].T_ProdBillOfMat t2,  
                                        [dbo].T_Part t3,  
                                        [dbo].T_PartGrp t4  
                                 WHERE  t1.ProdBOMProdHeaderDossierCode = BMsub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMsub.ProdBOMLineNr  
                                        AND t2.ProdHeaderDossierCode = t1.ProdHeaderDossierCode  
                                        AND t3.PartCode = t2.SubPartCode  
                                        AND NOT t3.Stand = N''  
                                        AND t4.PartGrpCode = t3.PartGrpCode  
                                        AND t4.PartGrpMainCode IN ('ALUM', 'HYTA', 'KUNS', 'METO', 'STAA', 'TEKB')  
                             )  
                        ELSE (  
                                 SELECT t1.Stand  
                                 FROM   [dbo].T_Part t1 WITH (NOLOCK),  
                                        [dbo].T_PartGrp t2 WITH (NOLOCK)  
                                 WHERE  t1.PartCode = BMsub.SubPartCode  
                                        AND t2.PartGrpCode = t1.PartGrpCode  
                                        AND t2.PartGrpMainCode IN ('ALUM', 'HYTA', 'KUNS', 'METO', 'STAA', 'TEKB')  
                             )  
                   END  AS [WerkstofNr],
				   
	CASE 
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PHmain.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PHmain.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PHmain.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PHmain.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') 
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PHmain.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PHmain.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PHmain.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PHmain.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL')
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PHmain.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PHmain.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PHmain.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PHmain.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL')
			ELSE '28,00' --Default value in case of no Cavity
	END AS [Cavities]
  FROM [T_prodbillofmat] bm
	--Head PD info:
	LEFT JOIN  [T_ProductionHeader] PHmain on PHmain.prodheaderdossiercode = bm.prodheaderdossiercode
	LEFT JOIN  [T_DossierMain] d on PHmain.DossierCode = d.DossierCode
	--PD Info:
	LEFT JOIN  [T_ProdHeadProdBOMLink] PHPBL on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
	LEFT JOIN  [T_ProductionHeader] PHsub on PHsub.prodheaderdossiercode = PHPBL.prodheaderdossiercode
	LEFT JOIN [T_prodbillofmat] BMsub on BMsub.prodheaderdossiercode = PHPBL.prodheaderdossiercode
	LEFT JOIN  [T_Part] p on p.PartCode = PHmain.PartCode
  WHERE 1=1
  AND BMsub.Remark <> 'Vervallen'
  AND PHPBL.ProdHeaderDossierCode = @ProdHeaderDossierCode
  Order by bmSub.PartPos