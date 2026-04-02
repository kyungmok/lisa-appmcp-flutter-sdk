#!/usr/bin/env bash
# setup-examples.sh — Build and deploy example Flutter apps to appmcp apps-dir.
#
# Prerequisites (install once via onboard.sh or manually):
#   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
#   sudo snap install flutter --classic
#
# Usage:
#   ./setup-examples.sh              # Build + deploy all examples
#   ./setup-examples.sh recipe_app   # Build + deploy specific example
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$SCRIPT_DIR/example"
APPS_DIR="${APPMCP_APPS_DIR:-$HOME/.appmcp/apps}"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }

# ─── Preflight check ───
preflight() {
    local ok=true

    if ! command -v flutter &>/dev/null; then
        error "flutter not found. Install: sudo snap install flutter --classic"
        ok=false
    fi

    for cmd in clang cmake ninja; do
        if ! command -v "$cmd" &>/dev/null; then
            error "$cmd not found. Install: sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev"
            ok=false
            break
        fi
    done

    if [ "$ok" = false ]; then
        exit 1
    fi

    flutter config --enable-linux-desktop 2>/dev/null || true
    info "Prerequisites OK"
}

# ─── Build an example app ───
build_app() {
    local app_dir="$1"
    local app_name
    app_name="$(basename "$app_dir")"

    echo ""
    echo "=== Building: $app_name ==="

    if [ ! -f "$app_dir/pubspec.yaml" ]; then
        error "No pubspec.yaml in $app_dir"
        return 1
    fi

    cd "$app_dir"
    flutter pub get
    flutter build linux --release
    info "$app_name built"
    cd "$SCRIPT_DIR"
}

# ─── Deploy to apps-dir ───
deploy_app() {
    local app_dir="$1"
    local app_name
    app_name="$(basename "$app_dir")"

    if [ ! -f "$app_dir/appMCP.json" ]; then
        error "No appMCP.json in $app_dir — skipping deploy"
        return 1
    fi

    # Read appId from appMCP.json
    local app_id
    app_id=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['appId'])" "$app_dir/appMCP.json")

    local deploy_dir="$APPS_DIR/$app_id"
    mkdir -p "$deploy_dir"

    # Copy appMCP.json
    cp "$app_dir/appMCP.json" "$deploy_dir/"

    # Copy build output
    local bundle_dir="$app_dir/build/linux/x64/release/bundle"
    if [ ! -d "$bundle_dir" ]; then
        # Try arm64
        bundle_dir="$app_dir/build/linux/arm64/release/bundle"
    fi

    if [ -d "$bundle_dir" ]; then
        cp -r "$bundle_dir"/* "$deploy_dir/"
    else
        error "Build output not found for $app_name"
        return 1
    fi

    # Create run.sh (appmcp-server executes this to launch the app)
    local binary_name="$app_name"
    cat > "$deploy_dir/run.sh" <<RUNEOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
exec ./$binary_name
RUNEOF
    chmod +x "$deploy_dir/run.sh"

    info "$app_name deployed to $deploy_dir (appId: $app_id)"
}

# ─── Main ───
main() {
    preflight

    # Determine which apps to build
    local targets=()
    if [ $# -gt 0 ]; then
        for t in "$@"; do
            if [ -d "$EXAMPLE_DIR/$t" ]; then
                targets+=("$EXAMPLE_DIR/$t")
            else
                error "Example not found: $t"
                exit 1
            fi
        done
    else
        for d in "$EXAMPLE_DIR"/*/; do
            [ -f "$d/pubspec.yaml" ] && targets+=("$d")
        done
    fi

    if [ ${#targets[@]} -eq 0 ]; then
        error "No example apps found in $EXAMPLE_DIR"
        exit 1
    fi

    echo ""
    echo "=== Apps to build: ${#targets[@]} ==="
    for t in "${targets[@]}"; do
        echo "  - $(basename "$t")"
    done

    # Build + deploy each
    for app_dir in "${targets[@]}"; do
        build_app "$app_dir"
        deploy_app "$app_dir"
    done

    echo ""
    echo "=== Done ==="
    info "Apps deployed to: $APPS_DIR"
    echo ""
    echo "  Deployed apps:"
    for d in "$APPS_DIR"/*/; do
        [ -f "$d/appMCP.json" ] && echo "    - $(basename "$d")"
    done
    echo ""
    echo "  appmcp-server will pick them up automatically."
    echo "  Restart Lisa if already running to refresh tools."
}

main "$@"
