"""Extract the Windows release templates from the official Godot ZIP over HTTP ranges."""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
import urllib.request
import zlib
from pathlib import Path

VERSION = "4.7.2"
URL = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"


def read_range(start: int, end: int) -> tuple[bytes, int]:
    request = urllib.request.Request(URL, headers={"User-Agent": "CinemaCleaner-build", "Range": f"bytes={start}-{end}"})
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status != 206:
            raise RuntimeError("The template server did not honor the requested byte range")
        content_range = response.headers["Content-Range"]
        if not content_range.startswith(f"bytes {start}-{end}/"):
            raise RuntimeError(f"Unexpected range: {content_range}")
        content = response.read()
        if len(content) != end - start + 1:
            raise RuntimeError("Truncated template download")
        return content, int(content_range.rsplit("/", 1)[1])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    # Obtain the archive size without downloading other platforms.
    _, total = read_range(0, 0)
    tail, _ = read_range(max(0, total - 65557), total - 1)
    end = tail.rfind(b"PK\x05\x06")
    if end < 0:
        raise RuntimeError("ZIP directory was not found")
    footer = struct.unpack_from("<4s4H2LH", tail, end)
    directory_size, directory_offset = footer[5:7]
    if directory_offset == 0xFFFFFFFF:
        raise RuntimeError("ZIP64 directory is not supported by this small downloader")
    directory, _ = read_range(directory_offset, directory_offset + directory_size - 1)
    wanted = {"windows_release_x86_64.exe", "windows_release_x86_64_console.exe", "version.txt"}
    found = set()
    manifest = {"version": VERSION, "source": URL, "files": []}
    args.output.mkdir(parents=True, exist_ok=True)
    offset = 0
    while offset < len(directory):
        entry = struct.unpack_from("<4s6H3L5H2L", directory, offset)
        if entry[0] != b"PK\x01\x02":
            raise RuntimeError("Invalid ZIP directory record")
        name_len, extra_len, comment_len = entry[10:13]
        name = directory[offset + 46:offset + 46 + name_len].decode("utf-8")
        filename = name.rsplit("/", 1)[-1]
        offset += 46 + name_len + extra_len + comment_len
        if filename not in wanted:
            continue
        header, _ = read_range(entry[16], entry[16] + 29)
        local_name_len, local_extra_len = struct.unpack_from("<HH", header, 26)
        data_start = entry[16] + 30 + local_name_len + local_extra_len
        data, _ = read_range(data_start, data_start + entry[8] - 1)
        if entry[4] == 8:
            data = zlib.decompress(data, -15)
        elif entry[4] != 0:
            raise RuntimeError("Unsupported ZIP compression")
        if len(data) != entry[9] or zlib.crc32(data) & 0xFFFFFFFF != entry[7]:
            raise RuntimeError(f"Template checksum mismatch: {filename}")
        (args.output / filename).write_bytes(data)
        found.add(filename)
        manifest["files"].append({"name": filename, "size": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        print(f"Verified {filename}: {len(data)} bytes", flush=True)
    if found != wanted:
        raise RuntimeError(f"Missing templates: {wanted - found}")
    (args.output / "download_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
