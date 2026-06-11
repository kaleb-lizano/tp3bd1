USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[Logout]
    @inIdUsuario INT
    , @inPostInIP VARCHAR(128)
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 2
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX) = ''
        , @idBitacora INT
        ;

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
            , @inIdUsuario
        );
    COMMIT TRANSACTION tEvento;

    SELECT @outResultCode AS [outResultCode];

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
