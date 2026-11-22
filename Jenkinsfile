// Vendor pipeline on Jenkins: the same app as the GitHub and GitLab pipelines, assessed with the
// Open Trust generic script pinned to a commit and signed with a key (Jenkins secret file), so L1.
// open-trust/demo/jenkins runs this pipeline in a local Jenkins.
pipeline {
    agent any
    environment {
        // the generic script, pinned by commit; the otrust release it runs, pinned by digest
        OTRUST_TEMPLATE = 'https://raw.githubusercontent.com/dario-mr/open-trust/934e34b1006ddae10c56d4f76b08becbf0503e52/ci-templates/generic/otrust-assess.sh'
        OTRUST_VERSION  = 'v0.1.13'
        OTRUST_SHA256_LINUX_AMD64 = '3025145a5bfbeb6b8b1d1b7f0d20c96dc5a30c78822f2d3cdb226e6817c9da9c'
        OTRUST_SHA256_LINUX_ARM64 = '40779afe78b66b8722923cd09927f5799716b584b7f93dcf50c467720eced750'
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
