"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { buscarUsuarioLogado, logout } from "@/services/authService";
import "@/components/login.css";

// Página protegida: só abre com token válido. Base para a tela de produtos.
export default function ProdutosPage() {
  const router = useRouter();
  const [usuario, setUsuario] = useState(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      router.replace("/");
      return;
    }
    buscarUsuarioLogado(token)
      .then(setUsuario)
      .catch(() => {
        logout();
        router.replace("/");
      });
  }, [router]);

  function sair() {
    logout();
    router.replace("/");
  }

  if (!usuario) {
    return (
      <main className="login-page">
        <p>Carregando...</p>
      </main>
    );
  }

  return (
    <main className="login-page">
      <header className="login-header">
        <img src="/logo.png" alt="Valit" className="login-logo" />
      </header>

      <section className="login-card">
        <h1>Produtos</h1>
        <p>
          Você está logado como <strong>{usuario.usuario}</strong>.
        </p>
        <button type="button" className="login-btn" onClick={sair} style={{ width: "100%" }}>
          Sair
        </button>
      </section>

      <footer className="login-footer">© 2026 Valit. Todos os direitos reservados.</footer>
    </main>
  );
}
