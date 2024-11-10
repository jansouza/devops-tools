# jenkins-library


Setup instructions
-------------

1. In Jenkins, go to Manage Jenkins &rarr; Configure System. Under _Global Pipeline Libraries_, add a library with the following settings:

    - Name: `pipeline-library`
    - Default version: Specify a Git reference (branch or commit SHA), e.g. `master`
    - Retrieval method: _Modern SCM_
    - Select the _Git_ type
    - Project repository: `git@github.com:jansouza/devops-tools.git`

2. Then create a Jenkins job with the following pipeline (note that the underscore `_` is not a typo):

    ```
    @Library('pipeline-library)_

    stage('Demo') {

      echo 'Hello World'

      sayHello 'Dave'

    }
    ```