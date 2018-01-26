
info() {
  echo -e "\e[34mINFO: ${1}\e[0m"
  logger $1
}

errorAndExit() {
  logger $1
  echo $1
  exit $2
}
