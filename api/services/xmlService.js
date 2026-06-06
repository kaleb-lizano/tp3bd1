const fs = require("fs");
const path = require("path");
const xml2js = require("xml2js");
const sql = require("mssql");
const config = require("../config");
const { registrarEvento } = require("./eventoService");

async function cargarDatosXml() {
  const xmlPath = path.join(__dirname, "../../data/datosCarga.xml");
  const xmlRaw = fs.readFileSync(xmlPath, "utf-8");
  const xmlData = xmlRaw.replace(/<\?xml[^?]*\?>\s*/, "");
  const conexion = await sql.connect(config.sql);

  const movimientosExistentes = await conexion.request()
    .output("outResultCode", sql.Int)
    .execute("usp_ObtenerMovimientos");

  if (movimientosExistentes.recordset.length > 0) {
    console.log("Los datos del XML ya fueron cargados previamente. Omitiendo carga.");
    return;
  }

  console.log("Cargando catalogos y empleados desde XML...");
  const resultCarga = await conexion.request()
    .input("inXml", sql.Xml, xmlData)
    .output("outResultCode", sql.Int)
    .execute("usp_CargarDatosXml");

  if (resultCarga.output.outResultCode !== 0) {
    throw new Error("Error al cargar catalogos y empleados desde XML. Codigo: " + resultCarga.output.outResultCode);
  }

  const parser = new xml2js.Parser({ explicitArray: false });
  const result = await parser.parseStringPromise(xmlData);
  const datos = result.Datos;

  if (datos.Empleados && datos.Empleados.empleado) {
    const empleados = Array.isArray(datos.Empleados.empleado) ? datos.Empleados.empleado : [datos.Empleados.empleado];
    console.log("Registrando eventos de inserción de empleados...");
    for (const emp of empleados) {
      const descripcion = `${emp.$.ValorDocumentoIdentidad}, ${emp.$.Nombre}, ${emp.$.Puesto}`;
      await registrarEvento(6, descripcion, "UsuarioScripts", "0.0.0.0", emp.$.FechaContratacion);
    }
  }

  if (datos.Movimientos && datos.Movimientos.movimiento) {
    const movimientos = Array.isArray(datos.Movimientos.movimiento) ? datos.Movimientos.movimiento : [datos.Movimientos.movimiento];
    console.log("Cargando Movimientos...");
    for (const mov of movimientos) {
      const nombreTipoMovimiento = mov.$.IdTipoMovimiento;

      const empleadoResult = await conexion.request()
        .input("inValorDocumentoIdentidad", sql.VarChar(16), mov.$.ValorDocId)
        .output("outResultCode", sql.Int)
        .execute("usp_ObtenerEmpleadoPorDocumento");

      const empleado = empleadoResult.recordset[0];
      if (!empleado) continue;

      const tipoMovResult = await conexion.request()
        .input("inNombreTipoMovimiento", sql.VarChar(128), nombreTipoMovimiento)
        .output("outResultCode", sql.Int)
        .execute("usp_ObtenerTipoMovimientoPorNombre");

      const tipoMovimiento = tipoMovResult.recordset[0];
      if (!tipoMovimiento) continue;

      const saldoActual = empleado.SaldoVacaciones;
      let nuevoSaldo;

      if (tipoMovimiento.TipoAccion === "Credito") {
        nuevoSaldo = saldoActual + parseFloat(mov.$.Monto);
      } else {
        nuevoSaldo = saldoActual - parseFloat(mov.$.Monto);
      }

      await conexion.request()
        .input("inValorDocumentoIdentidad", sql.VarChar(16), mov.$.ValorDocId)
        .input("inNombreTipoMovimiento", sql.VarChar(128), nombreTipoMovimiento)
        .input("inFecha", sql.Date, new Date(mov.$.Fecha))
        .input("inMonto", sql.Float, parseFloat(mov.$.Monto))
        .input("inNuevoSaldo", sql.Float, nuevoSaldo)
        .input("inPostByUser", sql.VarChar(128), mov.$.PostByUser)
        .input("inPostInIP", sql.VarChar(128), mov.$.PostInIP)
        .input("inPostTime", sql.DateTime, new Date(mov.$.PostTime))
        .output("outResultCode", sql.Int)
        .execute("usp_InsertarMovimiento");

      const descripcionMov = `${mov.$.ValorDocId}, ${empleado.Nombre}, ${nuevoSaldo}, ${nombreTipoMovimiento}, ${mov.$.Monto}`;
      await registrarEvento(14, descripcionMov, mov.$.PostByUser, mov.$.PostInIP, mov.$.PostTime);
    }
  }

  console.log("Carga de XML completada exitosamente.");
}

module.exports = {
  cargarDatosXml
};
