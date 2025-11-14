BEGIN TRANSACTION;
DECLARE @ProductionDossiercode NVARCHAR(4000) = N'{ProdHeaderDossierCode}' -- PD to update status
DECLARE @ProductionStatus NVARCHAR(10) = N'{NewStatus}' -- New Status

DECLARE @old_LastUpdatedOn NVARCHAR(30)
DECLARE @LastUpdatedOn NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120) -- Format: YYYY-MM-DD HH:MI:SS
DECLARE @ResultCode INT = 0
DECLARE @ResultMessage NVARCHAR(255)

-- Retrieve the latest LastUpdatedOn from the database
SELECT @old_LastUpdatedOn = LastUpdatedOn
FROM T_ProductionHeader
WHERE ProdHeaderDossierCode = @ProductionDossiercode

-- Ensure @old_LastUpdatedOn is not NULL (optional, remove if LastUpdatedOn is always set)
IF @old_LastUpdatedOn IS NULL
    SET @old_LastUpdatedOn = '2000-01-01 00:00:00.000'

-- Try updating the production header
BEGIN TRY
    EXEC [dbo].[IP_Upd_ProdHeader] 
        @ProductionDossiercode, 
        @old_LastUpdatedOn,  -- Use the latest value retrieved from DB
        NULL, NULL, @ProductionStatus, 
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
        NULL, NULL, NULL, NULL, N'', 0, NULL, NULL, NULL, NULL, 
        @LastUpdatedOn OUTPUT, N'RPA', NULL, NULL, 0, 920000, 
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
        NULL, NULL, NULL, 0

    -- If no error occurs, update success status
    SET @ResultCode = 1
    SET @ResultMessage = 'Status ProductionDossiercode '+ @ProductionDossiercode + ' successfully updated to ' + @ProductionStatus
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
    -- If an error occurs, set failure status and capture error message
    SET @ResultCode = 0
    SET @ResultMessage = ERROR_MESSAGE()
	ROLLBACK TRANSACTION
END CATCH

-- Return the result code and message
SELECT @ResultCode AS ResultCode, @ResultMessage AS Message
