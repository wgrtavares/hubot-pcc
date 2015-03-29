#!/bin/sh

#export HUBOT_LOG_LEVEL="debug"
export HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS='https://api.myjson.com/bins/4qtiv'
export HUBOT_GERENCIAMENTO_URL_JSON_CONCEITOS_READ_ONLY='http://myjson.com/4qtiv'
export HUBOT_REMOTE_JSON_HTTPS_HOSTNAME='api.myjson.com'
export HUBOT_REMOTE_JSON_HTTPS_PORT='443'
export HUBOT_REMOTE_JSON_HTTPS_PATH='/bins/4qtiv'
#export HUBOT_MONITOR_URL_JSON='https://api.myjson.com/bins/4qtiv'
export HUBOT_MONITOR_IS_CONSULTA_WEB_NA_CARGA='false'
export HUBOT_SERVICE_NAME='hubot-pcc'

export HUBOT_SERVICE_PID_FILE='/var/run/hubot-pcc.pid'
export HUBOT_SERVICE_LOG_FILE='/home/wagner/hubot/pcc/bin/hubot.log'
export TG_SERVICE_LOG_FILE='/home/wagner/hubot/pcc/bin/tg.log'
export TG_MODULES_TG_PATH='/home/wagner/hubot/pcc/node_modules/hubot-tg'
export TG_CLI='/home/wagner/tg/bin/telegram-cli'

stop () {

  cat "$HUBOT_SERVICE_PID_FILE" |
    while read pid;
    do
      sudo kill ${pid} 1> /dev/null 2>/dev/null;
    done
    sudo rm -fr "$HUBOT_SERVICE_PID_FILE" 1> /dev/null 2>/dev/null
    echo "Parado"

}

start () {
  if [ -f "$HUBOT_SERVICE_PID_FILE" ]; then
    echo "Já existe uma execução.\r\nNada feito."
    exit 1
  fi

  echo "Iniciando tg..."
  cd "$TG_MODULES_TG_PATH"
  "$TG_CLI" -k tg-server.pub -s hubot.lua -P 1123 1>>"$TG_SERVICE_LOG_FILE"  2>>"$TG_SERVICE_LOG_FILE" &
  echo "$!" | sudo tee "$HUBOT_SERVICE_PID_FILE"

  echo "Iniciando hubot..."
  cd ../../
  ./bin/hubot -a tg 1>> "$HUBOT_SERVICE_LOG_FILE" 2>> "$HUBOT_SERVICE_LOG_FILE" &
  echo "$!" | sudo tee -a "$HUBOT_SERVICE_PID_FILE"
  echo "Iniciado"
}

case "$1" in

  stop)
    stop
    ;;
  start)
    start
    ;;
  restart)
    stop
    start
    ;;
esac

exit 0