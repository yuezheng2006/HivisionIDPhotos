# HivisionIDPhotos Docker 部署指南

## 🔧 问题解决

### 原始错误
线上部署时出现的错误：
```
ValueError: 未找到任何存在的人像分割模型，请检查 hivision/creator/weights 目录下的文件
```

### ✅ 解决方案
已完全修复部署配置：
- 🤖 **智能模型管理**: 自动检查和下载必需的AI模型
- 🔄 **双重保障**: 构建时和运行时都会确保模型存在
- 📊 **健康检查**: Docker Compose内置健康检查
- 🚀 **简化部署**: 专注Docker模式，开箱即用

## 🚀 Docker 部署

### 方式一：Docker Compose（推荐）

```bash
# 启动所有服务
docker-compose up -d

# 启动Web界面服务（端口7860）
docker-compose up -d hivision_idphotos

# 启动API服务（端口8080）
docker-compose up -d hivision_idphotos_api

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 方式二：Docker 命令

```bash
# 构建镜像
docker build -t hivision_idphotos .

# 运行Web界面
docker run -p 7860:7860 hivision_idphotos

# 运行API服务
docker run -p 8080:8080 hivision_idphotos false python3 deploy_api.py
```

## 🌐 访问地址

| 服务 | 端口 | 访问地址 | 功能描述 |
|------|------|----------|----------|
| **Web界面** | 7860 | http://localhost:7860 | Gradio图形界面，用户友好 |
| **API服务** | 8080 | http://localhost:8080/docs | FastAPI接口文档和测试 |

## 🛠 环境要求

- **Docker**: >= 20.10
- **Docker Compose**: >= 1.29
- **内存**: >= 2GB 可用内存
- **存储**: >= 5GB 可用空间（用于模型文件）
- **网络**: 稳定的互联网连接（首次下载模型）

## ⚡ 启动流程

### 首次启动
1. **构建镜像**: 下载基础镜像，安装依赖
2. **下载模型**: 自动下载AI模型文件（约200-500MB）
3. **启动服务**: 启动Web界面和API服务
4. **健康检查**: 自动检测服务状态

**时间预估**: 首次启动3-5分钟，后续启动30秒内

## 🔧 故障排除

### 模型下载失败
```bash
# 手动下载模型
docker exec -it <container_id> python3 scripts/download_model.py --models all

# 检查模型文件
docker exec -it <container_id> ls -la hivision/creator/weights/
```

### 端口冲突
修改 `docker-compose.yml`:
```yaml
ports:
  - '7861:7860'  # Web界面改为7861端口
  - '8081:8080'  # API服务改为8081端口
```

### 内存不足
```bash
# 增加Docker内存限制
docker run --memory=4g -p 7860:7860 hivision_idphotos
```

## 📡 API使用示例

### 证件照制作
```bash
curl -X POST "http://localhost:8080/idphoto" \
  -H "Content-Type: multipart/form-data" \
  -F "input_image=@photo.jpg" \
  -F "height=413" \
  -F "width=295"
```

### 人像抠图
```bash
curl -X POST "http://localhost:8080/human_matting" \
  -H "Content-Type: multipart/form-data" \
  -F "input_image=@photo.jpg"
```

## 🎯 验证部署

```bash
# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs

# 手动验证
curl http://localhost:7860/      # Web界面
curl http://localhost:8080/docs  # API文档
```

## 📊 模型文件说明

| 模型文件 | 大小 | 用途 | 必需性 |
|----------|------|------|--------|
| `hivision_modnet.onnx` | ~25MB | 人像分割 | ✅ 必需 |
| `modnet_photographic_portrait_matting.onnx` | ~25MB | 人像分割 | ✅ 必需 |
| `rmbg-1.4.onnx` | ~176MB | 背景移除 | 🔶 可选 |
| `birefnet-v1-lite.onnx` | ~50MB | 精细分割 | 🔶 可选 |

成功部署的标志：
- ✅ 容器正常启动无错误日志
- ✅ 模型文件下载完成
- ✅ Web界面可正常访问
- ✅ API文档页面可正常打开