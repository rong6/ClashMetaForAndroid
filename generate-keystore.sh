#!/bin/bash

echo "================================================"
echo "  Android 签名密钥生成助手"
echo "================================================"
echo ""
echo "此脚本将帮助你生成 Android APK 签名所需的密钥文件"
echo ""

# 设置默认值
DEFAULT_KEYSTORE="cmfa-release-key.jks"
DEFAULT_ALIAS="cmfa-key"
DEFAULT_VALIDITY="10000"

# 输入密钥库名称
read -p "密钥库文件名 (默认: $DEFAULT_KEYSTORE): " KEYSTORE_NAME
KEYSTORE_NAME=${KEYSTORE_NAME:-$DEFAULT_KEYSTORE}

# 输入别名
read -p "密钥别名 (默认: $DEFAULT_ALIAS): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-$DEFAULT_ALIAS}

# 输入密钥库密码
echo ""
echo "⚠️  请设置密钥库密码（至少6个字符，请牢记）"
read -sp "密钥库密码: " STORE_PASSWORD
echo ""
read -sp "确认密钥库密码: " STORE_PASSWORD_CONFIRM
echo ""

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo "❌ 密码不匹配，请重新运行脚本"
    exit 1
fi

if [ ${#STORE_PASSWORD} -lt 6 ]; then
    echo "❌ 密码太短，至少需要6个字符"
    exit 1
fi

# 输入密钥密码
echo ""
echo "设置密钥密码（可以与密钥库密码相同）"
read -sp "密钥密码 (直接回车使用相同密码): " KEY_PASSWORD
echo ""

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$STORE_PASSWORD"
    echo "✓ 使用相同的密码"
fi

# 输入个人信息
echo ""
echo "请输入证书信息（用于标识密钥所有者）"
read -p "姓名 (CN): " CN
read -p "组织单位 (OU, 可选): " OU
read -p "组织 (O, 可选): " O
read -p "城市 (L, 可选): " L
read -p "省份 (ST, 可选): " ST
read -p "国家代码 (C, 如: CN, 可选): " C

# 构建 dname 参数
DNAME="CN=$CN"
[ ! -z "$OU" ] && DNAME="$DNAME, OU=$OU"
[ ! -z "$O" ] && DNAME="$DNAME, O=$O"
[ ! -z "$L" ] && DNAME="$DNAME, L=$L"
[ ! -z "$ST" ] && DNAME="$DNAME, ST=$ST"
[ ! -z "$C" ] && DNAME="$DNAME, C=$C"

echo ""
echo "================================================"
echo "准备生成密钥，请确认以下信息："
echo "================================================"
echo "密钥库文件: $KEYSTORE_NAME"
echo "密钥别名: $KEY_ALIAS"
echo "有效期: $DEFAULT_VALIDITY 天 (约27年)"
echo "证书信息: $DNAME"
echo "================================================"
echo ""
read -p "确认无误？(y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消"
    exit 0
fi

# 检查 keytool
if ! command -v keytool &> /dev/null; then
    echo "❌ 错误: 未找到 keytool 命令"
    echo "   请确保已安装 JDK 并配置了环境变量"
    exit 1
fi

# 生成密钥
echo ""
echo "🔧 正在生成密钥..."
echo ""

keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_NAME" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$DEFAULT_VALIDITY" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "$DNAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  ✅ 密钥生成成功！"
    echo "================================================"
    echo ""
    echo "📁 密钥文件: $KEYSTORE_NAME"
    echo ""
    echo "⚠️  请妥善保管以下信息（需要配置到 GitHub Secrets）："
    echo ""
    echo "----------------------------------------"
    echo "密钥库密码 (SIGNING_STORE_PASSWORD):"
    echo "$STORE_PASSWORD"
    echo ""
    echo "密钥别名 (SIGNING_KEY_ALIAS):"
    echo "$KEY_ALIAS"
    echo ""
    echo "密钥密码 (SIGNING_KEY_PASSWORD):"
    echo "$KEY_PASSWORD"
    echo "----------------------------------------"
    echo ""
    
    # 生成 base64
    echo "正在生成 Base64 编码（用于 KEYSTORE_BASE64）..."
    echo ""
    
    if command -v base64 &> /dev/null; then
        KEYSTORE_BASE64=$(base64 -w 0 "$KEYSTORE_NAME" 2>/dev/null || base64 "$KEYSTORE_NAME" | tr -d '\n')
        
        # 保存到文件
        echo "$KEYSTORE_BASE64" > "${KEYSTORE_NAME}.base64.txt"
        
        echo "✅ Base64 编码已保存到: ${KEYSTORE_NAME}.base64.txt"
        echo ""
        echo "📋 Base64 内容前100个字符预览："
        echo "${KEYSTORE_BASE64:0:100}..."
        echo ""
    else
        echo "⚠️  无法生成 Base64，请手动执行："
        echo "   base64 -w 0 $KEYSTORE_NAME > ${KEYSTORE_NAME}.base64.txt"
        echo ""
    fi
    
    # 生成配置摘要文件
    cat > "keystore-config-summary.txt" <<EOF
================================================
Android 签名密钥配置信息
================================================
生成时间: $(date)

密钥文件: $KEYSTORE_NAME
密钥别名: $KEY_ALIAS
证书信息: $DNAME

================================================
GitHub Secrets 配置（需要在仓库设置中添加）
================================================

1. KEYSTORE_BASE64
   值: 见 ${KEYSTORE_NAME}.base64.txt 文件内容

2. SIGNING_STORE_PASSWORD
   值: $STORE_PASSWORD

3. SIGNING_KEY_ALIAS
   值: $KEY_ALIAS

4. SIGNING_KEY_PASSWORD
   值: $KEY_PASSWORD

================================================
下一步操作
================================================

1. 访问 GitHub 仓库: https://github.com/rong6/ClashMetaForAndroid

2. 进入 Settings → Secrets and variables → Actions

3. 点击 "New repository secret"，逐个添加上述 4 个密钥

4. 确保 .github/workflows/build-fork.yaml 中的签名步骤已启用

5. 运行 workflow 测试签名构建

================================================
安全提示
================================================

⚠️  请妥善保管 $KEYSTORE_NAME 文件和密码！
   - 不要提交到 Git 仓库
   - 建议备份到安全的地方
   - 丢失后无法找回，需要重新生成并重新发布应用

EOF
    
    echo "✅ 配置摘要已保存到: keystore-config-summary.txt"
    echo ""
    echo "================================================"
    echo "📚 下一步操作"
    echo "================================================"
    echo ""
    echo "1. 查看配置信息:"
    echo "   cat keystore-config-summary.txt"
    echo ""
    echo "2. 复制 Base64 内容（用于 GitHub Secrets）:"
    echo "   cat ${KEYSTORE_NAME}.base64.txt"
    echo ""
    echo "3. 配置 GitHub Secrets:"
    echo "   访问: https://github.com/rong6/ClashMetaForAndroid/settings/secrets/actions"
    echo ""
    echo "4. 将生成的文件添加到 .gitignore（避免泄露）:"
    echo "   echo '*.jks' >> .gitignore"
    echo "   echo '*.base64.txt' >> .gitignore"
    echo "   echo 'keystore-config-summary.txt' >> .gitignore"
    echo ""
    
    # 自动添加到 .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q "*.jks" .gitignore; then
            echo "" >> .gitignore
            echo "# Android 签名密钥文件（敏感信息）" >> .gitignore
            echo "*.jks" >> .gitignore
            echo "*.keystore" >> .gitignore
            echo "*.base64.txt" >> .gitignore
            echo "keystore-config-summary.txt" >> .gitignore
            echo "signing.properties" >> .gitignore
            echo "✅ 已自动添加到 .gitignore"
        fi
    fi
    
    echo ""
    echo "完成！请查看 keystore-config-summary.txt 了解详细配置步骤。"
    
else
    echo ""
    echo "❌ 密钥生成失败，请检查错误信息"
    exit 1
fi
