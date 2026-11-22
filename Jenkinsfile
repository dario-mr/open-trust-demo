// Vendor pipeline on Jenkins: the same app as the GitHub and GitLab pipelines, assessed with the
// Open Trust generic script pinned to a commit and signed with a key (Jenkins secret file), so L1.
// open-trust/demo/jenkins runs this pipeline in a local Jenkins.
pipeline {
    agent any
    environment {
        // the generic script, pinned by commit; the otrust release it runs, pinned by digest
        OTRUST_TEMPLATE = 'https://raw.githubusercontent.com/dario-mr/open-trust/a6040024b8bdfb5a8df06e9a3719944cb19d0433/ci-templates/generic/otrust-assess.sh'
        OTRUST_VERSION  = 'v0.1.15'
        OTRUST_SHA256_LINUX_AMD64 = '4f280ac26ed2fc1030b10951af325b52dfd0d8ac6640af0378624603cf7e6ddd'
        OTRUST_SHA256_LINUX_ARM64 = 'b875874e2e9a321e46bc0a9b9d5dcdb6e425c135f3782ba665e6676f5aa0d756'
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
