USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[InsertarEmpleado]
    @inNombre VARCHAR(128)
    , @inTipoDocumento VARCHAR(32)
    , @inValorDocumentoIdentidad VARCHAR(32)
    , @inNombrePuesto VARCHAR(128)
    , @inFechaContratacion DATE
    , @inUsername VARCHAR(128)
    , @inPassword VARCHAR(128)
    , @inPostInIP VARCHAR(128)
    , @inPostByUserId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @TIPOEVENTO INT = 5
        , @postTime DATETIME = GETDATE()
        , @descripcion VARCHAR(MAX)
        , @idPuesto INT
        , @idEmpleado INT
        , @idUsuario INT
        , @idBitacora INT
        ;

    SELECT @idPuesto = [P].[id]
    FROM [dbo].[Puesto] AS [P]
    WHERE ([P].[Nombre] = @inNombrePuesto);

    IF (@idPuesto IS NULL)
    BEGIN
        SET @outResultCode = 50008;
        SELECT @outResultCode AS [outResultCode];
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[Empleado] AS [E]
        WHERE ([E].[ValorDocumentoIdentidad] = @inValorDocumentoIdentidad)
    )
    BEGIN
        SET @outResultCode = 50004;
        SELECT @outResultCode AS [outResultCode];
        RETURN;
    END;

    SET @descripcion =
        'Nombre=' + @inNombre
        + '; TipoDocumento=' + @inTipoDocumento
        + '; ValorDocumentoIdentidad=' + @inValorDocumentoIdentidad
        + '; Puesto=' + @inNombrePuesto
        + '; FechaContratacion=' + CONVERT(VARCHAR(10), @inFechaContratacion, 23)
        + '; FlagEsActivo=1'
        + '; Username=' + @inUsername;

    BEGIN TRANSACTION tInsertarEmpleado

        INSERT [dbo].[Empleado] (
            [idPuesto]
            , [TipoDocumento]
            , [ValorDocumentoIdentidad]
            , [Nombre]
            , [FechaContratacion]
            , [FlagEsActivo]
        )
        VALUES (
            @idPuesto
            , @inTipoDocumento
            , @inValorDocumentoIdentidad
            , @inNombre
            , @inFechaContratacion
            , 1
        );

        SET @idEmpleado = SCOPE_IDENTITY();

        INSERT [dbo].[Usuario] (
            [Username]
            , [Password]
        )
        VALUES (
            @inUsername
            , @inPassword
        );

        SET @idUsuario = SCOPE_IDENTITY();

        INSERT [dbo].[UsuarioEmpleado] (
            [id]
            , [idEmpleado]
        )
        VALUES (
            @idUsuario
            , @idEmpleado
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
            , @inPostByUserId
        );

    COMMIT TRANSACTION tInsertarEmpleado;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tInsertarEmpleado;
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
