// Cria o banco, as tabelas e o usuário de teste usando os dados do .env
// Uso: npm run db:setup
require("dotenv").config();
const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");

(async () => {
  const sql = fs.readFileSync(path.join(__dirname, "..", "database.sql"), "utf8");
  let conn;
  try {
    conn = await mysql.createConnection({
      host: process.env.DB_HOST || "127.0.0.1",
      port: Number(process.env.DB_PORT) || 3306,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      multipleStatements: true,
    });
    await conn.query(sql);
    console.log("Banco db_valit configurado com sucesso.");
  } catch (err) {
    console.error("Erro ao configurar o banco:", err.message);
    process.exitCode = 1;
  } finally {
    if (conn) await conn.end();
  }
})();
