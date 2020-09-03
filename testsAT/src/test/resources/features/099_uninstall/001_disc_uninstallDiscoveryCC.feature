@rest @dcos
Feature: [Uninstallation Discovery Command Center] Discovery uninstall with command center

  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
  Scenario: Uninstall Discovery
    Given I set sso token using host '!{EOS_ACCESS_POINT}' with user '${DCOS_TENANT1_OWNER_USER}' and password '${DCOS_TENANT1_OWNER_PASSWORD}' and tenant '${DCOS_TENANT1}'
    And I securely send requests to '!{EOS_ACCESS_POINT}:443'
    Then I uninstall service '${DISCOVERY_ID:-discovery-qa}' from tenant '${DCOS_TENANT1}'

  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
  Scenario: [QATM-1863][03] Delete Discovery policy
    Given I delete 'policy' '${DCOS_TENANT1}-${DISCOVERY_ID:-discovery-qa}' from tenant '${DCOS_TENANT1}' with tenant user and tenant password '${DCOS_TENANT1_OWNER_USER}:${DCOS_TENANT1_OWNER_PASSWORD}' if it exists

#  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
#  @include(feature:../templates/Discovery_Templates.feature,scenario: Get Postgres IP)
#  Scenario: Get Postgres IP
#
#  @skipOnEnv(DISCOVERY_SKIP_UNINSTALL=yes)
#  Scenario: Drop Schema
#    Given I open a ssh connection to '!{pgIP}' with user '${REMOTE_USER}' using pem file '${PEM_FILE_PATH}'
##    And I run 'sudo docker exec -t !{pgContainerName} psql -p 5432 -U postgres -c "\connect ${DISCOVERY_METADATA_DB_NAME:-discovery};" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DISCOVERY_METADATA_DB_NAME:-discovery}'""' in the ssh connection with exit status '0'
#    When I run 'docker exec -t !{pgContainerName} psql -p 5432 -U postgres -c "DROP DATABASE ${DISCOVERY_METADATA_DB_NAME:-discovery}"' in the ssh connection
#    Then the command output contains 'DROP DATABASE'
