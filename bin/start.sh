#!/bin/sh

pid_file=/var/run/hubot-pcc.pid
hubot_log_file=/home/wagner/hubot/pcc/bin/hubot.log
tg_log_file=/home/wagner/hubot/pcc/bin/tg.log


stop () {

  cat "$pid_file" |
    while read pid;
    do
      sudo kill ${pid} 1> /dev/null 2>/dev/null;
    done
    sudo rm -fr "$pid_file" 1> /dev/null 2>/dev/null
    echo "Parado"

}

start () {
  if [ -f "$pid_file" ]; then
    echo "Já existe uma execução.\r\nNada feito."
    exit 1
  fi

  echo "Iniciando tg..."
  cd /home/wagner/hubot/pcc/node_modules/hubot-tg
  /home/wagner/tg/bin/telegram-cli -s hubot.lua -P 1123 1>>"$tg_log_file"  2>>"$tg_log_file" &
  echo "$!" | sudo tee "$pid_file"

  echo "Iniciando hubot..."
  cd ../../
  ./bin/hubot -a tg 1>> "$hubot_log_file" 2>> "$hubot_log_file" &
  echo "$!" | sudo tee -a "$pid_file"
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