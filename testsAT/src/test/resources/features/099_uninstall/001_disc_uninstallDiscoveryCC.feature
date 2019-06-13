@rest @always
Feature: [QATM-1866] Discovery uninstall with Command Center

  Scenario:[QATM-1866][9001] Uninstall Discovery
    Given I authenticate to DCOS cluster '${DCOS_IP}' using email '${DCOS_USER:-admin}' with user '${BOOTSTRAP_USER:-operador}' and pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    And I open a ssh connection to '${DCOS_CLI_HOST}' with user 'root' and password 'stratio'
    # Check if service_ID contains "/" character or subdirectories. Ex: /discovery/discovery
    Then I run 'echo /discovery/${DISCOVERY_CLUSTER_NAME:-discovery}/} | sed 's/^\/\(.*\)/\1/'' in the ssh connection and save the value in environment variable 'serviceName'
    When I send a 'DELETE' request to '/service/deploy-api/deploy/uninstall?force=true&app=discovery/${DISCOVERY_CLUSTER_NAME:-discovery}'
    # Check Uninstall in DCOS
    Then in less than '600' seconds, checking each '10' seconds, the command output 'dcos task | grep ${DISCOVERY_CLUSTER_NAME:-discovery} | wc -l' contains '0'
    # Check Uninstall in CCT-API
    And in less than '200' seconds, checking each '10' seconds, I send a 'GET' request to '/service/deploy-api/deploy/status/all' so that the response does not contains '${DISCOVERY_CLUSTER_NAME:-discovery}'

  Scenario:[QATM-1866][9002] Retrieve Docker information
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When in less than '600' seconds, checking each '20' seconds, I send a 'GET' request to '/exhibitor/exhibitor/v1/explorer/node-data?key=%2Fdatastore%2Fcommunity%2F${POSTGRES_NAME:-postgrestls}%2Fplan-v2-json&_=' so that the response contains 'str'
    Then I send a 'GET' request to '/exhibitor/exhibitor/v1/explorer/node-data?key=%2Fdatastore%2Fcommunity%2F${POSTGRES_NAME:-postgrestls}%2Fplan-v2-json&_='
    And I save element '$.str' in environment variable 'exhibitor_answer'
    And I save ''!{exhibitor_answer}'' in variable 'parsed_answer'
    And I wait '2' seconds
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user '${ROOT_USER:-root}' and password '${ROOT_PASSWORD:-stratio}'
    And I run 'echo !{parsed_answer} | jq '.phases[0]."0001".steps[] | select (.[].name=="pg-0001")' |jq .[].agent_hostname | sed 's/^.\|.$//g'' in the ssh connection with exit status '0' and save the value in environment variable 'pgIP'
    And I run 'echo !{pgIP}' in the ssh connection
    Then I wait '3' seconds
    And I run 'echo !{parsed_answer} | jq '.phases[0]."0001".steps[] | select (.[].name=="pg-0001")' |jq .[].container_hostname | sed 's/^.\|.$//g'' in the ssh connection with exit status '0' and save the value in environment variable 'pgIPCalico'
    Then I wait '2' seconds
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    When I run 'sudo docker ps -q |sudo xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \// /'| grep '!{pgIPCalico} ' | awk '{print $2}'' in the ssh connection and save the value in environment variable 'postgresDocker'
    And I wait '3' seconds
    And I run 'echo !{postgresDocker}' in the ssh connection with exit status '0'

  @skipOnEnv(SKIP_POLICY)
  Scenario:[QATM-1866][9003] Delete postgres Policy
    # Generate token to connect to gosec
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${DCOS_USER:-admin}' and password '${DCOS_PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Send request
    When I send a 'DELETE' request to '${BASE_END_POINT:-/service/gosecmanagement}/api/policy/${DISCOVERY_CLUSTER_NAME:-discovery}_pg'
    Then the service response status must be '200'
    And I wait '5' seconds

  @skipOnEnv(SKIP_DATABASE_CREATION)
  Scenario:[QATM-1863][9004] Drop Schema
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    Then in less than '50' seconds, checking each '10' seconds, the command output 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -d ${DISCOVERY_CLUSTER_NAME:-discovery} -c "DROP SCHEMA \"${DISCOVERY_SCHEMA:-public}\" CASCADE;"' contains 'drop cascades'

  @skipOnEnv(SKIP_DATABASE_CREATION)
  Scenario:[QATM-1863][9003] Drop Database Discovery
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    Then in less than '400' seconds, checking each '10' seconds, the command output 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "DROP DATABASE \"${DISCOVERY_CLUSTER_NAME:-discovery}\""' contains 'DROP DATABASE'

  Scenario: [QATM-1866][9005] Delete user
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I send a 'DELETE' request to '/service/gosecmanagement/api/user/${DISCOVERY_CLUSTER_NAME:-discovery}'
    Then the service response status must be '200'

  @skipOnEnv(SKIP_GENERATE_DISC_DESCRIPTOR)
  Scenario: [QATM-1863][9006] Delete Command Center Descriptor
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Delete Descriptor
    When I send a 'DELETE' request to '/service/deploy-api/universe/discovery/${DISC_FLAVOUR}-auto/descriptor?force=true'
    Then the service response status must be '200'
