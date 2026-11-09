require("dotenv").config();
const express = require("express");
const cors = require("cors");
const db = require("./src/database/connection");
const authRoutes = require("./src/routes/authRoutes");

if (!process.env.JWT_SECRET) {
  console.error("JWT_SECRET não definido no .env (copie .env.example para .env)");
  process.exit(1);
}

const app = express();
app.use(cors({ origin: process.env.FRONTEND_URL || "http://localhost:3000" }));
app.use(express.json());

app.get("/api/health", (req, res) => res.json({ status: "ok" }));
app.use("/api/auth", authRoutes);

app.use((req, res) => res.status(404).json({ message: "Rota não encontrada" }));

const PORT = process.env.PORT || 3309;
app.listen(PORT, async () => {
  console.log(`API rodando na porta ${PORT}`);
  try {
    await db.query("SELECT 1 FROM usuarios LIMIT 1");
    console.log("Conectado ao banco de dados.");
  } catch (err) {
    console.error("Não foi possível acessar o banco:", err.message);
    console.error("Verifique o MySQL e os dados do .env, e rode: npm run db:setup");
  }
});
