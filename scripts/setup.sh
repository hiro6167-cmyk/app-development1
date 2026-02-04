#!/bin/bash

# PositiveVoice Setup Script
# このスクリプトは開発環境をセットアップします

set -e

echo "================================================"
echo "  PositiveVoice セットアップスクリプト"
echo "================================================"
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 関数定義
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 がインストールされています"
        return 0
    else
        echo -e "${RED}✗${NC} $1 がインストールされていません"
        return 1
    fi
}

# 1. 前提条件のチェック
echo "📋 前提条件をチェック中..."
echo ""

MISSING_DEPS=0

check_command "xcode-select" || MISSING_DEPS=1
check_command "aws" || MISSING_DEPS=1
check_command "sam" || MISSING_DEPS=1
check_command "python3" || MISSING_DEPS=1

echo ""

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${YELLOW}⚠️  不足しているツールをインストールしてください:${NC}"
    echo ""
    echo "  Xcode Command Line Tools:"
    echo "    xcode-select --install"
    echo ""
    echo "  AWS CLI:"
    echo "    brew install awscli"
    echo ""
    echo "  AWS SAM CLI:"
    echo "    brew install aws-sam-cli"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ 全ての前提条件が満たされています${NC}"
echo ""

# 2. iOS依存関係のインストール
echo "📱 iOS依存関係をセットアップ中..."
echo ""

cd "$(dirname "$0")/../PositiveVoice"

# Swift Package Managerの依存関係を解決
if [ -f "Package.swift" ]; then
    echo "  Swift Packageの依存関係を解決中..."
    swift package resolve || echo -e "${YELLOW}⚠️  Package解決に失敗しました。Xcodeで開いて解決してください${NC}"
fi

echo ""

# 3. バックエンドの設定
echo "☁️  AWSバックエンドをセットアップ中..."
echo ""

cd "$(dirname "$0")/../backend"

# AWS認証情報の確認
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓ AWS認証情報が設定されています${NC}"

    # デプロイするかどうか確認
    read -p "バックエンドをデプロイしますか？ (y/N): " DEPLOY_BACKEND

    if [[ $DEPLOY_BACKEND =~ ^[Yy]$ ]]; then
        echo ""
        echo "  SAMビルド中..."
        sam build

        echo ""
        echo "  SAMデプロイ中..."
        sam deploy --guided
    fi
else
    echo -e "${YELLOW}⚠️  AWS認証情報が設定されていません${NC}"
    echo "  'aws configure' を実行して設定してください"
fi

echo ""

# 4. Amplify設定の更新案内
echo "📝 次のステップ:"
echo ""
echo "  1. Xcodeでプロジェクトを開く:"
echo "     open PositiveVoice/PositiveVoice.xcodeproj"
echo ""
echo "  2. amplifyconfiguration.json を更新:"
echo "     - YOUR_USER_POOL_ID"
echo "     - YOUR_APP_CLIENT_ID"
echo "     - YOUR_IDENTITY_POOL_ID"
echo "     - YOUR_API_GATEWAY_ENDPOINT"
echo "     - YOUR_S3_BUCKET_NAME"
echo ""
echo "  3. Apple Developer設定:"
echo "     - Sign in with Apple を有効化"
echo "     - Bundle ID を設定"
echo ""
echo "  4. シミュレーターで実行:"
echo "     Cmd + R"
echo ""
echo "================================================"
echo -e "${GREEN}セットアップ完了！${NC}"
echo "================================================"
