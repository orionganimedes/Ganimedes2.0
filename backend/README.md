# Ganimedes Backend - PocketBase Local & VPS

Backend de persistencia, sincronización y autenticación en tiempo real para **Ganimedes Business & POS Engine**, impulsado por **PocketBase v0.25.9**.

---

## 🚀 Acceso Rápido

- **Panel de Administración Web:** [http://127.0.0.1:8090/_/](http://127.0.0.1:8090/_/)
- **API REST Base:** `http://127.0.0.1:8090/api/`
- **Superusuario Administrador:**
  - **Correo:** `admin@ganimedes.com`
  - **Contraseña:** `Ganimedes2026!`

---

## 🛠️ Cómo Iniciar el Servidor

### En tu computadora (Fedora / Linux):
```bash
cd /home/orion/Documentos/desarrollos/ganimedes2.0/backend
./run.sh
```
O directamente con el binario:
```bash
./pocketbase serve --http="0.0.0.0:8090"
```

> [!TIP]
> **Conexión desde dispositivos Flutter:**
> - **Desde Emulador Android:** Usa la URL `http://10.0.2.2:8090`
> - **Desde Dispositivo Físico (Pixel 7 por Wi-Fi):** Usa la IP de tu computadora (ejemplo: `http://192.168.1.XX:8090`)
> - **Desde Navegador Web / Linux Desktop:** Usa `http://127.0.0.1:8090`

---

## 📦 Colecciones Diseñadas y Sembradas

El backend cuenta con 9 colecciones configuradas y pobladas con datos de prueba realistas:

1. **`branches` (Sucursales)**:
   - Central, Polanco, Roma Norte y Condesa con dirección, teléfono y RFC.
2. **`users` (Especialistas / Barberos)**:
   - Carlos Mendoza (`carlos@ganimedes.com`, PIN `1234`, Sillón 01, Turno Mañana)
   - Mateo Style (`mateo@ganimedes.com`, PIN `2222`, Sillón 02)
   - David Cortes (`david@ganimedes.com`, PIN `3333`, Sillón 03)
3. **`categories` (Clasificación)**:
   - Cortes & Barba, Tratamientos, Pomadas & Styling, Bebidas / Bar, Insumos Barbería.
4. **`products_services` (Catálogo)**:
   - Fade Clásico (\$280), Ritual de Barba (\$200), Combo Completo (\$450), Pomada Matte (\$320), Aceite Wood (\$240), Cold Brew (\$50), Navajas Derby (\$150), Talco Pinaud (\$190).
5. **`chairs` (Sillones en Tiempo Real)**:
   - Sillón 01 (En servicio • Carlos M. • Alejandro Peña)
   - Sillón 02 (Disponible • Mateo S.)
   - Sillón 03 (En servicio • David C. • Roberto G.)
6. **`cash_shifts` (Cortes de Caja / Arqueo)**:
   - Turno Matutino abierto por Carlos M., fondo inicial \$1,500.00, ventas \$8,450.00, efectivo en gaveta \$5,700.00.
7. **`cash_movements` (Movimientos de Efectivo)**:
   - Registro de entradas y retiros de dinero de gaveta durante el turno.
8. **`sales` (Tickets y Ventas)**:
   - Tickets emitidos con folios correlativos (`#TK-1025`), desglose de totales y métodos de pago.
9. **`sale_items` (Detalle por Ticket)**:
   - Líneas de producto/servicio vinculadas al ticket.

---

## 🔄 Migraciones Automáticas (`pb_migrations/`)

Toda la base de datos se crea por código:
- `1790999000_init_schema.js`: Crea las tablas, tipos de campos y reglas de API.
- `1790999001_seed_data.js`: Puebla las sucursales, barberos, catálogo y turno inicial.

Para reiniciar o aplicar migraciones en otra máquina:
```bash
./pocketbase migrate up
```

---

## 🌐 Despliegue en VPS (Ubuntu) — Futura Etapa 4

Dado que PocketBase es un binario universal compilado en Go y SQLite es un archivo local:
1. Copias la carpeta `backend/` a tu VPS Ubuntu:
   ```bash
   scp -r backend usuario@ip-del-vps:/var/www/ganimedes-backend
   ```
2. Creas el servicio systemd (`/etc/systemd/system/pocketbase.service`):
   ```ini
   [Unit]
   Description=Ganimedes PocketBase
   After=network.target

   [Service]
   Type=simple
   User=www-data
   Group=www-data
   LimitNOFILE=4096
   Restart=always
   RestartSec=5s
   StandardOutput=append:/var/log/pocketbase.log
   StandardError=append:/var/log/pocketbase.err
   ExecStart=/var/www/ganimedes-backend/pocketbase serve --http="0.0.0.0:8090"

   [Install]
   WantedBy=multi-user.target
   ```
3. Inicias el servicio:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now pocketbase
   ```
¡Y listo! Funcionará en Ubuntu idéntico a Fedora.

---

## 🐳 Despliegue con Docker (recomendado)

La contenedorización empaqueta el binario + migraciones + hooks en una imagen
portable, con los datos persistidos en un volumen independiente.

### Requisitos
- Docker Engine + Docker Compose v2.

### 1. Configura las variables de entorno
```bash
cp .env.example .env
# Edita .env y define un PB_ADMIN_PASSWORD seguro
```

### 2. Construye y levanta el contenedor
```bash
docker compose up -d --build
```

### 3. Verifica
```bash
docker compose ps                     # estado + healthcheck
curl http://127.0.0.1:8090/api/health # debe responder 200
```

- **Panel admin:** http://127.0.0.1:8090/_/
- **API REST:**   http://127.0.0.1:8090/api/

### 4. Comandos útiles
```bash
docker compose logs -f pocketbase      # ver logs
docker compose down                    # detener (el volumen conserva los datos)
docker compose down -v                 # detener Y borrar el volumen de datos
```

### Migrar tus datos locales existentes (una sola vez)
Si ya tienes datos en `pb_data/` (como este repo) y quieres conservarlos en el
contenedor, impórtalos al volumen **antes** del primer arranque:

```bash
# 1. Crea el volumen sin arrancar el servicio
docker volume create ganimedes_pb_data

# 2. Copia tu base de datos dentro del volumen
docker run --rm -v ganimedes_pb_data:/pb_data \
  -v "$(pwd)/pb_data":/src alpine:3.20 \
  sh -c "cp -a /src/. /pb_data/ && chown -R 1000:1000 /pb_data"

# 3. Levanta el contenedor
docker compose up -d
```

> **Conexión desde Flutter:**
> - **Emulador Android:** `http://10.0.2.2:8090`
> - **Dispositivo físico (misma red):** `http://<IP-de-tu-PC>:8090`
> - **Producción (VPS):** expón el contenedor detrás de un proxy HTTPS
>   (Caddy/Nginx) y usa `https://api.tudominio.com`.

### Notas de seguridad del contenedor
- El binario corre como usuario **sin privilegios** (`pb`), no como root.
- `pb_data/` queda **fuera de la imagen** (volumen persistente).
- El password del superusuario se inyecta por `.env`, no queda hardcodeado en el
  binario. (El `upsert` lo aplica en cada arranque; si lo cambias en el panel,
  actualiza también el `.env`.)
