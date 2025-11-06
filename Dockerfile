# syntax=docker/dockerfile:1
# 公式のconda環境で上手くいかない (CUDA 拡張ビルドまわり)ためcondaを捨てる

# CUDA 11.8 / PyTorch 2.4 系の公式イメージ（ビルドツール入り）
FROM pytorch/pytorch:2.4.0-cuda11.8-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    FORCE_CUDA=1 \
    TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

# 共有ライブラリ（OpenCV 実行に必要）とビルドツール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake ninja-build \
    ffmpeg libgl1 libglib2.0-0 libxext6 libxrender1 libsm6 \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリにリポジトリを配置
WORKDIR /workspace/poison-splat
COPY . /workspace/poison-splat

# submodule を取得（ビルドに必須）。.git が無い場合はエラーにする。
RUN if [ -d .git ]; then \
        git submodule update --init --recursive; \
    fi && \
    test -d victim/gaussian-splatting/submodules/diff-gaussian-rasterization || \
    (echo "ERROR: submodules がありません。--recursive 付きで clone してください。" && exit 1)

# requirements.txt からローカルパス行（submodule 分）だけを除いた一時ファイルを作る
# それらはこの後で個別に -e インストールしてビルドします。
RUN grep -vE '^(victim/gaussian-splatting/submodules/diff-gaussian-rasterization|victim/gaussian-splatting/submodules/simple-knn|victim/Scaffold-GS/submodules/diff-gaussian-rasterization_scaffold|victim/mip-splatting/submodules/diff-gaussian-rasterization_mip)$' \
    requirements.txt > /tmp/requirements_nosub.txt

# （ベースに torch/torchvision は入っていますが）他の依存をインストール
RUN pip install --no-cache-dir -r /tmp/requirements_nosub.txt

# torch-scatter は Torch/CUDA に合わせた PYG の wheel を使うのが安全
ARG TORCH_VERSION=2.4.0
RUN pip install --no-cache-dir torch-scatter -f https://data.pyg.org/whl/torch-${TORCH_VERSION}+cu118.html

# ローカル CUDA 拡張をビルド & インストール（editable）
RUN pip install --no-cache-dir -e victim/gaussian-splatting/submodules/diff-gaussian-rasterization \
    && pip install --no-cache-dir -e victim/gaussian-splatting/submodules/simple-knn \
    && pip install --no-cache-dir -e victim/mip-splatting/submodules/diff-gaussian-rasterization_mip \
    && pip install --no-cache-dir -e victim/Scaffold-GS/submodules/diff-gaussian-rasterization_scaffold

# そのままシェルに入れるように
CMD ["/bin/bash"]
