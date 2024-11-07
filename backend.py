from fastapi import FastAPI, HTTPException, Depends, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
import uvicorn
from stacks_transactions import (
    make_contract_call, TransactionOptions, 
    StacksMainnet, StacksTestnet
)
from datetime import datetime, timedelta
import jwt
from redis import Redis
from fastapi_cache import FastAPICache
from fastapi_cache.decorator import cache
import asyncio
import logging
from prometheus_client import Counter, Histogram

# Enhanced Models
class Attribute(BaseModel):
    trait: str
    value: str

class Asset(BaseModel):
    asset_id: int
    name: str
    description: str
    image_uri: str
    game_id: int
    attributes: List[Attribute]
    rarity_score: int = Field(ge=0, le=100)

class AuctionListing(BaseModel):
    asset_id: int
    price: int
    min_bid: int
    duration_hours: int = Field(ge=1, le=168)  # Max 1 week

class GameRegistration(BaseModel):
    game_id: int
    name: str
    commission_rate: int = Field(ge=0, le=30)  # Max 30%

# Enhanced API Setup
app = FastAPI(title="NFT Game Assets Marketplace API", version="2.0.0")
redis = Redis(host='localhost', port=6379, decode_responses=True)

# Monitoring metrics
TRANSACTION_COUNTER = Counter('nft_transactions_total', 'Total number of NFT transactions')
RESPONSE_TIME = Histogram('api_response_time_seconds', 'Response time in seconds')

# Enhanced Security
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
SECRET_KEY = "your-secret-key"  # In production, use secure environment variable

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload["sub"]
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication")

# Enhanced Routes
@app.post("/assets/mint")
@RESPONSE_TIME.time()
async def mint_asset(
    asset: Asset,
    current_user: str = Depends(get_current_user)
):
    try:
        TRANSACTION_COUNTER.inc()
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="mint-asset",
            function_args=[
                asset.asset_id,
                asset.name,
                asset.description,
                asset.image_uri,
                asset.game_id,
                asset.attributes,
                asset.rarity_score
            ],
            network=NETWORK
        )
        # Cache the transaction
        await redis.setex(f"tx:{tx.txid}", 3600, "pending")
        return {"transaction_id": tx.txid}
    except Exception as e:
        logging.error(f"Minting error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/market/auction")
async def create_auction(
    listing: AuctionListing,
    current_user: str = Depends(get_current_user)
):
    try:
        expires_at = int((datetime.now() + timedelta(hours=listing.duration_hours)).timestamp())
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="list-asset-with-auction",
            function_args=[
                listing.asset_id,
                listing.price,
                listing.min_bid,
                expires_at
            ],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/games/register")
async def register_game(
    game: GameRegistration,
    current_user: str = Depends(get_current_user)
):
    try:
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="register-game",
            function_args=[
                game.game_id,
                game.name,
                game.commission_rate
            ],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/games/{game_id}/use-asset/{asset_id}")
async def use_asset(
    game_id: int,
    asset_id: int,
    current_user: str = Depends(get_current_user)
):
    try:
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="use-asset-in-game",
            function_args=[game_id, asset_id],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/assets/{asset_id}/full")
@cache(expire=300)  # Cache for 5 minutes
async def get_asset_full_details(asset_id: int):
    try:
        result = NETWORK.contract_call_read(
            CONTRACT_ADDRESS,
            CONTRACT_NAME,
            "get-asset-full-details",
            [asset_id]
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=404, detail="Asset not found")

# Background Tasks
async def monitor_auction_expiry():
    while True:
        try:
            current_time = int(datetime.now().timestamp())
            # Check for expired auctions
            # Implementation depends on specific storage mechanism
            await asyncio.sleep(300)  # Check every 5 minutes
        except Exception as e:
            logging.error(f"Auction monitor error: {str(e)}")
            await asyncio.sleep(60)

@app.on_event("startup")
async def startup_event():
    FastAPICache.init(backend=redis)
    asyncio.create_task(monitor_auction_expiry())

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)