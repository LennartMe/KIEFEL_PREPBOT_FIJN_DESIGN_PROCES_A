IF NOT EXISTS (
    SELECT 1
    FROM [StarcodeRPA]..CHeckQuantityRefInfo
    WHERE Partcode     = N'{Partcode}'
      AND Description = N'{Description}'
      AND CavityBased = {CavityBased}
      AND FormRelated = {FormRelated}
)
BEGIN
    INSERT INTO [StarcodeRPA]..CHeckQuantityRefInfo (
        Partcode,
        Description,
        CavityBased,
        FormRelated
    )
    VALUES (
        N'{Partcode}',      -- Partcode (nchar(15))
        N'{Description}',   -- Description (nvarchar(30))
        {CavityBased},      -- CavityBased (bit → 1 = true, 0 = false)
        {FormRelated}       -- FormRelated (bit → 1 = true, 0 = false)
    );
END;
