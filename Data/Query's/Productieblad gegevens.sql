DECLARE @ProductionDossiercode NVARCHAR(4000) = N'{Prodheaderdossiercode}';-- PD 

exec sp_executesql N'Exec SIP_rpt_CA002
@ProdHead1         = @P1
,@ProdHead2	   = @P2
,@VCInd            = @P3',N'@P1 nvarchar(4000),@P2 nvarchar(4000),@P3 bit',@ProductionDossiercode,@ProductionDossiercode,1

