#!/usr/bin/env python
# coding: utf-8

# https://book.mynavi.jp/manatee/detail/id=99887

import numpy as np
from keras.models import load_model
#from keras.preprocessing.image import ImageDataGenerator
from keras.preprocessing import image
import cv2
import random

class Prediction:
    """
    0 : angry
    1 : disgust
    2 : fear
    3 : happy
    4 : sad
    5 : surprise
    6 : neutral
    """
    classes = ['angry',
                    'disgust',
                    'fear',
                     'happy',
                     'sad',
                     'surprise',
                     'neutral']
    faces_detector = ''
    emotions_detector = ''

    def __init__(self):
        # 学習済みモデルのロード
        faces_detector_model_path = "./trained_model/haarcascade_frontalface_default.xml"
        Prediction.faces_detector = cv2.CascadeClassifier(faces_detector_model_path)

        emotions_detector_model_path = './trained_model/fer2013_mini_XCEPTION.110-0.65.hdf5'
        Prediction.emotions_detector = load_model(emotions_detector_model_path, compile=False)

    # 画像の切り抜き
    def clip(self,img, rect):
        x1 = rect[0]
        x2 = rect[0] + rect[2]
        y1 = rect[1]
        y2 = rect[1] + rect[3]
        return img[y1:y2, x1:x2]

    # 画像の前処理(表情推定に使用)
    def preprocessor(self,img, rect):
        face_img = self.clip(img, rect)
        gray_img = cv2.cvtColor(face_img, cv2.COLOR_BGR2GRAY)
        gray_img = cv2.resize(gray_img, (64,64), interpolation = cv2.INTER_AREA)
        img_array = image.img_to_array(gray_img)
        pImg = np.expand_dims(img_array, axis=0) / 255
        return pImg

    # 表情推定
    def classify_emotion(self,img):
        gray_img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = Prediction.faces_detector.detectMultiScale(gray_img)
        face_rect = faces[0]

        pImg = self.preprocessor(img, face_rect)
        prediction = Prediction.emotions_detector.predict(pImg)[0]

        result = [(Prediction.classes[i] , prediction[i]) for i in range(len(Prediction.classes))]
        return result, face_rect

    def select_hand_randomly(self,unused_faces=["disgust"]):
        indices = list(range(len(classes)))
        # 使用しない表情を削除
        for x in unused_faces:
            indices.remove(classes.index(x))
        # シャッフル
        random.shuffle(indices)
        return indices[:3]

        #  画像の読み込み
        image_path = './image/matayoshi.jpg'

        # 画像の読み込み ()
        img = cv2.imread(image_path)

        # どの表情がどの手に対応しているか
        # handsのindexが0ならグー, 1ならパー, 2ならチョキ
        # として、各indexに表情のclassが入っている
        hands = Prediction.select_hand_randomly()
        print("グー:", classes[hands[0]], ", パー:", classes[hands[1]], ", チョキ:", classes[hands[2]])
        # 例　: グー: angry , パー: surprise , チョキ: sad

    def run(self,img,hand):
        result, face_rect = self.classify_emotion(img)

        # 各手に対応した表情の取り出し
        prob = [(0, *result[hand[0]]) , (1, *result[hand[1]]), (2, *result[hand[2]])]
        # グー: 0 , パー: 1 , チョキ: 2

        # 確率の高い表情を取り出し
        maxp = max(prob, key=lambda x : x[2])
        # 例 : (1, 'happy', 0.29445335)
        return maxp
