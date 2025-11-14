DECLARE @ProdHeaderDossierCode NVARCHAR(50) = '{ProdHeaderDossierCode}';
DECLARE @PartCode NVARCHAR(50);
DECLARE @OrderDescription NVARCHAR(50);
DECLARE @SubPartCode NVARCHAR(50);
DECLARE @Tolerance FLOAT = 0.2;       -- Max 20% afwijking toegestaan
DECLARE @MinMatchScore FLOAT = 0.2;   -- Minimaal 20% overeenkomst

-- Haal PartCode + SubPartCode
SELECT TOP 1
   @PartCode = PH.PartCode,
   @SubPartCode = PBOM.SubPartCode
FROM T_ProductionHeader PH
INNER JOIN T_ProdBillOfMat PBOM ON PBOM.ProdHeaderDossierCode = PH.ProdHeaderDossierCode
WHERE PH.ProdHeaderDossierCode = @ProdHeaderDossierCode;

-- Haal OrderDescription van bovenliggende order
SELECT TOP 1
  @OrderDescription = PH.Description
FROM T_ProdHeadProdBOMLink L
LEFT JOIN T_ProductionHeader PH ON PH.ProdHeaderDossierCode = L.ProdBOMProdHeaderDossierCode
WHERE L.ProdHeaderDossierCode = @ProdHeaderDossierCode;

-- Referentieregel
WITH RefRow AS (
    SELECT TOP 1 *
    FROM T_ProdBillOfMat
    WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode
      AND SubPartCode = @SubPartCode
),
CompareRows AS (
    SELECT 
        PBOM.LineNr,
        PH.ProdHeaderDossierCode,
        PH.Description AS OrderDescription,

        -- Veldscore op 5 BOM-velden
        CASE WHEN ABS(R.NetQty - PBOM.NetQty) / NULLIF(R.NetQty, 0) <= @Tolerance THEN 1 ELSE 0 END +
        CASE WHEN ABS(R.NetLength - PBOM.NetLength) / NULLIF(R.NetLength, 0) <= @Tolerance THEN 1 ELSE 0 END +
        CASE WHEN ABS(R.NetWidth - PBOM.NetWidth) / NULLIF(R.NetWidth, 0) <= @Tolerance THEN 1 ELSE 0 END +
        CASE WHEN ABS(R.NetHeight - PBOM.NetHeight) / NULLIF(R.NetHeight, 0) <= @Tolerance THEN 1 ELSE 0 END +
        CASE WHEN R.Description = PBOM.Description THEN 1 ELSE 0 END AS MatchScore,

        -- Percentage character match op OrderDescription
        CAST(
            CASE 
                WHEN LEN(PH.Description) = 0 OR LEN(@OrderDescription) = 0 THEN 0
                ELSE 1.0 * LEN(
                    LEFT(PH.Description, 
                        LEN(
                            LEFT(PH.Description, LEN(@OrderDescription)) -- veiligst
                        )
                    )
                ) 
                / NULLIF(NULLIF(
                    CASE 
                        WHEN LEN(PH.Description) > LEN(@OrderDescription) THEN LEN(PH.Description)
                        ELSE LEN(@OrderDescription)
                    END, 0), 0)
            END AS FLOAT
        ) AS OrderDescriptionMatch
    FROM T_ProdBillOfMat PBOM
    INNER JOIN T_ProductionHeader PH ON PH.ProdHeaderDossierCode = PBOM.ProdHeaderDossierCode
    CROSS JOIN RefRow R
    WHERE 1=1
	--AND (PBOM.NetLength > 0 OR PBOM.NetWidth > 0 OR PBOM.NetHeight > 0)
	--AND (R.NetLength > 0 OR R.NetWidth > 0 OR R.NetHeight > 0)
		AND PH.PartCode = @PartCode
        AND PBOM.SubPartCode = @SubPartCode
        AND PH.ProdHeaderDossierCode <> @ProdHeaderDossierCode
        AND (
            PBOM.CreDate BETWEEN DATEADD(YEAR, -2, GETDATE()) AND GETDATE()
            OR PBOM.RequiredDate BETWEEN DATEADD(YEAR, -2, GETDATE()) AND GETDATE()
        )
),
Scored AS (
    SELECT *,
        CASE 
            WHEN ISNULL(NULLIF(LTRIM(RTRIM(@OrderDescription)), ''), '') = '' THEN
                MatchScore * 1.0 / 5.0
            ELSE
                0.75 * MatchScore / 5.0 + 0.25 * OrderDescriptionMatch
        END AS MatchPercentage
    FROM CompareRows
    WHERE 
        CASE 
            WHEN ISNULL(NULLIF(LTRIM(RTRIM(@OrderDescription)), ''), '') = '' THEN
                MatchScore * 1.0 / 5.0
            ELSE
                0.75 * MatchScore / 5.0 + 0.25 * OrderDescriptionMatch
        END >= @MinMatchScore
),
Top5 AS (
    SELECT TOP 5 ProdHeaderDossierCode, LineNr, OrderDescription, MatchPercentage
    FROM Scored
    ORDER BY MatchPercentage DESC
),
Filler AS (
    SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
),
TopCount AS (
    SELECT COUNT(*) AS ActualCount FROM Top5
),
FillCount AS (
    SELECT 5 - ActualCount AS Needed FROM TopCount
),
FillerRows AS (
    SELECT 'No Match Found' AS ProdHeaderDossierCode, NULL AS LineNr, NULL AS OrderDescription, 0.0 AS MatchPercentage
    FROM Filler
    CROSS JOIN FillCount
    WHERE Filler.rn <= FillCount.Needed
)
SELECT * FROM Top5
UNION ALL
SELECT * FROM FillerRows
ORDER BY MatchPercentage DESC, ProdHeaderDossierCode DESC;
