const router = require("express").Router();
const authController = require("../controllers/authController");
const autenticar = require("../middlewares/authMiddleware");

router.post("/login", authController.login);
router.post("/cadastro", authController.cadastro);
router.get("/me", autenticar, authController.me);

module.exports = router;
