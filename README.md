# docker-poison-splat

Poison-Splat（3D Gaussian Splatting への計算量攻撃実装）を **Conda なし／Docker 管理**で再現するためのリポジトリ。
- 元リポジトリ: https://github.com/jiahaolu97/poison-splat
- 動機: 元手順（Conda + pip）だと CUDA / PyTorch / CUDA拡張の組合せで互換性エラーが出やすいため、**Docker でバージョンを固定**して再現性を上げる。

---

## 前提条件

- NVIDIA GPU と対応ドライバ（CUDA 11.x 相当）
- Docker 
- NVIDIA Container Toolkit（`--gpus all` が使える状態）

---

## クイックスタート

```bash
# 1) リポジトリを submodule 付きで取得
git clone --recursive https://github.com/Toy10ka/docker-poison-splat.git
cd poison-splat

# 2) ビルド
docker build -t poison-splat:cu118 .

# 3) 実行：データセットをホストからマウントする例
# bash
docker run --gpus all -it --rm \
  -v $PWD/dataset:/workspace/poison-splat/dataset \
  poison-splat:cu118

# git bash
docker run --gpus all -it --rm \
  -v "/$(pwd | sed 's|/c/|c:/|')/dataset:/workspace/poison-splat/dataset" \
  poison-splat:cu118

# 4) コンテナ内で動作確認（README のテストスクリプト）
bash exp/00_test/test_install.sh

```
---

