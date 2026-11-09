const db = require("../database/connection");

async function buscarPorUsuario(usuario) {
  const [rows] = await db.query(
    "SELECT id, usuario, senha FROM usuarios WHERE usuario = ? LIMIT 1",
    [usuario]
  );
  return rows[0];
}

async function criar(usuario, senhaHash) {
  const [result] = await db.query(
    "INSERT INTO usuarios (usuario, senha) VALUES (?, ?)",
    [usuario, senhaHash]
  );
  return { id: result.insertId, usuario };
}

module.exports = { buscarPorUsuario, criar };
