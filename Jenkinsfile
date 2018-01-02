pipeline {
  agent any
  stages {
    stage('Build') {
      parallel {
        stage('son-gtkapi') {
          steps {
            sh 'cd tests/integration/build & ./gtkapi.sh'
          }
        }
        stage('son-gtkfnct') {
          steps {
            sh 'cd tests/integration/build & ./gtkfnct.sh'
          }
        }
        stage('son-keycloak') {
          steps {
            sh 'cd tests/integration/build & ./gtkkeycloak.sh'
          }
        }
        stage('son-gtkkpi') {
          steps {
            sh 'cd tests/integration/build & ./gtkkpi.sh'
          }
        }
        stage('son-gtklic') {
          steps {
            sh 'cd tests/integration/build & ./gtklic.sh'
          }
        }
        stage('son-gtkpkg') {
          steps {
            sh 'cd tests/integration/build & ./gtkpkg.sh'
          }
        }
        stage('son-gtkrec') {
          steps {
            sh 'cd tests/integration/build & ./gtkrec.sh'
          }
        }
        stage('son-gtkrlt') {
          steps {
            sh 'cd tests/integration/build & ./gtkrlt.sh'
          }
        }
        stage(' son-gtksrv') {
          steps {
            sh 'cd tests/integration/build & ./gtksrv.sh'
          }
        }
        stage('son-gtkusr') {
          steps {
            sh 'cd tests/integration/build & ./gtkusr.sh'
          }
        }
        stage('son-gtkvim') {
          steps {
            sh 'cd tests/integration/build & ./gtkvim.sh'
          }
        }
        stage('son-sec-gw') {
          steps {
            sh 'cd tests/integration/build & ./son-sec-gw.sh'
          }
        }
      }
    }
    stage('Checkstyle') {
      steps {
        sh 'cd tests/checkstyle & ./gtkall.sh'
      }
    }
    stage('Unit Tests Dependencies') {
      steps {
        sh 'cd tests/unit & ./test-dependencies.sh'
      }
    }
    stage('Unit Test Run') {
      parallel {
        stage('Unit Test Run') {
          steps {
            sh 'cd tests/unit & ./gtkapi.sh'
          }
        }
        stage('son-gtkfnct') {
          steps {
            sh 'cd tests/unit & ./gtkfnct.sh'
          }
        }
        stage('son-gtkkpi') {
          steps {
            sh 'cd tests/unit & ./gtkkpi.sh'
          }
        }
        stage('son-gtklic') {
          steps {
            sh 'cd tests/unit & ./gtklic.sh'
          }
        }
        stage('son-gtkpkg') {
          steps {
            sh 'cd tests/unit & ./gtkpkg.sh'
          }
        }
        stage('son-gtkrlt') {
          steps {
            sh 'cd tests/unit & ./gtkrlt'
          }
        }
        stage('son-gtksrv') {
          steps {
            sh 'cd tests/unit & ./gtksrv.sh'
          }
        }
        stage('son-gtkvim') {
          steps {
            sh 'cd tests/unit & ./gtkvim.sh'
          }
        }
      }
    }
    stage('Integration - Deployment') {
      steps {
        sh 'cd tests/integration & ./deploy.sh'
      }
    }
    stage('Integration - Test') {
      steps {
        sh 'cd tests/integration & ./funtionaltests.sh localhost'
      }
    }
    stage('Containers Publication') {
      parallel {
        stage('son-gtkapi') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkapi'
          }
        }
        stage('son-gtkfnct') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkfnct'
          }
        }
        stage('son-gtkkeycloak') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-keycloak'
          }
        }
        stage('son-gtkkpi') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkkpi'
          }
        }
        stage('son-gtklic') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtklic'
          }
        }
        stage('son-gtkpkg') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkpkg'
          }
        }
        stage('son-gtkrec') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkrec'
          }
        }
        stage('son-gtkrlt') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkrlt'
          }
        }
        stage('son-gtksrv') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtksrv'
          }
        }
        stage('son-gtkusr') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkusr'
          }
        }
        stage('son-gtkvim') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-gtkvim'
          }
        }
        stage('son-sec-gw') {
          steps {
            sh 'docker push registry.sonata-nfv.eu:5000/son-sec-gw'
          }
        }
      }
    }
    stage('Publish results') {
      steps {
        junit(allowEmptyResults: true, testResults: 'tests/spec/reports/son-gtkapi/*.xml, tests/spec/reports/son-gtkpkg/*.xml, tests/spec/reports/son-gtksrv/*.xml, tests/spec/reports/son-gtkfnct/*.xml, tests/spec/reports/son-gtklib/*.xml')
        checkstyle(pattern: 'test/checkstyle/reports/checkstyle-*.xml')
      }
    }
    stage('Email Notification') {
      steps {
        mail(to: 'felipe.vicens@atos.net; jbonnet@alticelabs.com', from: 'jenkins@sonata-nfv.eu', subject: '[JENKINS-5GTANGO] $PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS', body: 'Check console <a href="$BUILD_URL">output</a> to view full results.<br/> If you cannot connect to the build server, check the attached logs.<br/> <br/> --<br/> Following is the last 100 lines of the log.<br/> <br/> --LOG-BEGIN--<br/> <pre style=\'line-height: 22px; display: block; color: #333; font-family: Monaco,Menlo,Consolas,"Courier New",monospace; padding: 10.5px; margin: 0 0 11px; font-size: 13px; word-break: break-all; word-wrap: break-word; white-space: pre-wrap; background-color: #f5f5f5; border: 1px solid #ccc; border: 1px solid rgba(0,0,0,.15); -webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px;\'> ${BUILD_LOG, maxLines=100, escapeHtml=true} </pre> --LOG-END--')
      }
    }
  }
}
