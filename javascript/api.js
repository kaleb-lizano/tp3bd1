/* ===================================
  seccion de conexion con el backend
  ====================================*/

let _cachePlanillaSemanal = null;
let _cachePlanillaMensual = null;

function _idUsuarioSesion() {
	const s = obtenerSesion();
	return s?.id ?? "";
}

async function autenticar(username, password) {
	try {
		const resp = await fetch(`${API_BASE}/auth/login`, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ username, password }),
		});
		const data = await resp.json();
		if (!resp.ok) {
			return {
				ok: false,
				datos: { message: data.message || "Usuario o contraseña incorrectos." },
			};
		}
		return {
			ok: true,
			datos: {
				id: data.id,
				username: data.username,
				esAdmin: data.esAdmin,
				idEmpleado: data.idEmpleado,
				nombre: data.username,
			},
		};
	} catch (err) {
		return {
			ok: false,
			datos: { message: "No se pudo conectar con el servidor." },
		};
	}
}

async function obtenerPuestos() {
	const resp = await fetch(`${API_BASE}/puestos`);
	return await resp.json();
}

async function obtenerEmpleados(filtroNombre = "") {
	let url = `${API_BASE}/empleados?idUsuario=${encodeURIComponent(_idUsuarioSesion())}`;
	if (filtroNombre) url += `&filtro=${encodeURIComponent(filtroNombre)}`;

	const resp = await fetch(url);
	const filas = await resp.json();

	return (filas || []).map((e) => ({
		IdEmpleado: e.id,
		ValorDocumentoIdentidad: e.ValorDocumentoIdentidad,
		Nombre: e.Nombre,
		NombrePuesto: e.NombrePuesto,
	}));
}

async function consultarEmpleado(id) {
	const lista = await obtenerEmpleados("");
	return (
		lista.find((e) => e.IdEmpleado == id || e.ValorDocumentoIdentidad == id) ||
		null
	);
}

async function actualizarEmpleado(idOriginal, datos) {
	try {
		const resp = await fetch(
			`${API_BASE}/empleados/${encodeURIComponent(idOriginal)}`,
			{
				method: "PUT",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({
					nuevoNombre: datos.nombreNuevo,
					nuevoValorDocumento: datos.valorDocumentoNuevo,
					nuevoNombrePuesto: datos.nombrePuestoNuevo,
					idUsuario: _idUsuarioSesion(),
				}),
			},
		);
		const data = await resp.json();
		if (!resp.ok || data.ok === false) {
			return {
				ok: false,
				datos: { message: data.message || "Error al guardar empleado." },
			};
		}
		return { ok: true, datos: data };
	} catch (err) {
		return {
			ok: false,
			datos: { message: "No se pudo conectar con el servidor." },
		};
	}
}

async function insertarEmpleado() {
	return {
		ok: false,
		datos: {
			message: "La inserción de empleados no está disponible desde el sitio.",
		},
	};
}

async function obtenerPlanillasSemanal(idEmpleado) {
	const resp = await fetch(
		`${API_BASE}/planilla/semanal/${idEmpleado}?idUsuario=${encodeURIComponent(_idUsuarioSesion())}`,
	);
	_cachePlanillaSemanal = await resp.json();
	return _cachePlanillaSemanal.semanas || [];
}

async function obtenerDiasSemana(idPlanilla) {
	const dias = _cachePlanillaSemanal?.dias || [];
	return dias.filter((d) => d.IdPlanillaSemanal == idPlanilla);
}

async function obtenerDeduccionesSemana(idPlanilla) {
	const ded = _cachePlanillaSemanal?.deducciones || [];
	return ded.filter((d) => d.IdPlanillaSemanal == idPlanilla);
}

async function obtenerPlanillasMensual(idEmpleado) {
	const resp = await fetch(
		`${API_BASE}/planilla/mensual/${idEmpleado}?idUsuario=${encodeURIComponent(_idUsuarioSesion())}`,
	);
	_cachePlanillaMensual = await resp.json();
	return _cachePlanillaMensual.meses || [];
}

async function obtenerSemanasMes(idPlanilla) {
	const semanas = _cachePlanillaMensual?.semanas || [];
	return semanas.filter((s) => s.IdPlanillaMensual == idPlanilla);
}

async function obtenerDeduccionesMes(idPlanilla) {
	const ded = _cachePlanillaMensual?.deducciones || [];
	return ded.filter((d) => d.IdPlanillaMensual == idPlanilla);
}
