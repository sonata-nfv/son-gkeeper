pipeline {
// This step should not normally be used in your script. Consult the inline help for details.
withDockerRegistry([credentialsId: 'dockerregistry', url: 'registry.sonata-nfv.eu:5000']) {
    // some block
}

	def app
	agent any

	stages{
		stage('Build'){
			steps{
				echo 'Building son-gtkapi '
				app = docker.build("registry.sonata-nfv.eu:5000/son-gtkapi", "-f son-gtkapi/Dockerfile")
			}
		}
        }
}
