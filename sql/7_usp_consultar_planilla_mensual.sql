USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[ConsultarPlanillaMensual]
    @inIdEmpleado INT
    , @inCantidadMeses INT
    , @inPostInIP VARCHAR(128)
    , @inPostByUserId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 10 -- no se sabe, lo supongo basado en la tabla de eventos y el orden de lo poco de XML que se muestra
        , @postTime DATETIME = GETDATE()
        , @fechaInicio DATE
        , @fechaFin DATE
        , @descripcion VARCHAR(MAX)
        , @idBitacora INT
        ;

    DECLARE @Meses TABLE (
        [idPlanMes] INT
        , [idMes] INT
        , [Anio] INT
        , [Mes] INT
        , [FechaInicio] DATE
        , [FechaFin] DATE
    );

    INSERT @Meses (
        [idPlanMes]
        , [idMes]
        , [Anio]
        , [Mes]
        , [FechaInicio]
        , [FechaFin]
    )
    SELECT TOP (@inCantidadMeses)
        [PME].[id]
        , [MP].[id]
        , [MP].[Anio]
        , [MP].[Mes]
        , [MP].[FechaInicio]
        , [MP].[FechaFin]
    FROM [dbo].[PlanillaMesXEmpleado] AS [PME]
    INNER JOIN [dbo].[MesPlanilla] AS [MP]
        ON ([PME].[idMesPlanilla] = [MP].[id])
    WHERE ([PME].[idEmpleado] = @inIdEmpleado)
    ORDER BY [MP].[Anio] DESC, [MP].[Mes] DESC;

    IF NOT EXISTS (
        SELECT 1
        FROM @Meses AS [M]
    )
    BEGIN
        SET @descripcion =
            'Empleado.Id=' + CONVERT(VARCHAR(16), @inIdEmpleado) + '; (sin planillas mensuales)';
    END
    ELSE
    BEGIN
        SELECT
            @fechaInicio = MIN([M].[FechaInicio])
            , @fechaFin = MAX([M].[FechaFin])
        FROM @Meses AS [M];

        SET @descripcion =
            'Empleado.Id=' + CONVERT(VARCHAR(16), @inIdEmpleado)
            + '; FechaInicio=' + CONVERT(VARCHAR(16), @fechaInicio, 23)
            + '; FechaFin=' + CONVERT(VARCHAR(16), @fechaFin, 23);
    END;

    BEGIN TRANSACTION tEvento
        INSERT [dbo].[BitacoraEvento] (
            [idTipoEvento]
            , [EventDate]
            , [Descripcion]
            , [PostInIP]
            , [PostTime]
        )
        VALUES (
            @TIPOEVENTO
            , @postTime
            , @descripcion
            , @inPostInIP
            , @postTime
        );
        SET @idBitacora = SCOPE_IDENTITY();
        INSERT [dbo].[BitacoraEventoUsuario] (
            [id]
            , [PostByUserId]
        )
        VALUES (
            @idBitacora
            , @inPostByUserId
        );
    COMMIT TRANSACTION tEvento;

    SELECT
        [M].[idMes] AS [IdPlanillaMensual]
        , [M].[Anio] AS [Anio]
        , [M].[Mes] AS [Mes]
        , [PME].[SalarioBrutoMensual] AS [SalarioBruto]
        , [PME].[DeduccionesMensuales] AS [TotalDeducciones]
        , [PME].[SalarioNetoMensual] AS [SalarioNeto]
    FROM @Meses AS [M]
    INNER JOIN [dbo].[PlanillaMesXEmpleado] AS [PME]
        ON ([PME].[id] = [M].[idPlanMes])
    ORDER BY [M].[Anio] DESC, [M].[Mes] DESC;

    SELECT
        [M].[idMes] AS [IdPlanillaMensual]
        , [TD].[Nombre] AS [NombreDeduccion]
        , [DXM].[PorcentajeAplicado] * 100 AS [Porcentaje]
        , [DXM].[MontoAcumulado] AS [MontoDeduccion]
    FROM @Meses AS [M]
    INNER JOIN [dbo].[DeduccionXEmpleadoXMes] AS [DXM]
        ON ([DXM].[idPlanillaMesXEmpleado] = [M].[idPlanMes])
    INNER JOIN [dbo].[TipoDeduccion] AS [TD]
        ON ([TD].[id] = [DXM].[idTipoDeduccion])
    ORDER BY [M].[idMes], [TD].[Nombre];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tEvento;
    END;

    INSERT [dbo].[DBError] (
        [UserName]
        , [ErrorNumber]
        , [ErrorState]
        , [ErrorSeverity]
        , [ErrorLine]
        , [ErrorProcedure]
        , [ErrorMessage]
        , [ErrorDateTime]
    )
    SELECT
        SUSER_SNAME()
        , ERROR_NUMBER()
        , ERROR_STATE()
        , ERROR_SEVERITY()
        , ERROR_LINE()
        , ERROR_PROCEDURE()
        , ERROR_MESSAGE()
        , GETDATE();

    SET @outResultCode = 50008;
    SELECT @outResultCode AS [outResultCode];

END CATCH

SET NOCOUNT OFF;
END;
GO
