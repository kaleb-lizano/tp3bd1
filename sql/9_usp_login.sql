USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[Login]
    @inUsername VARCHAR(128)
    , @inPassword VARCHAR(128)
    , @inPostInIP VARCHAR(128)
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 1
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX)
        , @idUsuario INT
        , @passwordReal VARCHAR(128)
        , @esAdmin BIT = 0
        , @idEmpleado INT = 0
        , @idBitacora INT
        ;

    SELECT
        @idUsuario = [U].[id]
        , @passwordReal = [U].[Password]
    FROM [dbo].[Usuario] AS [U]
    WHERE ([U].[Username] = @inUsername);

    IF (@idUsuario IS NULL)
    BEGIN
        SET @outResultCode = 50001;
        SET @descripcion = 'UserName=' + @inUsername + '; resultado=no exitoso (usuario no existe)';
    END
    ELSE IF (@passwordReal != @inPassword)
    BEGIN
        SET @outResultCode = 50002;
        SET @descripcion = 'UserName=' + @inUsername + '; resultado=no exitoso (password incorrecto)';
    END
    ELSE
    BEGIN
        SET @descripcion = 'UserName=' + @inUsername + '; resultado=exitoso';

        IF EXISTS (
            SELECT 1
            FROM [dbo].[UsuarioAdministrador] AS [UA]
            WHERE ([UA].[id] = @idUsuario)
        )
        BEGIN
            SET @esAdmin = 1;
        END;

        SELECT @idEmpleado = [UE].[idEmpleado]
        FROM [dbo].[UsuarioEmpleado] AS [UE]
        WHERE ([UE].[id] = @idUsuario);
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

        IF (@idUsuario IS NOT NULL)
        BEGIN
            INSERT [dbo].[BitacoraEventoUsuario] (
                [id]
                , [PostByUserId]
            )
            VALUES (
                @idBitacora
                , @idUsuario
            );
        END;
    COMMIT TRANSACTION tEvento;

    IF (@outResultCode = 0)
    BEGIN
        SELECT
            @idUsuario AS [id]
            , @inUsername AS [Username]
            , @esAdmin AS [EsAdmin]
            , @idEmpleado AS [idEmpleado]
            ;
    END
    ELSE
    BEGIN
        SELECT @outResultCode AS [outResultCode];
    END;

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
