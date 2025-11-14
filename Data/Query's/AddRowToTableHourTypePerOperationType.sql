DELETE
    FROM [StarcodeRPA]..HourTypePerOperationType
    WHERE MachGrpCode     = N'{MachGrpCode}'

BEGIN
    INSERT INTO [StarcodeRPA]..HourTypePerOperationType (
        MachGrpCode,
        [Uren Type],
		PlanningBasedOnType
    )
    VALUES (
        N'{MachGrpCode}',      -- MachGrpCode (nchar(4))
        N'{UrenType}',      -- [Uren Type] 
		{PlanningBasedOnType} --(1 = MachineUren, 2 = Manuren)
    );
END;
