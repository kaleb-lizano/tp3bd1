"use strict";

const path = require("path");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const config = require("./config");
const { routes } = require("./routes/routes");
const { cargarCatalogosYSimular } = require("./services/simulacionService");

const app = express();

app.use(express.json());
app.use(cors());
app.use(bodyParser.json());

app.use(express.static(path.join(__dirname, "..")));

app.use("/api", routes);

app.listen(config.port, async () => {
	console.log(`El servidor se encuentra activo en el puerto: ${config.port}`);
	try {
		await cargarCatalogosYSimular();
	} catch (err) {
		console.warn(
			"[sim] No se pudo cargar/simular en el arranque (¿falta desplegar las tablas/SPs, o la BD no está accesible?):",
			err.message,
		);
	}
});
