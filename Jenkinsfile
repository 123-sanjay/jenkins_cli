pipeline {
  agent any
  stages {
    stage('Checkout') {
      agent any
      steps {
        echo 'Checking out code...'
        slackSend(color: 'warning', message: "$SLACK_STARTED")
        sh 'if [ -d ".git" ] ; then git clean -fdx; fi;'
        checkout scm
      }
    }
    stage('Build') {
      agent {
        dockerfile {
          reuseNode true
          args '-v ${PWD}:/var/www/html -v ${HOME}/.composer:/.composer -v ${HOME}/.npm:/.npm -w /var/www/html --cpus=0.5 --memory=1024m'
        }

      }
      steps {
        sh 'composer install'
        sh '#sh apply-patch.sh'
        sh 'php bin/magento setup:di:compile'
        sh 'bin/magento setup:static-content:deploy -f'
        sh 'git checkout -- .'
      }
    }
    stage('Compressing Source Code') {
      agent any
      steps {
        echo 'Compressing...'
        sh 'touch "${ARTIFACT}"'
        sh 'tar -czf "${ARTIFACT}" --exclude="${ARTIFACT}" --exclude=".ansible" --exclude=".docker" --exclude=".github" --exclude=".vagrant" --exclude=".docker" --exclude="auth.json" --exclude="Vagrantfile" --exclude="Dockerfile" --exclude="Jenkinsfile" --exclude=".git" --exclude="node_modules" .'
        archiveArtifacts "${ARTIFACT}"
      }
    }
    stage('Deploy') {
      agent any
      steps {
        echo 'Deploying '+ARTIFACT+' to '+SSH_SERVER+'...'
        sshPublisher(failOnError: true, publishers: [
                    sshPublisherDesc(
                        configName: "${SSH_SERVER}",
                        transfers: [
                            sshTransfer(
                                execCommand: """
                               
                                mv "./${ARTIFACT}" "${PROJECT_ROOT}";
                                cd "${PROJECT_ROOT}";
                                

                                echo "Creating release folder...";
                                mkdir -p "release/build-${BUILD_ID}";
                                
                                echo "Extracting build...";
                                tar -xzf "${ARTIFACT}" -C "release/build-${BUILD_ID}";
                                rm "${ARTIFACT}";
                                
                                echo "Symlinking release...";
                                rm -f "release/build-${BUILD_ID}/app/etc/env.php";
                                ln -s "${PROJECT_ROOT}/shared/app/etc/env.php" "release/build-${BUILD_ID}/app/etc/env.php";
                                
                                rm -rf "release/build-${BUILD_ID}/pub/media";
                                ln -s "${PROJECT_ROOT}/shared/media" "release/build-${BUILD_ID}/pub/media";

                                rm -rf "release/build-${BUILD_ID}/var";
                                ln -s "${PROJECT_ROOT}/shared/var" "release/build-${BUILD_ID}/var";

                                rm -f public_html;
                                ln -s "release/build-${BUILD_ID}" public_html;

                                echo "Removing older releases..."
                                cd "release/build-${BUILD_ID}/.."
                                ls -tQ | tail -n+4 | xargs --no-run-if-empty sudo rm -rf
                                

                                echo "Done"
                                """,
                                execTimeout: 90000000,
                                sourceFiles: "${ARTIFACT}"
                              )
                            ]
                          )
                        ])
                sh 'rm "${ARTIFACT}"'
              }
            }
          }
          environment {
            ARTIFACT_RANDOM = UUID.randomUUID().toString()
            SSH_SERVER = 'node-1'
            ENV_NAME = "${BRANCH_NAME == "master" ? "development" : BRANCH_NAME}"
            ARTIFACT = "build-${BRANCH_NAME}-${BUILD_ID}-${ARTIFACT_RANDOM}.tar.gz"
            PROJECT_ROOT = '/home/shrikant/jenkins_cli'
            SLACK_STARTED = "${env.JOB_NAME} has started deploying to ${BRANCH_NAME}-${env.BUILD_NUMBER}. <${env.BUILD_URL}/console|See details.>"
            SLACK_SUCCESS = "${env.JOB_NAME} has finished deploying to ${BRANCH_NAME}-${env.BUILD_NUMBER}. <${env.BUILD_URL}/console|See details.>"
            SLACK_ERROR = "ERROR: ${env.JOB_NAME} has failed deploying to ${BRANCH_NAME}-${env.BUILD_NUMBER}. <${env.BUILD_URL}/console|See details.>"
            ROOT_DIR = '/home/shrikant/jenkins_cli'
            RELEASE_DIR = 'releases/build-${BUILD_ID}'
          }
          post {
            success {
              slackSend(color: 'good', message: "$SLACK_SUCCESS")

            }

            regression {
              slackSend(color: 'danger', message: "$SLACK_ERROR")

            }

          }
          options {
            skipDefaultCheckout(true)
            disableConcurrentBuilds()
            buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
          }
          triggers {
            githubPush()
          }
        }
