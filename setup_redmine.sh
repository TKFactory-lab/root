#!/bin/bash

# ユーザーを作成するためのスクリプト
# RedmineのDockerイメージにログインして以下を実行する

# ユーザー情報: ログインID, メールアドレス, 名, 姓, パスワード, 管理者フラグ(1:Admin, 0:Member)
USERS=(
    "ktakada,roket.19780310@gmail.com,Kentaro,Takada,password,1"
    "nobu,nobunaga.oda@example.com,Nobunaga,Oda,password,1"
    "hide,hide.toyotomi@example.com,Hide,Toyotomi,password,0"
    "yasu,ieyasu.tokugawa@example.com,Ieyasu,Tokugawa,password,0"
)

for user in "${USERS[@]}"; do
    IFS=',' read -r login email firstname lastname password admin_flag <<< "$user"

    # RedmineのRakeタスクを使ってユーザーを作成
    # デフォルトのユーザーはID=1なので、IDが重複しないようにする
    if ! bundle exec rake redmine:user:list | grep -q "$login"; then
        echo "Creating user $login..."
        bundle exec rake redmine:user:create --trace <<EOF
$login
$email
$firstname
$lastname
$password
$password
$admin_flag
EOF
    else
        echo "User $login already exists."
    fi
done

# プロジェクトの作成（オプション）
# 例: SimpleWebAppというプロジェクトを作成
if ! bundle exec rake redmine:project:list | grep -q "SimpleWebApp"; then
    echo "Creating project SimpleWebApp..."
    bundle exec rake redmine:project:create name="SimpleWebApp" identifier="simple-webapp"
else
    echo "Project SimpleWebApp already exists."
fi

# スクリプトの実行完了を通知
echo "Redmine setup script finished."