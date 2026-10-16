#!/usr/bin/env bash

# Ganimedes Business & POS Engine - Backend Launcher
# PocketBase v0.25.9 Local Server

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

chmod +x pocketbase

echo "=========================================================="
echo "   🪐 GANIMEDES BUSINESS & POS ENGINE - BACKEND LOCAL   "
echo "=========================================================="
echo " Servidor: PocketBase v0.25.9"
echo " Puerto:   8090"
echo " Panel Web:  http://127.0.0.1:8090/_/"
echo " API URL:    http://127.0.0.1:8090/api/"
echo " Admin:      admin@ganimedes.com"
echo " Clave:      Ganimedes2026!"
echo "=========================================================="
echo " Para conectar desde Android Emulator: http://10.0.2.2:8090"
echo " Para conectar desde dispositivo físico: http://<tu-ip-local>:8090"
echo "=========================================================="
echo "Iniciando servidor PocketBase..."

./pocketbase serve --http="0.0.0.0:8090"
