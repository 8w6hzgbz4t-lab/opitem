#!/usr/bin/env python3
"""Generate the asset briefs with Meshy's text-to-3D preview/refine API.

Planning requires no key and makes no network requests. Generation requires a
Meshy API key supplied through MESHY_API_KEY or the local --prompt-key input.
This program has not submitted a paid task in the cloud handoff environment.
"""
from __future__ import annotations

import argparse
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
API_BASE = "https://api.meshy.ai/openapi/v2/text-to-3d"
MAX_DOWNLOAD = 256 * 1024 * 1024
TERMINAL_FAILURES = {"FAILED", "CANCELED", "CANCELLED", "EXPIRED"}


class MeshyError(RuntimeError):
    pass


def read_assets(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    assets = data["assets"] if isinstance(data, dict) else data
    seen = set()
    for asset in assets:
        key = asset.get("key", asset.get("id", asset.get("asset_key")))
        if not isinstance(key, str) or not re.fullmatch(r"[a-z][a-z0-9_]{1,70}", key):
            raise MeshyError("Each asset needs a safe lowercase key")
        if key in seen:
            raise MeshyError(f"Duplicate asset key: {key}")
        seen.add(key)
        asset["key"] = key
        prompt = asset.get("prompt", "")
        if not isinstance(prompt, str) or not 1 <= len(prompt) <= 600:
            raise MeshyError(f"{key}: generation prompt must contain 1–600 characters")
        triangles = asset.get("target_polycount", asset.get("target_triangles", 6000))
        if not isinstance(triangles, int) or not 100 <= triangles <= 300000:
            raise MeshyError(f"{key}: invalid target triangle count")
        asset["target_polycount"] = triangles
    return assets


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def valid_task_id(value: object) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{8,128}", value):
        raise MeshyError("Meshy returned an invalid task ID")
    return value


def preview_payload(asset: dict) -> dict:
    return {
        "mode": "preview",
        "prompt": asset["prompt"],
        "art_style": "realistic",
        "should_remesh": True,
        "topology": "triangle",
        "target_polycount": asset["target_polycount"],
    }


def refine_payload(asset: dict, preview_id: str) -> dict:
    result = {"mode": "refine", "preview_task_id": valid_task_id(preview_id), "enable_pbr": True}
    texture_prompt = asset.get("texture_prompt", "")
    if texture_prompt:
        if not isinstance(texture_prompt, str) or len(texture_prompt) > 600:
            raise MeshyError(f"{asset['key']}: texture prompt exceeds 600 characters")
        result["texture_prompt"] = texture_prompt
    return result


class MeshyClient:
    def __init__(self, key: str):
        if not key:
            raise MeshyError("Set MESHY_API_KEY securely or use --prompt-key in your local terminal")
        self._key = key

    def request(self, method: str, task_id: str | None = None, payload: dict | None = None) -> dict:
        url = API_BASE + ("/" + valid_task_id(task_id) if task_id else "")
        body = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = Request(url, data=body, method=method, headers={
            "Authorization": "Bearer " + self._key,
            "Content-Type": "application/json", "Accept": "application/json",
        })
        try:
            with urlopen(request, timeout=60) as response:
                result = json.load(response)
        except HTTPError as error:
            # Do not print response bodies, headers, or credentials.
            raise MeshyError(f"Meshy API returned HTTP {error.code}; inspect the task/account in Meshy") from None
        except (URLError, TimeoutError):
            raise MeshyError("Meshy request failed or timed out; submission was not retried") from None
        if not isinstance(result, dict):
            raise MeshyError("Meshy returned an unexpected response")
        return result

    def submit(self, payload: dict) -> str:
        return valid_task_id(self.request("POST", payload=payload).get("result"))

    def wait(self, task_id: str, timeout: float, poll: float) -> dict:
        deadline = time.monotonic() + timeout
        previous = None
        while True:
            task = self.request("GET", task_id=task_id)
            status = task.get("status")
            progress = task.get("progress", 0)
            if (status, progress) != previous:
                print(f"  {task_id}: {status} {progress}%", flush=True)
                previous = (status, progress)
            if status == "SUCCEEDED":
                return task
            if status in TERMINAL_FAILURES:
                raise MeshyError(f"Meshy task {task_id} ended with {status}; no replacement task was created")
            if status not in {"PENDING", "IN_PROGRESS"}:
                raise MeshyError(f"Unexpected Meshy task status: {status!r}")
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise MeshyError(f"Waiting timed out; run the same command to resume task {task_id}")
            time.sleep(min(poll, remaining))


def submit_once(client: MeshyClient, state: dict, path: Path, phase: str, payload: dict) -> str:
    id_key = phase + "_task_id"
    if state.get(id_key):
        return valid_task_id(state[id_key])
    if state.get("submission_in_flight"):
        raise MeshyError("A previous submission may have succeeded. Find its task ID in Meshy and use --resume-preview or --resume-refine; automatic duplicate submission is blocked")
    state["submission_in_flight"] = phase
    save_state(path, state)
    task_id = client.submit(payload)
    state[id_key] = task_id
    state.pop("submission_in_flight", None)
    save_state(path, state)
    return task_id


def validate_model(path: Path, extension: str) -> None:
    with path.open("rb") as stream:
        header = stream.read(32)
    if extension == "glb":
        if len(header) < 12 or header[:4] != b"glTF":
            raise MeshyError("Downloaded GLB has an invalid header")
        _, version, length = struct.unpack("<4sII", header[:12])
        if version != 2 or length != path.stat().st_size:
            raise MeshyError("Downloaded GLB is incomplete or uses an unsupported version")
    elif extension == "fbx":
        if not (header.startswith(b"Kaydara FBX Binary") or b"FBX" in header):
            raise MeshyError("Downloaded FBX has an unexpected header")


def download(url: str, target: Path, model_format: str | None = None) -> str:
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise MeshyError("Meshy download must use an HTTPS asset URL")
    if target.exists():
        if model_format:
            validate_model(target, model_format)
        if not target.stat().st_size:
            raise MeshyError(f"Existing output is empty: {target.name}")
        return hashlib.sha256(target.read_bytes()).hexdigest()
    temporary = target.with_suffix(target.suffix + ".part")
    try:
        # Signed asset URLs receive no Meshy Authorization header.
        with urlopen(Request(url), timeout=120) as response, temporary.open("wb") as stream:
            size = 0
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if size > MAX_DOWNLOAD:
                    raise MeshyError("Asset exceeds the download size limit")
                stream.write(chunk)
        if model_format:
            validate_model(temporary, model_format)
        if not temporary.stat().st_size:
            raise MeshyError("Meshy returned an empty download")
        temporary.replace(target)
    except (HTTPError, URLError, TimeoutError):
        raise MeshyError(f"Download failed for {target.name}; run again to resume") from None
    finally:
        if temporary.exists():
            temporary.unlink()
    return hashlib.sha256(target.read_bytes()).hexdigest()


def generate(asset: dict, client: MeshyClient, output: Path, args: argparse.Namespace) -> None:
    if asset.get("reference_required") or asset.get("needs_reference"):
        raise MeshyError(f"{asset['key']}: the exact artwork reference is required before generating this design")
    folder = output / asset["key"]
    path = folder / "state.json"
    state = json.loads(path.read_text()) if path.exists() else {"key": asset["key"], "status": "not_generated"}
    fingerprint = hashlib.sha256(json.dumps({"preview": preview_payload(asset), "texture_prompt": asset.get("texture_prompt", "")}, sort_keys=True).encode()).hexdigest()
    if state.get("prompt_sha256", fingerprint) != fingerprint:
        raise MeshyError("The brief changed after submission; use a new output folder to keep the previous model")
    state["prompt_sha256"] = fingerprint
    for phase in ("preview", "refine"):
        resumed = getattr(args, "resume_" + phase)
        if resumed:
            if state.get("submission_in_flight") not in (None, phase):
                raise MeshyError("Resume the pending phase before assigning another task ID")
            existing = state.get(phase + "_task_id")
            if existing and existing != resumed:
                raise MeshyError("A different task ID is already saved; keep it or choose another output folder")
            state[phase + "_task_id"] = valid_task_id(resumed)
            state.pop("submission_in_flight", None)
            save_state(path, state)
    # A saved/refound refine task already includes its preview. Never create a
    # new preview merely to download the result of an existing refine task.
    if state.get("refine_task_id"):
        refine_id = valid_task_id(state["refine_task_id"])
    else:
        preview_id = submit_once(client, state, path, "preview", preview_payload(asset))
        client.wait(preview_id, args.timeout, args.poll)
        refine_id = submit_once(client, state, path, "refine", refine_payload(asset, preview_id))
    refined = client.wait(refine_id, args.timeout, args.poll)
    urls = refined.get("model_urls", {})
    hashes = {}
    for extension in args.formats:
        if urls.get(extension):
            target = folder / f"{asset['key']}.{extension}"
            hashes[target.name] = download(urls[extension], target, extension)
    if not hashes:
        raise MeshyError("Meshy completed but returned none of the requested model formats")
    texture_sets = refined.get("texture_urls", [])
    if isinstance(texture_sets, dict):
        texture_sets = [texture_sets]
    for index, textures in enumerate(texture_sets):
        for channel, url in textures.items():
            if not isinstance(url, str) or not re.fullmatch(r"[a-z_]+", channel):
                continue
            suffix = Path(urlsplit(url).path).suffix.lower()
            suffix = suffix if suffix in {".png", ".jpg", ".jpeg", ".webp"} else ".bin"
            target = folder / f"texture_{index}_{channel}{suffix}"
            hashes[target.name] = download(url, target)
    state.update(status="downloaded", files_sha256=hashes)
    save_state(path, state)
    print(f"Downloaded {asset['key']} to {folder}", flush=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "generate"))
    parser.add_argument("--manifest", type=Path, default=ROOT / "assets.json")
    parser.add_argument("--output", type=Path, default=ROOT / "output")
    select = parser.add_mutually_exclusive_group()
    select.add_argument("--asset", nargs="+")
    select.add_argument("--all", action="store_true")
    parser.add_argument("--prompt-key", action="store_true", help="Read the API key privately from your local terminal")
    parser.add_argument("--resume-preview")
    parser.add_argument("--resume-refine")
    parser.add_argument("--formats", nargs="+", choices=("glb", "fbx"), default=["glb", "fbx"])
    parser.add_argument("--timeout", type=float, default=1200)
    parser.add_argument("--poll", type=float, default=5)
    args = parser.parse_args(argv)
    try:
        assets = read_assets(args.manifest)
        if args.asset:
            by_key = {a["key"]: a for a in assets}
            unknown = set(args.asset) - by_key.keys()
            if unknown:
                raise MeshyError("Unknown asset keys: " + ", ".join(sorted(unknown)))
            assets = [by_key[key] for key in dict.fromkeys(args.asset)]
        if args.command == "plan":
            for asset in assets:
                blocked = "REFERENCE NEEDED" if asset.get("reference_required") or asset.get("needs_reference") else "ready brief"
                print(f"{asset['key']}: {asset['target_polycount']} target triangles; {blocked}")
            print(f"{len(assets)} briefs; no Meshy task submitted")
            return 0
        if not args.asset and not args.all:
            raise MeshyError("Choose --asset KEY or explicitly use --all; plan never submits tasks")
        if (args.resume_preview or args.resume_refine) and len(assets) != 1:
            raise MeshyError("Resume task IDs require exactly one --asset")
        if args.timeout <= 0 or args.poll < 1:
            raise MeshyError("Timeout must be positive and polling interval at least one second")
        key = getpass.getpass("Meshy API key (local input, hidden): ") if args.prompt_key else os.environ.get("MESHY_API_KEY", "")
        client = MeshyClient(key)
        for asset in assets:
            print(f"Generating {asset['key']}", flush=True)
            generate(asset, client, args.output, args)
        return 0
    except (MeshyError, OSError, ValueError, KeyError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
