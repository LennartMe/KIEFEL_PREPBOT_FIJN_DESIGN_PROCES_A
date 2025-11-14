DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{ProdHeaderDossierCode}';

SELECT * FROM T_ProductionRouting WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode
AND ProdHeaderDossierCode <> ''