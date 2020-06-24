# 2020_itolab_hackason
表情じゃんけんゲーム

# テストサーバー(ローカル)の立ち上げ方
dockerをインストール済みの場合
コマンドラインで/serverフォルダに移動し
```2020_itolab_hackason/server> docker-compose up```

dockerのインストール方法は以下を参照(コマンドで確認するとこまで)

https://qiita.com/ama_keshi/items/b4c47a4aca5d48f2661c

テストサーバー(aws)もそのうち立ち上げます

# アプリとサーバー間の通信(websocket+json)
**()はテスト用の通信**
```
アプリ側:サーバーに接続
(サーバー側:クライアント全員に接続のメッセージを送る)**jsonじゃない**
アプリ側:{"type";"Matching"}のjsonを投げる
サーバー側:相手が見つからない場合は{"type":"Matching","res": "Waiting"}
見つかった場合は{"type":"Matching","res": "Found", "gu":?? ,"tyoki":?? ,"pa":??}
アプリ側:
```
