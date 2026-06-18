USE [TareaProgramadaTres];
GO

CREATE TABLE [dbo].[TipoJornada] (
    [id] INT NOT NULL PRIMARY KEY
    , [Nombre] VARCHAR(128) NOT NULL
    , [HoraInicio] TIME NOT NULL
    , [HoraFin] TIME NOT NULL
    , CONSTRAINT [AK_TipoJornada_Nombre] UNIQUE ([Nombre])
);
GO

CREATE TABLE [dbo].[Puesto] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [Nombre] VARCHAR(128) NOT NULL
    , [SalarioXHora] MONEY NOT NULL
    , CONSTRAINT [AK_Puesto_Nombre] UNIQUE ([Nombre])
);
GO

CREATE TABLE [dbo].[TipoEvento] (
    [id] INT NOT NULL PRIMARY KEY
    , [Nombre] VARCHAR(128) NOT NULL
);
GO

CREATE TABLE [dbo].[Error] (
    [Codigo] INT NOT NULL PRIMARY KEY
    , [Descripcion] VARCHAR(MAX) NOT NULL
);
GO

CREATE TABLE [dbo].[TipoMovimiento] (
    [id] INT NOT NULL PRIMARY KEY
    , [Nombre] VARCHAR(128) NOT NULL
    , [Accion] CHAR(8) NOT NULL
);
GO

CREATE TABLE [dbo].[TipoDeduccion] (
    [id] INT NOT NULL PRIMARY KEY
    , [idTipoMovimiento] INT NOT NULL
    , [Nombre] VARCHAR(128) NOT NULL
    , CONSTRAINT [AK_TipoDeduccion_Nombre] UNIQUE ([Nombre])
    , CONSTRAINT [FK_TipoDeduccion_TipoMovimiento]
        FOREIGN KEY ([idTipoMovimiento])
        REFERENCES [dbo].[TipoMovimiento] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionLey] (
    [id] INT NOT NULL PRIMARY KEY
    , [Porcentaje] DECIMAL(18, 4) NOT NULL
    , CONSTRAINT [FK_DeduccionLey_TipoDeduccion]
        FOREIGN KEY ([id]) REFERENCES [dbo].[TipoDeduccion] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionNoObligatoria] (
    [id] INT NOT NULL PRIMARY KEY
    , [FlagFijo] BIT NOT NULL
    , [Porcentaje] DECIMAL(18, 4) NOT NULL
    , CONSTRAINT [FK_DeduccionNoObligatoria_TipoDeduccion]
        FOREIGN KEY ([id]) REFERENCES [dbo].[TipoDeduccion] ([id])
);
GO

CREATE TABLE [dbo].[Feriado] (
    [id] INT NOT NULL PRIMARY KEY
    , [Nombre] VARCHAR(128) NOT NULL
    , [Fecha] DATE NOT NULL
    , CONSTRAINT [AK_Feriado_Fecha] UNIQUE ([Fecha])
);
GO

CREATE TABLE [dbo].[Usuario] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [Username] VARCHAR(128) NOT NULL
    , [Password] VARCHAR(128) NOT NULL
    , CONSTRAINT [AK_Usuario_Username] UNIQUE ([Username])
);
GO

CREATE TABLE [dbo].[Empleado] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idPuesto] INT NOT NULL
    , [ValorDocumentoIdentidad] VARCHAR(32) NOT NULL
    , [Nombre] VARCHAR(128) NOT NULL
    , [CuentaBancaria] VARCHAR(32) NOT NULL
    , [FechaContratacion] DATE NOT NULL
    , [FlagEsActivo] BIT NOT NULL
    , CONSTRAINT [AK_Empleado_Documento] UNIQUE ([ValorDocumentoIdentidad])
    , CONSTRAINT [FK_Empleado_Puesto]
        FOREIGN KEY ([idPuesto])
        REFERENCES [dbo].[Puesto] ([id])
);
GO

CREATE TABLE [dbo].[UsuarioAdministrador] (
    [id] INT NOT NULL PRIMARY KEY
    , CONSTRAINT [FK_UsuarioAdmin_Usuario]
        FOREIGN KEY ([id])
        REFERENCES [dbo].[Usuario] ([id])
);
GO

CREATE TABLE [dbo].[UsuarioEmpleado] (
    [id] INT NOT NULL PRIMARY KEY
    , [idEmpleado] INT NOT NULL
    , CONSTRAINT [AK_UsuarioEmpleado_Empleado] UNIQUE ([idEmpleado])
    , CONSTRAINT [FK_UsuarioEmpleado_Usuario]
        FOREIGN KEY ([id])
        REFERENCES [dbo].[Usuario] ([id])
    , CONSTRAINT [FK_UsuarioEmpleado_Empleado]
        FOREIGN KEY ([idEmpleado])
        REFERENCES [dbo].[Empleado] ([id])
);
GO

CREATE TABLE [dbo].[Impersonacion] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idUsuarioAdmin] INT NOT NULL
    , [idEmpleadoImpersonado] INT NOT NULL
    , [FlagActivo] BIT NOT NULL
    , CONSTRAINT [FK_Impersonacion_Admin]
        FOREIGN KEY ([idUsuarioAdmin])
        REFERENCES [dbo].[UsuarioAdministrador] ([id])
    , CONSTRAINT [FK_Impersonacion_Empleado]
        FOREIGN KEY ([idEmpleadoImpersonado])
        REFERENCES [dbo].[Empleado] ([id])
);
GO

CREATE TABLE [dbo].[MesPlanilla] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [Anio] INT NOT NULL
    , [Mes] INT NOT NULL
    , [FechaInicio] DATE NOT NULL
    , [FechaFin] DATE NOT NULL
    , [CantidadSemanas] INT NOT NULL
    , [FlagAbierto] BIT NOT NULL
    , CONSTRAINT [AK_MesPlanilla_AnioMes] UNIQUE ([Anio], [Mes])
);
GO

CREATE TABLE [dbo].[SemanaPlanilla] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idMesPlanilla] INT NOT NULL
    , [FechaInicio] DATE NOT NULL
    , [FechaFin] DATE NOT NULL
    , [NumeroSemana] INT NOT NULL
    , [FlagAbierta] BIT NOT NULL
    , CONSTRAINT [AK_SemanaPlanilla_Fechas] UNIQUE ([FechaInicio], [FechaFin])
    , CONSTRAINT [FK_SemanaPlanilla_MesPlanilla]
        FOREIGN KEY ([idMesPlanilla]) REFERENCES [dbo].[MesPlanilla] ([id])
);
GO

CREATE TABLE [dbo].[PlanillaMesXEmpleado] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idMesPlanilla] INT NOT NULL
    , [idEmpleado] INT NOT NULL
    , [SalarioBrutoMensual] MONEY NOT NULL
    , [DeduccionesMensuales] MONEY NOT NULL
    , [SalarioNetoMensual] MONEY NOT NULL
    , CONSTRAINT [AK_PlanMesXEmp] UNIQUE ([idMesPlanilla], [idEmpleado])
    , CONSTRAINT [FK_PlanMesXEmp_Mes]
        FOREIGN KEY ([idMesPlanilla])
        REFERENCES [dbo].[MesPlanilla] ([id])
    , CONSTRAINT [FK_PlanMesXEmp_Empleado]
        FOREIGN KEY ([idEmpleado])
        REFERENCES [dbo].[Empleado] ([id])
);
GO

CREATE TABLE [dbo].[PlanillaSemXEmpleado] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idSemanaPlanilla] INT NOT NULL
    , [idEmpleado] INT NOT NULL
    , [idPlanillaMesXEmpleado] INT NOT NULL
    , [SalarioBruto] MONEY NOT NULL
    , [TotalDeducciones] MONEY NOT NULL
    , [SalarioNeto] MONEY NOT NULL
    , [HorasOrdinarias] INT NOT NULL
    , [HorasExtrasNormales] INT NOT NULL
    , [HorasExtrasDobles] INT NOT NULL
    , [FlagCerrada] BIT NOT NULL
    , CONSTRAINT [AK_PlanSemXEmp] UNIQUE ([idSemanaPlanilla], [idEmpleado])
    , CONSTRAINT [FK_PlanSemXEmp_Semana]
        FOREIGN KEY ([idSemanaPlanilla]) REFERENCES [dbo].[SemanaPlanilla] ([id])
    , CONSTRAINT [FK_PlanSemXEmp_Empleado]
        FOREIGN KEY ([idEmpleado]) REFERENCES [dbo].[Empleado] ([id])
    , CONSTRAINT [FK_PlanSemXEmp_Mes]
        FOREIGN KEY ([idPlanillaMesXEmpleado]) REFERENCES [dbo].[PlanillaMesXEmpleado] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionXEmpleado] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idEmpleado] INT NOT NULL
    , [idTipoDeduccion] INT NOT NULL
    , [FechaInicio] DATE NOT NULL
    , CONSTRAINT [AK_DedXEmp_EmpTipo] UNIQUE ([idEmpleado], [idTipoDeduccion])
    , CONSTRAINT [FK_DedXEmp_Empleado]
        FOREIGN KEY ([idEmpleado]) REFERENCES [dbo].[Empleado] ([id])
    , CONSTRAINT [FK_DedXEmp_TipoDeduccion]
        FOREIGN KEY ([idTipoDeduccion]) REFERENCES [dbo].[TipoDeduccion] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionXEmpleadoFija] (
    [id] INT NOT NULL PRIMARY KEY
    , [Monto] MONEY NOT NULL
    , CONSTRAINT [FK_DedXEmpFija_Super]
        FOREIGN KEY ([id]) REFERENCES [dbo].[DeduccionXEmpleado] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionXEmpleadoPorcentual] (
    [id] INT NOT NULL PRIMARY KEY
    , [Porcentaje] DECIMAL(18, 4) NOT NULL
    , CONSTRAINT [FK_DedXEmpPorc_Super]
        FOREIGN KEY ([id]) REFERENCES [dbo].[DeduccionXEmpleado] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionXEmpleadoInactiva] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idEmpleado] INT NOT NULL
    , [idTipoDeduccion] INT NOT NULL
    , [FechaInicio] DATE NOT NULL
    , [FechaFin] DATE NOT NULL
    , CONSTRAINT [FK_DedXEmpInact_Empleado]
        FOREIGN KEY ([idEmpleado]) REFERENCES [dbo].[Empleado] ([id])
    , CONSTRAINT [FK_DedXEmpInact_TipoDeduccion]
        FOREIGN KEY ([idTipoDeduccion]) REFERENCES [dbo].[TipoDeduccion] ([id])
);
GO

CREATE TABLE [dbo].[DeduccionXEmpleadoXMes] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idPlanillaMesXEmpleado] INT NOT NULL
    , [idTipoDeduccion] INT NOT NULL
    , [MontoAcumulado] MONEY NOT NULL
    , [PorcentajeAplicado] DECIMAL(9, 4) NOT NULL
    , CONSTRAINT [AK_DedXEmpXMes] UNIQUE ([idPlanillaMesXEmpleado], [idTipoDeduccion])
    , CONSTRAINT [FK_DedXEmpXMes_PlanMes]
        FOREIGN KEY ([idPlanillaMesXEmpleado])
        REFERENCES [dbo].[PlanillaMesXEmpleado] ([id])
    , CONSTRAINT [FK_DedXEmpXMes_TipoDeduccion]
        FOREIGN KEY ([idTipoDeduccion])
        REFERENCES [dbo].[TipoDeduccion] ([id])
);
GO

CREATE TABLE [dbo].[JornadaXEmpleadoXSemana] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idSemanaPlanilla] INT NOT NULL
    , [idEmpleado] INT NOT NULL
    , [idTipoJornada] INT NOT NULL
    , CONSTRAINT [AK_JornadaXEmpXSem] UNIQUE ([idSemanaPlanilla], [idEmpleado])
    , CONSTRAINT [FK_JorXEmpXSem_Semana]
        FOREIGN KEY ([idSemanaPlanilla])
        REFERENCES [dbo].[SemanaPlanilla] ([id])
    , CONSTRAINT [FK_JorXEmpXSem_Empleado]
        FOREIGN KEY ([idEmpleado])
        REFERENCES [dbo].[Empleado] ([id])
    , CONSTRAINT [FK_JorXEmpXSem_TipoJornada]
        FOREIGN KEY ([idTipoJornada])
        REFERENCES [dbo].[TipoJornada] ([id])
);
GO

CREATE TABLE [dbo].[MarcaAsistencia] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idPlanillaSemXEmpleado] INT NOT NULL
    , [idEmpleado] INT NOT NULL
    , [idTipoJornada] INT NOT NULL
    , [Fecha] DATE NOT NULL
    , [HoraEntrada] DATETIME NOT NULL
    , [HoraSalida] DATETIME NOT NULL
    , [HorasOrdinarias] INT NOT NULL
    , [HorasExtrasNormales] INT NOT NULL
    , [HorasExtrasDobles] INT NOT NULL
    , [MontoOrdinario] MONEY NOT NULL
    , [MontoExtraNormal] MONEY NOT NULL
    , [MontoExtraDoble] MONEY NOT NULL
    , CONSTRAINT [FK_Marca_PlanSemXEmp]
        FOREIGN KEY ([idPlanillaSemXEmpleado])
        REFERENCES [dbo].[PlanillaSemXEmpleado] ([id])
    , CONSTRAINT [FK_Marca_Empleado]
        FOREIGN KEY ([idEmpleado])
        REFERENCES [dbo].[Empleado] ([id])
    , CONSTRAINT [FK_Marca_TipoJornada]
        FOREIGN KEY ([idTipoJornada])
        REFERENCES [dbo].[TipoJornada] ([id])
);
GO

CREATE TABLE [dbo].[MovimientoPlanilla] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idPlanillaSemXEmpleado] INT NOT NULL
    , [idTipoMovimiento] INT NOT NULL
    , [Fecha] DATE NOT NULL
    , [Monto] MONEY NOT NULL
    , [NuevoSaldo] MONEY NOT NULL
    , CONSTRAINT [FK_Mov_PlanSemXEmp]
        FOREIGN KEY ([idPlanillaSemXEmpleado])
        REFERENCES [dbo].[PlanillaSemXEmpleado] ([id])
    , CONSTRAINT [FK_Mov_TipoMovimiento]
        FOREIGN KEY ([idTipoMovimiento])
        REFERENCES [dbo].[TipoMovimiento] ([id])
);
GO

CREATE TABLE [dbo].[MovimientoHoras] (
    [id] INT NOT NULL PRIMARY KEY
    , [idMarcaAsistencia] INT NOT NULL
    , [CantidadHoras] INT NOT NULL
    , CONSTRAINT [FK_MovHoras_Movimiento]
        FOREIGN KEY ([id])
        REFERENCES [dbo].[MovimientoPlanilla] ([id])
    , CONSTRAINT [FK_MovHoras_Marca]
        FOREIGN KEY ([idMarcaAsistencia])
        REFERENCES [dbo].[MarcaAsistencia] ([id])
);
GO

CREATE TABLE [dbo].[MovimientoDeduccion] (
    [id] INT NOT NULL PRIMARY KEY
    , [PorcentajeAplicado] DECIMAL(9, 4) NOT NULL
    , CONSTRAINT [FK_MovDed_Movimiento]
        FOREIGN KEY ([id]) REFERENCES [dbo].[MovimientoPlanilla] ([id])
);
GO

CREATE TABLE [dbo].[BitacoraEvento] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [idTipoEvento] INT NOT NULL
    , [EventDate] DATE NOT NULL
    , [Descripcion] VARCHAR(MAX) NOT NULL
    , [PostInIP] VARCHAR(128) NOT NULL
    , [PostTime] DATETIME NOT NULL
    , CONSTRAINT [FK_BitacoraEvento_TipoEvento]
        FOREIGN KEY ([idTipoEvento])
        REFERENCES [dbo].[TipoEvento] ([id])
);
GO

CREATE TABLE [dbo].[BitacoraEventoUsuario] (
    [id] INT NOT NULL PRIMARY KEY
    , [PostByUserId] INT NOT NULL
    , CONSTRAINT [FK_BitacoraEventoUsuario_BitacoraEvento]
        FOREIGN KEY ([id])
        REFERENCES [dbo].[BitacoraEvento] ([id])
    , CONSTRAINT [FK_BitacoraEventoUsuario_Usuario]
        FOREIGN KEY ([PostByUserId])
        REFERENCES [dbo].[Usuario] ([id])
);
GO

CREATE TABLE [dbo].[DBError] (
    [id] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
    , [UserName] VARCHAR(128) NOT NULL
    , [ErrorNumber] INT NOT NULL
    , [ErrorState] INT NOT NULL
    , [ErrorSeverity] INT NOT NULL
    , [ErrorLine] INT NOT NULL
    , [ErrorProcedure] VARCHAR(MAX) NOT NULL
    , [ErrorMessage] VARCHAR(MAX) NOT NULL
    , [ErrorDateTime] DATETIME NOT NULL
);
GO
