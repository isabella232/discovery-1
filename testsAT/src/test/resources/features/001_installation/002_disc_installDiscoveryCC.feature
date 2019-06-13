@rest
Feature: [QATM-1866] Discovery install with Command Center

  @skipOnEnv(SKIP_GENERATE_DISC_DESCRIPTOR)
  Scenario: [QATM-1866][01] Generate New Descriptor for CommandCenter
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
   # Obtain Descriptor
    Given I authenticate to DCOS cluster '${DCOS_IP}' using email '${DCOS_USER:-admin}' with user '${BOOTSTRAP_USER:-operador}' and pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    Then I run 'curl -k -s -X GET -H 'Cookie:dcos-acs-auth-cookie=!{dcosAuthCookie}' https://${CLUSTER_ID:-nightly}.${CLUSTER_DOMAIN:-labs.stratio.com}:443/service/${DEPLOY_API:-deploy-api}/universe/discovery/${DISC_FLAVOUR}/descriptor | jq .> target/test-classes/schemas/discovery-descriptor.json' locally
   # Create Descriptor
    When I send a 'POST' request to '/service/${DEPLOY_API:-deploy-api}/universe/discovery/${DISC_FLAVOUR}-auto/descriptor' based on 'schemas/discovery-descriptor.json' as 'json' with:
      | $.data.model                      | REPLACE | ${DISC_FLAVOUR}-auto                                                        | string |
      | $.data.container.runners[0].image | REPLACE | ${DOCKER_URL_DISCOVERY:-qa.stratio.com/stratio/discovery}:${STRATIO_DISCOVERY_VERSION:-0.33.2} | string |

  @skipOnEnv(SKIP_USERS)
  Scenario: [QATM-1866][02] Create discovery user
    # Generate token to connect to gosec
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Send request - Sparta user
    And I create 'user' '${DISCOVERY_CLUSTER_NAME:-discovery}' in endpoint '/service/gosecmanagement/api/user' if it does not exist based on 'schemas/gosec_user.json' as 'json' with:
      | $.id    | UPDATE | ${DISCOVERY_CLUSTER_NAME:-discovery}               | string |
      | $.name  | UPDATE | ${DISCOVERY_CLUSTER_NAME:-discovery}               | string |
      | $.email | UPDATE | ${DISCOVERY_CLUSTER_NAME:-discovery}@discovery.com | string |
    And the service response must contain the text '"id":"${DISCOVERY_CLUSTER_NAME:-discovery}"'
  Scenario:[QATM-1866][03] Retrieve Docker information
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When in less than '600' seconds, checking each '20' seconds, I send a 'GET' request to '/exhibitor/exhibitor/v1/explorer/node-data?key=%2Fdatastore%2Fcommunity%2F${POSTGRES_NAME}%2Fplan-v2-json&_=' so that the response contains 'str'
    Then I send a 'GET' request to '/exhibitor/exhibitor/v1/explorer/node-data?key=%2Fdatastore%2Fcommunity%2F${POSTGRES_NAME:-postgrestls}%2Fplan-v2-json&_='
    And I save element '$.str' in environment variable 'exhibitor_answer'
    And I save ''!{exhibitor_answer}'' in variable 'parsed_answer'
    And I wait '2' seconds
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user '${ROOT_USER:-root}' and password '${ROOT_PASSWORD:-stratio}'
    And I run 'echo !{parsed_answer} | jq '.phases[0]."0001".steps[] | select (.[].name=="pg-0001")' |jq .[].agent_hostname | sed 's/^.\|.$//g'' in the ssh connection with exit status '0' and save the value in environment variable 'pgIP'
    And I run 'echo !{pgIP}' in the ssh connection
    Then I wait '10' seconds
    And I run 'echo !{parsed_answer} | jq '.phases[0]."0001".steps[] | select (.[].name=="pg-0001")' |jq .[].container_hostname | sed 's/^.\|.$//g'' in the ssh connection with exit status '0' and save the value in environment variable 'pgIPCalico'
    Then I wait '2' seconds
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    When I run 'sudo docker ps -q |sudo xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \// /'| grep '!{pgIPCalico} ' | awk '{print $2}'' in the ssh connection and save the value in environment variable 'postgresDocker'
    And I wait '10' seconds
    And I run 'echo !{postgresDocker}' in the ssh connection with exit status '0'

  @skipOnEnv(SKIP_DATABASE_CREATION)
  Scenario:[QATM-1866][03] Create database for Discovery on Postgres
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    When I run 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "CREATE DATABASE \"${DISCOVERY_CLUSTER_NAME:-discovery}\""' in the ssh connection
  # When I run 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "CREATE SCHEMA IF NOT EXISTS \"${DISCOVERY_SCHEMA:-public}\""' in the ssh connection
  @skipOnEnv(SKIP_POLICY)
  Scenario:[QATM-1866][04] Creation policy for user discovery
    # Generate token to connect to gosec
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Obtain postgres plugin version
    When I send a 'GET' request to '${BASE_END_POINT:-/service/gosecmanagement}/api/service'
    Then the service response status must be '200'
    And I save element '$.[?(@.type == "communitypostgres")].pluginList[*]' in environment variable 'POSTGRES_PLUGINS'
    And I run 'echo '!{POSTGRES_PLUGINS}' | jq '.[] | select (.instanceList[].name == "{POSTGRES_NAME:-postgrestls}").version'' locally and save the value in environment variable 'POSTGRES_PLUGIN_VERSION'
    # Create policy
    Given I create 'policy' '${DISCOVERY_CLUSTER_NAME:-discovery}_pg' in endpoint '${BASE_END_POINT:-/service/gosecmanagement}/api/policy' if it does not exist based on 'schemas/pg_policy_standar.json' as 'json' with:
      | $.id                                            | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}_pg   | string |
      | $.name                                          | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}_pg   | string |
      | $.users[0]                                      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}    | n/a |
      | $.services[0].instancesAcl[0].instances[0].name | UPDATE  | ${POSTGRES_NAME:-postgrestls} | string |
      | $.services[0].instancesAcl[0].acls[0].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[1].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[2].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[3].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[4].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[5].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[6].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[7].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[8].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[9].name      | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[10].name     | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[11].name     | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
      | $.services[0].instancesAcl[0].acls[12].name     | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}.* | string |
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    Then in less than '300' seconds, checking each '10' seconds, the command output 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "\du" -P pager=off' contains '${DISCOVERY_CLUSTER_NAME:-discovery}'


  Scenario: [QATM-1866][05] Take Marathon-lb IP
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user '${ROOT_USER:-root}' and password '${ROOT_PASSWORD:-stratio}'
    And I run 'dcos marathon task list | grep marathon.*lb.* | awk '{print $4}'' in the ssh connection and save the value in environment variable 'marathonIP'
    Then I wait '1' seconds
    And I open a ssh connection to '!{marathonIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I run 'hostname | sed -e 's|\..*||'' in the ssh connection with exit status '0' and save the value in environment variable 'MarathonLbDns'


  Scenario:[QATM-1866][06] Basic install
    Given I authenticate to DCOS cluster '${DCOS_IP}' using email '${DCOS_USER:-admin}' with user '${BOOTSTRAP_USER:-operador}' and pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Obtain schema
    When I send a 'GET' request to '/service/deploy-api/deploy/discovery/${DISC_FLAVOUR:-hydra}/schema?level=1'
    Then I save element '$' in environment variable 'discovery-json-schema'
    And I run 'echo !{discovery-json-schema}' locally
    # Convert to jsonSchema
    And I convert jsonSchema '!{discovery-json-schema}' to json and save it in variable 'discovery-basic.json'
    And I run 'echo '!{discovery-basic.json}' > target/test-classes/schemas/discovery-basic.json' locally
    # Launch basic install
    When I send a 'POST' request to '/service/deploy-api/deploy/discovery/${DISC_FLAVOUR:-pegaso}/schema' based on 'schemas/discovery-basic.json' as 'json' with:
      | $.general.serviceId                        | REPLACE | /discovery/${DISCOVERY_CLUSTER_NAME:-discovery}          | string |
      | $.general.marathonlb.haproxyhost           | REPLACE | !{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}     | string |
      | $.general.marathonlb.haproxypath           | REPLACE | /${DISCOVERY_CLUSTER_NAME:-discovery}                    | string |
      | $.general.datastore.metadataDbInstanceName | REPLACE | ${POSTGRES_NAME:-postgrestls}           | string |
      | $.general.datastore.metadataDbName         | REPLACE | ${DISCOVERY_CLUSTER_NAME:-discovery}                     | string |
      | $.general.datastore.tenantName             | REPLACE | ${DISCOVERY_CLUSTER_NAME:-discovery}                   | string |
      | $.general.datastore.metadataDbHost         | REPLACE | pg-0001.${POSTGRES_NAME:-postgrestls}.mesos      | string |
      | $.general.calico.networkName               | REPLACE | ${DISCOVERY_NETWORK_NAME:-stratio}                       | string |
      | $.general.resources.instances              | REPLACE | ${DISCOVERY_SERVICE_INSTANCES:-1}                        | number |
      | $.general.resources.cpus                   | REPLACE | ${DISCOVERY_SERVICE_CPUS:-1}                             | number |
      | $.general.resources.mem                    | REPLACE | ${DISCOVERY_SERVICE_MEM:-2048}                           | number |
      | $.general.identity.approlename             | REPLACE | ${APPROLENAME:-open}                                     | string |
# Comentamos variables ya que no disponemos de valores válidos
#       | $.settings.Login                            | ADD     | {}                                            | object  |
#       | $.settings.Login.mb-user-header             | ADD     | ${MB_USER_HEADER:- "fdsa"}                    | string  |
#       | $.settings.Login.mb-admin-group-header      | ADD     | ${MB_ADMIN_GROUP_HEADER:-"4e32" }             | string  |
#       | $.settings.Login.mb-group-header            | ADD     | ${MB_GROUP_HEADER:-"433" }                    | string  |
#       | $.general.identity.approlename              | UPDATE  | ${DISCOVERY_SECURITY_INSTANCE_APP_ROLE:-open} | n/a     |
    Then the service response status must be '202'
    And I run 'rm -f target/test-classes/schemas/discovery-basic.json' locally

  Scenario:[QATM-1866][07] Check status
    Given I authenticate to DCOS cluster '${DCOS_IP}' using email '${DCOS_USER:-admin}' with user '${BOOTSTRAP_USER:-operador}' and pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Check Application in API
    Then in less than '500' seconds, checking each '10' seconds, I send a 'GET' request to '/service/deploy-api/deploy/status/all' so that the response contains 'discovery/${DISCOVERY_CLUSTER_NAME:-discovery}'
    # Check status in API
    And in less than '500' seconds, checking each '10' seconds, I send a 'GET' request to '/service/deploy-api/deploy/status/service?service=/discovery/${DISCOVERY_CLUSTER_NAME:-discovery}' so that the response contains '"healthy":1'
    # Check status in DCOS
    # Checking if service_ID contains "/" character or subdirectories. Ex: /discovery/discovery
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user 'root' and password 'stratio'
    Then I run 'echo discovery/${DISCOVERY_CLUSTER_NAME:-discovery} | sed 's/\//./g' |  sed 's/^\.\(.*\)/\1/'' locally and save the value in environment variable 'serviceIDDcosTaskPath'
    And in less than '700' seconds, checking each '20' seconds, the command output 'dcos task | grep !{serviceIDDcosTaskPath} | grep R | wc -l' contains '1'
    When I run 'dcos task |  awk '{print $5}' | grep !{serviceIDDcosTaskPath}' in the ssh connection and save the value in environment variable 'dicoveryTaskId'
    Then in less than '10' seconds, checking each '10' seconds, the command output 'dcos marathon task show !{dicoveryTaskId} | grep TASK_RUNNING |wc -l' contains '1'
    And in less than '10' seconds, checking each '10' seconds, the command output 'dcos marathon task show !{dicoveryTaskId} | grep '"alive": true |wc -l' contains '1'

  Scenario:[QATM-1866][08] Check Discovery frontend
    Given I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}'
    And in less than '600' seconds, checking each '100' seconds, I send a 'GET' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}' so that the response contains 'Metabase'
    Then the service response status must be '200'

  @web
  Scenario:[QATM-1866][09] Check Discovery frontend
    Given My app is running in '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}'
    And in less than '300' seconds, checking each '10' seconds, '1' elements exists with 'xpath://input[@name="username"]'
    And in less than '300' seconds, checking each '10' seconds, '1' elements exists with 'xpath://input[@name="password"]'
    And I take a snapshot
