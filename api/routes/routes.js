"use strict";

const express = require("express");
const router = express.Router();

const auth = require("../controllers/authController");
const empleados = require("../controllers/empleadoController");
const planilla = require("../controllers/planillaController");
const sesion = require("../controllers/sesionController");

// auth
router.post("/auth/login", auth.login);
router.post("/auth/logout", auth.logout);

// cosas de empleados
router.get("/empleados", empleados.listar); // ?idUsuario=  (&filtro= para R02)
router.put("/empleados/:valorDocumento", empleados.editar);

// puestos
router.get("/puestos", empleados.listarPuestos);

// impersonar y eso
router.post("/sesion/impersonar", sesion.impersonar);
router.post("/sesion/regresar", sesion.regresar);

// planillas
router.get("/planilla/semanal/:idEmpleado", planilla.semanal); // ?cantidad=&idUsuario=
router.get("/planilla/mensual/:idEmpleado", planilla.mensual); // ?cantidad=&idUsuario=

module.exports = { routes: router };
