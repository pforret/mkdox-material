# Copyright (c) 2016-2024 Martin Donath <martin.donath@squidfunk.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

FROM --platform=linux/amd64 python:3.12-alpine3.20

# Build-time flags
ARG WITH_PLUGINS=true

# Environment variables
ENV PACKAGES=/usr/local/lib/python3.12/site-packages
ENV PYTHONDONTWRITEBYTECODE=1

# Set build directory
WORKDIR /tmp

# Copy files necessary for build
COPY material material
COPY package.json package.json
COPY README.md README.md
COPY *requirements.txt ./
COPY pyproject.toml pyproject.toml
COPY fonts /usr/share/fonts/Additional

# Perform build and cleanup artifacts and caches
# install all Alpine packages and update pip to latest version
RUN apk upgrade --update-cache -a
RUN apk add --no-cache \
    cairo \
    git \
    git-fast-import \
    openssh \
    pango \
    py3-brotli \
    py3-cffi \
    py3-pillow \
    pngquant \
    py3-pip

RUN apk add --no-cache \
    font-awesome \
    font-dejavu \
    font-inconsolata \
    font-noto \
    font-noto-extra \
    fontconfig \
    terminus-font \
    ttf-freefont \
  && fc-cache -f

RUN apk add --no-cache --virtual .build \
    freetype-dev \
    g++ \
    gcc \
    jpeg-dev \
    libffi-dev \
    musl-dev \
    openjpeg-dev \
    python3-dev \
    zlib-dev \
  && \
    pip install --no-cache-dir --upgrade pip \
  && \
    pip install --no-cache-dir .

## install plugins
RUN \
  if [ "${WITH_PLUGINS}" = "true" ]; then \
    pip install --no-cache-dir \
      weasyprint \
      mkdocs-awesome-pages-plugin \
      mkdocs-include-markdown-plugin \
      mkdocs-material[imaging] \
      mkdocs-material[recommended] \
      mkdocs-rss-plugin \
      mkdocs-with-pdf \
      markdown-include ; \
  fi \
&& \
  if [ -e user-requirements.txt ]; then \
    pip install -U -r user-requirements.txt; \
  fi \
&& \
  apk del .build \
&& \
  for theme in mkdocs readthedocs; do \
    rm -rf ${PACKAGES}/mkdocs/themes/$theme; \
    ln -s \
      ${PACKAGES}/material/templates \
      ${PACKAGES}/mkdocs/themes/$theme; \
  done \
&& \
  rm -rf /tmp/* /root/.cache \
&& \
  find ${PACKAGES} \
    -type f \
    -path "*/__pycache__/*" \
    -exec rm -f {} \; \
&& \
  git config --system --add safe.directory /docs \
&& \
  git config --system --add safe.directory /site

# Set working directory
WORKDIR /docs

# Expose MkDocs development server port
EXPOSE 8000

# Start development server by default
ENTRYPOINT ["mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
