# 🚀 Portainer + Load Balancer Integration

**Get your Elixir Load Balancer working with Portainer on Windows in minutes!**

## ⚡ Quick Start

### 1. Start Everything
```bash
./start-portainer-stack.sh
```

### 2. Configure Hosts File
**Windows (PowerShell as Administrator):**
```powershell
.\scripts\setup-windows-hosts.ps1
```

**Linux/WSL2:**
```bash
sudo ./scripts/setup-linux-hosts.sh
```

### 3. Access Services
- **Portainer**: http://portainer.local:9000
- **Load Balancer**: http://lb.local:4000
- **Test Apps**: http://web.local:8080

## 🎯 What You Get

✅ **Portainer** - Container management dashboard  
✅ **Load Balancer** - Traffic distribution with health checks  
✅ **Test Apps** - Two nginx instances for testing  
✅ **Local Domains** - Easy access via `.local` domains  
✅ **Health Monitoring** - Automatic container health checks  
✅ **Load Balancing** - Round-robin, least connections, IP hash  

## 🔧 How It Works

The load balancer runs in Docker alongside Portainer, with access to the Docker socket for container discovery and management. It automatically routes traffic based on domain names and performs health checks on your containers.

## 📚 Full Documentation

See [PORTAINER_INTEGRATION.md](PORTAINER_INTEGRATION.md) for complete setup instructions, troubleshooting, and advanced configuration.

## 🆘 Need Help?

1. Check the troubleshooting section in the full guide
2. Run `docker-compose logs` to see service logs
3. Verify your hosts file configuration
4. Ensure Docker Desktop is running

---

**Happy Load Balancing! 🎉**
