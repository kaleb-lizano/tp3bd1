
function _esperar() {
  return Promise.resolve();
}

/* =====================================================
   Datos de prueba
   ===================================================== */
const _puestos = [
  { Nombre: "Desarrollador Senior" },
  { Nombre: "Desarrollador Junior" },
  { Nombre: "Analista de Datos" },
  { Nombre: "Gerente de Proyecto" },
  { Nombre: "Diseñador UX" },
  { Nombre: "Contador" },
];

const _empleados = [
  { IdEmpleado: 1, ValorDocumentoIdentidad: "101110111", Nombre: "Alvarado Mora, Carlos",     NombrePuesto: "Desarrollador Senior", EsActivo: true },
  { IdEmpleado: 2, ValorDocumentoIdentidad: "202220222", Nombre: "Brenes Solís, María",       NombrePuesto: "Analista de Datos",    EsActivo: true },
  { IdEmpleado: 3, ValorDocumentoIdentidad: "303330333", Nombre: "Chaves Rojas, Luis",        NombrePuesto: "Diseñador UX",         EsActivo: true },
  { IdEmpleado: 4, ValorDocumentoIdentidad: "404440444", Nombre: "Delgado Ureña, Ana",        NombrePuesto: "Gerente de Proyecto",  EsActivo: false },
  { IdEmpleado: 5, ValorDocumentoIdentidad: "505550555", Nombre: "Esquivel Vargas, Roberto",  NombrePuesto: "Desarrollador Junior", EsActivo: true },
  { IdEmpleado: 6, ValorDocumentoIdentidad: "606660666", Nombre: "Fernández Lara, Sofía",    NombrePuesto: "Contador",             EsActivo: true },
];

const _planillasSemana = {
  /* Clave: idEmpleado */
  1: [
    { IdPlanillaSemanal: 101, FechaInicio: "2025-05-19", FechaFin: "2025-05-25", SalarioBruto: 310000, TotalDeducciones: 62000, SalarioNeto: 248000, HorasOrdinarias: 40, HorasExtrasNormales: 4, HorasExtrasDobles: 0 },
    { IdPlanillaSemanal: 102, FechaInicio: "2025-05-12", FechaFin: "2025-05-18", SalarioBruto: 300000, TotalDeducciones: 60000, SalarioNeto: 240000, HorasOrdinarias: 40, HorasExtrasNormales: 0, HorasExtrasDobles: 0 },
    { IdPlanillaSemanal: 103, FechaInicio: "2025-05-05", FechaFin: "2025-05-11", SalarioBruto: 325000, TotalDeducciones: 65000, SalarioNeto: 260000, HorasOrdinarias: 40, HorasExtrasNormales: 6, HorasExtrasDobles: 2 },
  ],
};

const _diasSemana = {
  /* Clave: idPlanillaSemanal */
  101: [
    { Fecha: "2025-05-19", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 0, MontoExtraNormal: 0,     HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-20", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 2, MontoExtraNormal: 16800,  HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-21", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 0, MontoExtraNormal: 0,     HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-22", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 2, MontoExtraNormal: 16800,  HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-23", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 0, MontoExtraNormal: 0,     HorasExtrasDobles: 0, MontoExtraDoble: 0 },
  ],
  102: [
    { Fecha: "2025-05-12", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 60000, HorasExtrasNormales: 0, MontoExtraNormal: 0, HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-13", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 60000, HorasExtrasNormales: 0, MontoExtraNormal: 0, HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-14", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 60000, HorasExtrasNormales: 0, MontoExtraNormal: 0, HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-15", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 60000, HorasExtrasNormales: 0, MontoExtraNormal: 0, HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-16", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 60000, HorasExtrasNormales: 0, MontoExtraNormal: 0, HorasExtrasDobles: 0, MontoExtraDoble: 0 },
  ],
  103: [
    { Fecha: "2025-05-05", HoraEntrada: "08:00:00", HoraSalida: "17:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 0, MontoExtraNormal: 0,     HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-06", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 2, MontoExtraNormal: 16800,  HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-07", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 2, MontoExtraNormal: 16800,  HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-08", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 2, MontoExtraNormal: 16800,  HorasExtrasDobles: 0, MontoExtraDoble: 0 },
    { Fecha: "2025-05-11", HoraEntrada: "08:00:00", HoraSalida: "19:00:00", HorasOrdinarias: 8, MontoOrdinario: 56000, HorasExtrasNormales: 0, MontoExtraNormal: 0,      HorasExtrasDobles: 2, MontoExtraDoble: 22400 },
  ],
};

const _deduccionesSemana = {
  /* Clave: idPlanillaSemanal */
  101: [
    { NombreDeduccion: "CCSS Patronal",  Porcentaje: 14.16, MontoDeduccion: 43896 },
    { NombreDeduccion: "CCSS Obrero",    Porcentaje:  9.17, MontoDeduccion: 28427 },
    { NombreDeduccion: "INS",            Porcentaje:  1.00, MontoDeduccion:  3100 },
    { NombreDeduccion: "Banco Popular",  Porcentaje: null,  MontoDeduccion:  5000 },
  ],
  102: [
    { NombreDeduccion: "CCSS Patronal",  Porcentaje: 14.16, MontoDeduccion: 42480 },
    { NombreDeduccion: "CCSS Obrero",    Porcentaje:  9.17, MontoDeduccion: 27510 },
    { NombreDeduccion: "INS",            Porcentaje:  1.00, MontoDeduccion:  3000 },
  ],
  103: [
    { NombreDeduccion: "CCSS Patronal",  Porcentaje: 14.16, MontoDeduccion: 46020 },
    { NombreDeduccion: "CCSS Obrero",    Porcentaje:  9.17, MontoDeduccion: 29802 },
    { NombreDeduccion: "INS",            Porcentaje:  1.00, MontoDeduccion:  3250 },
  ],
};

const _planillasMes = {
  /* Clave: idEmpleado */
  1: [
    { IdPlanillaMensual: 201, Anio: 2025, Mes: 5, SalarioBruto: 935000, TotalDeducciones: 187000, SalarioNeto: 748000 },
    { IdPlanillaMensual: 202, Anio: 2025, Mes: 4, SalarioBruto: 900000, TotalDeducciones: 180000, SalarioNeto: 720000 },
    { IdPlanillaMensual: 203, Anio: 2025, Mes: 3, SalarioBruto: 880000, TotalDeducciones: 176000, SalarioNeto: 704000 },
  ],
};

const _semanasMes = {
  /* Clave: idPlanillaMensual */
  201: [
    { FechaInicio: "2025-05-05", FechaFin: "2025-05-11", SalarioBruto: 325000, TotalDeducciones: 65000, SalarioNeto: 260000 },
    { FechaInicio: "2025-05-12", FechaFin: "2025-05-18", SalarioBruto: 300000, TotalDeducciones: 60000, SalarioNeto: 240000 },
    { FechaInicio: "2025-05-19", FechaFin: "2025-05-25", SalarioBruto: 310000, TotalDeducciones: 62000, SalarioNeto: 248000 },
  ],
};

const _deduccionesMes = {
  /* Clave: idPlanillaMensual */
  201: [
    { NombreDeduccion: "CCSS Patronal",  Porcentaje: 14.16, MontoDeduccion: 132396 },
    { NombreDeduccion: "CCSS Obrero",    Porcentaje:  9.17, MontoDeduccion:  85745 },
    { NombreDeduccion: "INS",            Porcentaje:  1.00, MontoDeduccion:   9350 },
    { NombreDeduccion: "Banco Popular",  Porcentaje: null,  MontoDeduccion:  15000 },
  ],
};

const _usuarios = [
  { Username: "admin",    Password: "admin123",  esAdmin: true,  idEmpleado: null, nombre: "Administrador" },
  { Username: "carlos",   Password: "carlos123", esAdmin: false, idEmpleado: 1,    nombre: "Alvarado Mora, Carlos" },
  { Username: "maria",    Password: "maria123",  esAdmin: false, idEmpleado: 2,    nombre: "Brenes Solís, María" },
];

/* =====================================================
   Funciones dummy
   ===================================================== */

/* Autenticación
   ===================================================== */
async function dummyLogin(username, password) {
  await _esperar();
  const usuario = _usuarios.find(u => u.Username === username && u.Password === password);
  if (!usuario) return { ok: false, datos: { message: "Usuario o contraseña incorrectos." } };
  return {
    ok: true,
    datos: {
      username: usuario.Username,
      esAdmin:  usuario.esAdmin,
      idEmpleado: usuario.idEmpleado,
      nombre: usuario.nombre,
    },
  };
}

/* Catálogos
   ===================================================== */
async function dummyObtenerPuestos() {
  await _esperar();
  return _puestos;
}

/* Empleados
   ===================================================== */
async function dummyObtenerEmpleados(filtroNombre = "") {
  await _esperar();
  let lista = [..._empleados];
  if (filtroNombre) {
    const patron = filtroNombre.toLowerCase();
    lista = lista.filter(e => e.Nombre.toLowerCase().includes(patron));
  }
  return lista.sort((a, b) => a.Nombre.localeCompare(b.Nombre, "es"));
}

async function dummyConsultarEmpleado(id) {
  await _esperar();
  const emp = _empleados.find(e => e.IdEmpleado == id || e.ValorDocumentoIdentidad == id);
  return emp || null;
}

async function dummyInsertarEmpleado(datos) {
  await _esperar();
  const nuevo = {
    IdEmpleado: _empleados.length + 1,
    ValorDocumentoIdentidad: datos.valorDocumentoIdentidad,
    Nombre: datos.nombre,
    NombrePuesto: datos.nombrePuesto,
    EsActivo: true,
  };
  _empleados.push(nuevo);
  return { ok: true, datos: nuevo };
}

async function dummyActualizarEmpleado(idOriginal, datos) {
  await _esperar();
  const idx = _empleados.findIndex(e => e.ValorDocumentoIdentidad == idOriginal);
  if (idx === -1) return { ok: false, datos: { message: "Empleado no encontrado." } };
  _empleados[idx] = {
    ..._empleados[idx],
    ValorDocumentoIdentidad: datos.valorDocumentoNuevo,
    Nombre:      datos.nombreNuevo,
    NombrePuesto: datos.nombrePuestoNuevo,
  };
  return { ok: true, datos: _empleados[idx] };
}

/* Planilla semanal
   ===================================================== */
async function dummyObtenerPlanillasSemanal(idEmpleado) {
  await _esperar();
  return _planillasSemana[idEmpleado] || [];
}

async function dummyObtenerDiasSemana(idPlanilla) {
  await _esperar();
  return _diasSemana[idPlanilla] || [];
}

async function dummyObtenerDeduccionesSemana(idPlanilla) {
  await _esperar();
  return _deduccionesSemana[idPlanilla] || [];
}

/* Planilla mensual
   ===================================================== */
async function dummyObtenerPlanillasMensual(idEmpleado) {
  await _esperar();
  return _planillasMes[idEmpleado] || [];
}

async function dummyObtenerSemanasMes(idPlanilla) {
  await _esperar();
  return _semanasMes[idPlanilla] || [];
}

async function dummyObtenerDeduccionesMes(idPlanilla) {
  await _esperar();
  return _deduccionesMes[idPlanilla] || [];
}
