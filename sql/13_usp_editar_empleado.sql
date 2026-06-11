USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[EditarEmpleado]
    @inValorDocumentoIdentidad VARCHAR(32)
    , @inNuevoNombre VARCHAR(128)
    , @inNuevoTipoDocumento VARCHAR(32)
    , @inNuevoValorDocumentoIdentidad VARCHAR(32)
    , @inNuevoNombrePuesto VARCHAR(128)
    , @inNuevaFechaContratacion DATE
    , @inPostInIP VARCHAR(128)
    , @inPostByUserId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 11
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX)
        , @idEmpleado INT
        , @oldNombre VARCHAR(128)
        , @oldTipoDocumento VARCHAR(32)
        , @oldValorDocumento VARCHAR(32)
        , @oldNombrePuesto VARCHAR(128)
        , @oldFechaContratacion DATE
        , @idPuestoNuevo INT
        , @idBitacora INT
        ;

    SELECT
        @idEmpleado = [E].[id]
        , @oldNombre = [E].[Nombre]
        , @oldTipoDocumento = [E].[TipoDocumento]
        , @oldValorDocumento = [E].[ValorDocumentoIdentidad]
        , @oldNombrePuesto = [P].[Nombre]
        , @oldFechaContratacion = [E].[FechaContratacion]
    FROM [dbo].[Empleado] AS [E]
    INNER JOIN [dbo].[Puesto] AS [P]
        ON ([E].[idPuesto] = [P].[id])
    WHERE ([E].[ValorDocumentoIdentidad] = @inValorDocumentoIdentidad);

    IF (@idEmpleado IS NULL)
    BEGIN
        SET @outResultCode = 50008;
        SELECT @outResultCode AS [outResultCode];
        RETURN;
    END;

    SELECT @idPuestoNuevo = [P].[id]
    FROM [dbo].[Puesto] AS [P]
    WHERE ([P].[Nombre] = @inNuevoNombrePuesto);

    IF (@idPuestoNuevo IS NULL)
    BEGIN
        SET @outResultCode = 50008;
        SELECT @outResultCode AS [outResultCode];
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[Empleado] AS [E]
        WHERE ([E].[ValorDocumentoIdentidad] = @inNuevoValorDocumentoIdentidad)
            AND ([E].[id] != @idEmpleado)
    )
    BEGIN
        SET @outResultCode = 50006;
        SELECT @outResultCode AS [outResultCode];
        RETURN;
    END;

    SET @descripcion =
        'Antes: Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleado)
        + '; Nombre=' + @oldNombre
        + '; TipoDocumento=' + @oldTipoDocumento
        + '; ValorDocumentoIdentidad=' + @oldValorDocumento
        + '; Puesto=' + @oldNombrePuesto
        + '; FechaContratacion=' + CONVERT(VARCHAR(10), @oldFechaContratacion, 23)
        + ' || Despues: Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleado)
        + '; Nombre=' + @inNuevoNombre
        + '; TipoDocumento=' + @inNuevoTipoDocumento
        + '; ValorDocumentoIdentidad=' + @inNuevoValorDocumentoIdentidad
        + '; Puesto=' + @inNuevoNombrePuesto
        + '; FechaContratacion=' + CONVERT(VARCHAR(10), @inNuevaFechaContratacion, 23);

    BEGIN TRANSACTION tEditarEmpleado

        UPDATE [dbo].[Empleado] WITH (ROWLOCK)
        SET [idPuesto] = @idPuestoNuevo
            , [TipoDocumento] = @inNuevoTipoDocumento
            , [ValorDocumentoIdentidad] = @inNuevoValorDocumentoIdentidad
            , [Nombre] = @inNuevoNombre
            , [FechaContratacion] = @inNuevaFechaContratacion
        WHERE ([id] = @idEmpleado);

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

    COMMIT TRANSACTION tEditarEmpleado;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tEditarEmpleado;
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
