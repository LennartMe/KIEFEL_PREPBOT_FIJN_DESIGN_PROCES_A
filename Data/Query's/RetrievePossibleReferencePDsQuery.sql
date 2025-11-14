DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{ProdHeaderDossierCode}';
DECLARE @FirstTwoOfPartcode varchar(255);
DECLARE @Partcode varchar(255);
DECLARE @Description varchar(255);
DECLARE @DUMMY_Description varchar(255);
DECLARE @ClassNr varchar(255);
DECLARE @WerkstofNr varchar(255);
DECLARE @Ref_Length NUMERIC(7,4);
DECLARE @Ref_Width NUMERIC(7,4);
DECLARE @Ref_Height NUMERIC(7,4);

--Assets values:
DECLARE @LengthPercentage FLOAT = '{LengthPercentage}';
DECLARE @WidthPercentage  FLOAT = '{WidthPercentage}';
DECLARE @HeightPercentage FLOAT = '{HeightPercentage}';

SELECT 
  @Partcode = LOWER(phsub.PartCode),
  @FirstTwoOfPartcode = LOWER(LEFT(LTRIM(phsub.PartCode), 2)),
  @ClassNr = P.Classnr,
  @Description = BMSub.Description,
  @DUMMY_Description = p.Description,
  @Ref_Length = BMSub.NetLength,
  @Ref_Width = BMSub.NetWidth,
  @Ref_Height = BMSub.NetHeight,
  @WerkstofNr = (  
            SELECT CASE   
                        WHEN (  
                                 SELECT TOP(1) 1  
                                 FROM   [dbo].T_ProdBillOfMat t1,  
                                        [dbo].T_Part t2,  
                                        [dbo].T_ProdHeadProdBomLink t3  
                                 WHERE  t1.ProdHeaderDossierCode = BMSub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMSub.ProdBOMLineNr  
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
                                 WHERE  t1.ProdBOMProdHeaderDossierCode = BMSub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMSub.ProdBOMLineNr  
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
                                 WHERE  t1.PartCode = BMSub.SubPartCode  
                                        AND t2.PartGrpCode = t1.PartGrpCode  
                                        AND t2.PartGrpMainCode IN ('ALUM', 'HYTA', 'KUNS', 'METO', 'STAA', 'TEKB')  
                             )  
                   END  
        )

  FROM [T_prodbillofmat] bm WITH (NOLOCK)
	--Head PD info:
	LEFT JOIN  [T_ProductionHeader] PHmain WITH (NOLOCK) on PHmain.prodheaderdossiercode = bm.prodheaderdossiercode
	LEFT JOIN [T_DossierMain] d WITH (NOLOCK) on PHmain.DossierCode = d.DossierCode
	--PD Info:
	LEFT JOIN [T_ProdHeadProdBOMLink] PHPBL WITH (NOLOCK) on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
	LEFT JOIN [T_ProductionHeader] PHsub WITH (NOLOCK) on PHsub.prodheaderdossiercode = PHPBL.prodheaderdossiercode
	LEFT JOIN [T_ProdBillOfMat] BMsub WITH (NOLOCK) on BMSub.prodheaderdossiercode = PHPBL.prodheaderdossiercode and BMSub.PartPos = 0
	LEFT JOIN [T_Part] p WITH (NOLOCK) on p.PartCode = PHmain.PartCode
	LEFT JOIN [T_Part] Psub WITH (NOLOCK) on Psub.PartCode = bm.SubPartCode
  WHERE 1=1
  AND PHPBL.ProdHeaderDossierCode = @ProdHeaderDossierCode
  ;

  WITH Scored AS (SELECT * FROM (
  SELECT 
	d.OrdNr,
	d.OrdDate,
	bm.ProdHeaderDossierCode [HeadPD],
	phmain.PartCode [HeadPD_Partcode],
	phmain.Description [OrderDescription],
	P.ClassNr,
	bm.ProdBOMLineNr,
	PHPBL.ProdHeaderDossierCode,
	phsub.partcode,
	--CAST(PHPBL.Qty as int) Qty,
	bm.Description [PD Description],
	--phmain.DesignCode,
	--phsub.DesignCode,
	(SELECT top 1 dm.DocPathName FROM [T_DocumentDetail] DD WITH (NOLOCK) LEFT JOIN [T_DocumentMain] DM WITH (NOLOCK) ON DM.DocId = DD.DocId WHERE DD.IsahPrimKey = phsub.ProdHeaderDossierCode	AND dm.docPathName LIKE '%.pdf') [DocPathName],
	BMSub.NetQty,
	BMSub.NetLength,
	BMSub.NetWidth,
	BMSub.NetHeight,
	BMSub.Description [Sub Article Description],
	(  
            SELECT CASE   
                        WHEN (  
                                 SELECT TOP(1) 1  
                                 FROM   [dbo].T_ProdBillOfMat t1 WITH (NOLOCK),  
                                        [dbo].T_Part t2 WITH (NOLOCK),  
                                        [dbo].T_ProdHeadProdBomLink t3 WITH (NOLOCK)  
                                 WHERE  t1.ProdHeaderDossierCode = BMSub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMSub.ProdBOMLineNr  
                                        AND t2.PartCode = t1.SubPartCode  
                                        AND t3.ProdBOMProdHeaderDossierCode = t1.ProdHeaderDossierCode  
                                        AND t3.ProdBOMLineNr = t1.ProdBOMLineNr  
                                        AND t2.Stand = N''  
                             ) IS NOT NULL THEN (  
                                 SELECT MIN(t3.Stand)  
                                 FROM   [dbo].T_ProdHeadProdBomLink t1 WITH (NOLOCK),  
                                        [dbo].T_ProdBillOfMat t2 WITH (NOLOCK),  
                                        [dbo].T_Part t3 WITH (NOLOCK),  
                                        [dbo].T_PartGrp t4 WITH (NOLOCK)  
                                 WHERE  t1.ProdBOMProdHeaderDossierCode = BMSub.ProdHeaderDossierCode  
                                        AND t1.ProdBOMLineNr = BMSub.ProdBOMLineNr  
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
                                 WHERE  t1.PartCode = BMSub.SubPartCode  
                                        AND t2.PartGrpCode = t1.PartGrpCode  
                                        AND t2.PartGrpMainCode IN ('ALUM', 'HYTA', 'KUNS', 'METO', 'STAA', 'TEKB')  
                             )  
                   END  
        )                            AS [WerkstofNr],
		    -- Individuele matches
    CASE 
        WHEN @Ref_Length = 0 THEN 100
        ELSE (1 - ABS(BMSub.NetLength - @Ref_Length) / @Ref_Length) * 100
    END AS Match_Length,

    CASE 
        WHEN @Ref_Width = 0 THEN 100
        ELSE (1 - ABS(BMSub.NetWidth - @Ref_Width) / @Ref_Width) * 100
    END AS Match_Width,

    CASE 
        WHEN @Ref_Height = 0 THEN 100
        ELSE (1 - ABS(BMSub.NetHeight - @Ref_Height) / @Ref_Height) * 100
    END AS Match_Height,

    -- Gemiddelde match
CAST(ROUND(
    (
        ISNULL(CASE WHEN @Ref_Length = 0 THEN 100 ELSE (1 - ABS(BMSub.NetLength - @Ref_Length) / @Ref_Length) * 100 END, 0) +
        ISNULL(CASE WHEN @Ref_Width = 0 THEN 100 ELSE (1 - ABS(BMSub.NetWidth - @Ref_Width) / @Ref_Width) * 100 END, 0) +
        ISNULL(CASE WHEN @Ref_Height = 0 THEN 100 ELSE (1 - ABS(BMSub.NetHeight - @Ref_Height) / @Ref_Height) * 100 END, 0)
    ) / 3, 2
) AS decimal(10,2)) AS MatchPercentage
    FROM [T_prodbillofmat] bm WITH (NOLOCK)
	--Head PD info:
	LEFT JOIN  [T_ProductionHeader] PHmain WITH (NOLOCK) on PHmain.prodheaderdossiercode = bm.prodheaderdossiercode
	LEFT JOIN [T_DossierMain] d WITH (NOLOCK) on PHmain.DossierCode = d.DossierCode
	--PD Info:
	LEFT JOIN [T_ProdHeadProdBOMLink] PHPBL WITH (NOLOCK) on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
	LEFT JOIN [T_ProductionHeader] PHsub WITH (NOLOCK) on PHsub.prodheaderdossiercode = PHPBL.prodheaderdossiercode
	LEFT JOIN [T_ProdBillOfMat] BMsub WITH (NOLOCK) on BMSub.prodheaderdossiercode = PHPBL.prodheaderdossiercode and BMSub.PartPos = 0
	LEFT JOIN [T_Part] p WITH (NOLOCK) on p.PartCode = PHmain.PartCode
	LEFT JOIN [T_Part] Psub WITH (NOLOCK) on Psub.PartCode = bm.SubPartCode
	WHERE 1=1
	AND PHPBL.ProdHeaderDossierCode <> @ProdHeaderDossierCode
	AND (SELECT top 1 dm.DocPathName FROM [T_DocumentDetail] DD WITH (NOLOCK) LEFT JOIN [T_DocumentMain] DM WITH (NOLOCK) ON DM.DocId = DD.DocId WHERE DD.IsahPrimKey = phsub.ProdHeaderDossierCode AND dm.docPathName LIKE '%.pdf') IS NOT NULL
	AND (LOWER(phsub.PartCode) LIKE '%'+ @Partcode + '%' or  LOWER(phsub.PartCode) LIKE '%'+ @FirstTwoOfPartcode + '%')
	AND BMSub.Description LIKE '%'+ @Description + '%'
	AND p.Description LIKE '%'+ @DUMMY_Description + '%'
	AND  PHsub.ProdStatusCode >=  45
	AND PHsub.ProdStatusCode NOT IN ('65','99')
	--AND P.ClassNr = @ClassNr
	) sub
  WHERE 1=1
  AND WerkstofNr IS NOT NULL
  AND WerkstofNr = @WerkstofNr
  AND Match_Length > @LengthPercentage
  AND Match_Width  > @WidthPercentage
  AND Match_Height > @HeightPercentage

  ),

  --extra filter op norm. werktstofnr

 Top4 AS (
    SELECT TOP 4 ProdHeaderDossierCode, [PD Description],
	REPLACE(CAST(CAST(REPLACE(MatchPercentage, ',', '.') AS DECIMAL(10,2)) - ABS(YEAR(OrdDate) - YEAR(GETDATE())) AS VARCHAR(20)), '.', ',') AS GoodMatch, --Jaartal meenemen in score betrouwaarheid.
	MatchPercentage, Match_Length, Match_Width, Match_Height
    FROM Scored
    ORDER BY GoodMatch DESC
),
Filler AS (
    SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
),
TopCount AS (
    SELECT COUNT(*) AS ActualCount FROM Top4
),
FillCount AS (
    SELECT 5 - ActualCount AS Needed FROM TopCount
),
FillerRows AS (
    SELECT 'No Match Found' AS ProdHeaderDossierCode, NULL AS [GoodMatch], NULL AS [PD Description], 0.0 AS MatchPercentage, 0.0 AS Match_Length, 0.0 AS Match_Width, 0.0 AS Match_Height
    FROM Filler 
    CROSS JOIN FillCount
    WHERE Filler.rn <= FillCount.Needed
)
SELECT * FROM Top4
WHERE 1=1
UNION ALL
SELECT * FROM FillerRows
ORDER BY MatchPercentage DESC, ProdHeaderDossierCode DESC;
