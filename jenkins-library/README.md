# jenkins-library


Setup instructions
-------------

1. In Jenkins, go to Manage Jenkins &rarr; Configure System. Under _Global Trusted Pipeline Libraries_, add a library with the following settings:

    - Name: `pipeline-library`
    - Default version: Specify a Git reference (branch or commit SHA), e.g. `main`
    - Retrieval method: _Modern SCM_
    - Select the _Git_ type
    - Project repository: `https://github.com/jansouza/devops-tools.git`

2. Then create a Jenkins job with the following pipeline (note that the underscore `_` is not a typo):

```
@Library("pipeline-library") _

pipeline {
    agent {
        kubernetes {
            yaml '''
              apiVersion: v1
              kind: Pod
              spec:
                containers:
                - name: devops-tools
                  image: jansouza/devops-tools:latest
                  alwaysPullImage: true
                  command: ["sleep", "infinity"]
            '''
            defaultContainer 'devops-tools'
        }
    }

    stages {
        stage('Demo') {
            steps {
                echo 'Hello World'
                sayHello 'Dave'
            }
        }
    }
}
```