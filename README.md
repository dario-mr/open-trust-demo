# Open Trust demo (vendor side)

A small Spring Boot app that plays the **software vendor** for [Open Trust](https://github.com/dario-mr/open-trust).

The [`build and assess`](.github/workflows/build.yml) workflow builds the image twice and pushes both to [`ghcr.io/dario-mr/open-trust-demo`](https://github.com/dario-mr/open-trust-demo/pkgs/container/open-trust-demo): **clean**, and **vulnerable** with `log4j-core` 2.14.1 (Log4Shell). It then calls the Open Trust assessor `dario-mr/open-trust/.github/workflows/assess.yml`, **pinned to a commit**, with the registry image pinned by digest.

The assessor is in another repository, so this repository can't add steps to it. That lets the keyless signature prove the assessment ran unmodified, at trust level **`L1+isolated-assessor`**. The evidence (SBOM, scan results) never leaves the run's artifacts.

## Verify as a customer

You need the image and the certificate. The image can come straight from the registry, pinned by digest, or as the OCI tar the workflow also keeps, for offline verification. The evidence is optional: if the vendor shares it, `--evidence` re-checks it and re-runs the policy.

```bash
gh release download v0.1.7 -R dario-mr/open-trust -p "otrust-$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" -O otrust && chmod +x otrust
RUN=$(gh run list -R dario-mr/open-trust-demo -w "build and assess" -s success -L 1 --json databaseId -q '.[0].databaseId')
gh run download $RUN -R dario-mr/open-trust-demo -n otrust-image-clean -D otrust-image-clean
DIGEST=sha256:$(jq -r '.dsseEnvelope.payload|@base64d|fromjson|.subject[0].digest.sha256' otrust-image-clean/certificate.sigstore.json)

./otrust verify otrust-image-clean/certificate.sigstore.json \
  --image ghcr.io/dario-mr/open-trust-demo@$DIGEST \
  --trust-policy trust.yaml \
  --trusted-root open-trust/internal/verify/testdata/public-good-trusted-root.json \
  --evidence otrust-image-clean
```

| Case | Result |
|---|---|
| clean | `VERIFIED` (exit 0), trust level `L1+isolated-assessor`, all six checks PASSED, including signed build provenance (`attest-build-provenance`) |
| vulnerable (`image-vulnerable`, `otrust-image-vulnerable`) | `ASSESSMENT_FAILED` (exit 10), with the Log4Shell CVEs listed |
| clean certificate + vulnerable image | `ARTIFACT_MISMATCH` (exit 14) |
| clean, with `--recheck` (needs Docker) | `VERIFIED`: your own scan of the image agrees with the certificate, and its packages match the vendor's SBOM |

[`trust.yaml`](trust.yaml) is the customer's decision about whom to trust. It accepts only the assessor workflow at its pinned commit, assessing this repository's `main` branch on a GitHub-hosted runner.

## The same app on GitLab

[`.gitlab-ci.yml`](.gitlab-ci.yml) runs the same build and assessment on GitLab CI ([gitlab.com/dario-mr/open-trust-demo](https://gitlab.com/dario-mr/open-trust-demo)) through the Open Trust GitLab template, pinned to a commit. It signs keyless with GitLab's OIDC identity.

GitLab's identity names the vendor's own pipeline, never an included template, so these certificates are **`L1+ci-identity`**. They prove which project, branch and commit produced the assessment, but not that the vendor couldn't change it. [`trust-gitlab.yaml`](trust-gitlab.yaml) is the matching customer policy:

```bash
glab job artifact main assess-clean -R dario-mr/open-trust-demo     # → otrust-out/ (certificate + evidence)
DIGEST=sha256:$(jq -r '.dsseEnvelope.payload|@base64d|fromjson|.subject[0].digest.sha256' otrust-out/certificate.sigstore.json)
./otrust verify otrust-out/certificate.sigstore.json --image registry.gitlab.com/dario-mr/open-trust-demo@$DIGEST \
  --trust-policy trust-gitlab.yaml \
  --trusted-root open-trust/internal/verify/testdata/public-good-trusted-root.json --evidence otrust-out
```

The check results are the same as on GitHub; only the trust level differs. A buyer whose policy demands `L1+isolated-assessor` rejects the GitLab certificate with `TRUST_LEVEL_TOO_LOW`.

## What this does not prove

- That the app is secure. The scanners find known issues only.
- That the scanned source is the whole source. The vendor still controls the repository and what it commits.
- Each certificate lists its own limitations.
