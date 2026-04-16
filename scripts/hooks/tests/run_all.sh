#!/usr/bin/env bash
# Минимальные smoke-тесты hooks
# Проверяют что hook-скрипты синтаксически корректны и покрывают все политики

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== ARIA Hooks Tests ==="

# Тест 1: синтаксис bash
for hook in pre-commit commit-msg pre-push install.sh; do
    if bash -n "$HOOKS_DIR/$hook" 2>/dev/null; then
        echo "[OK] $hook — синтаксис корректен"
    else
        echo "[FAIL] $hook — синтаксическая ошибка"
        exit 1
    fi
done

# Тест 2: pre-commit упоминает ключевые категории (как regex-фрагменты)
declare -a CATEGORIES=("CHANGED_CORE" "CHANGED_ADAPTERS" "CHANGED_POLICIES" "CHANGED_GUIDE" "CHANGED_HOOKS" "CHANGED_CHANGELOG")
for cat in "${CATEGORIES[@]}"; do
    if ! grep -qF "$cat" "$HOOKS_DIR/pre-commit"; then
        echo "[FAIL] pre-commit не определяет переменную: $cat"
        exit 1
    fi
done
echo "[OK] pre-commit покрывает все категории из CHANGELOG_POLICY"

# Тест 3: commit-msg содержит все scopes из COMMIT_POLICY
SCOPES=("CORE" "PROTOCOL" "ADAPTER" "POLICY" "DOCS" "HOOKS" "FIX" "META" "CONTRIB")
for scope in "${SCOPES[@]}"; do
    if ! grep -qE "\b$scope\b" "$HOOKS_DIR/commit-msg"; then
        echo "[FAIL] commit-msg не знает scope: $scope"
        exit 1
    fi
done
echo "[OK] commit-msg покрывает все scopes из COMMIT_POLICY"

# Тест 4: commit-msg проверяет Co-Authored-By
if ! grep -qF "Co-Authored-By" "$HOOKS_DIR/commit-msg"; then
    echo "[FAIL] commit-msg не проверяет Co-Authored-By (требование COMMIT_POLICY)"
    exit 1
fi
echo "[OK] commit-msg проверяет Co-Authored-By"

# Тест 5: pre-commit блокирует коммит core/ без CHANGELOG (симуляция)
# (полный integration test требовал бы git repo, пропускаем)
echo "[OK] Integration tests — пропускаю (требуют отдельный test repo)"

echo ""
echo "Все smoke-тесты прошли."
