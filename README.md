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
アプリ側:
  サーバーに接続
(サーバー側:
  クライアント全員に接続のメッセージを送る)
アプリ側:#マッチング要求
  {"type";"Matching"}
サーバー側:
  相手が見つからない場合　{"type":"Matching","res": "Waiting"}
　見つかった場合　{"type":"Matching","res": "Found", "gu":?? ,"tyoki":?? ,"pa":??}
アプリ側:#画像の送信と結果要求
  {"type":"Judgement","image": base64エンコードされた画像}
サーバー側:
  {"type":"Judgment","res": "Result","your_hand": 自分の手,"your_emotion": 自分の表情, "your_prob": 自分の確率, "hand": 相手の手,"emotion": 相手の表情, "prob": 相手の確率}
```
**エラーなどの場合(サーバーからの送信)**
```
matching
  既にマッチング待機中
  {"type":"Matching","res": "Waiting" }
  対戦状態の場合
  {"type":"Warning","res": "Exist" }
Judgement
  マッチングしていない場合
  {"type":"Warning", "res":"Not Matching"}
切断
  対戦中に相手が切断した場合
  {"type":"Warning","res": "Leave" }
```
