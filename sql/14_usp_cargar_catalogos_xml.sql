USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[CargarCatalogosXML]
    @inXmlCatalogos XML
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE @Puestos TABLE (
        [Nombre] VARCHAR(128)
        , [SalarioXHora] MONEY
    );
    DECLARE @Jornadas TABLE (
        [id] INT
        , [Nombre] VARCHAR(128)
        , [HoraInicio] TIME
        , [HoraFin] TIME
    );
    DECLARE @Feriados TABLE (
        [id] INT
        , [Nombre] VARCHAR(128)
        , [Fecha] DATE
    );
    DECLARE @Movimientos TABLE (
        [id] INT
        , [Nombre] VARCHAR(128)
        , [Accion] CHAR(8)
    );
    DECLARE @Deducciones TABLE (
        [id] INT
        , [Nombre] VARCHAR(128)
        , [idTipoMovimiento] INT
        , [EsObligatoria] BIT
        , [FlagFijo] BIT
        , [Porcentaje] DECIMAL(18, 4)
    );
    DECLARE @Eventos TABLE (
        [id] INT
        , [Nombre] VARCHAR(128)
    );
    DECLARE @Usuarios TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [Username] VARCHAR(128)
        , [Password] VARCHAR(128)
        , [Tipo] INT
    );
    DECLARE @Errores TABLE (
        [Codigo] INT
        , [Descripcion] VARCHAR(MAX)
    );

    INSERT @Puestos (
        [Nombre]
        , [SalarioXHora]
    )
    SELECT
        [N].value('@Nombre', 'VARCHAR(128)')
        , [N].value('@SalarioXHora', 'MONEY')
    FROM @inXmlCatalogos.nodes('/Datos/Puestos/Puesto') AS [T]([N]);

    INSERT @Jornadas (
        [id]
        , [Nombre]
        , [HoraInicio]
        , [HoraFin]
    )
    SELECT
        [N].value('@Id', 'INT')
        , [N].value('@Nombre', 'VARCHAR(128)')
        , [N].value('@HoraInicio', 'TIME')
        , [N].value('@HoraFin', 'TIME')
    FROM @inXmlCatalogos.nodes('/Datos/TiposJornada/TipoJornada') AS [T]([N]);

    INSERT @Feriados (
        [id]
        , [Nombre]
        , [Fecha]
    )
    SELECT
        [N].value('@Id', 'INT')
        , [N].value('@Nombre', 'VARCHAR(128)')
        , [N].value('@Fecha', 'DATE')
    FROM @inXmlCatalogos.nodes('/Datos/Feriados/Feriado') AS [T]([N]);

    INSERT @Movimientos (
        [id]
        , [Nombre]
        , [Accion]
    )
    SELECT
        [N].value('@Id', 'INT')
        , [N].value('@Nombre', 'VARCHAR(128)')
        , [N].value('@Accion', 'CHAR(8)')
    FROM @inXmlCatalogos.nodes('/Datos/TiposMovimiento/TipoMovimiento') AS [T]([N]);

    INSERT @Deducciones (
        [id]
        , [Nombre]
        , [idTipoMovimiento]
        , [EsObligatoria]
        , [FlagFijo]
        , [Porcentaje]
    )
    SELECT
        [N].value('@Id', 'INT')
        , [N].value('@Nombre', 'VARCHAR(128)')
        , [M].[id]
        , [N].value('@EsObligatoria', 'BIT')
        , (1 - [N].value('@EsPorcentual', 'INT'))
        , [N].value('@Valor', 'DECIMAL(18, 4)')
    FROM @inXmlCatalogos.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS [T]([N])
    INNER JOIN @Movimientos AS [M]
        ON ([M].[Nombre] = [N].value('@TipoMovimiento', 'VARCHAR(128)'));

    INSERT @Usuarios (
        [Username]
        , [Password]
        , [Tipo]
    )
    SELECT
        [N].value('@Username', 'VARCHAR(128)')
        , [N].value('@PasswordHash', 'VARCHAR(128)')
        , [N].value('@Tipo', 'INT')
    FROM @inXmlCatalogos.nodes('/Datos/Usuarios/Usuario') AS [T]([N]);

    INSERT @Errores (
        [Codigo]
        , [Descripcion]
    )
    SELECT
        [N].value('@Codigo', 'INT')
        , [N].value('@Descripcion', 'VARCHAR(MAX)')
    FROM @inXmlCatalogos.nodes('/Datos/Error/error') AS [T]([N]);

    INSERT @Eventos (
        [id]
        , [Nombre]
    )
    VALUES
        (1, 'Login')
        , (2, 'Logout')
        , (3, 'Listar empleados')
        , (4, 'Listar empleados con filtro')
        , (5, 'Insertar empleado')
        , (6, 'Eliminar empleado')
        , (7, 'Asociar deduccion')
        , (8, 'Desasociar deduccion')
        , (9, 'Consultar planilla semanal')
        , (10, 'Consultar planilla mensual')
        , (11, 'Editar empleado')
        , (12, 'Impersonar empleado')
        , (13, 'Regresar a interfaz de administrador')
        , (14, 'Ingreso de marcas de asistencia')
        , (15, 'Ingreso nuevas jornadas');

    BEGIN TRANSACTION tCargarCatalogos
        INSERT [dbo].[Puesto] (
            [Nombre]
            , [SalarioXHora]
        )
        SELECT
            [P].[Nombre]
            , [P].[SalarioXHora]
        FROM @Puestos AS [P]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[Puesto] AS [X]
            WHERE ([X].[Nombre] = [P].[Nombre])
        );

        INSERT [dbo].[TipoJornada] (
            [id]
            , [Nombre]
            , [HoraInicio]
            , [HoraFin]
        )
        SELECT
            [J].[id]
            , [J].[Nombre]
            , [J].[HoraInicio]
            , [J].[HoraFin]
        FROM @Jornadas AS [J]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[TipoJornada] AS [X]
            WHERE ([X].[id] = [J].[id])
        );

        INSERT [dbo].[Feriado] (
            [id]
            , [Nombre]
            , [Fecha]
        )
        SELECT
            [F].[id]
            , [F].[Nombre]
            , [F].[Fecha]
        FROM @Feriados AS [F]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[Feriado] AS [X]
            WHERE ([X].[id] = [F].[id])
        );

        INSERT [dbo].[TipoEvento] (
            [id]
            , [Nombre]
        )
        SELECT
            [EV].[id]
            , [EV].[Nombre]
        FROM @Eventos AS [EV]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[TipoEvento] AS [X]
            WHERE ([X].[id] = [EV].[id])
        );

        INSERT [dbo].[TipoMovimiento] (
            [id]
            , [Nombre]
            , [Accion]
        )
        SELECT
            [M].[id]
            , [M].[Nombre]
            , [M].[Accion]
        FROM @Movimientos AS [M]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[TipoMovimiento] AS [X]
            WHERE ([X].[id] = [M].[id])
        );

        INSERT [dbo].[TipoDeduccion] (
            [id]
            , [idTipoMovimiento]
            , [Nombre]
        )
        SELECT
            [D].[id]
            , [D].[idTipoMovimiento]
            , [D].[Nombre]
        FROM @Deducciones AS [D]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[TipoDeduccion] AS [X]
            WHERE ([X].[id] = [D].[id])
        );

        INSERT [dbo].[DeduccionLey] (
            [id]
            , [Porcentaje]
        )
        SELECT
            [D].[id]
            , [D].[Porcentaje]
        FROM @Deducciones AS [D]
        WHERE ([D].[EsObligatoria] = 1)
            AND NOT EXISTS (
                SELECT 1
                FROM [dbo].[DeduccionLey] AS [X]
                WHERE ([X].[id] = [D].[id])
            );

        INSERT [dbo].[DeduccionNoObligatoria] (
            [id]
            , [FlagFijo]
            , [Porcentaje]
        )
        SELECT
            [D].[id]
            , [D].[FlagFijo]
            , [D].[Porcentaje]
        FROM @Deducciones AS [D]
        WHERE ([D].[EsObligatoria] = 0)
            AND NOT EXISTS (
                SELECT 1
                FROM [dbo].[DeduccionNoObligatoria] AS [X]
                WHERE ([X].[id] = [D].[id])
            );

        INSERT [dbo].[Usuario] (
            [Username]
            , [Password]
        )
        SELECT
            [U].[Username]
            , [U].[Password]
        FROM @Usuarios AS [U]
        WHERE ([U].[Tipo] = 1)
            AND NOT EXISTS (
                SELECT 1
                FROM [dbo].[Usuario] AS [X]
                WHERE ([X].[Username] = [U].[Username])
            )
        ORDER BY [U].[Sec];

        INSERT [dbo].[UsuarioAdministrador] ([id])
        SELECT [USR].[id]
        FROM [dbo].[Usuario] AS [USR]
        INNER JOIN @Usuarios AS [U]
            ON ([U].[Username] = [USR].[Username])
        WHERE ([U].[Tipo] = 1)
            AND NOT EXISTS (
                SELECT 1
                FROM [dbo].[UsuarioAdministrador] AS [X]
                WHERE ([X].[id] = [USR].[id])
            );

        INSERT [dbo].[Error] (
            [Codigo]
            , [Descripcion]
        )
        SELECT
            [ER].[Codigo]
            , [ER].[Descripcion]
        FROM @Errores AS [ER]
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[Error] AS [X]
            WHERE ([X].[Codigo] = [ER].[Codigo])
        );

    COMMIT TRANSACTION tCargarCatalogos;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION tCargarCatalogos;
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
