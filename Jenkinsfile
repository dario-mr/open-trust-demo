// Vendor pipeline on Jenkins: the same app as the GitHub and GitLab pipelines, assessed with the
// Open Trust generic script pinned to a commit and signed with a key (Jenkins secret file), so L1.
// open-trust/demo/jenkins runs this pipeline in a local Jenkins.
pipeline {
    agent any
    environment {
        // the generic script, pinned by commit; the otrust release it runs, pinned by digest
        OTRUST_TEMPLATE = 'https://raw.githubusercontent.com/dario-mr/open-trust/7ca9040fda36c3e893ef94f3f12780a658b09657/ci-templates/generic/otrust-assess.sh'
        OTRUST_VERSION  = 'v0.1.16'
        OTRUST_SHA256_LINUX_AMD64 = 'd317f7d9ad521fb90a68d503c12305d3020dba75a3e24a0912fadb22697a8c4f'
        OTRUST_SHA256_LINUX_ARM64 = '25691c5472caabf42cabe84a3b1f8c09e9884701636680cb5751c60572d4bd64'
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
