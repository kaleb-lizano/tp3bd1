"use strict";

const path = require("path");
const express = require("express");
const config = require("./config");
const cors = require("cors");
const bodyParser = require("body-parser");
const userRoutes = require("./routes/routes");
const xmlService = require("./services/xmlService");

const app = express();

app.use(express.json());
app.use(cors());
app.use(bodyParser.json());

app.use(express.static(path.join(__dirname, "..")));

app.use("/api", userRoutes.routes);

app.listen(config.port, async () => {
    console.log(`El servidor se encuentra activo en el puerto: ${config.port}`);
    try {
        await xmlService.cargarDatosXml();
    } catch (err) {
        console.warn("Ocurrió un error al cargar XML en inicio o los datos ya se encuentran cargados en la base de datos:", err.message);
    }
});
