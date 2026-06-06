const sql = require("mssql");
const config = require("../config");

async function obtenerMensajeError(codigoError) {
  try {
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion
      .request()
      .input("inCodigo", sql.VarChar(8), codigoError.toString())
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerDescripcionError");

    if (resultado.recordset && resultado.recordset.length > 0) {
      return resultado.recordset[0].Descripcion;
    }
    return `Error interno. Código: ${codigoError}`;
  } catch (error) {
    console.error("Error al obtener descripción de error:", error);
    return `Error al consultar catálogo de errores. Código: ${codigoError}`;
  }
}

module.exports = {
  obtenerMensajeError
};
