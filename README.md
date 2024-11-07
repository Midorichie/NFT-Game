# NFT Game Assets Marketplace

A decentralized marketplace built on the Stacks blockchain for trading NFT game assets across multiple games. This platform enables game developers to integrate their games and players to seamlessly trade their in-game assets.

## 🌟 Features

### Core Functionality
- NFT minting and trading
- Cross-game asset compatibility
- Secure ownership transfer
- Detailed asset metadata storage
- Real-time market listings

### Advanced Features
- Auction system with minimum bids and time limits
- Game developer royalties/commission system
- Asset usage tracking across different games
- Rarity scoring system
- Game verification system
- Asset locking mechanism

## 🛠 Technology Stack

- **Blockchain**: Stacks
- **Smart Contracts**: Clarity
- **Backend**: Python/FastAPI
- **Caching**: Redis
- **Monitoring**: Prometheus
- **Authentication**: JWT

## 📋 Prerequisites

- Python 3.8+
- Stacks CLI
- Redis
- Node.js 14+

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/nft-game-marketplace.git
cd nft-game-marketplace
```

### 2. Install Dependencies
```bash
# Install Python dependencies
pip install -r requirements.txt

# Install Stacks CLI
npm install -g @stacks/cli
```

### 3. Configure Environment
Create a `.env` file in the root directory:
```env
NETWORK=testnet
CONTRACT_ADDRESS=your_contract_address
CONTRACT_NAME=game-assets
SECRET_KEY=your_secret_key
REDIS_URL=redis://localhost:6379
```

### 4. Deploy Smart Contract
```bash
# Deploy to testnet
stacks deploy game-assets.clar --network=testnet
```

### 5. Start the API Server
```bash
uvicorn app.main:app --reload
```

## 📖 API Documentation

### Asset Management
- `POST /assets/mint`: Mint new game assets
- `GET /assets/{asset_id}/full`: Get complete asset details
- `POST /market/auction`: Create asset auction
- `POST /market/buy/{asset_id}`: Purchase asset

### Game Integration
- `POST /games/register`: Register new game
- `POST /games/{game_id}/verify`: Verify game (admin only)
- `POST /games/{game_id}/use-asset/{asset_id}`: Record asset usage in game

## 🔒 Smart Contract Functions

### Asset Operations
```clarity
(define-public (mint-asset (asset-id uint) ...))
(define-public (list-asset-with-auction (asset-id uint) ...))
(define-public (buy-asset (asset-id uint)))
```

### Game Integration
```clarity
(define-public (register-game (game-id uint) ...))
(define-public (verify-game (game-id uint)))
(define-public (use-asset-in-game (game-id uint) (asset-id uint)))
```

## 🎮 Game Developer Integration

### 1. Register Your Game
```python
import requests

response = requests.post(
    "api/games/register",
    json={
        "game_id": 1,
        "name": "Your Game",
        "commission_rate": 5  # 5% commission
    }
)
```

### 2. Implement Asset Usage
```python
def use_asset(asset_id: int, player_id: str):
    response = requests.post(
        f"api/games/{GAME_ID}/use-asset/{asset_id}",
        headers={"Authorization": f"Bearer {player_token}"}
    )
```

## 🔍 Monitoring

The application includes Prometheus metrics for:
- Transaction counts
- API response times
- Active auctions
- Asset usage statistics

Access metrics at: `http://localhost:8000/metrics`

## 🧪 Testing

```bash
# Run unit tests
pytest tests/

# Run integration tests
pytest tests/integration/

# Run contract tests
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Stacks Foundation
- FastAPI team
- All contributors and users of the platform

## 📞 Support

For support:
- Create an issue in the repository
- Join our Discord community: [Discord Link]
- Email: support@nftgamemarketplace.com