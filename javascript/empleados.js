/* =====================================================
   Carga de catálogos
   ===================================================== */

async function cargarPuestos() {
  const select = $("puestoEmpleado");
  if (!select) return;

  try {
    const lista = await obtenerPuestos();
    select.innerHTML =
      `<option value="">Seleccione un puesto</option>` +
      lista.map(p => `<option value="${p.Nombre}">${p.Nombre}</option>`).join("");

  } catch (err) {
    console.error("Error al cargar puestos:", err);
    select.innerHTML = `<option value="">Error al cargar puestos</option>`;
  }
}

/* =====================================================
   Filtros
   ===================================================== */

function detectarTipoFiltro(valor) {
  const texto = valor.trim();
  if (!texto) return "todos";
  if (/^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/.test(texto)) return "nombre";
  return "invalido";
}

/* =====================================================
   Tabla de empleados
   ===================================================== */

function cargarTabla(lista) {
  const tabla = $("tabla-empleados");
  if (!tabla) return;

  tabla.innerHTML = "";

  if (!lista.length) {
    tabla.innerHTML = `
      <tr>
        <td colspan="3" style="text-align:center;color:var(--colorGris);padding:24px;">
          No se encontraron empleados.
        </td>
      </tr>`;
    return;
  }

  lista.forEach(e => {
    const fila = document.createElement("tr");
    fila.innerHTML = crearFilaEmpleado(e);
    tabla.appendChild(fila);
  });
}

function crearFilaEmpleado(e) {
  const id     = e.IdEmpleado || e.ValorDocumentoIdentidad;
  const nombre = e.Nombre;
  const puesto = e.NombrePuesto || e.Puesto || "";

  return `
    <td style="font-weight:600;">${nombre}</td>
    <td>${puesto}</td>
    <td>
      <div class="accionesTabla">
        <button class="btn btnSecundario btnAccion"
                data-accion="editar"
                data-id="${id}">Editar</button>
        <button class="btn btnImpersonar btnAccion"
                data-accion="impersonar"
                data-id="${id}"
                data-nombre="${nombre}">Impersonar</button>
      </div>
    </td>
  `;
}

/* =====================================================
   Formulario de empleado — limpieza
   ===================================================== */

function limpiarFormularioEmpleado() {
  $("form-empleado")?.reset();
  if ($("idEmpleadoEditar"))   $("idEmpleadoEditar").value   = "";
  if ($("titulo-formulario"))  $("titulo-formulario").textContent  = "Insertar empleado";
  if ($("subtitulo-formulario")) $("subtitulo-formulario").textContent = "Ingrese los datos del nuevo empleado.";
}

/* =====================================================
   Editar empleado existente
   ===================================================== */

async function editarEmpleado(id) {
  try {
    const e = await consultarEmpleado(id);

    if (!e) {
      mostrarMensaje($("mensaje-principal"), "Empleado no encontrado.", "error");
      return;
    }

    if ($("titulo-formulario"))
      $("titulo-formulario").textContent = "Editar empleado";
    if ($("subtitulo-formulario"))
      $("subtitulo-formulario").textContent = `Editando: ${e.Nombre}`;

    if ($("idEmpleadoEditar"))          $("idEmpleadoEditar").value           = e.ValorDocumentoIdentidad || id;
    if ($("valorDocumentoIdentidad"))   $("valorDocumentoIdentidad").value    = e.ValorDocumentoIdentidad;
    if ($("nombreEmpleado"))            $("nombreEmpleado").value             = e.Nombre;
    if ($("puestoEmpleado"))            $("puestoEmpleado").value             = e.NombrePuesto;

    limpiarMensaje($("mensaje-formulario"));
    mostrarVista("vista-formulario");

  } catch (err) {
    mostrarMensaje($("mensaje-principal"), "No se pudo obtener los datos del empleado.", "error");
  }
}

/* =====================================================
   Guardar empleado (insertar o actualizar)
   ===================================================== */

async function guardarEmpleadoDesdeFormulario() {
  const docEditar  = $("idEmpleadoEditar")?.value || null;
  const documento  = $("valorDocumentoIdentidad")?.value.trim();
  const nombre     = $("nombreEmpleado")?.value.trim();
  const puesto     = $("puestoEmpleado")?.value;

  if (!documento || !nombre || !puesto) {
    mostrarMensaje($("mensaje-formulario"), "Todos los campos son obligatorios.", "error");
    return;
  }

  try {
    let resultado;

    if (docEditar) {
      /* Actualización de empleado existente
         ===================================================== */
      resultado = await actualizarEmpleado(docEditar, {
        valorDocumentoNuevo: documento,
        nombreNuevo:         nombre,
        nombrePuestoNuevo:   puesto,
      });
    } else {
      /* Inserción de nuevo empleado
         ===================================================== */
      resultado = await insertarEmpleado({
        valorDocumentoIdentidad: documento,
        nombre,
        nombrePuesto: puesto,
      });
    }

    if (!resultado.ok) {
      mostrarMensaje($("mensaje-formulario"), resultado.datos.message || "Error al guardar empleado.", "error");
      return;
    }

    limpiarFormularioEmpleado();
    await cargarEmpleadosDesdeApi();
    mostrarVista("vista-principal");
    mostrarMensaje(
      $("mensaje-principal"),
      docEditar ? "Empleado actualizado correctamente." : "Empleado insertado correctamente."
    );

  } catch (err) {
    mostrarMensaje($("mensaje-formulario"), "No se pudo guardar el empleado.", "error");
  }
}

/* =====================================================
   Obtener listado de empleados desde el servicio
   ===================================================== */

async function cargarEmpleadosDesdeApi(queryParams = "") {
  try {
    /* Se extrae el filtro de nombre si viene en los parámetros
       ===================================================== */
    const params    = new URLSearchParams(queryParams);
    const filtroNombre = params.get("filtroNombre") || "";

    const lista = await obtenerEmpleados(filtroNombre);
    cargarTabla(lista);

  } catch (err) {
    console.error("Error al cargar empleados:", err);
    const t = $("tabla-empleados");
    if (t) t.innerHTML = `<tr><td colspan="3">Error al cargar empleados.</td></tr>`;
  }
}
