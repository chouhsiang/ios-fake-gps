# iOS 座標模擬 Web

透過網頁地圖設定 iPhone 的模擬 GPS 座標，後端使用 **Python + pymobiledevice3**。

## 功能

- **地圖**：以 Leaflet + 深色底圖顯示地圖
- **目前座標**：頁面上方顯示目前（上次設定）的經緯度，並在地圖上以標記顯示
- **點選設為新座標**：在地圖上點一下，即可將該點設為裝置的模擬位置（會呼叫 pymobiledevice3 寫入裝置）

## 環境需求

- Python 3.10+
- 已連接的 iOS 裝置（USB 或透過 RSD 隧道）
- **iOS 17+** 建議先建立 RSD 隧道（見下方）

## 安裝

```bash
cd /Users/hchou/Workspace/local2
pip install -r requirements.txt
```

## 執行

### 1. 啟動後端

請**先進入 `backend` 目錄**再執行（否則會出現 `Could not import module "main"`）：

```bash
cd backend
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

若要在專案根目錄執行，請改指定模組路徑：

```bash
python3 -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

瀏覽器開啟：**http://localhost:8000**

### 2. iOS 17+ 使用 RSD 隧道（建議）

若裝置為 **iOS 17 以上**，模擬座標需透過 DVT 的 RSD 連線，請先建立隧道：

```bash
# 終端機 A：建立隧道（需 sudo）
sudo python3 -m pymobiledevice3 remote start-quic-tunnel
```

輸出會包含 `serverAddress` 與 `serverRSDPort`。在網頁表頭「RSD 主機」與「埠」欄位填入這兩項後，再點選地圖設定座標。

### 3. 掛載 Developer Disk（若尚未掛載）

```bash
python3 -m pymobiledevice3 mounter auto-mount
```

## 專案結構

```
local2/
├── backend/
│   ├── main.py          # FastAPI 後端與 API
│   └── static/
│       ├── index.html   # 地圖頁
│       └── app.js       # 地圖邏輯與 API 呼叫
├── requirements.txt
└── README.md
```

## API

| 方法 | 路徑 | 說明 |
|------|------|------|
| GET  | `/api/location` | 取得目前（上次設定）座標 |
| POST | `/api/location` | 設定裝置模擬座標，body: `{ "lat": 25.033, "lng": 121.5654, "rsd_host": "選填", "rsd_port": 選填 }` |

## 注意事項

- 後端以 **subprocess** 呼叫 `pymobiledevice3 developer dvt simulate-location set` 設定座標。部分 iOS 版本或連線方式可能不穩定。
- 使用前請確認裝置已信任此電腦，且必要時已掛載 Developer Disk Image。
