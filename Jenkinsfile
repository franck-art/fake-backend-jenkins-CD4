pipeline {
    agent none
    stages {
        stage('Check bash syntax') {
            agent { docker { image 'koalaman/shellcheck-alpine:latest' } }
            steps {
                sh 'shellcheck --version'
                sh 'apk  --no-cache add grep'
                sh '''
                for file in $(grep -IRl "#!(/usr/bin/env |/bin/)" --exclude-dir ".git" --exclude Jenkinsfile \${WORKSPACE}); do
                  if ! shellcheck -x $file; then
                    export FAILED=1
                  else
                    echo "$file OK"
                  fi
                done
                if [ "${FAILED}" = "1" ]; then
                  exit 1
                fi
                '''
            }
        }
        stage('Check yaml syntax') {
            agent { docker { image 'sdesbure/yamllint' } }
            steps {
                sh 'yamllint --version'
                sh 'yamllint \${WORKSPACE}'
            }
        }
         stage('Check markdown syntax') {
            agent { docker { image 'ruby:alpine' } }
            steps {
                sh 'apk --no-cache add git'
                sh 'gem install mdl'
                sh 'mdl --version'
                sh 'mdl --style all --warnings --git-recurse \${WORKSPACE}'
            }
         }
         stage('Prepare ansible environment') {
            agent any
            environment {
                VAULTKEY = credentials('vaultkey')
                DEVOPSKEY = credentials('devopskey')
            }
            steps {
                sh 'echo \$VAULTKEY > vault.key'
                sh 'cp \$DEVOPSKEY id_rsa'
                sh 'chmod 600 id_rsa'
            }
         }
         stage('Test and deploy the application') {
            agent { docker { image 'registry.gitlab.com/robconnolly/docker-ansible:latest' } }
            stages {
               stage("Install ansible role dependencies") {
                   steps {
                       sh 'ansible-galaxy install -r requirements.yml'
                   }
               }
                stage("Ping targeted hosts") {
                   steps {
                       sh 'ansible all -m ping -i hosts --private-key id_rsa'
                   }
                }
                 stage("Vérify ansible playbook syntax") {
                   steps {
                       sh 'ansible-lint -x 306 playbook.yml'
                       sh 'echo "${GIT_BRANCH}"'
                   }
                 } 
               stage("Build docker images on build host") {
                   when {
                      expression { GIT_BRANCH == 'origin/dev' }
                   }
                   steps {
                       sh 'ansible-playbook  -i hosts --vault-password-file vault.key --private-key id_rsa --tags "build" --limit build playbook.yml'
                   }
               }
               stage("Deploy app in Pre-production Environment") {
                    when {
                       expression { GIT_BRANCH == 'origin/dev' }
                    }
                   steps {
                       sh 'ansible-playbook  -i hosts --vault-password-file vault.key --private-key id_rsa --tags "preprod" --limit preprod playbook.yml'
                   }
               }


               stage("Test the functioning of the app in Preprod environment") {
                    when {
                       expression { GIT_BRANCH == 'origin/dev' }
                    }
                   steps {
                       sh 'ansible-playbook  -i hosts --vault-password-file vault.key --private-key id_rsa --tags "test" --limit preprod playbook.yml'
                   }
               }

               stage("Deploy app in Production Environment") {
                    when {
                       expression { GIT_BRANCH == 'origin/master' }
                    }
                   steps {
                       sh 'ansible-playbook  -i hosts --vault-password-file vault.key --private-key id_rsa --tags "prod" --limit prod playbook.yml'
                   }
               }

            }
         }
    }
}

