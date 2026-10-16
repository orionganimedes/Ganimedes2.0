export const PB_URL = import.meta.env.VITE_POCKETBASE_URL || 'http://localhost:8090'
export const AGENT_URL = import.meta.env.VITE_AGENT_URL || 'http://localhost:8000'

async function handle(res) {
  if (!res.ok) {
    let detail = res.statusText
    try {
      const j = await res.json()
      detail = j.detail || j.message || detail
    } catch {}
    throw new Error(detail)
  }
  return res.json()
}

export async function login(email, password) {
  const res = await fetch(`${PB_URL}/api/collections/users/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: email, password }),
  })
  return handle(res) // { token, record }
}

export async function chat(token, message, history = []) {
  const res = await fetch(`${AGENT_URL}/api/agent/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: token },
    body: JSON.stringify({ message, history }),
  })
  return handle(res)
}

// Chat con streaming: devuelve tokens uno a uno (efecto letra por letra).
export async function* chatStream(token, message, history = []) {
  const res = await fetch(`${AGENT_URL}/api/agent/chat/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
      Authorization: token,
    },
    body: JSON.stringify({ message, history }),
  })

  if (!res.ok) {
    let detail = res.statusText
    try {
      const j = await res.json()
      detail = j.detail || j.message || detail
    } catch {}
    throw new Error(detail)
  }

  const reader = res.body.getReader()
  const decoder = new TextDecoder()
  let buffer = ''

  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buffer += decoder.decode(value, { stream: true })

    let idx
    while ((idx = buffer.indexOf('\n\n')) !== -1) {
      const chunk = buffer.slice(0, idx)
      buffer = buffer.slice(idx + 2)
      for (const line of chunk.split('\n')) {
        const trimmed = line.trim()
        if (!trimmed.startsWith('data: ')) continue
        const jsonStr = trimmed.slice(6).trim()
        if (!jsonStr) continue
        let data
        try {
          data = JSON.parse(jsonStr)
        } catch {
          continue
        }
        if (data.done === true) return
        if (data.error) throw new Error(data.error)
        if (data.token) yield data.token
      }
    }
  }
}

export async function getPrompt(token) {
  const res = await fetch(`${AGENT_URL}/api/agent/prompt`, {
    headers: { Authorization: token },
  })
  return handle(res)
}

export async function setPrompt(token, prompt) {
  const res = await fetch(`${AGENT_URL}/api/agent/prompt`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: token },
    body: JSON.stringify({ prompt }),
  })
  return handle(res)
}

export async function getTools(token) {
  const res = await fetch(`${AGENT_URL}/api/agent/tools`, {
    headers: { Authorization: token },
  })
  return handle(res)
}
