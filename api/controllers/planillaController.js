"use strict";
const sql = require("mssql");
const config = require("../config");

/* =====================================================
   PLANILLA SEMANAL
   ===================================================== */

async function obtenerPlanillasSemanal(req, res) {
  try {
    const { idEmpleado } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdEmpleado", sql.Int, idEmpleado)
      .execute("usp_obtener_planillas_semanales");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerPlanillasSemanal:", err);
    res.status(500).json({ message: "Error al obtener planillas semanales." });
  }
}

async function obtenerDiasPlanillaSemanal(req, res) {
  try {
    const { idPlanilla } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdPlanillaSemanal", sql.Int, idPlanilla)
      .execute("usp_obtener_dias_planilla_semanal");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerDiasPlanillaSemanal:", err);
    res.status(500).json({ message: "Error al obtener días de planilla." });
  }
}

async function obtenerDeduccionesSemana(req, res) {
  try {
    const { idPlanilla } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdPlanillaSemanal", sql.Int, idPlanilla)
      .execute("usp_obtener_deducciones_planilla_semanal");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerDeduccionesSemana:", err);
    res.status(500).json({ message: "Error al obtener deducciones semanales." });
  }
}

/* =====================================================
   PLANILLA MENSUAL
   ===================================================== */

async function obtenerPlanillasMensual(req, res) {
  try {
    const { idEmpleado } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdEmpleado", sql.Int, idEmpleado)
      .execute("usp_obtener_planillas_mensuales");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerPlanillasMensual:", err);
    res.status(500).json({ message: "Error al obtener planillas mensuales." });
  }
}

async function obtenerSemanasEnMes(req, res) {
  try {
    const { idPlanilla } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdPlanillaMensual", sql.Int, idPlanilla)
      .execute("usp_obtener_semanas_en_mes");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerSemanasEnMes:", err);
    res.status(500).json({ message: "Error al obtener semanas del mes." });
  }
}

async function obtenerDeduccionesMes(req, res) {
  try {
    const { idPlanilla } = req.params;
    const conexion = await sql.connect(config.sql);
    const resultado = await conexion.request()
      .input("inIdPlanillaMensual", sql.Int, idPlanilla)
      .execute("usp_obtener_deducciones_planilla_mensual");
    res.json(resultado.recordset);
  } catch (err) {
    console.error("Error obtenerDeduccionesMes:", err);
    res.status(500).json({ message: "Error al obtener deducciones mensuales." });
  }
}

module.exports = {
  obtenerPlanillasSemanal,
  obtenerDiasPlanillaSemanal,
  obtenerDeduccionesSemana,
  obtenerPlanillasMensual,
  obtenerSemanasEnMes,
  obtenerDeduccionesMes
};
