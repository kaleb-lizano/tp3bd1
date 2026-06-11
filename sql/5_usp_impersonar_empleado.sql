USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[ImpersonarEmpleado]
    @inIdUsuarioAdmin INT
    , @inIdEmpleado INT
    , @inPostInIP VARCHAR(128)
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 12 -- no se sabe, basado en que el XML de ejemplo del profe va en el orden de la tabla de eventos, supongo que 12
        , @postTime DATETIME = GETDATE()
        , @nombreEmpleado VARCHAR(128)
        , @descripcion VARCHAR(MAX)
        , @idBitacora INT
        ;

    IF NOT EXISTS (
        SELECT 1
        FROM [dbo].[UsuarioAdministrador] AS [UA]
        WHERE ([UA].[id] = @inIdUsuarioAdmin)
    )
    BEGIN
        SET @outResultCode = 50008;
        RETURN;
    END;

    SELECT @nombreEmpleado = [E].[Nombre]
    FROM [dbo].[Empleado] AS [E]
    WHERE ([E].[id] = @inIdEmpleado)
        AND ([E].[FlagEsActivo] = 1);

    IF (@nombreEmpleado IS NULL)
    BEGIN
        SET @outResultCode = 50008;
        RETURN;
    END;

    SET @descripcion = 'Empleado.Id=' + CONVERT(VARCHAR(16), @inIdEmpleado);

    BEGIN TRANSACTION tImpersonacion

        UPDATE [dbo].[Impersonacion] WITH (ROWLOCK)
        SET [FlagActivo] = 0
        WHERE ([idUsuarioAdmin] = @inIdUsuarioAdmin)
            AND ([FlagActivo] = 1);

        INSERT [dbo].[Impersonacion] (
            [idUsuarioAdmin]
            , [idEmpleadoImpersonado]
            , [FlagActivo]
        )
        VALUES (
            @inIdUsuarioAdmin
            , @inIdEmpleado
            , 1
        );

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
            , @inIdUsuarioAdmin
        );

    COMMIT TRANSACTION tImpersonacion;

    SELECT
        @inIdEmpleado AS [idEmpleado]
        , @nombreEmpleado AS [Nombre]
    ;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tImpersonacion;
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
