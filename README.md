# Open Trust demo (vendor side)

A small Spring Boot app that plays the **software vendor** for [Open Trust](https://github.com/dario-mr/open-trust).

The [`build and assess`](.github/workflows/build.yml) workflow builds the image twice: **clean**, and **vulnerable** with `log4j-core` 2.14.1 (Log4Shell). It then calls the Open Trust assessor `dario-mr/open-trust/.github/workflows/assess.yml`, **pinned to a commit**.

The assessor is in another repository, so this repository can't add steps to it. That lets the keyless signature prove the assessment ran unmodified, at trust level **`L1+isolated-assessor`**. The evidence (SBOM, scan results) never leaves the run's artifacts.

## Verify as a customer

You need the image and the certificate. The evidence is optional: if the vendor shares it, `--evidence` re-checks it and re-runs the policy.

```bash
git clone https://github.com/dario-mr/open-trust && (cd open-trust && go build -o ../otrust ./cmd/otrust)
RUN=$(gh run list -R dario-mr/open-trust-demo -w "build and assess" -s success -L 1 --json databaseId -q '.[0].databaseId')
gh run download $RUN -R dario-mr/open-trust-demo -n image-clean -n otrust-image-clean

./otrust verify otrust-image-clean/certificate.sigstore.json \
  --image image-clean/image.oci.tar \
  --trust-policy trust.yaml \
  --trusted-root open-trust/internal/verify/testdata/public-good-trusted-root.json \
  --evidence otrust-image-clean
```

| Case | Result |
|---|---|
| clean | `VERIFIED` (exit 0), trust level `L1+isolated-assessor` |
| vulnerable (`image-vulnerable`, `otrust-image-vulnerable`) | `ASSESSMENT_FAILED` (exit 10), with the Log4Shell CVEs listed |
| clean certificate + vulnerable image | `ARTIFACT_MISMATCH` (exit 14) |

[`trust.yaml`](trust.yaml) is the customer's decision about whom to trust. It accepts only the assessor workflow at its pinned commit, assessing this repository's `main` branch on a GitHub-hosted runner.

## What this does not prove

- That the app is secure. The scanners find known issues only.
- That the scanned source is the whole source. The vendor still controls the repository and what it commits.
- Each certificate lists its own limitations.
