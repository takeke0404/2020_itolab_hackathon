from websocket_server import WebsocketServer
from datetime import datetime

#コネクション接続時に呼ばれる関数
def new_client(client, server):
    #コネクションを確立している全体に送信
    server.send_message_to_all(datetime.now().isoformat() + ": new client joined!")

#クライアント側からメッセージが飛んできたとき
def message_recieve(client, server, message):
    #メッセージを送ってきた全体に送信
    server.send_message(client,message)

server = WebsocketServer(7532, host="0.0.0.0")
server.set_fn_new_client(new_client)
server.set_fn_message_received(message_recieve)
server.run_forever()
