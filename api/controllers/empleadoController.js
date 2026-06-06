const sql = require("mssql");
const config = require("../config");
const { registrarEvento } = require("../services/eventoService");
const { obtenerMensajeError } = require("../services/errorService");

async function insertarEmpleado(req, res, next) {
  try {
    const { valorDocumentoIdentidad, nombre, nombrePuesto, fechaContratacion, saldoVacaciones, esActivo, username } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    const conexion = await sql.connect(config.sql);

    if (!/^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/.test(nombre)) {
      const errorMsg = await obtenerMensajeError(50009);
      const descripcionFallo = `${errorMsg}, ${valorDocumentoIdentidad}, ${nombre}, ${nombrePuesto}`;
      await registrarEvento(5, descripcionFallo, username, ip);
      return res.status(400).json({ errorCode: 50009, message: errorMsg });
    }

    if (!/^\d+$/.test(valorDocumentoIdentidad)) {
      const errorMsg = await obtenerMensajeError(50010);
      const descripcionFallo = `${errorMsg}, ${valorDocumentoIdentidad}, ${nombre}, ${nombrePuesto}`;
      await registrarEvento(5, descripcionFallo, username, ip);
      return res.status(400).json({ errorCode: 50010, message: errorMsg });
    }

    const resultado = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumentoIdentidad)
      .input("inNombre", sql.VarChar(128), nombre)
      .input("inNombrePuesto", sql.VarChar(128), nombrePuesto)
      .input("inFechaContratacion", sql.Date, fechaContratacion)
      .input("inSaldoVacaciones", sql.Float, saldoVacaciones)
      .input("inEsActivo", sql.Bit, esActivo)
      .output("outResultCode", sql.Int)
      .execute("usp_InsertarEmpleado");

    const resultCode = resultado.output.outResultCode;

    if (resultCode !== 0) {
      const errorMsg = await obtenerMensajeError(resultCode);
      const descripcionFallo = `${errorMsg}, ${valorDocumentoIdentidad}, ${nombre}, ${nombrePuesto}`;
      await registrarEvento(5, descripcionFallo, username, ip);
      return res.status(400).json({ errorCode: resultCode, message: errorMsg });
    }

    const descripcionExito = `${valorDocumentoIdentidad}, ${nombre}, ${nombrePuesto}`;
    await registrarEvento(6, descripcionExito, username, ip);

    res.status(201).json({ message: "Empleado agregado exitosamente" });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function obtenerEmpleados(req, res, next) {
  try {
    const { filtroNombre, filtroDocumento, username } = req.query;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    const conexion = await sql.connect(config.sql);

    let resultado;

    if (filtroNombre) {
      await registrarEvento(11, filtroNombre, username, ip);

      resultado = await conexion
        .request()
        .input("inFiltroNombre", sql.VarChar(128), filtroNombre)
        .output("outResultCode", sql.Int)
        .execute("usp_FiltrarEmpleadosPorNombre");

    } else if (filtroDocumento) {
      await registrarEvento(12, filtroDocumento, username, ip);

      resultado = await conexion
        .request()
        .input("inFiltroDocumento", sql.VarChar(16), filtroDocumento)
        .output("outResultCode", sql.Int)
        .execute("usp_FiltrarEmpleadosPorDocumento");

    } else {
      resultado = await conexion
        .request()
        .output("outResultCode", sql.Int)
        .execute("usp_ObtenerEmpleados");
    }

    res.status(200).json(resultado.recordset || []);
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function consultarEmpleado(req, res, next) {
  try {
    const { valorDocumento } = req.params;
    const conexion = await sql.connect(config.sql);

    const resultado = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerEmpleadoPorDocumento");

    const empleado = resultado.recordset[0];

    if (!empleado) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }

    res.status(200).json(empleado);
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function actualizarEmpleado(req, res, next) {
  try {
    const { valorDocumento } = req.params;
    const { valorDocumentoNuevo, nombreNuevo, nombrePuestoNuevo, username } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    const conexion = await sql.connect(config.sql);

    const empleadoResult = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerEmpleadoPorDocumento");

    const empleadoAntes = empleadoResult.recordset[0];

    if (!empleadoAntes) {
      return res.status(404).json({ message: "Empleado no encontrado" });
    }

    const descripcionAntes = `Antes: ${empleadoAntes.ValorDocumentoIdentidad}, ${empleadoAntes.Nombre}, ${empleadoAntes.NombrePuesto}`;
    const descripcionDespues = `Después: ${valorDocumentoNuevo}, ${nombreNuevo}, ${nombrePuestoNuevo}. Saldo: ${empleadoAntes.SaldoVacaciones}`;

    if (!/^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/.test(nombreNuevo)) {
      const errorMsg = await obtenerMensajeError(50009);
      await registrarEvento(7, `${errorMsg}, ${descripcionAntes}, ${descripcionDespues}`, username, ip);
      return res.status(400).json({ errorCode: 50009, message: errorMsg });
    }

    if (!/^\d+$/.test(valorDocumentoNuevo)) {
      const errorMsg = await obtenerMensajeError(50010);
      await registrarEvento(7, `${errorMsg}, ${descripcionAntes}, ${descripcionDespues}`, username, ip);
      return res.status(400).json({ errorCode: 50010, message: errorMsg });
    }

    const resultado = await conexion
      .request()
      .input("inValorDocumentoActual", sql.VarChar(16), valorDocumento)
      .input("inValorDocumentoNuevo", sql.VarChar(16), valorDocumentoNuevo)
      .input("inNombreNuevo", sql.VarChar(128), nombreNuevo)
      .input("inNombrePuesto", sql.VarChar(128), nombrePuestoNuevo)
      .output("outResultCode", sql.Int)
      .execute("usp_ActualizarEmpleado");

    const resultCode = resultado.output.outResultCode;

    if (resultCode !== 0) {
      const errorMsg = await obtenerMensajeError(resultCode);
      await registrarEvento(7, `${errorMsg}, ${descripcionAntes}, ${descripcionDespues}`, username, ip);
      return res.status(400).json({ errorCode: resultCode, message: errorMsg });
    }

    await registrarEvento(8, `${descripcionAntes}, ${descripcionDespues}`, username, ip);

    res.status(200).json({ message: "Empleado actualizado exitosamente" });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function eliminarEmpleado(req, res, next) {
  try {
    const { valorDocumento } = req.params;
    const { confirmado, username } = req.body;
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

    const descripcionInfo = `${empleado.ValorDocumentoIdentidad}, ${empleado.Nombre}, ${empleado.NombrePuesto}, ${empleado.SaldoVacaciones}`;

    if (!confirmado) {
      await registrarEvento(9, descripcionInfo, username, ip);
      return res.status(200).json({ message: "Intento de borrado registrado" });
    }

    const resultado = await conexion
      .request()
      .input("inValorDocumentoIdentidad", sql.VarChar(16), valorDocumento)
      .output("outResultCode", sql.Int)
      .execute("usp_EliminarEmpleado");

    const resultCode = resultado.output.outResultCode;

    if (resultCode !== 0) {
      const errorMsg = await obtenerMensajeError(resultCode);
      return res.status(500).json({ errorCode: resultCode, message: errorMsg });
    }

    await registrarEvento(10, descripcionInfo, username, ip);

    res.status(200).json({ message: "Empleado eliminado exitosamente" });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

module.exports = {
  insertarEmpleado,
  obtenerEmpleados,
  consultarEmpleado,
  actualizarEmpleado,
  eliminarEmpleado
};

