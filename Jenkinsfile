@Library('libpipelines@master') _

hose {
    EMAIL = 'rocket'
    MODULE = 'discovery'
    REPOSITORY = 'discovery'
    SLACKTEAM = 'data-governance'
    BUILDTOOL = 'make'
    DEVTIMEOUT = 120
    RELEASETIMEOUT = 80
    BUILDTOOLVERSION = '3.5.0'
    NEW_VERSIONING = 'true'

    ATTIMEOUT = 90
    INSTALLTIMEOUT = 90
    ANCHORE_POLICY = 'discovery'

    PKGMODULESNAMES = ['discovery']

    DEV = { config ->
            doDocker(conf: config, skipOnPR: false)
    }

    INSTALLSERVICES = [

  	    ['CHROME': ['image': 'selenium/node-chrome-debug:3.9.1',
            		'volumes': ['/dev/shm:/dev/shm'],
	                'env': ['HUB_HOST=selenium391.cd','HUB_PORT=4444','SE_OPTS="-browser browserName=chrome,version=64%%JUID "']
            	       ]],
    ]

    INSTALLPARAMETERS = """
        | -DSELENIUM_GRID=selenium391.cd:4444
        | -DFORCE_BROWSER=chrome_64%%JUID
        | """

    ATCREDENTIALS = [[TYPE:'sshKey', ID:'PEM_VMWARE']]

    INSTALL { config, params ->
        def parameters = stringToMap(params.ENVIRONMENT)
    	parameters["PEM_FILE_PATH"] = params["HETZNER_CLUSTER"] ? "\$PEM_VMWARE_PATH" : "\$PEM_VMWARE_KEY"
        parameters["quietasdefault"] = parameters["quietasdefault"] ? parameters["quietasdefault"] : "false"
        parameters["groups"] = parameters["GROUPS_DISCOVERY"] ? parameters["GROUPS_DISCOVERY"] : "nightly"
        def environmentAuth = parameters["HETZNER_CLUSTER"]
        parameters = doReplaceTokens("", parameters)
        doAT(conf: config, parameters: parameters, customServices: customServices, environmentAuth: environmentAuth)

    }
}
