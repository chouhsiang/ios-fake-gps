#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="${ROOT_DIR}/requirements.txt"
VENV_DIR="${ROOT_DIR}/.venv"

log() { printf "%s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*" >&2; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

check_xcode_clt() {
  # 檢查 Xcode Command Line Tools 是否已安裝
  if ! command -v xcode-select >/dev/null 2>&1; then
    return 1
  fi

  local clt_path
  set +e
  clt_path="$(xcode-select -p 2>/dev/null)"
  local rc=$?
  set -e

  # 常見路徑：
  # /Library/Developer/CommandLineTools
  if [[ $rc -eq 0 && "${clt_path}" == /Library/Developer/CommandLineTools* ]]; then
    return 0
  fi
  return 1
}

ensure_xcode_clt() {
  if [[ "${SKIP_CLT_CHECK:-}" == "1" ]]; then
    warn "已跳過 Command Line Tools 檢查（SKIP_CLT_CHECK=1）"
    return 0
  fi

  if check_xcode_clt; then
    log "已偵測到 Xcode Command Line Tools：$(xcode-select -p)"
    return 0
  fi

  log "尚未安裝 Xcode Command Line Tools，將嘗試啟動安裝..."
  # 這會觸發 macOS 的安裝 UI/流程，通常需要使用者確認。
  # 不建議加上 sudo，避免權限互動問題。
  if ! xcode-select --install >/dev/null 2>&1; then
    warn "無法直接觸發安裝（可能已在安裝中，或需要手動執行）。"
  fi

  log "等待安裝完成（最多約 10 分鐘）。"
  local i
  for i in {1..120}; do
    if check_xcode_clt; then
      log "Command Line Tools 已安裝完成：$(xcode-select -p)"
      return 0
    fi
    sleep 5
  done

  die "Command Line Tools 仍未偵測到，請先完成安裝後再重新執行 init.sh"
}

ensure_python_and_venv() {
  command -v python3 >/dev/null 2>&1 || die "找不到 python3，請先安裝 Python 3.10+"

  local py_ver
  py_ver="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))' 2>/dev/null || true)"
  log "系統 python3 版本：${py_ver:-未知}"

  if [[ ! -f "${REQ_FILE}" ]]; then
    die "找不到 requirements.txt：${REQ_FILE}"
  fi

  if [[ ! -d "${VENV_DIR}" ]]; then
    log "建立虛擬環境：${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"
  else
    log "虛擬環境已存在：${VENV_DIR}"
  fi
}

install_deps() {
  local py pip
  py="${VENV_DIR}/bin/python"
  pip="${VENV_DIR}/bin/pip"

  [[ -x "${py}" ]] || die "虛擬環境 python 不存在：${py}"
  [[ -f "${REQ_FILE}" ]] || die "requirements.txt 不存在：${REQ_FILE}"

  # 盡量降低 pip 的資訊噴出量（只保留錯誤輸出到 stderr）
  export PIP_DISABLE_PIP_VERSION_CHECK=1
  export PIP_NO_COLOR=1

  log "更新 pip/setuptools/wheel..."
  "${py}" -m pip install --upgrade pip setuptools wheel >/dev/null

  log "安裝相依套件：$(basename "${REQ_FILE}")"
  "${py}" -m pip install -q -r "${REQ_FILE}" >/dev/null
}

main() {
  # 讓使用者知道目前在做什麼
  log "=== init.sh：初始化環境 ==="
  ensure_xcode_clt
  ensure_python_and_venv
  install_deps
  log "=== 完成 ==="
}

main "$@"

