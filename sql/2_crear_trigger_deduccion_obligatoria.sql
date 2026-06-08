USE [TareaProgramadaTres];
GO

CREATE OR ALTER TRIGGER [dbo].[trAsociaDeduccionObligatoria]
ON [dbo].[Empleado]
AFTER INSERT
AS
BEGIN
SET NOCOUNT ON;

    DECLARE
        @lastId INT
        , @q INT
        ;

    DECLARE @Obl TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [idEmpleado] INT
        , [idTipoDeduccion] INT
        , [Porcentaje] DECIMAL(18, 4)
        , [FechaInicio] DATE
    );

    INSERT @Obl (
        [idEmpleado]
        , [idTipoDeduccion]
        , [Porcentaje]
        , [FechaInicio]
    )
    SELECT
        [I].[id]
        , [DL].[id]
        , [DL].[Porcentaje]
        , [I].[FechaContratacion]
    FROM INSERTED AS [I]
    CROSS JOIN [dbo].[DeduccionLey] AS [DL];

    SET @q = @@ROWCOUNT;

    INSERT [dbo].[DeduccionXEmpleado] (
        [idEmpleado]
        , [idTipoDeduccion]
        , [FechaInicio]
    )
    SELECT
        [O].[idEmpleado]
        , [O].[idTipoDeduccion]
        , [O].[FechaInicio]
    FROM @Obl AS [O]
    ORDER BY [O].[Sec];

    SET @lastId = SCOPE_IDENTITY();

    INSERT [dbo].[DeduccionXEmpleadoPorcentual] (
        [id]
        , [Porcentaje]
    )
    SELECT
        @lastId - @q + [O].[Sec]
        , [O].[Porcentaje]
    FROM @Obl AS [O];

SET NOCOUNT OFF;
END;
GO
