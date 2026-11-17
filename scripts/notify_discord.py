#!/usr/bin/env python3
"""Post a message to a teammate's Discord channel and optionally ping people.

Usage:
    python3 scripts/notify_discord.py <channel> "<message>"

<channel> is whose channel to post in: nathan or kiran.
In the message, {nathan} and {kiran} turn into a Discord mention of that person.

Example:
    python3 scripts/notify_discord.py kiran "{kiran} please review https://github.com/nathancbao/arclive/pull/2"

Settings come from a git-ignored .env in the repo's main checkout (never commit webhook URLs):
    DISCORD_WEBHOOK_NATHAN, DISCORD_WEBHOOK_KIRAN, DISCORD_ID_NATHAN, DISCORD_ID_KIRAN
"""

import json
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

PEOPLE = ("nathan", "kiran")


def find_env() -> Path:
    """The .env in this checkout, or in the main checkout when this is a git worktree."""
    top = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip())
    common = Path(subprocess.check_output(["git", "rev-parse", "--git-common-dir"], text=True).strip())
    if not common.is_absolute():
        common = (Path.cwd() / common).resolve()
    for candidate in (top / ".env", common.parent / ".env"):
        if candidate.is_file():
            return candidate
    sys.exit("No .env found. See CLAUDE.md, 'Discord pings'.")


def read_env(path: Path) -> dict[str, str]:
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            values[key.strip()] = value.strip()
    return values


def main() -> None:
    if len(sys.argv) != 3 or sys.argv[1] not in PEOPLE:
        sys.exit(__doc__)
    channel, message = sys.argv[1], sys.argv[2]
    env = read_env(find_env())

    webhook = env.get(f"DISCORD_WEBHOOK_{channel.upper()}")
    if not webhook:
        sys.exit(f"DISCORD_WEBHOOK_{channel.upper()} is missing from .env")

    mentioned = []
    for person in PEOPLE:
        user_id = env.get(f"DISCORD_ID_{person.upper()}")
        if "{" + person + "}" in message:
            if not user_id:
                sys.exit(f"DISCORD_ID_{person.upper()} is missing from .env")
            message = message.replace("{" + person + "}", f"<@{user_id}>")
            mentioned.append(user_id)

    payload = {"content": message[:2000], "allowed_mentions": {"users": mentioned}}
    request = urllib.request.Request(
        webhook,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "arclive-notify/1.0"},
    )
    try:
        urllib.request.urlopen(request, timeout=15).read()
    except urllib.error.HTTPError as error:
        sys.exit(f"Discord rejected the message: HTTP {error.code}")
    print(f"Posted to {channel}'s channel.")


if __name__ == "__main__":
    main()
