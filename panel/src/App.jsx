import { useEffect, useState } from 'react'
import * as api from './api.js'

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('gb_token') || '')
  const [record, setRecord] = useState(null)
  const [view, setView] = useState('chat')

  return token && record ? (
    <Shell token={token} record={record} view={view} setView={setView} onLogout={() => {
      localStorage.removeItem('gb_token'); setToken(''); setRecord(null)
    }} />
  ) : (
    <Login onAuth={(token, record) => {
      localStorage.setItem('gb_token', token); setToken(token); setRecord(record)
    }} />
  )
}

function Login({ onAuth }) {
  const [email, setEmail] = useState('prueba@ganimedes.com')
  const [password, setPassword] = useState('prueba1234')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setError(''); setLoading(true)
    try {
      const { token, record } = await api.login(email, password)
      if (record.role !== 'admin') throw new Error('Solo los administradores pueden usar el panel')
      onAuth(token, record)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-wrap">
      <form className="card login" onSubmit={submit}>
        <h1>🪐 Ganimedes Panel</h1>
        <p className="muted">Panel de entrenamiento del agente</p>
        <label>Email</label>
        <input value={email} onChange={(e) => setEmail(e.target.value)} type="email" required />
        <label>Contraseña</label>
        <input value={password} onChange={(e) => setPassword(e.target.value)} type="password" required />
        {error && <p className="error">{error}</p>}
        <button disabled={loading}>{loading ? 'Entrando…' : 'Entrar'}</button>
      </form>
    </div>
  )
}

function Shell({ token, record, view, setView, onLogout }) {
  return (
    <div className="shell">
      <header>
        <div>
          <strong>🪐 Ganimedes Panel</strong>
          <span className="muted"> · {record.business_name || 'sin negocio'} · {record.email}</span>
        </div>
        <nav>
          <button className={view === 'chat' ? 'active' : ''} onClick={() => setView('chat')}>Chat</button>
          <button className={view === 'prompt' ? 'active' : ''} onClick={() => setView('prompt')}>Prompt</button>
          <button className={view === 'tools' ? 'active' : ''} onClick={() => setView('tools')}>Tools</button>
          <button onClick={onLogout}>Salir</button>
        </nav>
      </header>
      <main>
        {view === 'chat' && <Chat token={token} />}
        {view === 'prompt' && <PromptEditor token={token} />}
        {view === 'tools' && <Tools token={token} />}
      </main>
    </div>
  )
}

function Chat({ token }) {
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)

  async function send(e) {
    e.preventDefault()
    if (!input.trim() || busy) return
    const q = input.trim()
    setInput('')
    const history = messages.map(({ role, content }) => ({ role, content }))
    setMessages((m) => [...m, { role: 'user', content: q }, { role: 'assistant', content: '' }])
    setBusy(true)
    try {
      let full = ''
      for await (const token of api.chatStream(token, q, history)) {
        full += token
        setMessages((m) => {
          const copy = [...m]
          copy[copy.length - 1] = { ...copy[copy.length - 1], content: full }
          return copy
        })
      }
    } catch (err) {
      setMessages((m) => {
        const copy = [...m]
        copy[copy.length - 1] = { ...copy[copy.length - 1], content: '⚠️ ' + err.message }
        return copy
      })
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="chat">
      <div className="messages">
        {messages.length === 0 && <p className="muted center">Pregunta algo a tu agente, por ejemplo: «¿Cómo van las ventas?»</p>}
        {messages.map((m, i) => (
          <div key={i} className={`msg ${m.role}`}>
            {m.content || (busy && i === messages.length - 1 ? 'Pensando…' : '')}
          </div>
        ))}
      </div>
      <form className="composer" onSubmit={send}>
        <input value={input} onChange={(e) => setInput(e.target.value)} placeholder="Escribe tu mensaje…" autoFocus />
        <button disabled={busy}>Enviar</button>
      </form>
    </div>
  )
}

function PromptEditor({ token }) {
  const [prompt, setPrompt] = useState('')
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    api.getPrompt(token).then((r) => setPrompt(r.prompt)).catch(() => {})
  }, [token])

  async function save() {
    await api.setPrompt(token, prompt)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="prompt-editor">
      <h2>System prompt</h2>
      <p className="muted">Edita el prompt para "entrenar" el comportamiento del agente.</p>
      <textarea value={prompt} onChange={(e) => setPrompt(e.target.value)} rows={20} />
      <div>
        <button onClick={save}>Guardar prompt</button>
        {saved && <span className="ok">✓ guardado</span>}
      </div>
    </div>
  )
}

function Tools({ token }) {
  const [tools, setTools] = useState([])

  useEffect(() => {
    api.getTools(token).then((r) => setTools(r.tools || [])).catch(() => {})
  }, [token])

  return (
    <div>
      <h2>Tools disponibles</h2>
      {tools.length === 0 && <p className="muted">Cargando…</p>}
      {tools.map((t) => (
        <div key={t.name} className="card tool">
          <strong>{t.name}</strong>
          <p className="muted">{t.description}</p>
        </div>
      ))}
    </div>
  )
}
