#!/bin/bash
set -e

# HivisionIDPhotos 模型检查和下载脚本
# 支持构建时和运行时两种模式

BUILD_MODE=${1:-false}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查模型文件是否存在
check_models() {
    local weights_dir="hivision/creator/weights"
    local retinaface_dir="hivision/creator/retinaface/weights"
    
    # 必需的模型文件
    local required_models=(
        "$weights_dir/hivision_modnet.onnx"
        "$weights_dir/modnet_photographic_portrait_matting.onnx"
    )
    
    # 可选的模型文件
    local optional_models=(
        "$weights_dir/rmbg-1.4.onnx"
        "$weights_dir/birefnet-v1-lite.onnx"
        "$retinaface_dir/retinaface-resnet50.onnx"
    )
    
    local missing_required=()
    local missing_optional=()
    
    # 检查必需模型
    for model in "${required_models[@]}"; do
        if [ ! -f "$model" ]; then
            missing_required+=("$(basename "$model")")
        else
            log_success "Found required model: $(basename "$model")"
        fi
    done
    
    # 检查可选模型
    for model in "${optional_models[@]}"; do
        if [ ! -f "$model" ]; then
            missing_optional+=("$(basename "$model")")
        else
            log_success "Found optional model: $(basename "$model")"
        fi
    done
    
    # 返回缺失的必需模型数量
    echo ${#missing_required[@]}
}

# 下载模型
download_models() {
    local mode=${1:-"required"}
    
    log_info "Starting model download (mode: $mode)..."
    
    # 确保目录存在
    mkdir -p hivision/creator/weights
    mkdir -p hivision/creator/retinaface/weights
    
    case $mode in
        "required")
            log_info "Downloading required models..."
            if python3 scripts/download_model.py --models hivision_modnet modnet_photographic_portrait_matting; then
                log_success "Required models downloaded successfully"
            else
                log_error "Failed to download required models"
                return 1
            fi
            ;;
        "all")
            log_info "Downloading all available models..."
            if python3 scripts/download_model.py --models all; then
                log_success "All models downloaded successfully"
            else
                log_warning "Some models failed to download, but continuing..."
            fi
            ;;
        *)
            log_error "Unknown download mode: $mode"
            return 1
            ;;
    esac
}

# 验证模型文件
verify_models() {
    log_info "Verifying model files..."
    
    local weights_dir="hivision/creator/weights"
    
    if [ -d "$weights_dir" ]; then
        log_info "Contents of $weights_dir:"
        ls -la "$weights_dir/" || true
    else
        log_error "Weights directory does not exist: $weights_dir"
        return 1
    fi
    
    # 检查至少有一个必需的模型文件
    if [ -f "$weights_dir/hivision_modnet.onnx" ] || [ -f "$weights_dir/modnet_photographic_portrait_matting.onnx" ]; then
        log_success "At least one required model file found"
        return 0
    else
        log_error "No required model files found!"
        return 1
    fi
}

# 主函数
main() {
    if [ "$BUILD_MODE" = "true" ]; then
        log_info "Running in BUILD mode"
        
        # 构建时模式：尝试下载但不强制成功
        if ! download_models "required"; then
            log_warning "Build-time model download failed, models will be downloaded at runtime"
        fi
        
        # 构建时不需要启动应用
        return 0
    else
        log_info "Running in RUNTIME mode"
        log_info "Starting HivisionIDPhotos container..."
        
        # 运行时模式：检查模型并在需要时下载
        missing_count=$(check_models)
        
        if [ "$missing_count" -gt 0 ]; then
            log_warning "Missing $missing_count required model(s), downloading..."
            if ! download_models "required"; then
                log_error "Failed to download required models"
                exit 1
            fi
        else
            log_success "All required models are present"
        fi
        
        # 验证模型
        if ! verify_models; then
            log_error "Model verification failed"
            exit 1
        fi
        
        # 启动应用
        if [ $# -gt 1 ]; then
            log_info "Starting application with command: ${*:2}"
            exec "${@:2}"
        else
            log_info "No command specified, exiting"
            exit 0
        fi
    fi
}

# 脚本入口
main "$@"