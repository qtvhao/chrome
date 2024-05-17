
RUN set -xe; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
    npm install -g yarn; \
    yarn --version; \
    npm --version; \
    npm cache clean --force; \
    yarn cache clean --force; \
    apt-get purge -y --auto-remove chromium; \
    apt-get autoremove -y; \
    apt-get autoclean -y; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    rm -rf /tmp/* /var/tmp/*; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;
RUN . venv/bin/activate && wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x wait-for-it.sh
RUN mkdir -p /var/run/dbus;
