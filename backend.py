from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
from stacks_transactions import (
    make_contract_call, TransactionOptions, 
    StacksMainnet, StacksTestnet
)
import json

app = FastAPI()

# Configuration
CONTRACT_ADDRESS = "SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9"
CONTRACT_NAME = "game-assets"
NETWORK = StacksTestnet()

# Models
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

class Listing(BaseModel):
    asset_id: int
    price: int

# Routes
@app.post("/assets/mint")
async def mint_asset(asset: Asset):
    try:
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
                asset.attributes
            ],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/market/list")
async def list_asset(listing: Listing):
    try:
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="list-asset",
            function_args=[listing.asset_id, listing.price],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/market/buy/{asset_id}")
async def buy_asset(asset_id: int):
    try:
        tx = make_contract_call(
            contract_address=CONTRACT_ADDRESS,
            contract_name=CONTRACT_NAME,
            function_name="buy-asset",
            function_args=[asset_id],
            network=NETWORK
        )
        return {"transaction_id": tx.txid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/assets/{asset_id}")
async def get_asset(asset_id: int):
    try:
        # Call contract to get asset details
        result = NETWORK.contract_call_read(
            CONTRACT_ADDRESS,
            CONTRACT_NAME,
            "get-asset-details",
            [asset_id]
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=404, detail="Asset not found")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)