DECLARE @ProductionDossiercode NVARCHAR(4000) = N'{ProductionDossiercode}';-- PD 

exec sp_executesql N'Execute dbo.SIP_sel_StuklijstTekenkamer                                
      @ProdHeaderDossierCode = @P1',N'@P1 nvarchar(4000)',@ProductionDossiercode