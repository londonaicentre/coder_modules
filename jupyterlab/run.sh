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
if ! command -v $HOME/.venv/bin/jupyter > /dev/null 2>&1; then
  # install jupyterlab
  check_available_installer
  printf "$${BOLD}Installing jupyterlab!\n"
  case $INSTALLER in
    uv)
      uv venv --seed
      uv pip install ipykernel jupyterlab pip jupyterlab-git
      uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=aicentre \
        && printf "%s\n" "🥳 jupyterlab has been installed"
      ;;
  esac
else
  printf "%s\n\n" "🥳 jupyterlab is already installed"
fi

JUPYTERPATH="$HOME/.venv/bin/"

printf "🔌 Set git variables"
git config --global http.proxy $http_proxy
git config --global user.name $GIT_AUTHOR_NAME
git config --global user.email $GIT_AUTHOR_EMAIL

printf "👷 Starting jupyterlab in background..."
printf "check logs at ${LOG_PATH}"

# Note the need to unset http proxy settings; as a result of python badness
$JUPYTERPATH/jupyter-lab --no-browser \
  "$BASE_URL_FLAG" \
  --ServerApp.ip='*' \
  --ServerApp.port="${PORT}" \
  --ServerApp.token='' \
  --ServerApp.password='' \
  > "${LOG_PATH}" 2>&1 &
