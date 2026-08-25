#!/bin/bash

# ==========================================
# NMAP SMART SCANNER
# ==========================================

clear

echo "=========================================="
echo "        NMAP SMART SCANNER"
echo "=========================================="

read -rp "ALVO [+]: " alvo
read -rp "PORTA/PORTAS [+]: " ports
read -rp "TIMING 0-5 [+]: " time

# ------------------------------------------
# Validação
# ------------------------------------------

if [[ -z "$alvo" ]]; then
    echo "[!] Alvo não informado."
    exit 1
fi

if [[ -z "$ports" ]]; then
    echo "[!] Portas não informadas."
    exit 1
fi

if ! [[ "$time" =~ ^[0-5]$ ]]; then
    echo "[!] Timing deve estar entre 0 e 5."
    exit 1
fi

# ------------------------------------------
# Diretório do scan
# ------------------------------------------

timestamp=$(date +"%Y%m%d_%H%M%S")

safe_target=$(echo "$alvo" | tr '/: ' '___')

output_dir="scans/${safe_target}_${timestamp}"

mkdir -p "$output_dir"

report="$output_dir/report.txt"

echo
echo "[+] Alvo: $alvo"
echo "[+] Portas: $ports"
echo "[+] Timing: T$time"
echo "[+] Resultado: $output_dir"
echo

# ------------------------------------------
# Cabeçalho
# ------------------------------------------

{
    echo "=========================================="
    echo "NMAP SMART SCANNER"
    echo "=========================================="
    echo "Alvo: $alvo"
    echo "Portas: $ports"
    echo "Timing: T$time"
    echo "Data: $(date)"
    echo "=========================================="
    echo
} | tee "$report"

# ==========================================
# 1 - HOST DISCOVERY
# ==========================================

echo
echo "[+] 1. VERIFICANDO SE O HOST ESTÁ ONLINE..."

if sudo nmap -sn "$alvo" | grep -q "Host is up"; then
    echo "[+] Host está online."
else
    echo "[!] Host não respondeu ao ping."
    echo "[!] Continuando com -Pn..."
fi

# ==========================================
# 2 - TCP SCAN
# ==========================================

echo
echo "[+] 2. SCAN TCP..."

sudo nmap \
    -T"$time" \
    -sS \
    -Pn \
    --reason \
    "$alvo" \
    -p"$ports" \
    -oA "$output_dir/tcp"

# ==========================================
# 3 - SERVICE DETECTION
# ==========================================

echo
echo "[+] 3. IDENTIFICANDO SERVIÇOS..."

sudo nmap \
    -T"$time" \
    -sV \
    -Pn \
    --version-light \
    "$alvo" \
    -p"$ports" \
    -oA "$output_dir/services"

# ==========================================
# 4 - UDP SCAN
# ==========================================

echo
echo "[+] 4. SCAN UDP..."

sudo nmap \
    -T"$time" \
    -sU \
    -Pn \
    --top-ports 100 \
    "$alvo" \
    -oA "$output_dir/udp"

# ==========================================
# 5 - OS DETECTION
# ==========================================

echo
echo "[+] 5. DETECÇÃO DO SISTEMA OPERACIONAL..."

sudo nmap \
    -T"$time" \
    -O \
    -Pn \
    --osscan-guess \
    "$alvo" \
    -oA "$output_dir/os"

# ==========================================
# 6 - ENUMERAÇÃO NSE
# ==========================================

echo
echo "[+] 6. ENUMERAÇÃO DE SERVIÇOS..."

sudo nmap \
    -T"$time" \
    -sC \
    -sV \
    -Pn \
    "$alvo" \
    -p"$ports" \
    -oA "$output_dir/nse"

# ==========================================
# 7 - RELATÓRIO
# ==========================================

echo
echo "[+] GERANDO RELATÓRIO..."

{
    echo
    echo "=========================================="
    echo "RESULTADO TCP"
    echo "=========================================="

    cat "$output_dir/tcp.nmap"

    echo
    echo "=========================================="
    echo "SERVIÇOS"
    echo "=========================================="

    cat "$output_dir/services.nmap"

    echo
    echo "=========================================="
    echo "RESULTADO UDP"
    echo "=========================================="

    cat "$output_dir/udp.nmap"

    echo
    echo "=========================================="
    echo "SISTEMA OPERACIONAL"
    echo "=========================================="

    cat "$output_dir/os.nmap"

    echo
    echo "=========================================="
    echo "ENUMERAÇÃO NSE"
    echo "=========================================="

    cat "$output_dir/nse.nmap"

} > "$report"

echo
echo "=========================================="
echo "SCAN FINALIZADO"
echo "=========================================="

echo "[+] Relatório:"
echo "    $report"

echo
echo "[+] Arquivos:"
ls -lh "$output_dir"
