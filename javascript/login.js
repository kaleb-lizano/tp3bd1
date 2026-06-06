/* =====================================================
   Inicio de sesión
   ===================================================== */

function validarCamposLogin(username, password) {
  if (!username && !password) return "Debe ingresar usuario y contraseña.";
  if (!username) return "Debe ingresar el usuario.";
  if (!password) return "Debe ingresar la contraseña.";
  return null;
}

function initLogin() {
  const form      = $("form-login");
  const inputUser = $("username");
  const inputPass = $("password");
  const btnLogin  = $("btn-login");
  const mensaje   = $("mensaje-login");

  if (obtenerSesion()) { location.href = "index.html"; return; }

  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    const username = inputUser.value.trim();
    const password = inputPass.value.trim();
    const errorCampos = validarCamposLogin(username, password);

    if (errorCampos) {
      mostrarMensaje(mensaje, errorCampos, "error");
      return;
    }

    btnLogin.disabled = true;

    try {
      /* Llamada al servicio de autenticación
         ===================================================== */
      const { ok, datos } = await dummyLogin(username, password);

      if (!ok) {
        mostrarMensaje(mensaje, datos.message || "Error al iniciar sesión.", "error");
        btnLogin.disabled = false;
        return;
      }

      guardarSesion({
        username:   datos.username,
        esAdmin:    datos.esAdmin   ?? false,
        idEmpleado: datos.idEmpleado ?? null,
        nombre:     datos.nombre     ?? datos.username,
      });

      location.href = "index.html";

    } catch (err) {
      mostrarMensaje(mensaje, "No se pudo conectar con el servidor.", "error");
      btnLogin.disabled = false;
    }
  });
}
