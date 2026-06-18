USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[EjecutarSimulacion]
    @inXmlOperaciones XML
    , @inPostInIP VARCHAR(128)
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    DECLARE
        @JUEVES INT = 3
        , @VIERNES INT = 4
        , @DOMINGO INT = 6
        -- los tipos de evento que asumo basado en la tabla del profe y el hecho de que el XML parcial del profe venía en ese orden
        , @EVENTOINSERTAR INT = 5
        , @EVENTOELIMINAR INT = 6
        , @EVENTOASOCIAR INT = 7
        , @EVENTODESASOCIAR INT = 8
        , @EVENTOMARCA INT = 14
        , @EVENTOJORNADA INT = 15
        -- tipos de movimiento
        , @TMORDINARIO INT = 1
        , @TMEXTRANORMAL INT = 2
        , @TMEXTRADOBLE INT = 3
        -- los múltiplos para horas extra
        , @FACTOREXTRANORMAL DECIMAL(9, 4) = 1.5
        , @FACTOREXTRADOBLE DECIMAL(9, 4) = 2.0
        -- post time
        , @postTime DATETIME = GETDATE()
        -- vars para loop relacionado a fechas
        , @loFecha INT
        , @hiFecha INT
        , @fechaOperacion DATE
        , @fechaStr VARCHAR(16)
        , @xmlDia XML
        -- vars para calendario, o sea semanas/meses etc
        , @diaSemana INT
        , @esJueves BIT
        , @inicioSemanaActual DATE
        , @inicioSemanaSiguiente DATE
        , @proximoInicioSemana DATE
        , @cierreActual DATE
        , @cierreSiguiente DATE
        , @anioMesActual INT
        , @mesMesActual INT
        , @anioMesSiguiente INT
        , @mesMesSiguiente INT
        , @ultimoDiaMes DATE
        , @ultimoDiaMesAnterior DATE
        , @ultimoJuevesAnterior DATE
        , @fechaInicioMesActual DATE
        , @fechaFinMesActual DATE
        , @cantSemMesActual INT
        , @fechaInicioMesSig DATE
        , @fechaFinMesSig DATE
        , @cantSemMesSig INT
        , @fechaFinSemanaActual DATE
        , @numeroSemanaActual INT
        , @fechaFinSemanaSig DATE
        , @numeroSemanaSig INT
        -- vars para los while
        , @lo INT
        , @hi INT
        -- vars para bitacora
        , @descripcion VARCHAR(MAX)
        -- variables para los valores de las operaciones e insertar empleados
        , @opNombre VARCHAR(128)
        , @opValorDoc VARCHAR(32)
        , @opPuesto VARCHAR(128)
        , @opCuenta VARCHAR(32)
        , @opUsername VARCHAR(128)
        , @opPassword VARCHAR(128)
        , @opFechaContratacion DATE
        , @idPuesto INT
        , @idEmpleadoNuevo INT
        , @idUsuario INT
        -- variables para asociar o desasociar deducciones
        , @opTipoDeduccion VARCHAR(128)
        , @opMontoFijo MONEY
        , @idEmpleadoDed INT
        , @idTipoDeduccion INT
        , @flagFijo BIT
        , @porcentajeCatalogo DECIMAL(18, 4)
        , @idDeduccion INT
        , @fechaInicioDed DATE
        -- variables para eliminar empleados
        , @idEmpleadoDel INT
        , @flagEsActivoDel BIT
        , @nombreDel VARCHAR(128)
        , @nombrePuestoDel VARCHAR(128)
        , @fechaContratacionDel DATE
        -- variables para procesar a cada empleado
        , @idEmpleado INT
        , @fechaContratacionEmp DATE
        , @flagEliminaHoy BIT
        -- mas variables para meses, semanas y PSxE, relacionado a la apertura
        , @idMesActual INT
        , @idPMEActual INT
        , @idSemActual INT
        , @idPSEActual INT
        , @idMesSig INT
        , @idSemSig INT
        , @flagCerrada BIT -- flag para cierre
        -- saldo
        , @saldoActual MONEY
        -- variables para marcas de asistencia
        , @salarioXHora MONEY
        , @idTipoJornadaMarca INT
        , @horaInicioJornada TIME
        , @horaFinJornada TIME
        , @horasTrabajadas INT
        , @horasJornada INT
        , @horasOrdinarias INT
        , @horasExtraNormales INT
        , @horasExtraDobles INT
        , @hSlot INT
        , @hEnt DATETIME
        , @hSal DATETIME
        , @montoOrdinario MONEY
        , @montoExtraNormal MONEY
        , @montoExtraDoble MONEY
        , @saldoOrd MONEY
        , @saldoNorm MONEY
        , @saldoDoble MONEY
        , @idMarca INT
        , @idMovimiento INT
        -- variables para procesar el cierre
        , @totalDeducciones MONEY
        , @saldoCorrido MONEY
        , @loDed INT
        , @hiDed INT
        , @dedTipoMov INT
        , @dedMonto MONEY
        , @dedPorc DECIMAL(9, 4)
        -- variable para la sig jornada
        , @idTipoJornadaSig INT
        ;

    DECLARE @Fechas TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [Fecha] DATE
    );
    DECLARE @Inserts TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [Nombre] VARCHAR(128)
        , [ValorDoc] VARCHAR(32)
        , [Puesto] VARCHAR(128)
        , [Cuenta] VARCHAR(32)
        , [Username] VARCHAR(128)
        , [Password] VARCHAR(128)
        , [FechaContratacion] DATE
    );
    DECLARE @Elimina TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [ValorDoc] VARCHAR(32)
    );
    DECLARE @Asocia TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [ValorDoc] VARCHAR(32)
        , [TipoDeduccion] VARCHAR(128)
        , [MontoFijo] MONEY
    );
    DECLARE @Desasocia TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [ValorDoc] VARCHAR(32)
        , [TipoDeduccion] VARCHAR(128)
    );
    DECLARE @Marcas TABLE (
        [idEmpleado] INT
        , [HoraEntrada] DATETIME
        , [HoraSalida] DATETIME
    );
    DECLARE @Jornadas TABLE (
        [idEmpleado] INT
        , [idTipoJornada] INT
    );
    DECLARE @Empleados TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [idEmpleado] INT
        , [FechaContratacion] DATE
    );
    DECLARE @Horas TABLE (
        [h] INT
        , [fechaSlot] DATE
    );
    DECLARE @Deducciones TABLE (
        [Sec] INT IDENTITY(1, 1)
        , [idTipoDeduccion] INT
        , [idTipoMovimiento] INT
        , [monto] MONEY
        , [porcentajeAplicado] DECIMAL(9, 4)
    );

    -- loop para fechas
    INSERT @Fechas ([Fecha])
    SELECT [D].[N].value('@Fecha', 'DATE')
    FROM @inXmlOperaciones.nodes('/Operaciones/FechaOperacion') AS [D]([N])
    ORDER BY [D].[N].value('@Fecha', 'DATE');

    SET @loFecha = 1;

    SELECT @hiFecha = MAX([F].[Sec])
    FROM @Fechas AS [F];

    WHILE (@loFecha <= @hiFecha)
    BEGIN

        SELECT @fechaOperacion = [F].[Fecha]
        FROM @Fechas AS [F]
        WHERE ([F].[Sec] = @loFecha);


        SET @diaSemana = DATEDIFF(DAY, 0, @fechaOperacion) % 7;

        SET @esJueves = 0;
        IF (@diaSemana = @JUEVES)
        BEGIN
            SET @esJueves = 1;
        END;

        -- inicio de la semana actual
        SET @inicioSemanaActual = DATEADD(DAY, -(((@diaSemana - @VIERNES) + 7) % 7), @fechaOperacion);
        SET @inicioSemanaSiguiente = DATEADD(DAY, 1, @fechaOperacion);
        SET @proximoInicioSemana = DATEADD(DAY, 7, @inicioSemanaActual);
        SET @cierreActual = DATEADD(DAY, 6, @inicioSemanaActual);
        SET @cierreSiguiente = DATEADD(DAY, 6, @inicioSemanaSiguiente);
        SET @anioMesActual = YEAR(@cierreActual);
        SET @mesMesActual = MONTH(@cierreActual);
        SET @anioMesSiguiente = YEAR(@cierreSiguiente);
        SET @mesMesSiguiente = MONTH(@cierreSiguiente);

        -- limites del mes planilla actual
        SET @ultimoDiaMes = EOMONTH(DATEFROMPARTS(@anioMesActual, @mesMesActual, 1));
        SET @ultimoDiaMesAnterior = DATEADD(DAY, -1, DATEFROMPARTS(@anioMesActual, @mesMesActual, 1));
        SET @fechaFinMesActual = DATEADD(DAY, -((((DATEDIFF(DAY, 0, @ultimoDiaMes) % 7) - @JUEVES) + 7) % 7), @ultimoDiaMes);
        SET @ultimoJuevesAnterior = DATEADD(DAY, -((((DATEDIFF(DAY, 0, @ultimoDiaMesAnterior) % 7) - @JUEVES) + 7) % 7), @ultimoDiaMesAnterior);
        SET @fechaInicioMesActual = DATEADD(DAY, 1, @ultimoJuevesAnterior);
        SET @cantSemMesActual = DATEDIFF(DAY, @ultimoJuevesAnterior, @fechaFinMesActual) / 7;

        -- limites del mes planilla sig
        SET @ultimoDiaMes = EOMONTH(DATEFROMPARTS(@anioMesSiguiente, @mesMesSiguiente, 1));
        SET @ultimoDiaMesAnterior = DATEADD(DAY, -1, DATEFROMPARTS(@anioMesSiguiente, @mesMesSiguiente, 1));
        SET @fechaFinMesSig = DATEADD(DAY, -((((DATEDIFF(DAY, 0, @ultimoDiaMes) % 7) - @JUEVES) + 7) % 7), @ultimoDiaMes);
        SET @ultimoJuevesAnterior = DATEADD(DAY, -((((DATEDIFF(DAY, 0, @ultimoDiaMesAnterior) % 7) - @JUEVES) + 7) % 7), @ultimoDiaMesAnterior);
        SET @fechaInicioMesSig = DATEADD(DAY, 1, @ultimoJuevesAnterior);
        SET @cantSemMesSig = DATEDIFF(DAY, @ultimoJuevesAnterior, @fechaFinMesSig) / 7;

        -- limites de semana
        SET @fechaFinSemanaActual = DATEADD(DAY, 6, @inicioSemanaActual);
        SET @numeroSemanaActual = (DATEDIFF(DAY, @fechaInicioMesActual, @inicioSemanaActual) / 7) + 1;
        SET @fechaFinSemanaSig = DATEADD(DAY, 6, @inicioSemanaSiguiente);
        SET @numeroSemanaSig = (DATEDIFF(DAY, @fechaInicioMesSig, @inicioSemanaSiguiente) / 7) + 1;

        SET @fechaStr = CONVERT(VARCHAR(16), @fechaOperacion, 23);
        SET @xmlDia = @inXmlOperaciones.query('/Operaciones/FechaOperacion[@Fecha=sql:variable("@fechaStr")]');

        DELETE @Inserts;
        DELETE @Elimina;
        DELETE @Asocia;
        DELETE @Desasocia;
        DELETE @Marcas;
        DELETE @Jornadas;
        DELETE @Empleados;

        INSERT @Inserts (
            [Nombre]
            , [ValorDoc]
            , [Puesto]
            , [Cuenta]
            , [Username]
            , [Password]
            , [FechaContratacion]
        )
        SELECT
            [N].value('@Nombre', 'VARCHAR(128)')
            , [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
            , [N].value('@Puesto', 'VARCHAR(128)')
            , [N].value('@CuentaBancaria', 'VARCHAR(32)')
            , [N].value('@Username', 'VARCHAR(128)')
            , [N].value('@Password', 'VARCHAR(128)')
            , [N].value('@FechaContratacion', 'DATE')
        FROM @xmlDia.nodes('/FechaOperacion/InsertarEmpleado') AS [T]([N]);

        INSERT @Elimina (
            [ValorDoc]
        )
        SELECT [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        FROM @xmlDia.nodes('/FechaOperacion/EliminarEmpleado') AS [T]([N]);

        INSERT @Asocia (
            [ValorDoc]
            , [TipoDeduccion]
            , [MontoFijo]
        )
        SELECT
            [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
            , [N].value('@TipoDeduccion', 'VARCHAR(128)')
            , [N].value('@MontoFijo', 'MONEY')
        FROM @xmlDia.nodes('/FechaOperacion/AsociaEmpleadoConDeduccion') AS [T]([N]);

        INSERT @Desasocia (
            [ValorDoc]
            , [TipoDeduccion]
        )
        SELECT
            [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
            , [N].value('@TipoDeduccion', 'VARCHAR(128)')
        FROM @xmlDia.nodes('/FechaOperacion/DesasociaEmpleadoConDeduccion') AS [T]([N]);

        SELECT @lo = MIN([I].[Sec])
        FROM @Inserts AS [I];
        SELECT @hi = MAX([I].[Sec])
        FROM @Inserts AS [I];

        WHILE (@lo <= @hi)
        BEGIN
            SELECT
                @opNombre = [I].[Nombre]
                , @opValorDoc = [I].[ValorDoc]
                , @opPuesto = [I].[Puesto]
                , @opCuenta = [I].[Cuenta]
                , @opUsername = [I].[Username]
                , @opPassword = [I].[Password]
                , @opFechaContratacion = [I].[FechaContratacion]
            FROM @Inserts AS [I]
            WHERE ([I].[Sec] = @lo);

            SET @idPuesto = NULL;
            SELECT @idPuesto = [P].[id]
            FROM [dbo].[Puesto] AS [P]
            WHERE ([P].[Nombre] = @opPuesto);

            -- puesto debe existir y si el documento ya está entonces se skipea
            IF (@idPuesto IS NOT NULL)
                AND NOT EXISTS (
                    SELECT 1
                    FROM [dbo].[Empleado] AS [E]
                    WHERE ([E].[ValorDocumentoIdentidad] = @opValorDoc)
                )
            BEGIN
                SET @descripcion =
                    'Nombre=' + @opNombre
                    + '; ValorDocumentoIdentidad=' + @opValorDoc
                    + '; Puesto=' + @opPuesto
                    + '; CuentaBancaria=' + @opCuenta
                    + '; FechaContratacion=' + CONVERT(VARCHAR(16), @opFechaContratacion, 23)
                    + '; FlagEsActivo=1'
                    + '; Username=' + @opUsername;

                BEGIN TRANSACTION tInsertar
                    INSERT [dbo].[Empleado] (
                        [idPuesto]
                        , [ValorDocumentoIdentidad]
                        , [Nombre]
                        , [CuentaBancaria]
                        , [FechaContratacion]
                        , [FlagEsActivo]
                    )
                    VALUES (
                        @idPuesto
                        , @opValorDoc
                        , @opNombre
                        , @opCuenta
                        , @opFechaContratacion
                        , 1
                    );

                    SET @idEmpleadoNuevo = SCOPE_IDENTITY();

                    INSERT [dbo].[Usuario] (
                        [Username]
                        , [Password]
                    )
                    VALUES (
                        @opUsername
                        , @opPassword
                    );

                    SET @idUsuario = SCOPE_IDENTITY();

                    INSERT [dbo].[UsuarioEmpleado] (
                        [id]
                        , [idEmpleado]
                    )
                    VALUES (
                        @idUsuario
                        , @idEmpleadoNuevo
                    );

                    INSERT [dbo].[BitacoraEvento] (
                        [idTipoEvento]
                        , [EventDate]
                        , [Descripcion]
                        , [PostInIP]
                        , [PostTime]
                    )
                    VALUES (
                        @EVENTOINSERTAR
                        , @fechaOperacion
                        , @descripcion
                        , @inPostInIP
                        , @postTime
                    );
                COMMIT TRANSACTION tInsertar;
            END;

            SET @lo = @lo + 1;
        END;

        -- asociar deducciones no obligatorias
        SELECT @lo = MIN([A].[Sec])
        FROM @Asocia AS [A];

        SELECT @hi = MAX([A].[Sec])
        FROM @Asocia AS [A];

        WHILE (@lo <= @hi)
        BEGIN
            SELECT
                @opValorDoc = [A].[ValorDoc]
                , @opTipoDeduccion = [A].[TipoDeduccion]
                , @opMontoFijo = [A].[MontoFijo]
            FROM @Asocia AS [A]
            WHERE ([A].[Sec] = @lo);

            SET @idEmpleadoDed = NULL;
            SELECT @idEmpleadoDed = [E].[id]
            FROM [dbo].[Empleado] AS [E]
            WHERE ([E].[ValorDocumentoIdentidad] = @opValorDoc);

            SET @idTipoDeduccion = NULL;
            SELECT @idTipoDeduccion = [TD].[id]
            FROM [dbo].[TipoDeduccion] AS [TD]
            WHERE ([TD].[Nombre] = @opTipoDeduccion);

            SET @flagFijo = NULL;
            IF (@idTipoDeduccion IS NOT NULL)
            BEGIN
                SELECT
                    @flagFijo = [DNO].[FlagFijo]
                    , @porcentajeCatalogo = [DNO].[Porcentaje]
                FROM [dbo].[DeduccionNoObligatoria] AS [DNO]
                WHERE ([DNO].[id] = @idTipoDeduccion);
            END;

            IF (@idEmpleadoDed IS NOT NULL)
                AND (@flagFijo IS NOT NULL)
                AND NOT EXISTS (
                    SELECT 1
                    FROM [dbo].[DeduccionXEmpleado] AS [DXE]
                    WHERE ([DXE].[idEmpleado] = @idEmpleadoDed)
                        AND ([DXE].[idTipoDeduccion] = @idTipoDeduccion)
                )
                AND NOT EXISTS (
                    SELECT 1
                    FROM [dbo].[DeduccionXEmpleadoInactiva] AS [DXI]
                    WHERE ([DXI].[idEmpleado] = @idEmpleadoDed)
                        AND ([DXI].[idTipoDeduccion] = @idTipoDeduccion)
                        AND ([DXI].[FechaInicio] = @proximoInicioSemana)
                )
            BEGIN
                SET @descripcion =
                    'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleadoDed)
                    + '; TipoDeduccion.Id=' + CONVERT(VARCHAR(16), @idTipoDeduccion);
                IF (@flagFijo = 1)
                BEGIN
                    SET @descripcion = @descripcion + '; ValorMontoFijo=' + CONVERT(VARCHAR(32), @opMontoFijo);
                END
                ELSE
                BEGIN
                    SET @descripcion = @descripcion + '; ValorPorcentual=' + CONVERT(VARCHAR(32), @porcentajeCatalogo);
                END;

                BEGIN TRANSACTION tAsociar
                    INSERT [dbo].[DeduccionXEmpleado] (
                        [idEmpleado]
                        , [idTipoDeduccion]
                        , [FechaInicio]
                    )
                    VALUES (
                        @idEmpleadoDed
                        , @idTipoDeduccion
                        , @proximoInicioSemana
                    );

                    SET @idDeduccion = SCOPE_IDENTITY();

                    IF (@flagFijo = 1)
                    BEGIN
                        INSERT [dbo].[DeduccionXEmpleadoFija] (
                            [id]
                            , [Monto]
                        )
                        VALUES (
                            @idDeduccion
                            , @opMontoFijo
                        );
                    END
                    ELSE
                    BEGIN
                        INSERT [dbo].[DeduccionXEmpleadoPorcentual] (
                            [id]
                            , [Porcentaje]
                        )
                        VALUES (
                            @idDeduccion
                            , @porcentajeCatalogo
                        );
                    END;

                    INSERT [dbo].[BitacoraEvento] (
                        [idTipoEvento]
                        , [EventDate]
                        , [Descripcion]
                        , [PostInIP]
                        , [PostTime]
                    )
                    VALUES (
                        @EVENTOASOCIAR
                        , @fechaOperacion
                        , @descripcion
                        , @inPostInIP
                        , @postTime
                    );
                COMMIT TRANSACTION tAsociar;
            END;

            SET @lo = @lo + 1;
        END;

        -- desasociar deducciones
        SELECT @lo = MIN([D].[Sec])
        FROM @Desasocia AS [D];

        SELECT @hi = MAX([D].[Sec])
        FROM @Desasocia AS [D];

        WHILE (@lo <= @hi)
        BEGIN
            SELECT
                @opValorDoc = [D].[ValorDoc]
                , @opTipoDeduccion = [D].[TipoDeduccion]
            FROM @Desasocia AS [D]
            WHERE ([D].[Sec] = @lo);

            SET @idEmpleadoDed = NULL;
            SELECT @idEmpleadoDed = [E].[id]
            FROM [dbo].[Empleado] AS [E]
            WHERE ([E].[ValorDocumentoIdentidad] = @opValorDoc);

            SET @idTipoDeduccion = NULL;
            SELECT @idTipoDeduccion = [TD].[id]
            FROM [dbo].[TipoDeduccion] AS [TD]
            WHERE ([TD].[Nombre] = @opTipoDeduccion);

            SET @idDeduccion = NULL;
            IF (@idEmpleadoDed IS NOT NULL)
                AND (@idTipoDeduccion IS NOT NULL)

            BEGIN
                SELECT
                    @idDeduccion = [DXE].[id]
                    , @fechaInicioDed = [DXE].[FechaInicio]
                FROM [dbo].[DeduccionXEmpleado] AS [DXE]
                WHERE ([DXE].[idEmpleado] = @idEmpleadoDed)
                    AND ([DXE].[idTipoDeduccion] = @idTipoDeduccion);
            END;

            IF (@idDeduccion IS NOT NULL)
            BEGIN
                SET @descripcion =
                    'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleadoDed)
                    + '; TipoDeduccion.Id=' + CONVERT(VARCHAR(16), @idTipoDeduccion);

                BEGIN TRANSACTION tDesasociar
                    INSERT [dbo].[DeduccionXEmpleadoInactiva] (
                        [idEmpleado]
                        , [idTipoDeduccion]
                        , [FechaInicio]
                        , [FechaFin]
                    )
                    VALUES (
                        @idEmpleadoDed
                        , @idTipoDeduccion
                        , @fechaInicioDed
                        , @proximoInicioSemana
                    );

                    DELETE [dbo].[DeduccionXEmpleadoFija]
                    WHERE ([id] = @idDeduccion);

                    DELETE [dbo].[DeduccionXEmpleadoPorcentual]
                    WHERE ([id] = @idDeduccion);

                    DELETE [dbo].[DeduccionXEmpleado]
                    WHERE ([id] = @idDeduccion);

                    INSERT [dbo].[BitacoraEvento] (
                        [idTipoEvento]
                        , [EventDate]
                        , [Descripcion]
                        , [PostInIP]
                        , [PostTime]
                    )
                    VALUES (
                        @EVENTODESASOCIAR
                        , @fechaOperacion
                        , @descripcion
                        , @inPostInIP
                        , @postTime
                    );
                COMMIT TRANSACTION tDesasociar;
            END;

            SET @lo = @lo + 1;
        END;

        INSERT @Marcas (
            [idEmpleado]
            , [HoraEntrada]
            , [HoraSalida]
        )
        SELECT
            [E].[id]
            , [N].value('@HoraEntrada', 'DATETIME')
            , [N].value('@HoraSalida', 'DATETIME')
        FROM @xmlDia.nodes('/FechaOperacion/MarcaAsistencia') AS [T]([N])
        INNER JOIN [dbo].[Empleado] AS [E]
            ON ([E].[ValorDocumentoIdentidad] = [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)'));

        INSERT @Jornadas (
            [idEmpleado]
            , [idTipoJornada]
        )
        SELECT
            [E].[id]
            , [TJ].[id]
        FROM @xmlDia.nodes('/FechaOperacion/AsignarJornada') AS [T]([N])
        INNER JOIN [dbo].[Empleado] AS [E]
            ON ([E].[ValorDocumentoIdentidad] = [N].value('@ValorDocumentoIdentidad', 'VARCHAR(32)'))
        INNER JOIN [dbo].[TipoJornada] AS [TJ]
            ON ([TJ].[Nombre] = [N].value('@Jornada', 'VARCHAR(128)'));

        -- insertar los empleados para procesar
        INSERT @Empleados (
            [idEmpleado]
            , [FechaContratacion]
        )
        SELECT
            [E].[id]
            , [E].[FechaContratacion]
        FROM [dbo].[Empleado] AS [E]
        WHERE ([E].[FlagEsActivo] = 1)
            AND (
                (@esJueves = 1)
                OR EXISTS (
                    SELECT 1
                    FROM @Marcas AS [M]
                    WHERE ([M].[idEmpleado] = [E].[id])
                )
            )
        ORDER BY [E].[id];

        SELECT @lo = MIN([EM].[Sec])
        FROM @Empleados AS [EM];

        SELECT @hi = MAX([EM].[Sec])
        FROM @Empleados AS [EM];

        -- loop para hacer una transacción por empleado
        WHILE (@lo <= @hi)
        BEGIN

            SELECT
                @idEmpleado = [EM].[idEmpleado]
                , @fechaContratacionEmp = [EM].[FechaContratacion]
            FROM @Empleados AS [EM]
            WHERE ([EM].[Sec] = @lo);

            SET @flagEliminaHoy = 0;
            IF EXISTS (
                SELECT 1
                FROM @Elimina AS [DEL]
                INNER JOIN [dbo].[Empleado] AS [E2]
                    ON ([E2].[ValorDocumentoIdentidad] = [DEL].[ValorDoc])
                WHERE ([E2].[id] = @idEmpleado)
            )
            BEGIN
                SET @flagEliminaHoy = 1;
            END;

            BEGIN TRANSACTION tEmpleado
                IF (@fechaContratacionEmp <= @inicioSemanaActual)
                BEGIN
                    SET @idMesActual = NULL;
                    SELECT @idMesActual = [MES].[id]
                    FROM [dbo].[MesPlanilla] AS [MES]
                    WHERE ([MES].[Anio] = @anioMesActual)
                        AND ([MES].[Mes] = @mesMesActual);

                    IF (@idMesActual IS NULL)
                    BEGIN
                        INSERT [dbo].[MesPlanilla] (
                            [Anio]
                            , [Mes]
                            , [FechaInicio]
                            , [FechaFin]
                            , [CantidadSemanas]
                            , [FlagAbierto]
                        )
                        VALUES (
                            @anioMesActual
                            , @mesMesActual
                            , @fechaInicioMesActual
                            , @fechaFinMesActual
                            , @cantSemMesActual
                            , 1
                        );
                        SET @idMesActual = SCOPE_IDENTITY();
                    END;

                    SET @idPMEActual = NULL;

                    SELECT @idPMEActual = [PME].[id]
                    FROM [dbo].[PlanillaMesXEmpleado] AS [PME]
                    WHERE ([PME].[idMesPlanilla] = @idMesActual)
                        AND ([PME].[idEmpleado] = @idEmpleado);

                    IF (@idPMEActual IS NULL)
                    BEGIN
                        INSERT [dbo].[PlanillaMesXEmpleado] (
                            [idMesPlanilla]
                            , [idEmpleado]
                            , [SalarioBrutoMensual]
                            , [DeduccionesMensuales]
                            , [SalarioNetoMensual]
                        )
                        VALUES (
                            @idMesActual
                            , @idEmpleado
                            , 0
                            , 0
                            , 0
                        );
                        SET @idPMEActual = SCOPE_IDENTITY();
                    END;

                    SET @idSemActual = NULL;
                    SELECT @idSemActual = [SP].[id]
                    FROM [dbo].[SemanaPlanilla] AS [SP]
                    WHERE ([SP].[FechaInicio] = @inicioSemanaActual);

                    IF (@idSemActual IS NULL)
                    BEGIN
                        INSERT [dbo].[SemanaPlanilla] (
                            [idMesPlanilla]
                            , [FechaInicio]
                            , [FechaFin]
                            , [NumeroSemana]
                            , [FlagAbierta]
                        )
                        VALUES (
                            @idMesActual
                            , @inicioSemanaActual
                            , @fechaFinSemanaActual
                            , @numeroSemanaActual
                            , 1
                        );
                        SET @idSemActual = SCOPE_IDENTITY();
                    END;

                    SET @idPSEActual = NULL;
                    SELECT
                        @idPSEActual = [PSE].[id]
                        , @saldoActual = [PSE].[SalarioBruto]
                        , @flagCerrada = [PSE].[FlagCerrada]
                    FROM [dbo].[PlanillaSemXEmpleado] AS [PSE]
                    WHERE ([PSE].[idSemanaPlanilla] = @idSemActual)
                        AND ([PSE].[idEmpleado] = @idEmpleado);

                    IF (@idPSEActual IS NULL)
                    BEGIN
                        INSERT [dbo].[PlanillaSemXEmpleado] (
                            [idSemanaPlanilla]
                            , [idEmpleado]
                            , [idPlanillaMesXEmpleado]
                            , [SalarioBruto]
                            , [TotalDeducciones]
                            , [SalarioNeto]
                            , [HorasOrdinarias]
                            , [HorasExtrasNormales]
                            , [HorasExtrasDobles]
                            , [FlagCerrada]
                        )
                        VALUES (
                            @idSemActual
                            , @idEmpleado
                            , @idPMEActual
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                        );
                        SET @idPSEActual = SCOPE_IDENTITY();
                        SET @saldoActual = 0;
                        SET @flagCerrada = 0;
                    END;

                    IF EXISTS (
                        SELECT 1
                        FROM @Marcas AS [M]
                        WHERE ([M].[idEmpleado] = @idEmpleado)
                    )
                    AND NOT EXISTS (
                        SELECT 1
                        FROM [dbo].[MarcaAsistencia] AS [MA]
                        WHERE ([MA].[idEmpleado] = @idEmpleado)
                            AND ([MA].[Fecha] = @fechaOperacion)
                    )
                    BEGIN
                        SELECT
                            @hEnt = [M].[HoraEntrada]
                            , @hSal = [M].[HoraSalida]
                        FROM @Marcas AS [M]
                        WHERE ([M].[idEmpleado] = @idEmpleado);

                        SELECT @salarioXHora = [P].[SalarioXHora]
                        FROM [dbo].[Empleado] AS [E]
                        INNER JOIN [dbo].[Puesto] AS [P]
                            ON ([E].[idPuesto] = [P].[id])
                        WHERE ([E].[id] = @idEmpleado);

                        SET @idTipoJornadaMarca = NULL;
                        SET @horaInicioJornada = NULL;
                        SET @horaFinJornada = NULL;
                        
                        SELECT
                            @idTipoJornadaMarca = [TJ].[id]
                            , @horaInicioJornada = [TJ].[HoraInicio]
                            , @horaFinJornada = [TJ].[HoraFin]
                        FROM [dbo].[JornadaXEmpleadoXSemana] AS [JXS]
                        INNER JOIN [dbo].[TipoJornada] AS [TJ]
                            ON ([JXS].[idTipoJornada] = [TJ].[id])
                        WHERE ([JXS].[idSemanaPlanilla] = @idSemActual)
                            AND ([JXS].[idEmpleado] = @idEmpleado);

                        SET @horasTrabajadas = DATEDIFF(MINUTE, @hEnt, @hSal) / 60;
                        SET @horasJornada = ((DATEDIFF(MINUTE, @horaInicioJornada, @horaFinJornada) + 1440) % 1440) / 60;

                        DELETE @Horas;
                        SET @hSlot = 0;
                        WHILE (@hSlot < @horasTrabajadas)
                        BEGIN
                            INSERT @Horas (
                                [h]
                                , [fechaSlot]
                            )
                            VALUES (
                                @hSlot
                                , CAST(DATEADD(HOUR, @hSlot, @hEnt) AS DATE)
                            );
                            SET @hSlot = @hSlot + 1;
                        END;

                        SELECT @horasOrdinarias = COUNT(1)
                        FROM @Horas AS [H]
                        WHERE ([H].[h] < @horasJornada);

                        SELECT @horasExtraDobles = COUNT(1)
                        FROM @Horas AS [H]
                        WHERE ([H].[h] >= @horasJornada)
                            AND (
                                ((DATEDIFF(DAY, 0, [H].[fechaSlot]) % 7) = @DOMINGO)
                                OR EXISTS (
                                    SELECT 1
                                    FROM [dbo].[Feriado] AS [F]
                                    WHERE ([F].[Fecha] = [H].[fechaSlot])
                                )
                            );

                        SELECT @horasExtraNormales = COUNT(1)
                        FROM @Horas AS [H]
                        WHERE ([H].[h] >= @horasJornada)
                            AND ((DATEDIFF(DAY, 0, [H].[fechaSlot]) % 7) != @DOMINGO)
                            AND NOT EXISTS (
                                SELECT 1
                                FROM [dbo].[Feriado] AS [F]
                                WHERE ([F].[Fecha] = [H].[fechaSlot])
                            );

                        SET @montoOrdinario = @horasOrdinarias * @salarioXHora;
                        SET @montoExtraNormal = @horasExtraNormales * @salarioXHora * @FACTOREXTRANORMAL;
                        SET @montoExtraDoble = @horasExtraDobles * @salarioXHora * @FACTOREXTRADOBLE;
                        SET @saldoOrd = @saldoActual + @montoOrdinario;
                        SET @saldoNorm = @saldoOrd + @montoExtraNormal;
                        SET @saldoDoble = @saldoNorm + @montoExtraDoble;

                        INSERT [dbo].[MarcaAsistencia] (
                            [idPlanillaSemXEmpleado]
                            , [idEmpleado]
                            , [idTipoJornada]
                            , [Fecha]
                            , [HoraEntrada]
                            , [HoraSalida]
                            , [HorasOrdinarias]
                            , [HorasExtrasNormales]
                            , [HorasExtrasDobles]
                            , [MontoOrdinario]
                            , [MontoExtraNormal]
                            , [MontoExtraDoble]
                        )
                        VALUES (
                            @idPSEActual
                            , @idEmpleado
                            , @idTipoJornadaMarca
                            , @fechaOperacion
                            , @hEnt
                            , @hSal
                            , @horasOrdinarias
                            , @horasExtraNormales
                            , @horasExtraDobles
                            , @montoOrdinario
                            , @montoExtraNormal
                            , @montoExtraDoble
                        );

                        SET @idMarca = SCOPE_IDENTITY();

                        IF (@horasOrdinarias > 0)
                        BEGIN
                            INSERT [dbo].[MovimientoPlanilla] (
                                [idPlanillaSemXEmpleado]
                                , [idTipoMovimiento]
                                , [Fecha]
                                , [Monto]
                                , [NuevoSaldo]
                            )
                            VALUES (
                                @idPSEActual
                                , @TMORDINARIO
                                , @fechaOperacion
                                , @montoOrdinario
                                , @saldoOrd
                            );
                            SET @idMovimiento = SCOPE_IDENTITY();
                            INSERT [dbo].[MovimientoHoras] (
                                [id]
                                , [idMarcaAsistencia]
                                , [CantidadHoras]
                            )
                            VALUES (
                                @idMovimiento
                                , @idMarca
                                , @horasOrdinarias
                            );
                            UPDATE [dbo].[PlanillaSemXEmpleado] WITH (ROWLOCK)
                            SET [SalarioBruto] = @saldoOrd
                                , [HorasOrdinarias] = [HorasOrdinarias] + @horasOrdinarias
                            WHERE ([id] = @idPSEActual);
                        END;

                        IF (@horasExtraNormales > 0)
                        BEGIN
                            INSERT [dbo].[MovimientoPlanilla] (
                                [idPlanillaSemXEmpleado]
                                , [idTipoMovimiento]
                                , [Fecha]
                                , [Monto]
                                , [NuevoSaldo]
                            )
                            VALUES (
                                @idPSEActual
                                , @TMEXTRANORMAL
                                , @fechaOperacion
                                , @montoExtraNormal
                                , @saldoNorm
                            );
                            SET @idMovimiento = SCOPE_IDENTITY();
                            INSERT [dbo].[MovimientoHoras] (
                                [id]
                                , [idMarcaAsistencia]
                                , [CantidadHoras]
                            )
                            VALUES (
                                @idMovimiento
                                , @idMarca
                                , @horasExtraNormales
                            );
                            UPDATE [dbo].[PlanillaSemXEmpleado] WITH (ROWLOCK)
                            SET [SalarioBruto] = @saldoNorm
                                , [HorasExtrasNormales] = [HorasExtrasNormales] + @horasExtraNormales
                            WHERE ([id] = @idPSEActual);
                        END;

                        IF (@horasExtraDobles > 0)
                        BEGIN
                            INSERT [dbo].[MovimientoPlanilla] (
                                [idPlanillaSemXEmpleado]
                                , [idTipoMovimiento]
                                , [Fecha]
                                , [Monto]
                                , [NuevoSaldo]
                            )
                            VALUES (
                                @idPSEActual
                                , @TMEXTRADOBLE
                                , @fechaOperacion
                                , @montoExtraDoble
                                , @saldoDoble
                            );
                            SET @idMovimiento = SCOPE_IDENTITY();
                            INSERT [dbo].[MovimientoHoras] (
                                [id]
                                , [idMarcaAsistencia]
                                , [CantidadHoras]
                            )
                            VALUES (
                                @idMovimiento
                                , @idMarca
                                , @horasExtraDobles
                            );
                            UPDATE [dbo].[PlanillaSemXEmpleado] WITH (ROWLOCK)
                            SET [SalarioBruto] = @saldoDoble
                                , [HorasExtrasDobles] = [HorasExtrasDobles] + @horasExtraDobles
                            WHERE ([id] = @idPSEActual);
                        END;

                        INSERT [dbo].[BitacoraEvento] (
                            [idTipoEvento]
                            , [EventDate]
                            , [Descripcion]
                            , [PostInIP]
                            , [PostTime]
                        )
                        VALUES (
                            @EVENTOMARCA
                            , @fechaOperacion
                            , 'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleado)
                                + '; MarcaInicio=' + CONVERT(VARCHAR(32), @hEnt, 120)
                                + '; MarcaFin=' + CONVERT(VARCHAR(32), @hSal, 120)
                            , @inPostInIP
                            , @postTime
                        );

                        SET @saldoActual = @saldoDoble;
                    END;

                    IF (@esJueves = 1)
                        AND (@flagCerrada = 0)
                    BEGIN
                        -- deducciones porcentuales activas
                        DELETE @Deducciones;
                        INSERT @Deducciones (
                            [idTipoDeduccion]
                            , [idTipoMovimiento]
                            , [monto]
                            , [porcentajeAplicado]
                        )
                        SELECT
                            [DXE].[idTipoDeduccion]
                            , [TD].[idTipoMovimiento]
                            , ([DXP].[Porcentaje] * @saldoActual)
                            , [DXP].[Porcentaje]
                        FROM [dbo].[DeduccionXEmpleado] AS [DXE]
                        INNER JOIN [dbo].[DeduccionXEmpleadoPorcentual] AS [DXP]
                            ON ([DXE].[id] = [DXP].[id])
                        INNER JOIN [dbo].[TipoDeduccion] AS [TD]
                            ON ([DXE].[idTipoDeduccion] = [TD].[id])
                        WHERE ([DXE].[idEmpleado] = @idEmpleado)
                            AND ([DXE].[FechaInicio] <= @inicioSemanaActual)
                        ORDER BY [DXE].[idTipoDeduccion];

                        -- deducciones fijas
                        INSERT @Deducciones (
                            [idTipoDeduccion]
                            , [idTipoMovimiento]
                            , [monto]
                            , [porcentajeAplicado]
                        )
                        SELECT
                            [DXE].[idTipoDeduccion]
                            , [TD].[idTipoMovimiento]
                            , ([DXF].[Monto] / @cantSemMesActual)
                            , 0
                        FROM [dbo].[DeduccionXEmpleado] AS [DXE]
                        INNER JOIN [dbo].[DeduccionXEmpleadoFija] AS [DXF]
                            ON ([DXE].[id] = [DXF].[id])
                        INNER JOIN [dbo].[TipoDeduccion] AS [TD]
                            ON ([DXE].[idTipoDeduccion] = [TD].[id])
                        WHERE ([DXE].[idEmpleado] = @idEmpleado)
                            AND ([DXE].[FechaInicio] <= @inicioSemanaActual)
                        ORDER BY [DXE].[idTipoDeduccion];

                        -- aplicar cada deduccion
                        SET @saldoCorrido = @saldoActual;
                        SET @totalDeducciones = 0;
                        SELECT @loDed = MIN([D].[Sec])
                        FROM @Deducciones AS [D];

                        SELECT @hiDed = MAX([D].[Sec])
                        FROM @Deducciones AS [D];

                        WHILE (@loDed <= @hiDed)
                        BEGIN
                            SELECT
                                @dedTipoMov = [D].[idTipoMovimiento]
                                , @dedMonto = [D].[monto]
                                , @dedPorc = [D].[porcentajeAplicado]
                            FROM @Deducciones AS [D]
                            WHERE ([D].[Sec] = @loDed);

                            SET @totalDeducciones = @totalDeducciones + @dedMonto;
                            SET @saldoCorrido = @saldoActual - @totalDeducciones;

                            INSERT [dbo].[MovimientoPlanilla] (
                                [idPlanillaSemXEmpleado]
                                , [idTipoMovimiento]
                                , [Fecha]
                                , [Monto]
                                , [NuevoSaldo]
                            )
                            VALUES (
                                @idPSEActual
                                , @dedTipoMov
                                , @fechaOperacion
                                , @dedMonto
                                , @saldoCorrido
                            );

                            SET @idMovimiento = SCOPE_IDENTITY();

                            INSERT [dbo].[MovimientoDeduccion] (
                                [id]
                                , [PorcentajeAplicado]
                            )
                            VALUES (
                                @idMovimiento
                                , @dedPorc
                            );

                            SET @loDed = @loDed + 1;
                        END;

                        UPDATE [dbo].[PlanillaSemXEmpleado] WITH (ROWLOCK)
                        SET [TotalDeducciones] = @totalDeducciones
                            , [SalarioNeto] = (@saldoActual - @totalDeducciones)
                            , [FlagCerrada] = 1
                        WHERE ([id] = @idPSEActual);

                        UPDATE [dbo].[PlanillaMesXEmpleado] WITH (ROWLOCK)
                        SET [SalarioBrutoMensual] = [SalarioBrutoMensual] + @saldoActual
                            , [DeduccionesMensuales] = [DeduccionesMensuales] + @totalDeducciones
                            , [SalarioNetoMensual] = [SalarioNetoMensual] + (@saldoActual - @totalDeducciones)
                        WHERE ([id] = @idPMEActual);

                        UPDATE [DXM] WITH (ROWLOCK)
                        SET [DXM].[MontoAcumulado] = [DXM].[MontoAcumulado] + [D].[monto]
                        FROM [dbo].[DeduccionXEmpleadoXMes] AS [DXM]
                        INNER JOIN @Deducciones AS [D]
                            ON ([DXM].[idTipoDeduccion] = [D].[idTipoDeduccion])
                        WHERE ([DXM].[idPlanillaMesXEmpleado] = @idPMEActual);

                        INSERT [dbo].[DeduccionXEmpleadoXMes] (
                            [idPlanillaMesXEmpleado]
                            , [idTipoDeduccion]
                            , [MontoAcumulado]
                            , [PorcentajeAplicado]
                        )
                        SELECT
                            @idPMEActual
                            , [D].[idTipoDeduccion]
                            , [D].[monto]
                            , [D].[porcentajeAplicado]
                        FROM @Deducciones AS [D]
                        WHERE NOT EXISTS (
                            SELECT 1
                            FROM [dbo].[DeduccionXEmpleadoXMes] AS [DXM]
                            WHERE ([DXM].[idPlanillaMesXEmpleado] = @idPMEActual)
                                AND ([DXM].[idTipoDeduccion] = [D].[idTipoDeduccion])
                        );

                        -- cerrar la semana y el mes si esta es su ultima semana
                        UPDATE [dbo].[SemanaPlanilla] WITH (ROWLOCK)
                        SET [FlagAbierta] = 0
                        WHERE ([id] = @idSemActual);

                        IF (@fechaFinSemanaActual = @fechaFinMesActual)
                        BEGIN
                            UPDATE [dbo].[MesPlanilla] WITH (ROWLOCK)
                            SET [FlagAbierto] = 0
                            WHERE ([id] = @idMesActual);
                        END;
                    END;
                END;

                IF (@esJueves = 1)
                    AND (@fechaContratacionEmp <= @inicioSemanaSiguiente)
                    AND (@flagEliminaHoy = 0)
                BEGIN
                    -- abrir mes sig
                    SET @idMesSig = NULL;
                    SELECT @idMesSig = [MES].[id]
                    FROM [dbo].[MesPlanilla] AS [MES]
                    WHERE ([MES].[Anio] = @anioMesSiguiente)
                        AND ([MES].[Mes] = @mesMesSiguiente);

                    IF (@idMesSig IS NULL)
                    BEGIN
                        INSERT [dbo].[MesPlanilla] (
                            [Anio]
                            , [Mes]
                            , [FechaInicio]
                            , [FechaFin]
                            , [CantidadSemanas]
                            , [FlagAbierto]
                        )
                        VALUES (
                            @anioMesSiguiente
                            , @mesMesSiguiente
                            , @fechaInicioMesSig
                            , @fechaFinMesSig
                            , @cantSemMesSig
                            , 1
                        );
                        SET @idMesSig = SCOPE_IDENTITY();
                    END;

                    SET @idPMEActual = NULL;
                    SELECT @idPMEActual = [PME].[id]
                    FROM [dbo].[PlanillaMesXEmpleado] AS [PME]
                    WHERE ([PME].[idMesPlanilla] = @idMesSig)
                        AND ([PME].[idEmpleado] = @idEmpleado);

                    IF (@idPMEActual IS NULL)
                    BEGIN
                        INSERT [dbo].[PlanillaMesXEmpleado] (
                            [idMesPlanilla]
                            , [idEmpleado]
                            , [SalarioBrutoMensual]
                            , [DeduccionesMensuales]
                            , [SalarioNetoMensual]
                        )
                        VALUES (
                            @idMesSig
                            , @idEmpleado
                            , 0
                            , 0
                            , 0
                        );
                        SET @idPMEActual = SCOPE_IDENTITY();
                    END;

                    -- abrir semana sig
                    SET @idSemSig = NULL;
                    SELECT @idSemSig = [SP].[id]
                    FROM [dbo].[SemanaPlanilla] AS [SP]
                    WHERE ([SP].[FechaInicio] = @inicioSemanaSiguiente);

                    IF (@idSemSig IS NULL)
                    BEGIN
                        INSERT [dbo].[SemanaPlanilla] (
                            [idMesPlanilla]
                            , [FechaInicio]
                            , [FechaFin]
                            , [NumeroSemana]
                            , [FlagAbierta]
                        )
                        VALUES (
                            @idMesSig
                            , @inicioSemanaSiguiente
                            , @fechaFinSemanaSig
                            , @numeroSemanaSig
                            , 1
                        );
                        SET @idSemSig = SCOPE_IDENTITY();
                    END;

                    IF NOT EXISTS (
                        SELECT 1
                        FROM [dbo].[PlanillaSemXEmpleado] AS [PSE]
                        WHERE ([PSE].[idSemanaPlanilla] = @idSemSig)
                            AND ([PSE].[idEmpleado] = @idEmpleado)
                    )
                    BEGIN
                        INSERT [dbo].[PlanillaSemXEmpleado] (
                            [idSemanaPlanilla]
                            , [idEmpleado]
                            , [idPlanillaMesXEmpleado]
                            , [SalarioBruto]
                            , [TotalDeducciones]
                            , [SalarioNeto]
                            , [HorasOrdinarias]
                            , [HorasExtrasNormales]
                            , [HorasExtrasDobles]
                            , [FlagCerrada]
                        )
                        VALUES (
                            @idSemSig
                            , @idEmpleado
                            , @idPMEActual
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                            , 0
                        );
                    END;

                    -- asignar la jornada de la semana sig
                    SET @idTipoJornadaSig = NULL;
                    SELECT @idTipoJornadaSig = [J].[idTipoJornada]
                    FROM @Jornadas AS [J]
                    WHERE ([J].[idEmpleado] = @idEmpleado);

                    IF (@idTipoJornadaSig IS NOT NULL)
                        AND NOT EXISTS (
                            SELECT 1
                            FROM [dbo].[JornadaXEmpleadoXSemana] AS [JXS]
                            WHERE ([JXS].[idSemanaPlanilla] = @idSemSig)
                                AND ([JXS].[idEmpleado] = @idEmpleado)
                        )
                    BEGIN
                        INSERT [dbo].[JornadaXEmpleadoXSemana] (
                            [idSemanaPlanilla]
                            , [idEmpleado]
                            , [idTipoJornada]
                        )
                        VALUES (
                            @idSemSig
                            , @idEmpleado
                            , @idTipoJornadaSig
                        );

                        INSERT [dbo].[BitacoraEvento] (
                            [idTipoEvento]
                            , [EventDate]
                            , [Descripcion]
                            , [PostInIP]
                            , [PostTime]
                        )
                        VALUES (
                            @EVENTOJORNADA
                            , @fechaOperacion
                            , 'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleado)
                                + '; TipoJornada.Id=' + CONVERT(VARCHAR(16), @idTipoJornadaSig)
                            , @inPostInIP
                            , @postTime
                        );
                    END;
                END;

            COMMIT TRANSACTION tEmpleado;

            SET @lo = @lo + 1;

        END;

        -- eliminar empleado
        SELECT @lo = MIN([E].[Sec])
        FROM @Elimina AS [E];

        SELECT @hi = MAX([E].[Sec])
        FROM @Elimina AS [E];

        WHILE (@lo <= @hi)
        BEGIN
            SELECT @opValorDoc = [E].[ValorDoc]
            FROM @Elimina AS [E]
            WHERE ([E].[Sec] = @lo);

            SET @idEmpleadoDel = NULL;
            SELECT
                @idEmpleadoDel = [E].[id]
                , @flagEsActivoDel = [E].[FlagEsActivo]
                , @nombreDel = [E].[Nombre]
                , @nombrePuestoDel = [P].[Nombre]
                , @fechaContratacionDel = [E].[FechaContratacion]
            FROM [dbo].[Empleado] AS [E]
            INNER JOIN [dbo].[Puesto] AS [P]
                ON ([E].[idPuesto] = [P].[id])
            WHERE ([E].[ValorDocumentoIdentidad] = @opValorDoc);

            IF (@idEmpleadoDel IS NOT NULL)
                AND (@flagEsActivoDel = 1)
            BEGIN
                SET @descripcion =
                    'Empleado.Id=' + CONVERT(VARCHAR(16), @idEmpleadoDel)
                    + '; Nombre=' + @nombreDel
                    + '; ValorDocumentoIdentidad=' + @opValorDoc
                    + '; Puesto=' + @nombrePuestoDel
                    + '; FechaContratacion=' + CONVERT(VARCHAR(16), @fechaContratacionDel, 23);

                BEGIN TRANSACTION tEliminar
                    UPDATE [dbo].[Empleado] WITH (ROWLOCK)
                    SET [FlagEsActivo] = 0
                    WHERE ([id] = @idEmpleadoDel);

                    INSERT [dbo].[BitacoraEvento] (
                        [idTipoEvento]
                        , [EventDate]
                        , [Descripcion]
                        , [PostInIP]
                        , [PostTime]
                    )
                    VALUES (
                        @EVENTOELIMINAR
                        , @fechaOperacion
                        , @descripcion
                        , @inPostInIP
                        , @postTime
                    );
                COMMIT TRANSACTION tEliminar;
            END;

            SET @lo = @lo + 1;
        END;

        SET @loFecha = @loFecha + 1;

    END;

    SELECT @outResultCode AS [outResultCode];

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 BEGIN
        ROLLBACK TRANSACTION;
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
