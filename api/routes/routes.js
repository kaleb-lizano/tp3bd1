"use strict";

const express = require("express");
const router = express.Router();

const authController = require("../controllers/authController");
const empleadoController = require("../controllers/empleadoController");
const movimientoController = require("../controllers/movimientoController");
const catalogoController = require("../controllers/catalogoController");
const xmlController = require("../controllers/xmlController");
const planillaController = require("../controllers/planillaController");

// Auth
router.post("/auth/login", authController.login);
router.post("/auth/logout", authController.logout);

// Empleados
router.get("/empleados", empleadoController.obtenerEmpleados);
router.get("/empleados/:valorDocumento", empleadoController.consultarEmpleado);
router.post("/empleados", empleadoController.insertarEmpleado);
router.put("/empleados/:valorDocumento", empleadoController.actualizarEmpleado);
router.post("/empleados/:valorDocumento/eliminar", empleadoController.eliminarEmpleado);

// Movimientos
router.get("/movimientos/:valorDocumento", movimientoController.obtenerMovimientos);
router.post("/movimientos/:valorDocumento", movimientoController.insertarMovimiento);

// Catálogos
router.get("/catalogos/puestos", catalogoController.obtenerPuestos);
router.get("/catalogos/tiposMovimiento", catalogoController.obtenerTiposMovimiento);
router.get("/catalogos/error/:codigo", catalogoController.obtenerError);

// Admin
router.post("/admin/cargar-xml", xmlController.cargarXML);

// Planilla semanal (R04)
router.get("/planilla/semanal/:idEmpleado", planillaController.obtenerPlanillasSemanal);
router.get("/planilla/semanal/:idPlanilla/dias", planillaController.obtenerDiasPlanillaSemanal);
router.get("/planilla/semanal/:idPlanilla/deducciones", planillaController.obtenerDeduccionesSemana);

// Planilla mensual (R05)
router.get("/planilla/mensual/:idEmpleado", planillaController.obtenerPlanillasMensual);
router.get("/planilla/mensual/:idPlanilla/semanas", planillaController.obtenerSemanasEnMes);
router.get("/planilla/mensual/:idPlanilla/deducciones", planillaController.obtenerDeduccionesMes);

module.exports = { routes: router };
