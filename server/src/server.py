from websocket_server import WebsocketServer
from datetime import datetime
import json
from collections import deque

#properties
matching_queue = deque()#マッチング待機キュー
matching_list = deque()#対戦ペアを格納するリスト
judgment_queue = deque()#結果待機キュー

#コネクション接続時に呼ばれる関数
def new_client(client, server):
    #コネクションを確立している全体に送信
    server.send_message_to_all(datetime.now().isoformat() + ": new client joined!")

#クライアント側からメッセージが飛んできたとき
def message_recieve(client, server, message):
    #メッセージを送ってきたクライアントに送信
    server.send_message(client,"client send : " + message)
    print(message)

    #jsonのparse
    data_json = json.loads(message)

    #connect(マッチング処理)
    if data_json['type'] == "Matching":
        #マッチング不成立ならマッチングの待機キューに追加
        if len(matching_queue) == 0:
            matching_queue.append(client)
            server.send_message(client,json.dumps({"type":"Matching","res": "Waiting" }))
        else:
            rival = matching_queue.pop()
            matching_list.append([rival,client])
            #どの表情をどの手にするかの決定

            #clientへの通知
            server.send_message(client,json.dumps({"type":"Matching","res": "Found"}))
            server.send_message(rival,json.dumps({"type":"Matching","res": "Found"}))

    #判定処理
    if data_json['type'] == "Judgment":
        #jsonから画像を取得判定、相手が終わるまでjudgment_queueに格納


        #対戦ペアをリストから削除
        for i in matching_list:
            if client in matching_list[i]:
                matching_list.remove(matching_list[i])

        #結果の送信

#コネクション切断時の処理
def client_left(client,server):
    return

server = WebsocketServer(7532, host="0.0.0.0")
server.set_fn_new_client(new_client)
server.set_fn_message_received(message_recieve)
server.set_fn_client_left(client_left)
server.run_forever()
