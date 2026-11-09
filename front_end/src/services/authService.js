import { API_URL } from "./api";

async function request(path, options = {}) {
  let res;
  try {
    res = await fetch(`${API_URL}${path}`, {
      ...options,
      headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    });
  } catch {
    throw new Error("Não foi possível conectar ao servidor. O backend está rodando?");
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(data.message || "Erro na requisição");
    err.status = res.status;
    throw err;
  }
  return data;
}

export function login(usuario, senha) {
  return request("/auth/login", {
    method: "POST",
    body: JSON.stringify({ usuario, senha }),
  });
}

export function cadastrar(usuario, senha) {
  return request("/auth/cadastro", {
    method: "POST",
    body: JSON.stringify({ usuario, senha }),
  });
}

export function buscarUsuarioLogado(token) {
  return request("/auth/me", { headers: { Authorization: `Bearer ${token}` } });
}

export function logout() {
  localStorage.removeItem("token");
}
