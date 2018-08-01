from channels.generic.websocket import JsonWebsocketConsumer


class TextReaderConsumer(JsonWebsocketConsumer):
    def receive_json(self, content, **kwargs):
        self.send_json({'stuff': 'test'}, True)
