Feature: [QATM-1866] Login with user and password
  @rest
  Scenario:[QATM-1866] Take Marathon-lb IP
    When I open a ssh connection to '${DCOS_CLI_HOST}' with user '${ROOT_USER:-root}' and password '${ROOT_PASSWORD:-stratio}'
    And I run 'dcos marathon task list | grep marathon.*lb.* | awk '{print $4}'' in the ssh connection and save the value in environment variable 'marathonIP'
    Then I wait '1' seconds
    And I open a ssh connection to '!{marathonIP}' with user '${BOOTSTRAP_USER:-operador}' using pem file '${BOOTSTRAP_PEM:-src/test/resources/credentials/key.pem}'
    And I run 'hostname | sed -e 's|\..*||'' in the ssh connection with exit status '0' and save the value in environment variable 'MarathonLbDns'

  @web
  Scenario:[QATM-1866] Default Login
    Given My app is running in '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}'
    When I wait for element 'xpath://input[@name="username"]' to be available for '120' seconds
    And '1' elements exists with 'xpath://input[@name="username"]'
    And I type '${USER:-demo@stratio.com}' on the element on index '0'
    And '1' elements exists with 'xpath://input[@name="password"]'
    And I type '${PASSWORD:-123456}' on the element on index '0'
    And '1' elements exists with 'xpath://*[@id="root"]/div/div/div/div[2]/form/div[4]/button'
    And I click on the element on index '0'
    And I wait '5' seconds
    #And '1' elements exists with 'xpath://*[contains(@data-metabase-event,'New Question')]'
    Then '1' element exists with 'css:.Navbar__SearchInput-eetmmO'
    And I take a snapshot

  @web
  Scenario:[QATM-1866] Login with invalid user
    Given My app is running in '!{MarathonLbDns}.${CLUSTER_DOMAIN:-labs.stratio.com}:443'
    When I securely browse to '/${DISCOVERY_CLUSTER_NAME:-discovery}'
    When I wait for element 'xpath://input[@name="username"]' to be available for '120' seconds
    And '1' elements exists with 'xpath://input[@name="username"]'
    And I type '${USER:-demo@stratio.com}' on the element on index '0'
    And '1' elements exists with 'xpath://input[@name="password"]'
    And I type '11111111' on the element on index '0'
    And '1' elements exists with 'xpath://*[@id="root"]/div/div/div/div[2]/form/div[4]/button'
    And I click on the element on index '0'
    And I wait '5' seconds
    Then '0' element exists with 'css:.Navbar__SearchInput-eetmmO'
    And I take a snapshot
