"use strict";

const { getPool, sql } = require("../db");
const { getIp } = require("./authController");

async function semanal(req, res) {
	try {
		const { idEmpleado } = req.params;
		const { cantidad, idUsuario } = req.query;
		const pool = await getPool();

		const result = await pool
			.request()
			.input("inIdEmpleado", sql.Int, Number(idEmpleado))
			.input("inCantidadSemanas", sql.Int, Number(cantidad) || 4)
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.input("inPostByUserId", sql.Int, Number(idUsuario))
			.output("outResultCode", sql.Int)
			.execute("ConsultarPlanillaSemanal");

		return res.status(200).json({
			semanas: result.recordsets[0] || [],
			deducciones: result.recordsets[1] || [],
			dias: result.recordsets[2] || [],
		});
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

async function mensual(req, res) {
	try {
		const { idEmpleado } = req.params;
		const { cantidad, idUsuario } = req.query;
		const pool = await getPool();

		const result = await pool
			.request()
			.input("inIdEmpleado", sql.Int, Number(idEmpleado))
			.input("inCantidadMeses", sql.Int, Number(cantidad) || 6)
			.input("inPostInIP", sql.VarChar(128), getIp(req))
			.input("inPostByUserId", sql.Int, Number(idUsuario))
			.output("outResultCode", sql.Int)
			.execute("ConsultarPlanillaMensual");

		return res.status(200).json({
			meses: result.recordsets[0] || [],
			deducciones: result.recordsets[1] || [],
			semanas: result.recordsets[2] || [],
		});
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
}

module.exports = { semanal, mensual };
