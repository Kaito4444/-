from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import openai
import os
from dotenv import load_dotenv
import base64
from PIL import Image
import io
import requests
from bs4 import BeautifulSoup
import json
from typing import Dict, List
import aiohttp
import asyncio

# 環境変数の読み込み
load_dotenv()

app = FastAPI()

# CORSミドルウェアの設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OpenAI APIキーの設定
openai.api_key = os.getenv("OPENAI_API_KEY")

async def analyze_image_with_gpt4(image_data: bytes) -> Dict:
    """
    GPT-4 Visionを使用して画像を分析し、商品情報を抽出する
    """
    # 画像をBase64エンコード
    base64_image = base64.b64encode(image_data).decode('utf-8')
    
    try:
        response = await openai.chat.completions.create(
            model="gpt-4-vision-preview",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "この商品画像を分析して、以下の情報を日本語で提供してください：\n1. 商品名（タイトルとして適切な形式）\n2. 商品の詳細な説明\n3. 商品のカテゴリー\n4. 商品の状態\nJSON形式で返してください。"
                        },
                        {
                            "type": "image_url",
                            "image_url": f"data:image/jpeg;base64,{base64_image}"
                        }
                    ]
                }
            ],
            max_tokens=500
        )
        
        # レスポンスから必要な情報を抽出
        content = response.choices[0].message.content
        # JSON文字列を抽出して解析
        json_str = content[content.find("{"):content.rfind("}")+1]
        return json.loads(json_str)
    except Exception as e:
        return {"error": str(e)}

async def scrape_mercari_prices(search_term: str) -> List[int]:
    """
    メルカリから類似商品の価格を取得する（デモ用の簡易実装）
    実際の実装では、より詳細なスクレイピングロジックが必要です
    """
    # この部分は実際のスクレイピング実装に置き換える必要があります
    # デモ用のダミーデータを返します
    return [1000, 1500, 2000, 2500, 3000]

def calculate_suggested_price(prices: List[int]) -> Dict[str, int]:
    """
    収集した価格データから推奨価格を計算する
    """
    if not prices:
        return {"suggested_price": 0, "min_price": 0, "max_price": 0}
    
    return {
        "suggested_price": int(sum(prices) / len(prices)),
        "min_price": min(prices),
        "max_price": max(prices)
    }

@app.post("/analyze-product")
async def analyze_product(file: UploadFile = File(...)):
    """
    商品画像を分析し、タイトル、説明、推奨価格を生成する
    """
    try:
        # 画像データの読み込み
        image_data = await file.read()
        
        # 画像の分析
        analysis_result = await analyze_image_with_gpt4(image_data)
        
        # 類似商品の価格を取得
        prices = await scrape_mercari_prices(analysis_result.get("商品名", ""))
        
        # 推奨価格の計算
        price_info = calculate_suggested_price(prices)
        
        return {
            "title": analysis_result.get("商品名", ""),
            "description": analysis_result.get("商品の詳細な説明", ""),
            "category": analysis_result.get("商品のカテゴリー", ""),
            "condition": analysis_result.get("商品の状態", ""),
            "price_suggestion": price_info
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)