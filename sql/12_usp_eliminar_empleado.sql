USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[EliminarEmpleado]
    @inValorDocumentoIdentidad VARCHAR(32)
    , @inPostInIP VARCHAR(128)
    , @inPostByUserId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 6
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX)
        , @idEmpleado INT
        , @nombre VARCHAR(128)
        , @tipoDocumento VARCHAR(32)
        , @nombrePuesto VARCHAR(128)
        , @fechaContratacion DATE
        , @idBitacora INT
        ;

    SELECT
        @idEmpleado = [E].[id]
        , @nombre = [E].[Nombre]
        , @tipoDocumento = [E].[TipoDocumento]
        , @nombrePuesto = [P].[Nombre]
        , @fechaContratacion = [E].[FechaContratacion]
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

    SET @descripcion =
        'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleado)
        + '; Nombre=' + @nombre
        + '; TipoDocumento=' + @tipoDocumento
        + '; ValorDocumentoIdentidad=' + @inValorDocumentoIdentidad
        + '; Puesto=' + @nombrePuesto
        + '; FechaContratacion=' + CONVERT(VARCHAR(10), @fechaContratacion, 23);

    BEGIN TRANSACTION tEliminarEmpleado

        UPDATE [dbo].[Empleado] WITH (ROWLOCK)
        SET [FlagEsActivo] = 0
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

    COMMIT TRANSACTION tEliminarEmpleado;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tEliminarEmpleado;
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
