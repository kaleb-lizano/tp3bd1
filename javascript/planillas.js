/* =====================================================
   Estado compartido entre vistas de planilla
   ===================================================== */

let planillaSemanalData = [];
let planillaMensualData = [];

/* =====================================================
   Planilla semanal
   ===================================================== */

async function cargarPlanillaSemanal() {
  const imp        = obtenerImpersonacion();
  const sesion     = obtenerSesion();
  const idEmpleado = imp ? imp.idEmpleado : sesion?.idEmpleado;

  limpiarMensaje($("mensaje-planilla-semanal"));
  $("tbody-semanal").innerHTML = `
    <tr>
      <td colspan="7" style="text-align:center;padding:24px;color:var(--colorGris);">
        Cargando...
      </td>
    </tr>`;

  try {
    const lista = await dummyObtenerPlanillasSemanal(idEmpleado);
    planillaSemanalData = lista;
    renderizarTablaSemanal(lista);

  } catch (err) {
    mostrarMensaje($("mensaje-planilla-semanal"), "Error al cargar la planilla semanal.", "error");
  }
}

function renderizarTablaSemanal(lista) {
  const tbody = $("tbody-semanal");

  if (!lista.length) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" style="text-align:center;padding:24px;color:var(--colorGris);">
          No hay planillas registradas.
        </td>
      </tr>`;
    return;
  }

  tbody.innerHTML = lista.map((s, i) => `
    <tr>
      <td style="font-family:var(--fuenteDisplay);font-size:0.85rem;">
        ${formatearFechaSinHora(s.FechaInicio)} — ${formatearFechaSinHora(s.FechaFin)}
      </td>
      <td class="celdaClickeable"
          data-accion="ver-bruto-semanal"
          data-idx="${i}">
        ${formatearMoneda(s.SalarioBruto)}
      </td>
      <td class="celdaClickeable"
          data-accion="ver-deducciones-semanal"
          data-idx="${i}">
        ${formatearMoneda(s.TotalDeducciones)}
      </td>
      <td style="font-weight:700;">${formatearMoneda(s.SalarioNeto)}</td>
      <td style="text-align:center;">${s.HorasOrdinarias     ?? 0}</td>
      <td style="text-align:center;">${s.HorasExtrasNormales ?? 0}</td>
      <td style="text-align:center;">${s.HorasExtrasDobles   ?? 0}</td>
    </tr>
  `).join("");
}

/* =====================================================
   Detalle diario de una semana (salario bruto clickeable)
   ===================================================== */

async function abrirDetalleBrutoSemanal(semana) {
  const modal = $("modal-planilla");
  $("modal-planilla-titulo").textContent =
    `Detalle diario — semana del ${formatearFechaSinHora(semana.FechaInicio)}`;
  $("modal-planilla-cuerpo").innerHTML =
    `<p style="color:var(--colorGris);text-align:center;padding:20px;">Cargando...</p>`;
  modal.classList.remove("oculto");

  try {
    /* Se consulta la asistencia día a día para la semana seleccionada
       ===================================================== */
    const dias = await dummyObtenerDiasSemana(semana.IdPlanillaSemanal);

    if (!dias.length) {
      $("modal-planilla-cuerpo").innerHTML =
        `<p style="color:var(--colorGris);">Sin asistencias registradas.</p>`;
      return;
    }

    $("modal-planilla-cuerpo").innerHTML = `
      <div class="contenedorTabla">
        <table>
          <thead>
            <tr>
              <th>Día</th>
              <th>Entrada</th>
              <th>Salida</th>
              <th>H. Ord.</th>
              <th>Monto Ord.</th>
              <th>H. Extra Norm.</th>
              <th>Monto Extra</th>
              <th>H. Extra Doble</th>
              <th>Monto Doble</th>
            </tr>
          </thead>
          <tbody>
            ${dias.map(d => `
              <tr>
                <td style="font-family:var(--fuenteDisplay);font-size:0.8rem;">
                  ${formatearFechaSinHora(d.Fecha)}
                </td>
                <td>${formatearHora(d.HoraEntrada)}</td>
                <td>${formatearHora(d.HoraSalida)}</td>
                <td style="text-align:center;">${d.HorasOrdinarias     ?? 0}</td>
                <td>${formatearMoneda(d.MontoOrdinario)}</td>
                <td style="text-align:center;">${d.HorasExtrasNormales ?? 0}</td>
                <td>${formatearMoneda(d.MontoExtraNormal)}</td>
                <td style="text-align:center;">${d.HorasExtrasDobles   ?? 0}</td>
                <td>${formatearMoneda(d.MontoExtraDoble)}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>`;

  } catch (err) {
    $("modal-planilla-cuerpo").innerHTML =
      `<p style="color:var(--colorRojo);">Error al cargar el detalle.</p>`;
  }
}

/* =====================================================
   Deducciones de una semana (total deducciones clickeable)
   ===================================================== */

async function abrirDeduccionesSemanal(semana) {
  const modal = $("modal-planilla");
  $("modal-planilla-titulo").textContent =
    `Deducciones — semana del ${formatearFechaSinHora(semana.FechaInicio)}`;
  $("modal-planilla-cuerpo").innerHTML =
    `<p style="color:var(--colorGris);text-align:center;padding:20px;">Cargando...</p>`;
  modal.classList.remove("oculto");

  try {
    /* Se consultan las deducciones aplicadas en la semana seleccionada
       ===================================================== */
    const lista = await dummyObtenerDeduccionesSemana(semana.IdPlanillaSemanal);
    renderizarModalDeducciones(lista);

  } catch (err) {
    $("modal-planilla-cuerpo").innerHTML =
      `<p style="color:var(--colorRojo);">Error al cargar deducciones.</p>`;
  }
}

/* =====================================================
   Planilla mensual
   ===================================================== */

async function cargarPlanillaMensual() {
  const imp        = obtenerImpersonacion();
  const sesion     = obtenerSesion();
  const idEmpleado = imp ? imp.idEmpleado : sesion?.idEmpleado;

  limpiarMensaje($("mensaje-planilla-mensual"));
  $("tbody-mensual").innerHTML = `
    <tr>
      <td colspan="4" style="text-align:center;padding:24px;color:var(--colorGris);">
        Cargando...
      </td>
    </tr>`;

  try {
    /* Se obtienen las planillas mensuales del empleado activo
       ===================================================== */
    const lista = await dummyObtenerPlanillasMensual(idEmpleado);
    planillaMensualData = lista;
    renderizarTablaMensual(lista);

  } catch (err) {
    mostrarMensaje($("mensaje-planilla-mensual"), "Error al cargar la planilla mensual.", "error");
  }
}

function renderizarTablaMensual(lista) {
  const tbody = $("tbody-mensual");

  if (!lista.length) {
    tbody.innerHTML = `
      <tr>
        <td colspan="4" style="text-align:center;padding:24px;color:var(--colorGris);">
          No hay planillas registradas.
        </td>
      </tr>`;
    return;
  }

  tbody.innerHTML = lista.map((m, i) => `
    <tr>
      <td style="font-family:var(--fuenteDisplay);font-size:0.85rem;">
        ${m.Anio ?? ""} / ${String(m.Mes ?? "").padStart(2, "0")}
      </td>
      <td class="celdaClickeable"
          data-accion="ver-bruto-mensual"
          data-idx="${i}">
        ${formatearMoneda(m.SalarioBruto)}
      </td>
      <td class="celdaClickeable"
          data-accion="ver-deducciones-mensual"
          data-idx="${i}">
        ${formatearMoneda(m.TotalDeducciones)}
      </td>
      <td style="font-weight:700;">${formatearMoneda(m.SalarioNeto)}</td>
    </tr>
  `).join("");
}

/* =====================================================
   Semanas que componen un mes (salario bruto clickeable)
   ===================================================== */

async function abrirDetalleBrutoMensual(mes) {
  const modal = $("modal-planilla");
  $("modal-planilla-titulo").textContent =
    `Semanas incluidas — ${mes.Anio}/${String(mes.Mes).padStart(2, "0")}`;
  $("modal-planilla-cuerpo").innerHTML =
    `<p style="color:var(--colorGris);text-align:center;padding:20px;">Cargando...</p>`;
  modal.classList.remove("oculto");

  try {
    /* Se consultan las semanas que conforman el mes seleccionado
       ===================================================== */
    const lista = await dummyObtenerSemanasMes(mes.IdPlanillaMensual);

    if (!lista.length) {
      $("modal-planilla-cuerpo").innerHTML =
        `<p style="color:var(--colorGris);">Sin semanas registradas.</p>`;
      return;
    }

    $("modal-planilla-cuerpo").innerHTML = `
      <div class="contenedorTabla">
        <table>
          <thead>
            <tr>
              <th>Semana</th>
              <th>Bruto</th>
              <th>Deducciones</th>
              <th>Neto</th>
            </tr>
          </thead>
          <tbody>
            ${lista.map(s => `
              <tr>
                <td style="font-family:var(--fuenteDisplay);font-size:0.8rem;">
                  ${formatearFechaSinHora(s.FechaInicio)} — ${formatearFechaSinHora(s.FechaFin)}
                </td>
                <td>${formatearMoneda(s.SalarioBruto)}</td>
                <td>${formatearMoneda(s.TotalDeducciones)}</td>
                <td style="font-weight:700;">${formatearMoneda(s.SalarioNeto)}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>`;

  } catch (err) {
    $("modal-planilla-cuerpo").innerHTML =
      `<p style="color:var(--colorRojo);">Error al cargar el detalle.</p>`;
  }
}

/* =====================================================
   Deducciones de un mes (total deducciones clickeable)
   ===================================================== */

async function abrirDeduccionesMensual(mes) {
  const modal = $("modal-planilla");
  $("modal-planilla-titulo").textContent =
    `Deducciones — ${mes.Anio}/${String(mes.Mes).padStart(2, "0")}`;
  $("modal-planilla-cuerpo").innerHTML =
    `<p style="color:var(--colorGris);text-align:center;padding:20px;">Cargando...</p>`;
  modal.classList.remove("oculto");

  try {
    /* Se consultan las deducciones consolidadas del mes seleccionado
       ===================================================== */
    const lista = await dummyObtenerDeduccionesMes(mes.IdPlanillaMensual);
    renderizarModalDeducciones(lista);

  } catch (err) {
    $("modal-planilla-cuerpo").innerHTML =
      `<p style="color:var(--colorRojo);">Error al cargar deducciones.</p>`;
  }
}

/* =====================================================
   Renderizado del modal de deducciones (reutilizable)
   ===================================================== */

function renderizarModalDeducciones(lista) {
  if (!lista.length) {
    $("modal-planilla-cuerpo").innerHTML =
      `<p style="color:var(--colorGris);">Sin deducciones aplicadas.</p>`;
    return;
  }

  $("modal-planilla-cuerpo").innerHTML = `
    <div class="contenedorTabla">
      <table>
        <thead>
          <tr>
            <th>Deducción</th>
            <th>Porcentaje</th>
            <th>Monto</th>
          </tr>
        </thead>
        <tbody>
          ${lista.map(d => `
            <tr>
              <td style="font-weight:600;">${d.NombreDeduccion}</td>
              <td>${d.Porcentaje != null ? d.Porcentaje + " %" : "—"}</td>
              <td style="font-family:var(--fuenteDisplay);">
                ${formatearMoneda(d.MontoDeduccion)}
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>`;
}
