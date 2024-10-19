# First stage: building dependencies
FROM python:3.11-slim AS builder

LABEL description="Docker container for MASt3R with dependencies installed. CPU VERSION"

ENV DEVICE="cpu"
ENV MODEL="MASt3R_ViTLarge_BaseDecoder_512_dpt.pth"
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies for the build
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libgl1-mesa-glx \
    libegl1-mesa \
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libasound2 \
    libxi6 \
    libxtst6 \
    libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone the repository
RUN git clone --recursive https://github.com/naver/mast3r /mast3r

# Set working directory to dust3r (subfolder of the repo)
WORKDIR /mast3r/dust3r

# Install CPU version of PyTorch and related dependencies
RUN pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.1 --extra-index-url https://download.pytorch.org/whl/cpu

# Install all other necessary requirements
RUN pip install -r requirements.txt
RUN pip install -r requirements_optional.txt

# Install OpenCV with a specific version
RUN pip install opencv-python==4.8.0.74

# Second stage: final image
FROM python:3.11-slim

LABEL description="Final Docker container for running MASt3R"

# Copy necessary files from the build stage
COPY --from=builder /mast3r /mast3r

# Set the working directory
WORKDIR /mast3r

# Install any final runtime dependencies
RUN pip install -r requirements.txt

# Copy and set up the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint to the custom script
ENTRYPOINT ["/entrypoint.sh"]
