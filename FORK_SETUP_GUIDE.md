# Fork 仓库配置指南

## 📋 目录
1. [启用 GitHub Actions](#启用-github-actions)
2. [配置签名密钥（可选）](#配置签名密钥可选)
3. [使用构建功能](#使用构建功能)
4. [自动同步上游](#自动同步上游)
5. [常见问题](#常见问题)

---

## 🚀 启用 GitHub Actions

### 步骤 1：在 GitHub 仓库中启用 Actions
1. 访问你的 fork 仓库：`https://github.com/rong6/ClashMetaForAndroid`
2. 点击顶部的 **Actions** 标签
3. 如果提示需要启用，点击 **"I understand my workflows, go ahead and enable them"**

### 步骤 2：配置仓库权限
1. 进入 **Settings** → **Actions** → **General**
2. 在 **Workflow permissions** 部分：
   - 选择 **"Read and write permissions"**
   - 勾选 **"Allow GitHub Actions to create and approve pull requests"**
3. 点击 **Save**

---

## 🔑 配置签名密钥（可选但推荐）

如果你想要构建已签名的 APK（用于正式发布或直接安装），需要配置签名密钥。

### 方式 1：使用自动化脚本生成（推荐）

我已经为你准备了一键生成脚本，会自动生成密钥并准备好配置信息：

```bash
# 给脚本添加执行权限
chmod +x generate-keystore.sh

# 运行脚本
./generate-keystore.sh
```

脚本会引导你完成以下步骤：
1. ✅ 设置密钥库名称和别名
2. ✅ 设置安全密码
3. ✅ 输入证书信息（姓名、组织等）
4. ✅ 自动生成密钥文件（.jks）
5. ✅ 自动生成 Base64 编码
6. ✅ 生成配置摘要文件，包含所有需要的信息
7. ✅ 自动添加到 .gitignore，防止泄露

**运行完成后，你会得到：**
- `cmfa-release-key.jks` - 密钥文件（妥善保管！）
- `cmfa-release-key.jks.base64.txt` - Base64 编码（用于 GitHub Secrets）
- `keystore-config-summary.txt` - 完整的配置信息

### 方式 2：手动生成

如果你更喜欢手动操作：

```bash
# 使用 keytool 生成密钥
keytool -genkeypair -v \
  -keystore cmfa-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias cmfa-key

# 生成 Base64 编码（Linux/Mac）
base64 -w 0 cmfa-release-key.jks > cmfa-release-key.jks.base64.txt

# 或 Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cmfa-release-key.jks")) | Out-File -Encoding ASCII cmfa-release-key.jks.base64.txt
```

**需要记录以下信息：**
- Keystore 密码
- Key alias（别名）
- Key 密码

### 配置 GitHub Secrets

#### 步骤 1：访问 Secrets 设置页面

直接访问：https://github.com/rong6/ClashMetaForAndroid/settings/secrets/actions

或手动导航：
1. 进入仓库 **Settings** 标签
2. 左侧菜单选择 **Secrets and variables** → **Actions**
3. 点击绿色的 **New repository secret** 按钮

#### 步骤 2：逐个添加以下 4 个 Secrets

如果你使用了 `generate-keystore.sh` 脚本，所有信息都在 `keystore-config-summary.txt` 文件中。

| Secret 名称 | 说明 | 从哪里获取 |
|------------|------|-----------|
| `KEYSTORE_BASE64` | Base64 编码的 keystore 文件 | 复制 `*.base64.txt` 文件的全部内容 |
| `SIGNING_STORE_PASSWORD` | Keystore 密码 | 生成密钥时设置的密码 |
| `SIGNING_KEY_ALIAS` | Key 别名 | 生成密钥时设置的别名（默认：cmfa-key）|
| `SIGNING_KEY_PASSWORD` | Key 密码 | 生成密钥时设置的密码 |

**添加示例：**
1. 点击 **New repository secret**
2. Name 填写：`KEYSTORE_BASE64`
3. Secret 粘贴：`*.base64.txt` 文件的完整内容
4. 点击 **Add secret**
5. 重复以上步骤添加其他 3 个密钥

#### 步骤 3：验证配置

添加完成后，你应该在 Secrets 页面看到 4 个密钥：
- ✅ KEYSTORE_BASE64
- ✅ SIGNING_STORE_PASSWORD
- ✅ SIGNING_KEY_ALIAS
- ✅ SIGNING_KEY_PASSWORD

### 签名功能已自动启用 ✅

我已经在 [.github/workflows/build-fork.yaml](.github/workflows/build-fork.yaml) 中启用了签名构建功能，无需额外操作。

**工作方式：**
- 🔧 选择 **debug** 类型：构建未签名的 Alpha 版本
- ✅ 选择 **release** 类型：构建已签名的 Meta 正式版本（需要配置上述 Secrets）
- 🚀 推送代码到 main：自动构建未签名的 Alpha 版本

---

## 🛠️ 使用构建功能

### 方式 1：自动构建（推送触发）

每次推送代码到 `main` 分支时，自动触发构建：

```bash
git add .
git commit -m "Your changes"
git push origin main
```

### 方式 2：手动构建

1. 访问 **Actions** 标签
2. 选择 **"Build Fork APK"** workflow
3. 点击 **"Run workflow"** 下拉按钮
4. 选择构建类型：
   - **debug**: 未签名的 Alpha 版本（alphaRelease）
   - **release**: 已签名的 Meta 正式版本（metaRelease，需要先配置签名密钥）
5. 点击绿色的 **"Run workflow"** 按钮
6. 等待构建完成（约 15-30 分钟）

**提示：** 
- 如果选择 release 但未配置签名密钥，构建会提示警告但仍会尝试构建
- debug 版本可以直接安装测试，但需要在手机上允许安装未知来源

### 下载构建的 APK

构建完成后，下载编译好的 APK：

1. 进入 **Actions** 标签
2. 点击对应的构建任务（绿色✅表示成功）
3. 滚动到页面底部的 **Artifacts** 部分
4. 下载你需要的架构版本

#### APK 文件说明

| 文件名 | 架构 | 推荐用途 | 文件大小 |
|--------|------|----------|---------|
| `CMFA-x.x.x-arm64-v8a-xxx.apk` | 64位 ARM | ⭐ **推荐** - 适合大部分现代 Android 手机 | 较小 |
| `CMFA-x.x.x-armeabi-v7a-xxx.apk` | 32位 ARM | 旧版手机、低端设备 | 较小 |
| `CMFA-x.x.x-universal-xxx.apk` | 通用 | 兼容所有设备，但体积最大 | 最大 |
| `CMFA-x.x.x-x86_64-xxx.apk` | 64位 x86 | 模拟器、平板电脑 | 较小 |

**如何选择？**
- ✅ **不确定用哪个**：下载 arm64-v8a（适合 99% 的现代手机）
- ✅ **想要最小体积**：根据你的设备架构选择对应版本
- ✅ **想要最大兼容性**：下载 universal（但体积会大很多）

**查看手机架构：**
```bash
# 如果你的手机已安装 Termux 或类似工具
uname -m
# 输出 aarch64 → 使用 arm64-v8a
# 输出 armv7l → 使用 armeabi-v7a
```

或使用 [CPU-Z](https://play.google.com/store/apps/details?id=com.cpuid.cpu_z) 等应用查看

---

## 🔄 自动同步上游

我已经创建了 [sync-upstream.yaml](.github/workflows/sync-upstream.yaml) workflow，它会：

### 功能特性
- ✅ 每天自动同步上游 MetaCubeX/ClashMetaForAndroid 的更新
- ✅ 自动保护你的自定义文件：
  - `app/src/main/res/` 目录下的所有文件
  - `app/src/main/ic_launcher-playstore.png`
  - `app/src/main/ic_launcher-web.png`
- ✅ 如果有冲突，自动创建 PR 提醒你手动处理

### 手动同步

如果想立即同步：
1. 访问 **Actions** → **"Sync from Upstream"**
2. 点击 **"Run workflow"**
3. 点击绿色的 **"Run workflow"** 按钮

### 修改同步频率

编辑 [.github/workflows/sync-upstream.yaml](.github/workflows/sync-upstream.yaml) 的第 5 行：

```yaml
- cron: '0 0 * * 0'  # 每周日同步一次
```

可选的频率：
- `'0 */6 * * *'` - 每 6 小时
- `'0 0 * * *'` - 每天
- `'0 0 1 * *'` - 每月 1 号

---

## ❓ 常见问题

### Q1: 构建失败提示 "Gradle sync failed"
**A:** 可能是子模块未正确初始化，在本地运行：
```bash
git submodule update --init --recursive --force
git add .
git commit -m "Update submodules"
git push
```

### Q2: 如何生成签名密钥？
**A:** 使用我提供的脚本最简单：
```bash
chmod +x generate-keystore.sh
./generate-keystore.sh
```
按照提示完成后，查看 `keystore-config-summary.txt` 文件获取所有需要的配置信息。

### Q3: 忘记了 keystore 密码怎么办？
**A:** 不幸的是，keystore 密码无法找回。你需要：
1. 重新生成新的密钥
2. 使用新密钥重新签名并发布应用
3. ⚠️ 注意：这会导致用户无法直接升级，需要卸载重装

建议：将密码保存在密码管理器中（如 1Password、Bitwarden）

### Q4: 如何添加更多保护文件？
**A:** 编辑 [sync-upstream.yaml](.github/workflows/sync-upstream.yaml)，在 `Restore Custom Files` 步骤中添加：
```yaml
git checkout HEAD -- 你的文件路径 || true
```

也可以在 [.gitattributes](.gitattributes) 中添加：
```
你的文件路径 merge=ours
```

### Q5: 构建时间太长，如何加速？
**A:** 
- 第一次构建需要 20-30 分钟（下载依赖、编译 Go Core）
- 后续构建有缓存，约 10-15 分钟
- 推送代码时避免频繁触发，可以使用 `[skip ci]` 在 commit message 中

### Q6: Debug 版本 APK 无法安装
**A:** Debug 版本未签名，需要：
- **方案 1（推荐）**：配置签名密钥，使用 release 类型构建
- **方案 2**：在手机上启用"允许安装未知来源应用"
  - 设置 → 安全 → 未知来源 → 允许该来源

### Q7: 如何验证 APK 已正确签名？
**A:** 使用以下命令检查：
```bash
# 查看签名信息
keytool -printcert -jarfile app-release.apk

# 或使用 apksigner
apksigner verify --verbose app-release.apk
```

已签名的 APK 会显示证书信息和签名者。

### Q8: 同步上游时发生冲突怎么办？
**A:** workflow 会自动创建一个 PR，你需要：
1. 查看 PR 中的冲突文件
2. 在本地检出该分支：
   ```bash
   git fetch origin
   git checkout sync-upstream-conflict
   ```
3. 手动解决冲突，提交并推送
4. 合并 PR

### Q9: GitHub Actions 消耗配额怎么办？
**A:** 
- **免费账户**：每月 2000 分钟 (Linux)
- 单次构建约 20-30 分钟
- 如果配额不够：
  - 减少自动同步频率（改为每周或手动）
  - 使用 `paths-ignore` 避免不必要的构建
  - 升级到 GitHub Pro（每月 3000 分钟）

### Q10: 如何停止自动同步？
**A:** 
- **方案 1**：禁用 workflow
  - Actions → Sync from Upstream → 右上角 `···` → Disable workflow
- **方案 2**：删除文件
  ```bash
  git rm .github/workflows/sync-upstream.yaml
  git commit -m "Disable auto sync"
  git push
  ```

### Q11: release 版本和 debug 版本有什么区别？
**A:** 

| 特性 | Debug (Alpha) | Release (Meta) |
|------|---------------|----------------|
| 签名状态 | ❌ 未签名 | ✅ 已签名 |
| 可直接安装 | 需要开启未知来源 | 可直接安装 |
| 代码优化 | 较少 | ProGuard 优化 |
| 体积 | 较大 | 较小 |
| 调试信息 | 包含 | 已移除 |
| 适用场景 | 快速测试 | 正式发布 |

### Q12: 如何查看详细的构建日志？
**A:** 
1. Actions → 选择对应的构建任务
2. 点击任务名称进入详情页
3. 展开各个步骤查看输出
4. 点击右上角的齿轮图标可以下载完整日志

### Q13: KEYSTORE_BASE64 内容太长，无法复制？
**A:** 
- 使用脚本生成的 `.base64.txt` 文件
- 用文本编辑器打开，Ctrl+A 全选，Ctrl+C 复制
- 或使用命令直接复制到剪贴板：
  ```bash
  # Linux
  cat *.base64.txt | xclip -selection clipboard
  # Mac  
  cat *.base64.txt | pbcopy
  # Windows (PowerShell)
  Get-Content *.base64.txt | Set-Clipboard
  ```

---

## 📝 下一步

- [ ] 提交这些新文件到仓库
- [ ] 在 GitHub 上启用 Actions
- [ ] 配置仓库权限
- [ ] （可选）配置签名密钥
- [ ] 运行第一次构建测试

## 🔗 相关链接

- [GitHub Actions 文档](https://docs.github.com/actions)
- [Android 应用签名](https://developer.android.com/studio/publish/app-signing)
- [上游仓库](https://github.com/MetaCubeX/ClashMetaForAndroid)

---

**需要帮助？** 在 Issues 中提问或查看上游仓库的文档。
