const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const usuarioModel = require("../models/usuarioModel");

function gerarToken(user) {
  return jwt.sign({ id: user.id, usuario: user.usuario }, process.env.JWT_SECRET, {
    expiresIn: "8h",
  });
}

async function login(usuario, senha) {
  const user = await usuarioModel.buscarPorUsuario(usuario);
  if (!user) return null;

  const ok = await bcrypt.compare(senha, user.senha);
  if (!ok) return null;

  return gerarToken(user);
}

// Retorna o token do novo usuário, ou null se o e-mail já estiver cadastrado
async function cadastrar(usuario, senha) {
  const existente = await usuarioModel.buscarPorUsuario(usuario);
  if (existente) return null;

  const hash = await bcrypt.hash(senha, 10);
  const user = await usuarioModel.criar(usuario, hash);
  return gerarToken(user);
}

module.exports = { login, cadastrar };
