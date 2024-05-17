FROM ghcr.io/qtvhao/python-3.12-bookworm:main

ENV DL_GOOGLE_CHROME_VERSION="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
RUN set -xe; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        task-japanese \
        ca-certificates \
        fonts-liberation \
        fonts-dejavu \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-ipafont-mincho \
        fonts-wqy-zenhei \
        fonts-wqy-microhei \
    ; \
    curl -sSL -o google-chrome-stable_current_amd64.deb $DL_GOOGLE_CHROME_VERSION; \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get -fy --no-install-recommends install; \
    rm google-chrome-stable_current_amd64.deb; \
    which google-chrome-stable; \
    curl -sSL -o chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip; \
    unzip chromedriver_linux64.zip; \
    mv chromedriver /usr/local/bin/; \
    rm chromedriver_linux64.zip; \
    which chromedriver; \
    apt-get clean; \
    apt-get purge -y --auto-remove chromium; \
    apt-get autoremove -y; \
    apt-get autoclean -y; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    rm -rf /tmp/* /var/tmp/*; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;

RUN set -xe; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        gnome-screenshot \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libxcomposite1 \
        tesseract-ocr \
        xdotool \
        jq \
    ; \
    apt-get clean; \
    apt-get purge -y --auto-remove chromium; \
    apt-get autoremove -y; \
    apt-get autoclean -y; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    rm -rf /tmp/* /var/tmp/*; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;
RUN mkdir -p /var/run/dbus;
