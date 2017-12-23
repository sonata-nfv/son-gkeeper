pipeline {
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
