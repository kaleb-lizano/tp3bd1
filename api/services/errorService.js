"use strict";

const { getPool, sql } = require("../db");

async function mensajeError(codigo) {
	if (!codigo || codigo === 0) {
		return "";
	}
	try {
		const pool = await getPool();
		const result = await pool
			.request()
			.input("inCodigo", sql.Int, Number(codigo))
			.output("outResultCode", sql.Int)
			.execute("ObtenerError");

		const fila = result.recordset && result.recordset[0];
		if (fila && fila.Descripcion) {
			return fila.Descripcion;
		}
	} catch (err) {
		console.warn(
			"[errorService] No se pudo obtener la descripción del código " +
				codigo +
				":",
			err.message,
		);
	}
	return `Error (código ${codigo})`;
}

module.exports = { mensajeError };
