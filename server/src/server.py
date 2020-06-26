from websocket_server import WebsocketServer
from datetime import datetime
import json
from collections import deque
import prediction
import itertools
import random
import cv2

#properties
matching_queue = deque()#マッチング待機キュー
matching_list = list()#対戦ペアを格納するリスト
matching_user = list()#対戦状態にあるクライアントのリスト
judgment_list = list()#結果待機リスト
classes = [0,1,2,3,4,5,6]
hand_list = list(itertools.permutations(classes, 3)) #どの表情をどの手にするかの順列

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
            server.send_message(client,json.dumps({"type":"Warning","res": "Exist" }))
            return

        #マッチング不成立ならマッチングの待機キューに追加
        if len(matching_queue) == 0:
            matching_queue.append(client)
            server.send_message(client,json.dumps({"type":"Matching","res": "Waiting" }))
        else:
            rival = matching_queue.pop()
            #どの表情をどの手にするか決定
            hand_num = random.randint(0, len(hand_list))
            #対戦リストへの追加
            matching_card = [rival,client,hand_num]
            matching_list.append(matching_card)
            matching_user.append(client)
            matching_user.append(rival)
            client['rival'] = rival
            client['matching'] = matching_card
            rival['rival'] = client
            rival['matching'] = matching_card


            #clientへの通知
            server.send_message(client,json.dumps({"type":"Matching","res": "Found"}))
            server.send_message(rival,json.dumps({"type":"Matching","res": "Found"}))

    #判定処理
    if data_json['type'] == "Judgment":
        if client not in matching_user:
            server.send_message(client,json.dumps({"type":"Warning", "res":"Not Matching"}))
            return
        #jsonから画像を取得判定、相手が終わるまでjudgment_listに格納
        img = cv2.imread(test.jpg)
        #画僧が送信されてない際の処理
        if img is None:
            server.send_message(client,json.dumps({"type":"Judgment","res":"Not Image"}))
            return
        else:
            #画像から表情推定の結果を返す(顔ではない画像に対応なし)
            result = prediction.run(img,client['matching_card'][2])

            #対戦相手が画僧を送信していなければjudgment_listに格納して待機
            if client['rival'] not in judgment_list[:][0]:
                judgment_list.append(client,result)
                server.send_message(client,json.dumps({"type":"Judgment","res":"Waiting"}))
                return
            else:
                for judgment_data in judgment_list:
                    if client['rival'] == judgment_data[0]:
                        rival_result = judgment_data[1]
                        client_result = result
                        #結果の送信
                        server.send_message(client,json.dumps({"type":"Judgment","res":"Result","your_hand":client_result[0],"your_emotion":client_result[1],"your_prob":client_result[2],"hand":rival_result[0],"emotion":rival_result[1],"prob":rival_result[2]}))
                        server.send_message(client['rival'],json.dumps({"type":"Judgment","res":"Result","your_hand":rival_result[0],"your_emotion":rival_result[1],"your_prob":rival_result[2],"hand":client_result[0],"emotion":client_result[1],"prob":client_result[2]}))
        #対戦ペアをリストから削除
        matching_list.remove(client['matching'])
        matching_user.remove(client)
        matching_user.remove(client['rival'])

        # #結果の送信
        # server.send_message(client,json.dumps({"type":"Judgment","res": "Result"}))
        # server.send_message(client['rival'],json.dumps({"type":"Judgment","res": "Result"}))

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
