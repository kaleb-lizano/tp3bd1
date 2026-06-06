const sql = require("mssql");
const config = require("../config");

async function obtenerPuestos(req, res, next) {
  try {
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion
      .request()
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerPuestos");

    res.status(200).json(resultado.recordset || []);
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function obtenerTiposMovimiento(req, res, next) {
  try {
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion
      .request()
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerTiposMovimiento");

    res.status(200).json(resultado.recordset || []);
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function obtenerError(req, res, next) {
  try {
    const { codigo } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion
      .request()
      .input("inCodigo", sql.VarChar(8), codigo)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerDescripcionError");

    res.status(200).json(resultado.recordset[0] || null);
  } catch (err) {
    res.status(500).send(err.message);
  }
}

module.exports = {
  obtenerPuestos,
  obtenerTiposMovimiento,
  obtenerError
};
