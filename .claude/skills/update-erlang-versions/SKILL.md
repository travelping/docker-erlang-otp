---
name: update-erlang-versions
description: You are an AI assistant responsible for maintaining the Erlang/OTP versions in this project. Your task is to update the `versions.json` file with the latest Erlang/OTP and rebar3 releases according to specific versioning rules.
---

## Instructions

### 1. Analyze the Current State

Read the `versions.json` file to get the list of currently supported Erlang/OTP and rebar3 versions.

### 2. Fetch Latest Release Information

- Go to the official Erlang/OTP website (erlang.org) and find the list of all available releases.
- Go to the official rebar3 website (rebar3.org) or its GitHub repository to find the latest available releases.

### 3. Apply Versioning Rules

**For each version in `versions.json`:**
- Check if there is a newer patch release available. If so, update the `version` and `download_sha256`.

**For the current major release series:**
- Add any new minor versions that are not already in `versions.json`.
- Ensure all minor versions of the current major release are present.

**When a new major release is published (e.g., 29.0):**
- Add the new major release to the `otp` section.
- Remove any release candidates for that major version (e.g., `29.0-rc1`).
- For the *previous* major release series (e.g., 28.x), remove all versions except for the single latest minor/patch release (e.g., keep `28.3.1` and remove `28.0.4`, `28.1.1`, `28.2`).

**For new release candidates (e.g., 29.0-rc1):**
- Add the release candidate to the `otp` section.
- **Do not** remove any older versions when adding a release candidate.

**For each new Erlang/OTP version added:**
- Find the latest compatible `rebar3` version.
- Choose a suitable recent `alpine` linux release.
- Find the `download_sha256` for the new Erlang/OTP and rebar3 versions.
- If the `rebar3` version is new, add it to the `rebar3` section of `versions.json`.

### 4. Final Verification

After updating `versions.json`, review the `.github/workflows/images.yaml` file to ensure that the workflow will run correctly with the updated versions. No changes should be needed in this file as it is designed to be dynamic.

### 5. Finalize and Propose Changes

**Commit the changes:**
- Commit the modifications to `versions.json` and any other files you have changed.
- Use a clear and descriptive commit message. Follow this template:
  ```
  feat(otp): Update Erlang/OTP versions

  - Add OTP <new versions>
  - Update OTP <updated versions>
  - Remove OTP <removed versions>
  ```
  (Replace `<...>` with the actual version numbers)

**Create a Pull Request:**
- If you have the capability, create a new branch and push the changes to it.
- Then, create a pull request on GitHub. The target for the pull request MUST be the `master` branch of the `travelping/docker-erlang-otp` repository (https://github.com/travelping/docker-erlang-otp/).
- Use a title and description that clearly explains the changes.

## Example Workflow

**When a new major release (29.0) is published:**

1. A new major version `29.0` is released.
2. Add `29.0` to the `otp` section in `versions.json` with its corresponding `alpine` version, `rebar3` version, and `download_sha256`.
3. If the `rebar3` version for `29.0` is new, add it to the `rebar3` section.
4. Identify that `28.x` is now the previous major release series.
5. Find the latest minor/patch release in the `28.x` series (e.g., `28.3.1`).
6. Remove all other `28.x` versions from the `otp` section (e.g., `28.0.4`, `28.1.1`, `28.2`).
7. The `versions.json` file is now updated.

## Files to Modify

- `versions.json` - Primary file containing version information
- `.github/workflows/images.yaml` - Review only, typically no changes needed

## Key Considerations

- Always verify SHA256 checksums for downloads
- Maintain backward compatibility by keeping the latest patch of the previous major version
- Remove release candidates only when the stable version is released
- Ensure alpine and rebar3 versions are compatible with the OTP version being added
