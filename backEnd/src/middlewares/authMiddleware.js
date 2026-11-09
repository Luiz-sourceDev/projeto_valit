const jwt = require("jsonwebtoken");

// Exige o header "Authorization: Bearer <token>"
function autenticar(req, res, next) {
  const header = req.headers.authorization || "";
  const [tipo, token] = header.split(" ");
  if (tipo !== "Bearer" || !token) {
    return res.status(401).json({ message: "Token não informado" });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: "Sessão expirada ou inválida" });
  }
}

module.exports = autenticar;
