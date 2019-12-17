#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"
export PORT=4536
export NO_PROMETHEUS=true

# - - - - - - - - - - - - - - - - - - - - - -
ip_address_slow()
{
  if [ -n "${DOCKER_MACHINE_NAME}" ]; then
    docker-machine ip ${DOCKER_MACHINE_NAME}
  else
    echo localhost
  fi
}
readonly IP_ADDRESS=$(ip_address_slow)

# - - - - - - - - - - - - - - - - - - - - - -
wait_briefly_until_ready()
{
  local -r port="${1}"
  local -r name="${2}"
  local -r max_tries=10
  echo -n "Waiting until ${name} is ready"
  for _ in $(seq ${max_tries})
  do
    echo -n '.'
    if ready ${port}; then
      echo 'OK'
      return
    else
      sleep 0.1
    fi
  done
  echo 'FAIL'
  echo "${name} not ready after ${max_tries} tries"
  if [ -f "$(ready_response_filename)" ]; then
    echo "$(ready_response)"
  fi
  docker logs ${name}
  exit 3
}

# - - - - - - - - - - - - - - - - - - -
ready()
{
  local -r port="${1}"
  local -r path=ready
  local -r ready_cmd="\
    curl \
      --fail \
      --output $(ready_response_filename) \
      --silent \
      -X GET \
        http://${IP_ADDRESS}:${port}/${path}"
  rm -f "$(ready_response_filename)"
  if ${ready_cmd} && [ "$(ready_response)" = '{"ready?":true}' ]; then
    true
  else
    false
  fi
}

# - - - - - - - - - - - - - - - - - - -
ready_response()
{
  cat "$(ready_response_filename)"
}

# - - - - - - - - - - - - - - - - - - -
ready_response_filename()
{
  echo /tmp/curl-custom-ready-output
}

# - - - - - - - - - - - - - - - - - - -
exit_unless_clean()
{
  local -r name="${1}"
  local -r docker_log=$(docker logs "${name}" 2>&1)
  local -r line_count=$(echo -n "${docker_log}" | grep -c '^')
  echo -n "Checking ${name} started cleanly..."
  # 3 lines on Thin (Unicorn=6, Puma=6)
  #Thin web server (v1.7.2 codename Bachmanity)
  #Maximum connections set to 1024
  #Listening on 0.0.0.0:4536, CTRL+C to stop
  if [ "${line_count}" == '3' ]; then
    echo 'OK'
  else
    echo 'FAIL'
    echo_docker_log "${name}" "${docker_log}"
    exit 3
  fi
}

# - - - - - - - - - - - - - - - - - - -
echo_docker_log()
{
  local -r name="${1}"
  local -r docker_log="${2}"
  echo "[docker logs ${name}]"
  echo "<docker_log>"
  echo "${docker_log}"
  echo "</docker_log>"
}

# - - - - - - - - - - - - - - - - - - -
container_up()
{
  local -r port="${1}"
  local -r service_name="${2}"
  local -r container_name="test-${service_name}"
  echo
  docker-compose \
    --file "${ROOT_DIR}/docker-compose.yml" \
    up \
    -d \
    --force-recreate \
      "${service_name}"
  if [ "${3}" = 'ready' ]; then
    wait_briefly_until_ready "${port}" "${container_name}"
  fi
  if [ "${4}" = 'clean' ]; then
    exit_unless_clean "${container_name}"
  fi
}

# - - - - - - - - - - - - - - - - - - -
container_up 4526 custom-start-points ready clean
container_up 4537 saver               ready clean
container_up 4523 creator             ready clean
container_up 4536 custom              ready
# can't do clean-check for custom as sinatra-contrib
# does several method redefinitions which cause warnings
container_up 80 nginx
sleep 1