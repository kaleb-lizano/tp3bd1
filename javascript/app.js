/* =====================================================
   Inicialización de la aplicación
   ===================================================== */

async function initApp() {
  const sesion = obtenerSesion();
  if (!sesion) { location.href = "login.html"; return; }

  const imp     = obtenerImpersonacion();
  const esAdmin = sesion.esAdmin || sesion.rol === "admin";

  if (imp && !esAdmin) {
    terminarImpersonacion();
    await mostrarVistaEmpleado(sesion.idEmpleado, sesion.nombre || sesion.username);

  } else if (imp && esAdmin) {
    /* Admin impersonando
       ===================================================== */
    mostrarBannerImpersonacion(imp, true);
    await mostrarVistaEmpleado(imp.idEmpleado, imp.nombre);

  } else if (esAdmin) {
    /* Sesión de administrador
       ===================================================== */
    await initVistaAdmin(sesion);

  } else {
    /* Sesión de empleado 
       ===================================================== */
    await mostrarVistaEmpleado(sesion.idEmpleado, sesion.nombre || sesion.username);
  }
}

/* =====================================================
   Vista de administrador — listado y filtro de empleados
   ===================================================== */

async function initVistaAdmin(sesion) {
  $("usuario-activo").textContent = sesion.username;
  $("btn-logout").addEventListener("click", cerrarSesion);

  /* Botones del encabezado
     ===================================================== */
  $("btn-mostrar-formulario").addEventListener("click", () => {
    limpiarFormularioEmpleado();
    limpiarMensaje($("mensaje-formulario"));
    mostrarVista("vista-formulario");
  });

  $("btn-cancelar-formulario").addEventListener("click", async () => {
    limpiarFormularioEmpleado();
    await cargarEmpleadosDesdeApi();
    mostrarVista("vista-principal");
  });

  /* Barra de filtros
     ===================================================== */
  $("btn-filtrar").addEventListener("click", filtrarDesdeInterfaz);

  $("btn-limpiar-filtro").addEventListener("click", async () => {
    $("filtro-empleado").value = "";
    await cargarEmpleadosDesdeApi();
    limpiarMensaje($("mensaje-principal"));
  });

  /* Acciones sobre la tabla de empleados
     ===================================================== */
  $("tabla-empleados").addEventListener("click", manejarAccionTablaAdmin);

  $("form-empleado").addEventListener("submit", e => {
    e.preventDefault();
    guardarEmpleadoDesdeFormulario();
  });

  await cargarPuestos();
  await cargarEmpleadosDesdeApi();
  mostrarVista("vista-principal");
}

function manejarAccionTablaAdmin(e) {
  const btn = e.target.closest("button[data-accion]");
  if (!btn) return;

  const id     = btn.dataset.id;
  const nombre = btn.dataset.nombre;

  if (btn.dataset.accion === "editar")      editarEmpleado(id);
  if (btn.dataset.accion === "impersonar")  impersonarEmpleado(id, nombre);
}

async function filtrarDesdeInterfaz() {
  limpiarMensaje($("mensaje-principal"));

  const filtro = $("filtro-empleado").value;
  const tipo   = detectarTipoFiltro(filtro);

  if (tipo === "invalido") {
    mostrarMensaje($("mensaje-principal"), "El filtro solo puede contener letras y espacios.", "error");
    return;
  }

  const queryParams = tipo === "nombre"
    ? `filtroNombre=${encodeURIComponent(filtro.trim())}`
    : "";

  await cargarEmpleadosDesdeApi(queryParams);
}

/* =====================================================
   Impersonación de empleado
   ===================================================== */

async function impersonarEmpleado(idEmpleado, nombre) {
  const sesion = obtenerSesion();
  try {
    const resp = await fetch(`${API_BASE}/sesion/impersonar`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idUsuarioAdmin: sesion?.id, idEmpleado: Number(idEmpleado) }),
    });
    const datos = await resp.json();
    if (!resp.ok) {
      mostrarMensaje($("mensaje-principal"), "No se pudo impersonar al empleado.", "error");
      return;
    }

    const nombreEmpleado = datos.Nombre || nombre || idEmpleado;
    iniciarImpersonacion(idEmpleado, nombreEmpleado);
    mostrarBannerImpersonacion({ idEmpleado, nombre: nombreEmpleado }, true);
    await mostrarVistaEmpleado(idEmpleado, nombreEmpleado);

  } catch (err) {
    mostrarMensaje($("mensaje-principal"), "No se pudo conectar con el servidor.", "error");
  }
}

function mostrarBannerImpersonacion(imp, esAdmin) {
  const banner = $("banner-impersonacion");
  if (!banner) return;

  banner.classList.remove("oculto");
  $("banner-nombre-impersonado").textContent = imp.nombre;
  const btnVolver = $("btn-volver-admin");
  if (!btnVolver) return;

  if (esAdmin) {
    btnVolver.classList.remove("oculto");
    btnVolver.onclick = volverAAdmin;
  } else {
    btnVolver.classList.add("oculto");
  }
}

async function volverAAdmin() {
  const sesion = obtenerSesion();
  try {
    await fetch(`${API_BASE}/sesion/regresar`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idUsuarioAdmin: sesion?.id }),
    });
  } catch (err) {
    console.warn("Error al regresar a admin:", err);
  }
  terminarImpersonacion();
  location.reload();
}

/* =====================================================
   Vista de empleado — planillas
   ===================================================== */

let manejadorPlanillaRegistrado = false;

async function mostrarVistaEmpleado(idEmpleado, nombre) {
  $("vista-empleado")?.classList.remove("oculto");
  ["vista-principal", "vista-formulario"].forEach(id => $(id)?.classList.add("oculto"));

  const elNombre = $("empleado-nombre-vista");
  if (elNombre) elNombre.textContent = nombre || idEmpleado;

  /* Navegación entre pestañas de planilla
     ===================================================== */
  const btnSemanal = $("tab-semanal");
  const btnMensual = $("tab-mensual");
  const btnCerrarModal = $("btn-cerrar-modal-planilla");
  const btnLogoutEmpleado = $("btn-logout-empleado");

  if (btnSemanal) btnSemanal.onclick = () => mostrarTabEmpleado("semanal");
  if (btnMensual) btnMensual.onclick = () => mostrarTabEmpleado("mensual");
  if (btnCerrarModal) btnCerrarModal.onclick = () => $("modal-planilla")?.classList.add("oculto");

  if (btnLogoutEmpleado) {
    const estaImpersonando = Boolean(obtenerImpersonacion());

    btnLogoutEmpleado.disabled = estaImpersonando;
    btnLogoutEmpleado.title = estaImpersonando
      ? "Regrese a la interfaz de administrador para cerrar sesión"
      : "Cerrar sesión";

    btnLogoutEmpleado.onclick = () => {
      if (Boolean(obtenerImpersonacion())) return;
      cerrarSesion();
    };
  }

  if (!manejadorPlanillaRegistrado) {
    document.addEventListener("click", manejarClickPlanilla);
    manejadorPlanillaRegistrado = true;
  }

  await mostrarTabEmpleado("semanal");
}

async function mostrarTabEmpleado(tab) {
  const semanal    = $("vista-planilla-semanal");
  const mensual    = $("vista-planilla-mensual");
  const btnSemanal = $("tab-semanal");
  const btnMensual = $("tab-mensual");

  if (tab === "semanal") {
    semanal?.classList.remove("oculto");
    mensual?.classList.add("oculto");
    btnSemanal?.classList.add("btnPrimario");
    btnSemanal?.classList.remove("btnSecundario");
    btnMensual?.classList.add("btnSecundario");
    btnMensual?.classList.remove("btnPrimario");
    await cargarPlanillaSemanal();
  } else {
    mensual?.classList.remove("oculto");
    semanal?.classList.add("oculto");
    btnMensual?.classList.add("btnPrimario");
    btnMensual?.classList.remove("btnSecundario");
    btnSemanal?.classList.add("btnSecundario");
    btnSemanal?.classList.remove("btnPrimario");
    await cargarPlanillaMensual();
  }
}

function manejarClickPlanilla(e) {
  const celda  = e.target.closest("[data-accion]");
  if (!celda) return;

  const accion = celda.dataset.accion;
  const idx    = parseInt(celda.dataset.idx);

  if (accion === "ver-bruto-semanal")      abrirDetalleBrutoSemanal(planillaSemanalData[idx]);
  if (accion === "ver-deducciones-semanal") abrirDeduccionesSemanal(planillaSemanalData[idx]);
  if (accion === "ver-bruto-mensual")      abrirDetalleBrutoMensual(planillaMensualData[idx]);
  if (accion === "ver-deducciones-mensual") abrirDeduccionesMensual(planillaMensualData[idx]);
}

/* =====================================================
   Punto de entrada
   ===================================================== */

const page = document.body.dataset.page;

if (page === "login") initLogin();
if (page === "app")   initApp();
