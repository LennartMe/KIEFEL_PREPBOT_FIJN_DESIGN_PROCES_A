--Caviteit onafhankelijk Bewerkingstijden controle
DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{Prodheaderdossiercode}';

SELECT * FROM (
SELECT 
	Ordnr,
	Head_PD,
	Cavities,
	prodheaderdossiercode,
	Partcode,
	Cavities_Dummy,
	LineNr, 
	QTY_PD,
	QTY_DUMMY,
	MachGrpCode, 
	MachineUrenOld,
	--MachineUrenDummy,
	--MachineUrenDummyRounded,
	FORMAT(CAST((ROUND(((TRY_CAST(REPLACE(MachineUrenDummy, ',', '.') AS FLOAT) / TRY_CAST(REPLACE(QTY_DUMMY, ',', '.') AS FLOAT)) * TRY_CAST(REPLACE(QTY_PD, ',', '.') AS FLOAT)) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
		AS MachineUrenDummy_Calculated,
	--(CAST(MachineUrenDummy AS DECIMAL(10, 3)) / CAST(QTY_DUMMY AS DECIMAL(10, 3))) * CAST(QTY_PD AS DECIMAL(10, 3)) AS ManUrenDummy_Calculated,
	ManUrenOld, 
	--ManUrenDummy,
	--ManUrenDummyRounded,
	FORMAT(CAST((ROUND(((TRY_CAST(REPLACE(ManUrenDummy, ',', '.') AS FLOAT) / TRY_CAST(REPLACE(QTY_DUMMY, ',', '.') AS FLOAT)) * TRY_CAST(REPLACE(QTY_PD, ',', '.') AS FLOAT)) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
		AS ManUrenDummy_Calculated


	
FROM 

(SELECT
	dm.ordnr,
	h.ProdHeaderDossierCode [Head_PD],
	CASE 
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') 
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL')
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL')
		ELSE NULL 
	END AS [Cavities],
	m.ProdHeaderDossierCode,
	d.PartCode,
	'28,00' [Cavities_Dummy],
	m.LineNr,
    m.MachGrpCode,
	CASE WHEN m.MachCode = '     ' THEN '' ELSE m.Machcode END AS MachcodeOld,
	'' AS MachcodeNew,
    m.QTY [QTY_PD],
	d.QTY [QTY_DUMMY],
    FORMAT(CAST((m.MachCycleTime / 3600) as decimal(10,3)), 'N2', 'nl-NL') as [MachineUrenOld],
	CASE 
        WHEN m.MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
        WHEN PlanningBasedOnType = 2 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If Type is ManHours return 0,00 as new value for MachineHours
        WHEN (m.MachCycleTime = 0 OR m.MachCycleTime IS NULL) AND m.OccupationCycleTime > 0 AND FORMAT(CAST((ROUND((m.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00'
			THEN '0,10'  --If MachineHours is empty, but ManHours is filled in and above 0, but rounded ManHours is 0, then return 0,10 
		WHEN (m.MachCycleTime = 0 OR m.MachCycleTime IS NULL) AND m.OccupationCycleTime > 0 
			THEN FORMAT(CAST((ROUND((m.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')  --If MachineHours is empty, but ManHours is filled in, copy and round ManHours as new value for MachineHours
        WHEN FORMAT(CAST((ROUND((m.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00' 
             AND m.MachCycleTime > 0 
			THEN '0,10' --If MachineHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN m.MachCycleTime = 0  
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If MachineHours is 0, return as 0,00 
        ELSE FORMAT(CAST((ROUND((m.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
    END as [MachineUrenNew],
	    FORMAT(CAST((d.MachCycleTime / 3600) as decimal(10,3)), 'N2', 'nl-NL') as [MachineUrenDummy],
	CASE 
        WHEN d.MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
	    WHEN FORMAT(CAST((ROUND((d.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00' 
             AND d.MachCycleTime > 0 
			THEN '0,10' --If MachineHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN d.MachCycleTime = 0  
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If MachineHours is 0, return as 0,00 
        ELSE FORMAT(CAST((ROUND((d.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
    END as [MachineUrenDummyRounded],
	    (SELECT FORMAT(CAST((AVG(MachCycleTime) / 3600) as decimal(10,3)), 'N2', 'nl-NL') 
     FROM [T_ProdBillOfOper] s1
     WHERE s1.MachGrpCode = m.MachGrpCode 
       AND s1.ProdBOOLineNr = m.ProdBOOLineNr 
       AND s1.Qty = m.Qty 
       AND s1.PlanningBasedOnType = m.PlanningBasedOnType 
       AND StartDate > GETDATE() -365) as [AVG_MachineUren],
    FORMAT(CAST((m.OccupationCycleTime / 3600) as decimal(10,3)), 'N2', 'nl-NL') as [ManUrenOld],
	CASE 
        WHEN m.MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
        WHEN PlanningBasedOnType = 1 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If Type is MachineHours return 0,00 as new value for ManHours
        WHEN (m.OccupationCycleTime = 0 OR m.OccupationCycleTime IS NULL) AND m.MachCycleTime > 0 AND FORMAT(CAST((ROUND((m.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00'
			THEN '0,10'  --If ManHours is empty, but MachineHours is filled in and above 0, but rounded MachineHours is 0, then return 0,10 
		WHEN (m.OccupationCycleTime = 0 OR m.OccupationCycleTime IS NULL) AND m.MachCycleTime > 0 
			THEN FORMAT(CAST((ROUND((m.MachCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')  --If ManHours is empty, but MachineHours is filled in, copy and round MachineHours as new value for ManHours
        WHEN FORMAT(CAST((ROUND((m.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00' 
             AND m.OccupationCycleTime > 0 
			THEN '0,10' --If ManHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN m.OccupationCycleTime = 0  
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If ManHours is 0, return as 0,00 
        ELSE FORMAT(CAST((ROUND((m.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
    END as [ManUrenNew],
    (SELECT FORMAT(CAST((AVG(OccupationCycleTime) / 3600) as decimal(10,3)), 'N2', 'nl-NL') 
     FROM [T_ProdBillOfOper] s2
     WHERE s2.MachGrpCode = m.MachGrpCode 
       AND s2.ProdBOOLineNr = m.ProdBOOLineNr 
       AND s2.Qty = m.Qty 
       AND s2.PlanningBasedOnType = m.PlanningBasedOnType 
       AND StartDate > GETDATE() -365) as [AVG_ManUren],
	       FORMAT(CAST((d.OccupationCycleTime / 3600) as decimal(10,3)), 'N2', 'nl-NL') as [ManUrenDummy],
	CASE 
        WHEN d.MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
		WHEN FORMAT(CAST((ROUND((d.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL') = '0,00' 
             AND d.OccupationCycleTime > 0 
			THEN '0,10' --If ManHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN d.OccupationCycleTime = 0  
			THEN FORMAT(CAST(('0') as decimal(10,3)), 'N2', 'nl-NL') --If ManHours is 0, return as 0,00 
        ELSE FORMAT(CAST((ROUND((d.OccupationCycleTime / 3600) * 4,0) / 4.0) as decimal(10,3)), 'N2', 'nl-NL')
    END as [ManUrenDummyRounded],

    PlanningBasedOnType,
    CASE 
        WHEN PlanningBasedOnType = 2 THEN 'ManUren' 
        WHEN PlanningBasedOnType = 1 THEN 'MachineUren' 
        ELSE '' 
    END AS SoortUren
    
FROM [T_ProdBillOfOper] m
LEFT JOIN [T_ProductionHeader] h on h.ProdHeaderDossierCode = (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = m.ProdHeaderDossiercode)
INNER JOIN [T_ProductionHeader] h1 on h1.ProdHeaderDossierCode = m.ProdHeaderDossierCode
INNER JOIN [T_BillOfOper] d on d.PartCode = h1.PartCode and d.MachGrpCode = m.MachGrpCode
INNER JOIN [T_DossierMain] dm on dm.dossiercode = h.dossiercode

Where m.ProdHeaderDossierCode IN (@ProdHeaderDossierCode) AND d.PARTCODE IN (Select T_Part.PartCode From T_Part WITH (NOLOCK) Where Partcode <> '' and   PartObsInd = 0 and   PartGrpCode in ('MK'))
) sub1 ) sub2
WHERE ManUrenOld <> ManUrenDummy_Calculated OR MachineUrenOld <> MachineUrenDummy_Calculated
order by linenr
