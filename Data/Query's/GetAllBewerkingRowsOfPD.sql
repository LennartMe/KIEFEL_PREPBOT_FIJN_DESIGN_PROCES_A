DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{ProdHeaderDossierCode}';

DECLARE @QuantityNew FLOAT
SET @QuantityNew = '{QuantityNew}'; -- gewenste nieuwe hoeveelheid

SELECT DISTINCT
    LineNr,
    CASE WHEN Next_LineNr IS NULL THEN '' ELSE Next_LineNr END as Next_lineNr, 
	CASE WHEN Next_LineNr2 IS NULL THEN '' ELSE Next_LineNr2 END as Next_lineNr2, 
    partcode, 
    ProdBOOLineNr, 
    MachGrpCode,
    CASE WHEN Previous_LineNr IS NOT NULL AND Next_LineNr IS NOT NULL THEN 'True' ELSE 'False' END as [Tussenvoegen],
    ProdBOOPartDescription,
	Qty AS [Qty_Old],
    @QuantityNew AS Qty,
	[Uren Type]	,
    MachineUren,
    Dummy_MachineUren,
	-- MachineUrenPercentageVerschil
		CASE 
		    WHEN TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3)) IS NULL 
		         OR TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3)) = 0 
		    THEN '0,00 %'
		    WHEN TRY_CAST(REPLACE(Dummy_Machineuren, ',', '.') AS decimal(10,3)) = TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3)) 
		    THEN '0,00 %'
		    ELSE 
		        (CASE 
		            WHEN TRY_CAST(REPLACE(Dummy_Machineuren, ',', '.') AS decimal(10,3)) > TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3)) 
		            THEN '-' ELSE '+' 
		        END) + FORMAT(ABS(
		            (TRY_CAST(REPLACE(Dummy_Machineuren, ',', '.') AS decimal(10,3)) 
		            - TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3)))
		            * 100.0 
		            / TRY_CAST(REPLACE(Machineuren, ',', '.') AS decimal(10,3))
		        ), 'N2', 'nl-NL') + ' %'
		END AS [MachineUrenPercentageVerschil],
	Manuren,
    Dummy_Manuren,
	

	-- ManUrenPercentageVerschil
		CASE 
		    WHEN TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3)) IS NULL 
		         OR TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3)) = 0 
		    THEN '0,00 %'
		    WHEN TRY_CAST(REPLACE(Dummy_Manuren, ',', '.') AS decimal(10,3)) = TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3)) 
		    THEN '0,00 %'
		    ELSE 
		        (CASE 
		            WHEN TRY_CAST(REPLACE(Dummy_Manuren, ',', '.') AS decimal(10,3)) > TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3)) 
		            THEN '-' ELSE '+' 
		        END) + FORMAT(ABS(
		            (TRY_CAST(REPLACE(Dummy_Manuren, ',', '.') AS decimal(10,3)) 
		            - TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3)))
		            * 100.0 
		            / TRY_CAST(REPLACE(Manuren, ',', '.') AS decimal(10,3))
		        ), 'N2', 'nl-NL') + ' %'
		END AS [ManUrenPercentageVerschil],
	Memo,
	Cavities,
	CavitiesDecimal

FROM (
    SELECT 
        ph.partcode,
        prpreviousinfo.LineNr [Previous_LineNr],
        pboo.linenr,
        MIN(prnextinfo.LineNr) OVER (PARTITION BY pboo.LineNr) AS Next_LineNr, 
		Case WHEN MIN(prnextinfo.LineNr) OVER (PARTITION BY pboo.LineNr) <> MAX(prnextinfo.LineNr) OVER (PARTITION BY pboo.LineNr) THEN MAX(prnextinfo.LineNr) OVER (PARTITION BY pboo.LineNr) END AS Next_LineNr2,  
        prprevious.ProdBOOLineNr [Previous_prodBOOLineNr],
        pboo.prodboolinenr,
        prnext.ToBOOLineNr [Next_ProdBOOLineNr],
        pboo.MachGrpCode, 
        pboo.ProdBOOPartDescription, 
        pboo.Qty,
		CASE 
		WHEN HTPOT.MachGrpCode IS NOT NULL THEN HTPOT.[Uren Type]
        WHEN pboo.PlanningBasedOnType = 2 THEN 'ManUren'
        WHEN pboo.PlanningBasedOnType = 1 THEN 'MachineUren'
        ELSE '' 
    END AS [Uren Type],

        CASE
		WHEN HTPOT.PlanningBasedOnType IS NOT NULL
         AND HTPOT.PlanningBasedOnType = 2 THEN '0,00'
		WHEN HTPOT.PlanningBasedOnType IS NULL
         AND pboo.PlanningBasedOnType = 2 THEN '0,00'
		WHEN pboo.MachCycleTime > 0 
			THEN (CASE WHEN pboo.MachGrpCode IN ('DSO','FR','VO','CAM') THEN FORMAT(ISNULL(CAST((ISNULL(pboo.MachCycleTime, 0) / NULLIF(pboo.Qty, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
																		ELSE FORMAT(ISNULL(CAST((ISNULL(pboo.MachCycleTime, 0) / NULLIF(pboo.Qty, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') END)
			ELSE (CASE WHEN pboo.MachGrpCode IN ('DSO','FR','VO','CAM') THEN FORMAT(ISNULL(CAST((ISNULL(DUMMY.MachCycleTime, 0) / NULLIF(pboo.Qty, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
																		ELSE FORMAT(ISNULL(CAST((ISNULL(DUMMY.MachCycleTime, 0) / NULLIF(pboo.Qty, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') END)
			END AS [MachineUren], 
        
        CASE WHEN CQRI.FormRelated = 1 
		THEN 
		FORMAT(ISNULL(CAST((ISNULL(DUMMY.MachCycleTime, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL')
		ELSE 
		FORMAT(ISNULL(CAST((ISNULL(DUMMY.MachCycleTime, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
		END AS [Dummy_MachineUren],


        CASE
		WHEN HTPOT.PlanningBasedOnType IS NOT NULL
         AND HTPOT.PlanningBasedOnType = 1 THEN '0,00'
		WHEN HTPOT.PlanningBasedOnType IS NULL
         AND pboo.PlanningBasedOnType = 1 THEN '0,00'
		WHEN pboo.OccupationCycleTime > 0
			THEN (CASE WHEN pboo.MachGrpCode IN ('DSO','FR','VO','CAM') THEN FORMAT(ISNULL(CAST((ISNULL(pboo.OccupationCycleTime, 0) / NULLIF(pboo.Qty, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
																		ELSE FORMAT(ISNULL(CAST((ISNULL(pboo.OccupationCycleTime, 0) / NULLIF(pboo.Qty, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') END)
			ELSE (CASE WHEN pboo.MachGrpCode IN ('DSO','FR','VO','CAM') THEN FORMAT(ISNULL(CAST((ISNULL(DUMMY.OccupationCycleTime, 0) / NULLIF(pboo.Qty, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
																		ELSE FORMAT(ISNULL(CAST((ISNULL(DUMMY.OccupationCycleTime, 0) / NULLIF(pboo.Qty, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') END)
			END AS [Manuren], 

        CASE WHEN CQRI.FormRelated = 1 
		THEN 
		FORMAT(ISNULL(CAST((ISNULL(DUMMY.OccupationCycleTime, 0) * @QuantityNew / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL')
		ELSE 
		FORMAT(ISNULL(CAST((ISNULL(DUMMY.OccupationCycleTime, 0) / 3600.0) AS decimal(10,3)), 0), 'N2', 'nl-NL') 
		END AS [Dummy_Manuren],


        pboo.info [Memo],
		CASE 
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PH.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PH.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') 
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PH.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PH.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL')
			WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(PH.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
			THEN FORMAT(TRY_CAST(LEFT(PH.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL')
			ELSE '28,00' --Default value in case of no Cavity
	END AS [Cavities],
	cav.CavitiesDecimal

    FROM T_ProdBillOfOper pboo
	LEFT JOIN [StarcodeRPA].[dbo].[HourTypePerOperationType] HTPOT 
		on HTPOT.MachGrpCode = pboo.MachGrpCode 
    LEFT JOIN T_ProductionRouting prnext 
        ON prnext.ProdHeaderDossierCode = pboo.ProdHeaderDossierCode AND prnext.ProdBOOLineNr = pboo.ProdBOOLineNr
    LEFT JOIN T_ProdBillOfOper prnextinfo 
        ON prnext.ProdHeaderDossierCode = prnextinfo.ProdHeaderDossierCode AND prnext.ToBOOLineNr = prnextinfo.ProdBOOLineNr
    LEFT JOIN T_ProductionRouting prprevious 
        ON prprevious.ProdHeaderDossierCode = pboo.ProdHeaderDossierCode AND prprevious.ToBOOLineNr = pboo.ProdBOOLineNr
    LEFT JOIN T_ProdBillOfOper prpreviousinfo 
        ON prprevious.ProdHeaderDossierCode = prpreviousinfo.ProdHeaderDossierCode AND prprevious.ProdBOOLineNr = prpreviousinfo.ProdBOOLineNr
    LEFT JOIN T_ProductionHeader ph 
        ON ph.ProdHeaderDossierCode = pboo.ProdHeaderDossierCode
    LEFT JOIN [StarcodeRPA]..CheckQuantityRefInfo CQRI on CQRI.Partcode = ph.PartCode
	OUTER APPLY (
    SELECT TOP 1 * 
    FROM T_BillOfOper dummy
    WHERE dummy.PartCode = ph.PartCode 
      AND dummy.MachGrpCode = pboo.MachGrpCode
      AND dummy.LineNr IS NOT NULL

    ORDER BY ABS(dummy.LineNr - pboo.ProdBOOLineNr)
) AS DUMMY
OUTER APPLY (
    SELECT 
        CAST(
            CASE 
                WHEN (SELECT MIN(ProdBOMProdHeaderDossierCode) 
                      FROM T_ProdHeadProdBOMLink PHPBL 
                      WHERE PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL
                     AND TRY_CAST(LEFT(PH.Description, 3) AS decimal(10,2)) IS NOT NULL
                     AND (SELECT COUNT(*) 
                          FROM [T_ProdBillOfMat] bm 
                          WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
                THEN TRY_CAST(LEFT(PH.Description, 3) AS decimal(10,2))

                WHEN (SELECT MIN(ProdBOMProdHeaderDossierCode) 
                      FROM T_ProdHeadProdBOMLink PHPBL 
                      WHERE PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL
                     AND TRY_CAST(LEFT(PH.Description, 2) AS decimal(10,2)) IS NOT NULL
                     AND (SELECT COUNT(*) 
                          FROM [T_ProdBillOfMat] bm 
                          WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
                THEN TRY_CAST(LEFT(PH.Description, 2) AS decimal(10,2))

                WHEN (SELECT MIN(ProdBOMProdHeaderDossierCode) 
                      FROM T_ProdHeadProdBOMLink PHPBL 
                      WHERE PHPBL.ProdHeaderDossierCode = PH.ProdHeaderDossiercode) IS NULL
                     AND TRY_CAST(LEFT(PH.Description, 1) AS decimal(10,2)) IS NOT NULL
                     AND (SELECT COUNT(*) 
                          FROM [T_ProdBillOfMat] bm 
                          WHERE bm.ProdHeaderDossierCode = PH.ProdHeaderDossierCode) > 0
                THEN TRY_CAST(LEFT(PH.Description, 1) AS decimal(10,2))

                ELSE 28.00
            END AS decimal(10,2)
        ) AS CavitiesDecimal
) cav
    WHERE pboo.ProdHeaderDossierCode = @ProdHeaderDossierCode
      AND pboo.ProdHeaderDossierCode <> ''
) sub
order by LineNr

