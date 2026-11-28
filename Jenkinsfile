// Vendor pipeline on Jenkins: the same app as the GitHub and GitLab pipelines, assessed with the
// Open Trust generic script pinned to a commit and signed with a key (Jenkins secret file), so L1.
// open-trust/demo/jenkins runs this pipeline in a local Jenkins.
pipeline {
    agent any
    environment {
        // the generic script, pinned by commit; the otrust release it runs, pinned by digest
        OTRUST_TEMPLATE = 'https://raw.githubusercontent.com/dario-mr/open-trust/dd478ffb3c8f7ea1ce53d487b62c8e6c0344e00f/ci-templates/generic/otrust-assess.sh'
        OTRUST_VERSION  = 'v0.1.18'
        OTRUST_SHA256_LINUX_AMD64 = 'c7196235a3388446ff5c17490562822023d9462e0859baedaedba8ba9c05d968'
        OTRUST_SHA256_LINUX_ARM64 = '3c71900b546298bbbed2b87e94bfb9405f55f24cf60e0ceabd2958f80e18dc71'
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
