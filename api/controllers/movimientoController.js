const sql = require("mssql");
const config = require("../config");
const { registrarEvento } = require("../services/eventoService");
const { obtenerMensajeError } = require("../services/errorService");

async function obtenerMovimientos(req, res, next) {
  try {
    const { valorDocumento } = req.params;
    const conexion = await sql.connect(config.sql);

    const empleadoResult = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerEmpleadoPorDocumento");

    const empleado = empleadoResult.recordset[0];

    if (!empleado) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }

    const movimientosResult = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerMovimientosPorEmpleado");

    res.status(200).json({
      empleado: {
        valorDocumentoIdentidad: empleado.ValorDocumentoIdentidad,
        nombre: empleado.Nombre,
        saldoVacaciones: empleado.SaldoVacaciones
      },
      movimientos: movimientosResult.recordset || []
    });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function insertarMovimiento(req, res, next) {
  try {
    const { valorDocumento } = req.params;
    const { nombreTipoMovimiento, monto, username } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    const conexion = await sql.connect(config.sql);

    const empleadoResult = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerEmpleadoPorDocumento");

    const empleado = empleadoResult.recordset[0];

    if (!empleado) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }

    const tipoMovResult = await conexion
      .request()
      .input("inNombreTipoMovimiento", sql.VarChar(128), nombreTipoMovimiento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerTipoMovimientoPorNombre");

    const tipoMovimiento = tipoMovResult.recordset[0];

    if (!tipoMovimiento) {
      return res.status(400).json({ message: "Tipo de movimiento no encontrado" });
    }

    const saldoActual = empleado.SaldoVacaciones;
    let nuevoSaldo;

    if (tipoMovimiento.TipoAccion === "Credito") {
      nuevoSaldo = saldoActual + monto;
    } else {
      nuevoSaldo = saldoActual - monto;
    }

    if (nuevoSaldo < 0) {
      const errorMsg = await obtenerMensajeError(50011);
      const descripcionFallo = `${errorMsg}, ${empleado.ValorDocumentoIdentidad}, ${empleado.Nombre}, ${saldoActual}, ${nombreTipoMovimiento}, ${monto}`;
      await registrarEvento(13, descripcionFallo, username, ip);
      return res.status(400).json({ errorCode: 50011, message: errorMsg });
    }

    const fechaMov = new Date();

    const resultado = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .input("inNombreTipoMovimiento", sql.VarChar(128), nombreTipoMovimiento)
      .input("inFecha", sql.Date, fechaMov)
      .input("inMonto", sql.Float, monto)
      .input("inNuevoSaldo", sql.Float, nuevoSaldo)
      .input("inPostByUser", sql.VarChar(128), username)
      .input("inPostInIP", sql.VarChar(128), ip)
      .input("inPostTime", sql.DateTime, fechaMov)
      .output("outResultCode", sql.Int)
      .execute("usp_InsertarMovimiento");

    const resultCode = resultado.output.outResultCode;

    if (resultCode !== 0) {
      const errorMsg = await obtenerMensajeError(resultCode);
      const descripcionFallo = `${errorMsg}, ${empleado.ValorDocumentoIdentidad}, ${empleado.Nombre}, ${saldoActual}, ${nombreTipoMovimiento}, ${monto}`;
      await registrarEvento(13, descripcionFallo, username, ip);
      return res.status(400).json({ errorCode: resultCode, message: errorMsg });
    }

    const empleadoDespues = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerEmpleadoPorDocumento");

    const nuevoSaldoReal = empleadoDespues.recordset[0].SaldoVacaciones;
    const descripcionExito = `${empleado.ValorDocumentoIdentidad}, ${empleado.Nombre}, ${nuevoSaldoReal}, ${nombreTipoMovimiento}, ${monto}`;
    await registrarEvento(14, descripcionExito, username, ip);

    res.status(201).json({ message: "Movimiento insertado exitosamente" });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

module.exports = {
  obtenerMovimientos,
  insertarMovimiento
};

