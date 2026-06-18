"use strict";

const { getPool, sql } = require("../db");
const { mensajeError } = require("../services/errorService");

function getIp(req) {
	return req.headers["x-forwarded-for"] || req.ip || "127.0.0.1";
}

async function login(req, res) {
	try {
		const { username, password } = req.body;
		const pool = await getPool();

		const result = await pool
			.request()
			.input("inUsername", sql.VarChar(128), username)
			.input("inPassword", sql.VarChar(128), password)
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.output("outResultCode", sql.Int)
			.execute("Login");

		if (result.output.outResultCode !== 0) {
			const codigo = result.output.outResultCode;
			return res
				.status(401)
				.json({ errorCode: codigo, message: await mensajeError(codigo) });
		}

		const fila = result.recordset[0];
		return res.status(200).json({
			id: fila.id,
			username: fila.Username,
			esAdmin: !!fila.EsAdmin,
			idEmpleado: fila.idEmpleado,
		});
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

async function logout(req, res) {
	try {
		const { idUsuario } = req.body;
		const pool = await getPool();

		await pool
			.request()
			.input("inIdUsuario", sql.Int, idUsuario)
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.output("outResultCode", sql.Int)
			.execute("Logout");

		return res.status(200).json({ ok: true });
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

module.exports = { login, logout, getIp };
