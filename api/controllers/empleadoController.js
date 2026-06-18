"use strict";

const { getPool, sql } = require("../db");
const { getIp } = require("./authController");
const { mensajeError } = require("../services/errorService");

async function listar(req, res) {
	try {
		const { idUsuario, filtro } = req.query;
		const pool = await getPool();

		let result;
		if (filtro && filtro.trim() !== "") {
			result = await pool
				.request()
				.input("inFiltro", sql.VarChar(128), filtro)
				.input("inPostInIP", sql.VarChar(128), getIp(req))
				.input("inPostByUserId", sql.Int, Number(idUsuario))
				.output("outResultCode", sql.Int)
				.execute("ListarEmpleadosFiltro");
		} else {
			result = await pool
				.request()
				.input("inPostInIP", sql.VarChar(128), getIp(req))
				.input("inPostByUserId", sql.Int, Number(idUsuario))
				.output("outResultCode", sql.Int)
				.execute("ListarEmpleados");
		}

		return res.status(200).json(result.recordset || []);
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

async function editar(req, res) {
	try {
		const { valorDocumento } = req.params;
		const {
			nuevoNombre,
			nuevoValorDocumento,
			nuevoNombrePuesto,
			idUsuario,
		} = req.body;
		const pool = await getPool();

		const result = await pool
			.request()
			.input("inValorDocumentoIdentidad", sql.VarChar(32), valorDocumento)
			.input("inNuevoNombre", sql.VarChar(128), nuevoNombre)
			.input(
				"inNuevoValorDocumentoIdentidad",
				sql.VarChar(32),
				nuevoValorDocumento,
			)
			.input("inNuevoNombrePuesto", sql.VarChar(128), nuevoNombrePuesto)
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.input("inPostByUserId", sql.Int, Number(idUsuario))
			.output("outResultCode", sql.Int)
			.execute("EditarEmpleado");

		const codigo = result.output.outResultCode;
		if (codigo !== 0) {
			return res
				.status(400)
				.json({ errorCode: codigo, message: await mensajeError(codigo) });
		}
		return res
			.status(200)
			.json({ ok: true, message: "Empleado editado correctamente" });
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

async function listarPuestos(req, res) {
	try {
		const pool = await getPool();
		const result = await pool
			.request()
			.output("outResultCode", sql.Int)
			.execute("ListarPuestos");

		return res.status(200).json(result.recordset || []);
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

module.exports = { listar, editar, listarPuestos };
