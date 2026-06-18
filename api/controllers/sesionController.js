"use strict";

const { getPool, sql } = require("../db");
const { getIp } = require("./authController");

async function impersonar(req, res) {
	try {
		const { idUsuarioAdmin, idEmpleado } = req.body;
		const pool = await getPool();

		const result = await pool
			.request()
			.input("inIdUsuarioAdmin", sql.Int, Number(idUsuarioAdmin))
			.input("inIdEmpleado", sql.Int, Number(idEmpleado))
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.output("outResultCode", sql.Int)
			.execute("ImpersonarEmpleado");

		if (result.output.outResultCode !== 0) {
			return res.status(400).json({ errorCode: result.output.outResultCode });
		}
		return res
			.status(200)
			.json(
				result.recordset && result.recordset[0]
					? result.recordset[0]
					: { ok: true },
			);
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

async function regresar(req, res) {
	try {
		const { idUsuarioAdmin } = req.body;
		const pool = await getPool();

		await pool
			.request()
			.input("inIdUsuarioAdmin", sql.Int, Number(idUsuarioAdmin))
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.output("outResultCode", sql.Int)
			.execute("RegresarAdmin");

		return res.status(200).json({ ok: true });
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

module.exports = { impersonar, regresar };
