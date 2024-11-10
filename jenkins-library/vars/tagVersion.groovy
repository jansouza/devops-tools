import libs.SemVer

def call(Map config) {

  def build_number = "${config.build_number}"
  def git_branch = "${config.git_branch}"
  def git_repo = "${config.git_repo}"

  echo "build_number=${build_number}"
  echo "git_branch=${git_branch}"
  echo "git_repo=${git_repo}"
  
  cleanWs()
  git branch: "${git_branch}",
      url: "${git_repo}"

  def currentVersion = sh(returnStdout: true, script: 'git tag --points-at HEAD|tail -1').trim()
  echo "currentVersion=${currentVersion}"

  // New Tag
  def new_tag = SemVer.bump(currentVersion)
  echo "new_tag=${new_tag}"

  sh "git config --global user.email 'jenkins@localhost'"
  sh "git config --global user.name 'Jenkins'"
  sh "git tag -a ${new_tag} -m '[Jenkins] New Tag'"
  sh "git push --tags"
}