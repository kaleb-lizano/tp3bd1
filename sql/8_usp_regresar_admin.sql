USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[RegresarAdmin]
    @inIdUsuarioAdmin INT
    , @inPostInIP VARCHAR(128)
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 13 -- no se sabe, lo supongo basado en la tabla de eventos y el orden de lo poco de XML que se muestra
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX) = ''
        , @idBitacora INT
        ;

    BEGIN TRANSACTION tRegresarAdmin

        UPDATE [dbo].[Impersonacion] WITH (ROWLOCK)
        SET [FlagActivo] = 0
        WHERE ([idUsuarioAdmin] = @inIdUsuarioAdmin)
            AND ([FlagActivo] = 1);

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

    COMMIT TRANSACTION tRegresarAdmin;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tRegresarAdmin;
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
