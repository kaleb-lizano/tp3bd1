"use strict";

const fs = require("fs");
const path = require("path");
const { getPool, sql } = require("../db");
const config = require("../config");

function leerXml(nombreArchivo) {
	const ruta = path.join(__dirname, "..", "..", "data", nombreArchivo);
	const crudo = fs.readFileSync(ruta, "utf-8");
	return crudo.replace(/<\?xml[^?]*\?>\s*/, "");
}

async function cargarCatalogosYSimular() {
	const pool = await getPool();

	console.log("Cargando catálogos desde data/datos.xml ...");
	const cat = await pool
		.request()
		.input("inXmlCatalogos", sql.Xml, leerXml("datos.xml"))
		.output("outResultCode", sql.Int)
		.execute("CargarCatalogosXML");

	if (cat.output.outResultCode !== 0) {
		throw new Error(
			"CargarCatalogosXML devolvió el código " + cat.output.outResultCode,
		);
	}

	console.log("Ejecutando la simulación desde data/Operaciones.xml ...");
	const sim = await pool
		.request()
		.input("inXmlOperaciones", sql.Xml, leerXml("Operaciones.xml"))
		.input("inPostInIP", sql.VarChar(128), config.sim.ip)
		.output("outResultCode", sql.Int)
		.execute("EjecutarSimulacion");

	if (sim.output.outResultCode !== 0) {
		throw new Error(
			"EjecutarSimulacion devolvió el código " + sim.output.outResultCode,
		);
	}

	console.log("Catálogos + simulación completados.");
}

module.exports = { cargarCatalogosYSimular };
