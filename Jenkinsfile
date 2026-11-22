// Vendor pipeline on Jenkins: the same app as the GitHub and GitLab pipelines, assessed with the
// Open Trust generic script pinned to a commit and signed with a key (Jenkins secret file), so L1.
// open-trust/demo/jenkins runs this pipeline in a local Jenkins.
pipeline {
    agent any
    environment {
        // the generic script, pinned by commit; the otrust release it runs, pinned by digest
        OTRUST_TEMPLATE = 'https://raw.githubusercontent.com/dario-mr/open-trust/9fe30e6ea967ab565e310fc183382b74f04cd121/ci-templates/generic/otrust-assess.sh'
        OTRUST_VERSION  = 'v0.1.12'
        OTRUST_SHA256_LINUX_AMD64 = '3d2ae0ad95272ce02b823a0ca365b85369172c75afd1071a973e88fa2e82b1f5'
        OTRUST_SHA256_LINUX_ARM64 = '3a5fe0836bcff0bb163f67043fde81f6b88382c9fe4ca73191d884dc08381be1'
        OTRUST_SUBJECT  = 'example.com/open-trust-demo:clean'
    }
    stages {
        stage('Build') {
            steps {
                // an OCI layout gives a stable digest; the docker-container builder can export one
                sh '''
                    docker buildx inspect otrust-oci >/dev/null 2>&1 || docker buildx create --name otrust-oci --driver docker-container >/dev/null
                    docker buildx build --builder otrust-oci --provenance=mode=min --sbom=false --build-arg VARIANT=clean --output type=oci,dest=image.oci.tar .
                '''
            }
        }
        stage('Assess') {
            steps {
                withCredentials([file(credentialsId: 'otrust-signing-key', variable: 'OTRUST_KEY')]) {
                    sh '''
                        curl -fsSLo otrust-assess.sh "$OTRUST_TEMPLATE"
                        OTRUST_IMAGE=image.oci.tar sh otrust-assess.sh
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'otrust-out/**', allowEmptyArchive: true
                }
            }
        }
    }
}
