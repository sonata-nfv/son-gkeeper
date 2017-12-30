pipeline {
	agent node
	stages{
		stage('Build'){
			steps{
				echo 'Building son-gtkapi '
				docker.withDockerRegistry([credentialsId: 'dockerregistry', url: 'registry.sonata-nfv.eu:5000']) {
					app = docker.build("registry.sonata-nfv.eu:5000/son-gtkapi", "-f son-gtkapi/Dockerfile")
				}
			}
		}
		stage('Test'){
			steps{
				echo 'Testing son-gtkapi'
				docker.withDockerRegistry([credentialsId: 'dockerregistry', url: 'registry.sonata-nfv.eu:5000']) {
					docker.image('redis') { redis ->
						docker.image('redis').inside("--link ${redis.id}:son-redis"){
							sh ' while ! nc -z localhost 6379; do sleep 1; done'
						}
					}
				}
				docker.image('registry.sonata-nfv.eu:5000/son-gtkrlt').withRun('-e RACK_ENV=integration --link ${redis.id}:son-redis') { rlt -> 
					docker.image("registry.sonata-nfv.eu:5000/son-gtkapi").inside('-e RACK_ENV=integration --link ${rlt.id}:son-redis -v "$(pwd)/spec/reports/son-gtkapi:/app/spec/reports'){ api ->
						sh 'bundle exec rake ci:all'
					}
				}
				sh "docker logs ${rlt.id}"
				sh "docker logs ${api.id}"
				sh "docker logs ${redis.id}"	
			}	
        }
	}
}
