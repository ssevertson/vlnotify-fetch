#!/bin/bash

disabled() {
  echo "Continuous Deployment disabled - ${*}" 1>&2 && exit 0
}

[[ -n "${TRAVIS_PULL_REQUEST}" && "${TRAVIS_PULL_REQUEST}" != "false"  ]] && disabled "Pull request #${TRAVIS_PULL_REQUEST}"
[[ -n "${TRAVIS_BRANCH}"       && "${TRAVIS_BRANCH}"       != "master" ]] && disabled "Branch ${TRAVIS_BRANCH}"

[[ -z "${IRON_IO_JSON}" ]] && IRON_IO_JSON='iron.json'

if [[ ! -e "${IRON_IO_JSON}" ]]
then
  [[ -z "${IRON_IO_PROJECT_ID}" ]] && disabled 'env.IRON_IO_PROJECT_ID not set'
  [[ -z "${IRON_IO_TOKEN}"      ]] && disabled 'env.IRON_IO_TOKEN not set'

  IRON_IO_JSON_GENERATED=1
  cat > "${IRON_IO_JSON}" <<-EOF
    {
      "project_id": "${IRON_IO_PROJECT_ID}",
      "token": "${IRON_IO_TOKEN}"
    }
EOF
fi

type iron_worker >/dev/null 2>&1 || gem install iron_worker_ng || exit
iron_worker upload fetch

if [[ ${IRON_IO_JSON_GENERATED} -eq 1 ]]
then
  rm "${IRON_IO_JSON}"
fi