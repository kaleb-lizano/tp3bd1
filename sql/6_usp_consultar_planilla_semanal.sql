USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[ConsultarPlanillaSemanal]
    @inIdEmpleado INT
    , @inCantidadSemanas INT
    , @inPostInIP VARCHAR(128)
    , @inPostByUserId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 9 -- no se sabe, lo supongo basado en la tabla de eventos y el orden de lo poco de XML que se muestra
        , @postTime DATETIME = GETDATE()
        , @fechaInicio DATE
        , @fechaFin DATE
        , @descripcion VARCHAR(MAX)
        , @idBitacora INT
        ;

    DECLARE @Semanas TABLE (
        [idPlanSem] INT
        , [idSemana] INT
        , [FechaInicio] DATE
        , [FechaFin] DATE
    );

    INSERT @Semanas (
        [idPlanSem]
        , [idSemana]
        , [FechaInicio]
        , [FechaFin]
    )
    SELECT TOP (@inCantidadSemanas)
        [PSE].[id]
        , [SP].[id]
        , [SP].[FechaInicio]
        , [SP].[FechaFin]
    FROM [dbo].[PlanillaSemXEmpleado] AS [PSE]
    INNER JOIN [dbo].[SemanaPlanilla] AS [SP]
        ON ([PSE].[idSemanaPlanilla] = [SP].[id])
    WHERE ([PSE].[idEmpleado] = @inIdEmpleado)
    ORDER BY [SP].[FechaInicio] DESC;

    IF NOT EXISTS (
        SELECT 1
        FROM @Semanas AS [S]
    )
    BEGIN
        SET @descripcion =
            'Empleado.Id=' + CONVERT(VARCHAR(16), @inIdEmpleado) + '; (sin planillas semanales)';
    END
    ELSE
    BEGIN
        SELECT
            @fechaInicio = MIN([S].[FechaInicio])
            , @fechaFin = MAX([S].[FechaFin])
        FROM @Semanas AS [S];

        SET @descripcion =
            'Empleado.Id=' + CONVERT(VARCHAR(16), @inIdEmpleado)
            + '; FechaInicio=' + CONVERT(VARCHAR(10), @fechaInicio, 23)
            + '; FechaFin=' + CONVERT(VARCHAR(10), @fechaFin, 23);
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
        [S].[idSemana] AS [IdPlanillaSemanal]
        , [S].[FechaInicio] AS [FechaInicio]
        , [S].[FechaFin] AS [FechaFin]
        , [PSE].[SalarioBruto] AS [SalarioBruto]
        , [PSE].[TotalDeducciones] AS [TotalDeducciones]
        , [PSE].[SalarioNeto] AS [SalarioNeto]
        , [PSE].[HorasOrdinarias] AS [HorasOrdinarias]
        , [PSE].[HorasExtrasNormales] AS [HorasExtrasNormales]
        , [PSE].[HorasExtrasDobles] AS [HorasExtrasDobles]
    FROM @Semanas AS [S]
    INNER JOIN [dbo].[PlanillaSemXEmpleado] AS [PSE]
        ON ([PSE].[id] = [S].[idPlanSem])
    ORDER BY [S].[FechaInicio] DESC;

    SELECT
        [S].[idSemana] AS [IdPlanillaSemanal]
        , [TM].[Nombre] AS [NombreDeduccion]
        , [MD].[PorcentajeAplicado] * 100 AS [Porcentaje]
        , [MP].[Monto] AS [MontoDeduccion]
    FROM @Semanas AS [S]
    INNER JOIN [dbo].[MovimientoPlanilla] AS [MP]
        ON ([MP].[idPlanillaSemXEmpleado] = [S].[idPlanSem])
    INNER JOIN [dbo].[MovimientoDeduccion] AS [MD]
        ON ([MD].[id] = [MP].[id])
    INNER JOIN [dbo].[TipoMovimiento] AS [TM]
        ON ([TM].[id] = [MP].[idTipoMovimiento])
    ORDER BY [S].[idSemana], [TM].[Nombre];

    SELECT
        [S].[idSemana] AS [IdPlanillaSemanal]
        , [MA].[Fecha] AS [Fecha]
        , [MA].[HoraEntrada] AS [HoraEntrada]
        , [MA].[HoraSalida] AS [HoraSalida]
        , [MA].[HorasOrdinarias] AS [HorasOrdinarias]
        , [MA].[MontoOrdinario] AS [MontoOrdinario]
        , [MA].[HorasExtrasNormales] AS [HorasExtrasNormales]
        , [MA].[MontoExtraNormal] AS [MontoExtraNormal]
        , [MA].[HorasExtrasDobles] AS [HorasExtrasDobles]
        , [MA].[MontoExtraDoble] AS [MontoExtraDoble]
    FROM @Semanas AS [S]
    INNER JOIN [dbo].[MarcaAsistencia] AS [MA]
        ON ([MA].[idPlanillaSemXEmpleado] = [S].[idPlanSem])
    ORDER BY [S].[idSemana], [MA].[Fecha], [MA].[HoraEntrada];

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
