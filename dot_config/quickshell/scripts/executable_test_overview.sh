#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# OVERVIEW PANEL TEST SUITE
#═══════════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════════════════"
echo "  OVERVIEW PANEL — Automated Test Suite"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# ═══ TEST 1: Syntax Check ═══
echo "[TEST 1] QML Syntax Check (qmllint)"
if command -v qmllint >/dev/null 2>&1; then
    if qmllint /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml 2>&1 | grep -q "warning\|error"; then
        echo "  ❌ FAIL: qmllint found issues"
        qmllint /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml 2>&1 | head -10
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "  ✓ PASS: qmllint clean"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
else
    echo "  ⚠ SKIP: qmllint not available"
fi
echo ""

# ═══ TEST 2: VDeskHelper uses movetodesksilent ═══
echo "[TEST 2] VDeskHelper uses movetodesksilent dispatcher"
if grep -q "movetodesksilent" /home/runner/work/yeniden/yeniden/quickshell/VDeskHelper.qml; then
    echo "  ✓ PASS: VDeskHelper uses movetodesksilent"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: VDeskHelper missing movetodesksilent"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 3: No native workspace dispatchers in OverviewPanel ═══
echo "[TEST 3] No native workspace dispatchers in OverviewPanel"
if grep -E "movetoworkspace[^s]|workspace current" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml >/dev/null 2>&1; then
    echo "  ❌ FAIL: Found native workspace dispatcher in OverviewPanel"
    grep -nE "movetoworkspace[^s]|workspace current" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml | head -5
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo "  ✓ PASS: No native workspace dispatchers"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
echo ""

# ═══ TEST 4: No hardcoded hex colors ═══
echo "[TEST 4] No hardcoded hex colors in OverviewPanel"
if grep -E "#[0-9a-fA-F]{3,8}" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml >/dev/null 2>&1; then
    echo "  ❌ FAIL: Hardcoded colors found:"
    grep -nE "#[0-9a-fA-F]{3,8}" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml | head -5
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo "  ✓ PASS: No hardcoded colors"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
echo ""

# ═══ TEST 5: Scale factor present ═══
echo "[TEST 5] Coordinate scale factor present"
if grep -q "_scale" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: Scale factor present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Scale factor missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 6: VDeskHelper imported correctly ═══
echo "[TEST 6] VDeskHelper referenced in OverviewPanel"
if grep -q "VDeskHelper" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: VDeskHelper referenced"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: VDeskHelper not referenced"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 7: Drag state object exists ═══
echo "[TEST 7] Drag state object exists"
if grep -q "_drag.*active" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: Drag state object present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Drag state object missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 8: Resize handle exists ═══
echo "[TEST 8] Resize handle exists"
if grep -q "resizeHandle\|Qt.SizeFDiagCursor" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: Resize handle present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Resize handle missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 9: Keyboard navigation exists ═══
echo "[TEST 9] Keyboard navigation exists"
if grep -q "Keys.onPressed" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: Keyboard navigation present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Keyboard navigation missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ TEST 10: Animation behaviors exist ═══
echo "[TEST 10] Animation behaviors exist"
if grep -q "Behavior on" /home/runner/work/yeniden/yeniden/quickshell/components/OverviewPanel.qml; then
    echo "  ✓ PASS: Animation behaviors present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Animation behaviors missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# ═══ SUMMARY ═══
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "  Test Summary"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "  ✓ PASSED: $PASS_COUNT"
echo "  ❌ FAILED: $FAIL_COUNT"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All automated tests passed!"
    exit 0
else
    echo "❌ Some tests failed. Review output above."
    exit 1
fi
