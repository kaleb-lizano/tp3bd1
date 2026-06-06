/* =====================================================
   Constantes
   ===================================================== */
const STORAGE_KEYS = {
  sesion: "planilla_sesion_usuario",
  xmlCargado: "planilla_xml_cargado"
};

const API_BASE = "/api";

/* =====================================================
   Utilidades generales
   ===================================================== */
function $(id) { return document.getElementById(id); }

function mostrarVista(vista) {
  [
    "vista-principal", "vista-formulario",
    "vista-empleado", "vista-planilla-semanal", "vista-planilla-mensual"
  ].forEach(id => $(id)?.classList.add("oculto"));
  $(vista)?.classList.remove("oculto");
}

function mostrarMensaje(contenedor, texto, tipo = "success") {
  if (!contenedor) return;
  const clase = tipo === "error" ? "mensajeError" : "mensajeExito";
  contenedor.innerHTML = `<div class="mensaje ${clase}">${texto}</div>`;
}

function limpiarMensaje(contenedor) {
  if (contenedor) contenedor.innerHTML = "";
}

function formatearMoneda(valor) {
  return Number(valor || 0).toLocaleString("es-CR", { style: "currency", currency: "CRC", maximumFractionDigits: 0 });
}

function formatearFechaSinHora(fechaIso) {
  if (!fechaIso) return "-";
  return new Date(fechaIso).toISOString().split("T")[0];
}

function formatearFecha(fechaIso) {
  if (!fechaIso) return "-";
  return new Date(fechaIso).toLocaleString("es-CR");
}

function formatearHora(horaStr) {
  if (!horaStr) return "-";
  return horaStr.substring(0, 5);
}

/* =====================================================
   Sesión
   ===================================================== */
function obtenerSesion() {
  return JSON.parse(localStorage.getItem(STORAGE_KEYS.sesion) || "null");
}

function guardarSesion(datos) {
  localStorage.setItem(STORAGE_KEYS.sesion, JSON.stringify(datos));
}

async function cerrarSesion() {
  const sesion = obtenerSesion();
  try {
    await fetch(`${API_BASE}/auth/logout`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: sesion?.username || "" })
    });
  } catch (err) {
    console.warn("Error al registrar logout:", err);
  }
  localStorage.removeItem(STORAGE_KEYS.sesion);
  location.href = "login.html";
}

/* =====================================================
   Impersonación
   ===================================================== */
function obtenerImpersonacion() {
  const s = obtenerSesion();
  return s?.impersonando || null;  // { idEmpleado, nombre }
}

function iniciarImpersonacion(idEmpleado, nombre) {
  const s = obtenerSesion();
  guardarSesion({ ...s, impersonando: { idEmpleado, nombre } });
}

function terminarImpersonacion() {
  const s = obtenerSesion();
  const { impersonando, ...resto } = s;
  guardarSesion(resto);
}
