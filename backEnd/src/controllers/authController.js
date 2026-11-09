const authService = require("../services/authService");

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

async function login(req, res) {
  const { usuario, senha } = req.body || {};
  if (!usuario || !senha) {
    return res.status(400).json({ message: "Informe usuário e senha" });
  }

  try {
    const token = await authService.login(String(usuario).trim(), senha);
    if (!token) return res.status(401).json({ message: "Usuário ou senha inválidos" });
    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erro interno do servidor" });
  }
}

async function cadastro(req, res) {
  const { usuario, senha } = req.body || {};
  if (!usuario || !senha) {
    return res.status(400).json({ message: "Informe e-mail e senha" });
  }
  const email = String(usuario).trim();
  if (!EMAIL_REGEX.test(email)) {
    return res.status(400).json({ message: "E-mail inválido" });
  }
  if (String(senha).length < 6) {
    return res.status(400).json({ message: "A senha deve ter pelo menos 6 caracteres" });
  }

  try {
    const token = await authService.cadastrar(email, String(senha));
    if (!token) return res.status(409).json({ message: "Este e-mail já está cadastrado" });
    res.status(201).json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erro interno do servidor" });
  }
}

function me(req, res) {
  res.json({ id: req.user.id, usuario: req.user.usuario });
}

module.exports = { login, cadastro, me };
