"use strict";

const sql = require("mssql");
const config = require("./config");

let poolPromise = null;

function getPool() {
	if (!poolPromise) {
		poolPromise = new sql.ConnectionPool(config.sql)
			.connect()
			.then((pool) => {
				pool.on("error", (err) =>
					console.error("Error en el pool de SQL:", err),
				);
				return pool;
			})
			.catch((err) => {
				poolPromise = null;
				throw err;
			});
	}
	return poolPromise;
}

module.exports = { getPool, sql };
