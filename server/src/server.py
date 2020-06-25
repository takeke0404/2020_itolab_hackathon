from websocket_server import WebsocketServer
from datetime import datetime
import json
from collections import deque

#properties
matching_queue = deque()#マッチング待機キュー
matching_list = list()#対戦ペアを格納するリスト
matching_user = list()#対戦状態にあるクライアントのリスト
judgment_list = list()#結果待機リスト

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
        #既にマッチング済み、待機キューに追加済みの際のエラー処理
        if client in matching_queue:
            server.send_message(client,json.dumps({"type":"Matching","res": "Waiting" }))
            return
        elif client in matching_user:
            server.send_message(client,json.dumps({"type":"Matching","res": "Exist" }))
            return

        #マッチング不成立ならマッチングの待機キューに追加
        if len(matching_queue) == 0:
            matching_queue.append(client)
            server.send_message(client,json.dumps({"type":"Matching","res": "Waiting" }))
        else:
            rival = matching_queue.pop()
            #対戦リストへの追加
            matching_card = [rival,client]
            matching_list.append(matching_card)
            matching_user.append(client)
            matching_user.append(rival)
            client['rival'] = rival
            client['matching'] = matching_card
            rival['rival'] = client
            rival['matching'] = matching_card

            #どの表情をどの手にするかの決定

            #clientへの通知
            server.send_message(client,json.dumps({"type":"Matching","res": "Found"}))
            server.send_message(rival,json.dumps({"type":"Matching","res": "Found"}))

    #判定処理
    if data_json['type'] == "Judgment":
        #jsonから画像を取得判定、相手が終わるまでjudgment_listに格納


        #対戦ペアをリストから削除
        matching_list.remove(client['matching'])

        #結果の送信

#コネクション切断時の処理
def client_left(client,server):
    #待機キューに存在する場合
    if client in matching_queue:
        matching_queue.remove(client)
        return
    #対戦中
    if client in matching_user:
        matching_list.remove(client['matching'])
        matching_user.remove(client)
        matching_user.remove(client['rival'])
        server.send_message(client['rival'],json.dumps({"type":"Warning","res": "Leave" }))
        return

server = WebsocketServer(7532, host="0.0.0.0")
server.set_fn_new_client(new_client)
server.set_fn_message_received(message_recieve)
server.set_fn_client_left(client_left)
server.run_forever()
