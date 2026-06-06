"use strict";
const sql = require("mssql");
const config = require("../config");
const { registrarEvento } = require("../services/eventoService");
const { obtenerMensajeError } = require("../services/errorService");

async function verificarBloqueoLogin(conexion, ip, username) {
  const ahora = new Date();
  const hace20min = new Date(ahora.getTime() - 20 * 60 * 1000);
  const hace10min = new Date(ahora.getTime() - 10 * 60 * 1000);

  const resultadoFallidos = await conexion.request()
    .input("inPostInIP", sql.VarChar(128), ip)
    .input("inIdTipoEvento", sql.Int, 2)
    .input("inUsername", sql.VarChar(128), username)
    .output("outResultCode", sql.Int)
    .execute("usp_ObtenerEventosPorIP");

  const intentosFallidos = resultadoFallidos.recordset.filter(
    (e) => new Date(e.PostTime) >= hace20min
  ).length;

  const resultadoBloqueado = await conexion.request()
    .input("inPostInIP", sql.VarChar(128), ip)
    .input("inIdTipoEvento", sql.Int, 3)
    .input("inUsername", sql.VarChar(128), username)
    .output("outResultCode", sql.Int)
    .execute("usp_ObtenerEventosPorIP");

  const bloqueadoReciente = resultadoBloqueado.recordset.some(
    (e) => new Date(e.PostTime) >= hace10min
  );

  return { intentosFallidos, bloqueadoReciente };
}

async function login(req, res) {
  try {
    const { username, password } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    const conexion = await sql.connect(config.sql);

    const { intentosFallidos, bloqueadoReciente } = await verificarBloqueoLogin(conexion, ip, username);

    if (intentosFallidos > 5 || bloqueadoReciente) {
      await registrarEvento(3, "", username, ip);
      const errorMsg = await obtenerMensajeError(50003);
      return res.status(403).json({ errorCode: 50003, message: errorMsg });
    }

    const userResult = await conexion.request()
      .input("inUsername", sql.VarChar(128), username)
      .output("outResultCode", sql.Int)
      .execute("usp_ObtenerUsuarioPorUsername");

    const usuario = userResult.recordset[0];

    if (!usuario) {
      await registrarEvento(2, `${intentosFallidos + 1}. Código: 50001`, username, ip);
      const errorMsg = await obtenerMensajeError(50001);
      return res.status(401).json({ errorCode: 50001, message: errorMsg });
    }

    if (usuario.Password !== password) {
      await registrarEvento(2, `${intentosFallidos + 1}. Código: 50002`, username, ip);
      const errorMsg = await obtenerMensajeError(50002);
      return res.status(401).json({ errorCode: 50002, message: errorMsg });
    }

    await registrarEvento(1, "Exitoso", username, ip);

    // Retornar datos de sesión incluyendo rol y id de empleado (si aplica)
    // NOTA: el SP usp_ObtenerUsuarioPorUsername debe retornar EsAdmin e IdEmpleado
    //       en la nueva DB. Si no existen aún, se usará false/null por defecto.
    res.status(200).json({
      username: usuario.Username,
      esAdmin: usuario.EsAdmin ?? false,
      idEmpleado: usuario.IdEmpleado ?? null,
      nombre: usuario.Nombre ?? null
    });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

async function logout(req, res) {
  try {
    const { username } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.ip || '127.0.0.1';
    await registrarEvento(4, "", username, ip);
    res.status(200).json({ message: "Logout exitoso" });
  } catch (err) {
    res.status(500).send(err.message);
  }
}

module.exports = { login, logout };
