@rest
Feature:[QATM-1866] Postgres conexion with Discovery

  Background: Initial setup
    Given I authenticate to DCOS cluster '${DCOS_IP}' using email '${DCOS_USER:-admin}' with user '${BOOTSTRAP_USER:-operador}' and pem file 'src/test/resources/credentials/${PEM_FILE:-key.pem}'
    And I open a ssh connection to '${DCOS_CLI_HOST}' with user '${CLI_USER:-root}' and password '${CLI_PASSWORD:-stratio}'
    And I securely send requests to '${DCOS_IP}:443'

  Scenario:[01] Obtain postgreSQL ip and port
    Given I send a 'GET' request to '/service/${POSTGRES_NAME:-postgrestls}/v1/service/status'
    Then the service response status must be '200'
    And I save element in position '0' in '$.status[?(@.role == "master")].dnsHostname' in environment variable 'postgresTLS_Host'
    And I save element in position '0' in '$.status[?(@.role == "master")].ports[0]' in environment variable 'postgresTLS_Port'
    And I wait '5' seconds

  Scenario: [QATM-1866][05] Take Marathon-lb IP
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user '${ROOT_USER:-root}' and password '${ROOT_PASSWORD:-stratio}'
    And I run 'dcos marathon task list | grep marathon.*lb.* | awk '{print $4}'' in the ssh connection and save the value in environment variable 'marathonIP'
    Then I wait '1' seconds
    And I open a ssh connection to '!{marathonIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I run 'hostname | sed -e 's|\..*||'' in the ssh connection with exit status '0' and save the value in environment variable 'MarathonLbDns'

  Scenario:[QATM-1866][03] Retrieve Docker information
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

  Scenario:[QATM-1866][04] Create database for Discovery on Postgres
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
      When I run 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "CREATE DATABASE ${DISCOVERY_DATA_DB:-pruebadiscovery}"' in the ssh connection
      Then the command output contains 'CREATE DATABASE'
      And I wait '30' seconds


  @skipOnEnv(SKIP_POLICY)
  Scenario:[QATM-1866][04] Creation policy for user discovery
    # Generate token to connect to gosec
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${USER:-admin}' and password '${PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Obtain postgres plugin version
    When I send a 'GET' request to '${BASE_END_POINT:-/service/gosecmanagement}/api/service'
    Then the service response status must be '200'
    And I save element '$.[?(@.type == "communitypostgres")].pluginList[*]' in environment variable 'POSTGRES_PLUGINS'
    And I run 'echo '!{POSTGRES_PLUGINS}' | jq '.[] | select (.instanceList[].name == "${POSTGRES_FRAMEWORK_ID_TLS:-postgrestls}").version'' locally and save the value in environment variable 'POSTGRES_PLUGIN_VERSION'
    # Create policy
    Given I create 'policy' 'pdiscovery_pg' in endpoint '${BASE_END_POINT:-/service/gosecmanagement}/api/policy' if it does not exist based on 'schemas/pg_policy_standar.json' as 'json' with:
      | $.id                                            | UPDATE  | pdiscovery_pg   | string |
      | $.name                                          | UPDATE  | pdiscovery_pg   | string |
      | $.users[0]                                      | UPDATE | ${DISCOVERY_CLUSTER_NAME:-discovery}    | n/a |
      | $.services[0].instancesAcl[0].instances[0].name | UPDATE  | ${POSTGRES_NAME:-postgrestls} | string |
      | $.services[0].instancesAcl[0].acls[0].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[1].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[2].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[3].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[4].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[5].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[6].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[7].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[8].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[9].name      | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[10].name     | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[11].name     | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
      | $.services[0].instancesAcl[0].acls[12].name     | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}.* | string |
    Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    Then in less than '300' seconds, checking each '10' seconds, the command output 'sudo docker exec -t !{postgresDocker} psql -p 5432 -U postgres -c "\du" -P pager=off' contains '${DISCOVERY_TENANT_NAME:-crossdata-1}'

    Scenario:[QATM-1866][05] Create data for Discovery on Postgres
      Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
      And I outbound copy 'src/test/resources/schemas/createPGContent.sql' through a ssh connection to '/tmp'
      Then in less than '300' seconds, checking each '10' seconds, the command output 'sudo docker cp /tmp/createPGContent.sql !{postgresDocker}:/tmp/ ; sudo docker exec -t !{postgresDocker} psql -p 5432 -U "${DISCOVERY_TENANT_NAME:-crossdata-1}" -d ${DISCOVERY_DATA_DB:-pruebadiscovery} -f /tmp/createPGContent.sql | grep "INSERT 0 1" | wc -l' contains '254'
      Then the command output contains '254'

    Scenario:[04] Create Postgres Connection with Discovery
      # Register postgres database
      Given I obtain metabase id for user '${USER:-demo@stratio.com}' and password '${PASSWORD:-123456}' in endpoint 'https://!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_SESSION:-/api/session}' and save in context cookies
      When I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
      When I send a 'POST' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATABASES:-/api/database}' based on 'schemas/registerdatabase.json' as 'json' with:
      #Then in less than '5' seconds, checking each '1' seconds, I send a 'POST' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATABASES:-/api/database}' so that the response contains '"name":"${DISCOVERY_CLUSTER_NAME:-discovery}",' based on 'schemas/registerdatabase.json' as 'json' with:
        | $.engine                                        | UPDATE  | ${DISCOVERY_ENGINE_PG:-postgres}                                                                                                                                                        | string |
        | $.name                                          | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}_pg                                                                                                                                     | string |
        | $.details.host                                  | UPDATE  | !{postgresTLS_Host}                                                                                                                                                                     | string |
        | $.details.port                                  | REPLACE | !{postgresTLS_Port}                                                                                                                                                                     | number |
        | $.details.dbname                                | UPDATE  | ${DISCOVERY_DATA_DB:-pruebadiscovery}                                                                                                                                                   | string |
        | $.details.user                                  | UPDATE  | ${DISCOVERY_CLUSTER_NAME:-discovery}                                                                                                                                                   | string |
        | $.details.additional-options                    | UPDATE  | ssl=true&sslmode=verify-full&sslcert=/root/kms/${DISCOVERY_CLUSTER_NAME:-discovery}.pem&sslkey=/root/kms/${DISCOVERY_CLUSTER_NAME:-discovery}.pk8&sslrootcert=/root/kms/root.pem      | string |
      # Get postgres database id
      Then the service response status must be '200'
      When I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
      Then in less than '300' seconds, checking each '10' seconds, I send a 'GET' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATABASES:-/api/database}' so that the response contains '"engine":"postgres"'
      Then the service response status must be '200'
      And I save element '$' in environment variable 'exhibitor_answer'
      And I save ''!{exhibitor_answer}'' in variable 'parsed_answer'
      And I run 'echo !{parsed_answer} | jq '.[] | select(.engine=="postgres") | .id'' locally and save the value in environment variable 'pgdatabaseId'
      When I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
      Then in less than '300' seconds, checking each '10' seconds, I send a 'GET' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATABASES:-/api/table}' so that the response contains '"engine":"postgres"'
      Then the service response status must be '200'
      And I save element '$' in environment variable 'tables_answer'
      And I save ''!{tables_answer}'' in variable 'parsed_answer'
      And I run 'echo !{parsed_answer} | jq '.[] | select(.name=="table_test_plan") | .id'' locally and save the value in environment variable 'pgtableId'
      # Check query postgres database
      When I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
      #Then in less than '5' seconds, checking each '1' seconds, I send a 'POST' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATASET:-/api/dataset}' so that the response contains '200' based on 'schemas/dataset.json' as 'json' with:
      #And I wait '4' seconds
      When I send a 'POST' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATASET:-/api/dataset}' based on 'schemas/dataset.json' as 'json' with:
        | $.database                 | REPLACE | !{pgdatabaseId}                         | number |
        | $.type                     | UPDATE  | ${DISCOVERY_TYPE_DATASET:-query}        | string |
        | $.query.source_table       | REPLACE | !{pgtableId}                            | number |
      And the service response must contain the text 'Northern Europe'


  @web
  Scenario:[QATM-1866] Postgres envidences
    Given My app is running in '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}'
    When I wait for element 'xpath://input[@name="username"]' to be available for '120' seconds
    And '1' elements exists with 'xpath://input[@name="username"]'
    And I type '${USER:-demo@stratio.com}' on the element on index '0'
    And '1' elements exists with 'xpath://input[@name="password"]'
    And I type '${PASSWORD:-123456}' on the element on index '0'
    And '1' elements exists with 'xpath://*[@id="root"]/div/div/div/div[2]/form/div[4]/button'
    And I click on the element on index '0'
    When I wait for element 'css:.Navbar__SearchInput-eetmmO' to be available for '15' seconds
    #When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}/browse/!{pgdatabaseId}'
    When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}/browse/20'
    And I wait '2' seconds
    And I take a snapshot
    #When I wait for element 'xpath://div[@class="sc-htpNat jncdfk"]' to be available for '120' seconds
    #When I wait for element 'xpath://*[@class='sc-htpNat jncdfk']//*[text()='Table Test Plan']' to be available for '120' seconds
    #When I wait for element 'xpath://*[@id="root"]//*[text()='Table Test Plan']' to be available for '120' seconds
#    And this text exists 'Europe'


  Scenario:[QATM-1866][03] Delete postgres Policy
    # Generate token to connect to gosec
    Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${DCOS_USER:-admin}' and password '${DCOS_PASSWORD:-1234}' and tenant 'NONE'
    And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    # Send request
    And I wait '1' seconds
    When I send a 'DELETE' request to '${BASE_END_POINT:-/service/gosecmanagement}/api/policy/pdiscovery_pg'
    Then the service response status must be '200'
    And I wait '5' seconds


  Scenario:[QATM-1866][05] Delete database conexion with Postgrestls
    Given I obtain metabase id for user '${USER:-demo@stratio.com}' and password '${PASSWORD:-123456}' in endpoint 'https://!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_SESSION:-/api/session}' and save in context cookies
    When I securely send requests to '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I send a 'DELETE' request to '/${DISCOVERY_CLUSTER_NAME:-discovery}${DISCOVERY_DATABASES:-/api/database}/!{pgtableId}'

  Scenario:[QATM-1866][06] Delete database for Discovery on Postgrestls
      Given I set sso token using host '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}' with user '${DCOS_USER:-admin}' and password '${DCOS_PASSWORD:-1234}' and tenant 'NONE'
      And I securely send requests to '${CLUSTER_ID}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
      When in less than '300' seconds, checking each '20' seconds, I send a 'GET' request to '/exhibitor/exhibitor/v1/explorer/node-data?key=%2Fdatastore%2Fcommunity%2F${POSTGRES_NAME:-postgrestls}%2Fplan-v2-json&_=' so that the response contains 'str'
      And the service response status must be '200'
      And I save element '$.str' in environment variable 'exhibitor_answer'
      And I save ''!{exhibitor_answer}'' in variable 'parsed_answer'
      And I run 'echo !{parsed_answer} | jq '.phases[0]' | jq '."0001".steps[0]'| jq '."0"'.agent_hostname | sed 's/^.\|.$//g'' locally with exit status '0' and save the value in environment variable 'pgIP'
      And I run 'echo !{pgIP}' locally
      Then I wait '10' seconds
      When in less than '300' seconds, checking each '20' seconds, I send a 'GET' request to '/service/${POSTGRES_NAME:-postgrestls}/v1/service/status' so that the response contains 'status'
      Then the service response status must be '200'
      And I save element in position '0' in '$.status[?(@.role == "master")].assignedHost' in environment variable 'pgIPCalico'
      And I save element in position '0' in '$.status[?(@.role == "master")].ports[0]' in environment variable 'pgPortCalico'
      Given I open a ssh connection to '!{pgIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
      When I run 'sudo docker ps -q |sudo xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \// /'| grep !{pgIPCalico} | awk '{print $2}'' in the ssh connection and save the value in environment variable 'postgresDocker'
      When I run 'sudo docker exec -t !{postgresDocker} psql -p !{pgPortCalico} -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DISCOVERY_DATA_DB:-pruebadiscovery}'"' in the ssh connection
      When I run 'sudo docker exec -t !{postgresDocker} psql -p !{pgPortCalico} -U postgres -c "DROP DATABASE ${DISCOVERY_DATA_DB:-pruebadiscovery}"' in the ssh connection
      Then the command output contains 'DROP DATABASE'
