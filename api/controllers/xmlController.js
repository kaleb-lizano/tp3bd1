const xmlService = require("../services/xmlService");

async function cargarXML(req, res, next) {
  try {
    await xmlService.cargarDatosXml();
    res.status(200).json({ message: "La base de datos se inicializó correctamente con los datos del XML." });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Error al cargar los datos del XML.", error: err.message });
  }
}

module.exports = {
  cargarXML
};
