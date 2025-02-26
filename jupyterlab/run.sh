#!/usr/bin/env sh
INSTALLER=""
check_available_installer() {
  # check if uv is installed
  if command -v uv > /dev/null 2>&1; then
    echo "uv is installed"
    INSTALLER="uv"
    return
  fi
  echo "No valid installer is not installed"
  echo "Please install pipx or uv in your Dockerfile/VM image before running this script"
  exit 1
}

if [ -n "${BASE_URL}" ]; then
  BASE_URL_FLAG="--ServerApp.base_url=${BASE_URL}"
fi

BOLD='\033[0;1m'

# check if jupyterlab is installed
if ! command -v jupyter-lab > /dev/null 2>&1; then
  # install jupyterlab
  check_available_installer
  printf "$${BOLD}Installing jupyterlab!\n"
  case $INSTALLER in
    uv)
      uv venv --seed
      uv pip install ipykernel jupyterlab pip jupyterlab-git
      uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=aicentre \
        && printf "%s\n" "🥳 jupyterlab has been installed"
      JUPYTERPATH="$HOME/.venv/bin/"
      ;;
  esac
else
  printf "%s\n\n" "🥳 jupyterlab is already installed"
fi


printf "⚠️ setting proxy vars..."
cat $HOME/.local/share/jupyter/kernels/aicentre/kernel.json | jq -r \
  --arg http_proxy "$http_proxy" \
  --arg https_proxy "$https_proxy" \
  '.env += {"http_proxy": $http_proxy, "https_proxy": $https_proxy}' \
  > tmp.json

printf "➡️ updating kernelspec..."
mv tmp.json $HOME/.local/share/jupyter/kernels/aicentre/kernel.json
# Removes the default kernelspec that does not have env setup
$JUPYTERPATH/jupyter kernelspec remove python3 -y

printf "👷 Starting jupyterlab in background..."
printf "check logs at ${LOG_PATH}"

# Note the need to unset http proxy settings; as a result of python badness
http_proxy= https_proxy= $JUPYTERPATH/jupyter-lab --no-browser \
  "$BASE_URL_FLAG" \
  --ServerApp.ip='*' \
  --ServerApp.port="${PORT}" \
  --ServerApp.token='' \
  --ServerApp.password='' \
  > "${LOG_PATH}" 2>&1 &
