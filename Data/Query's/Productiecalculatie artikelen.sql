DECLARE @ProdHeaderDossierCode NVARCHAR(4000) = N'{ProdHeaderDossierCode}';-- PD 

exec sp_executesql N'Execute dbo.SIP_sel_StuklijstTekenkamer                                
      @ProdHeaderDossierCode = @P1',N'@P1 nvarchar(4000)',@ProdHeaderDossierCode