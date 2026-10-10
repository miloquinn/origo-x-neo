#!/usr/bin/env python3
"""Build Origo X's bundled skin artwork from auditable SVG sources.

The original 16 semantic icon geometries below are adapted from ByteDance
IconPark v1.4.2 (Apache-2.0). The expanded semantic set, badge shapes,
palettes, dark variants, selected states, and background compositions are
original Origo X artwork.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import subprocess
import tempfile
from pathlib import Path


SKIN_ROOT = Path(__file__).resolve().parents[1]
COLLECTIONS_ROOT = SKIN_ROOT / "collections"
BACKGROUNDS_ROOT = SKIN_ROOT / "backgrounds"
MAGICK = shutil.which("magick")
SIPS = shutil.which("sips")


ICONS = {
    "home": """
      <path d="M9 18V42H39V18L24 6L9 18Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M19 29V42H29V29H19Z" fill="$PAPER" stroke="$ACCENT" stroke-width="4" stroke-linejoin="round"/>
      <path d="M9 42H39" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
    """,
    "library": """
      <path d="M5 6H39C39 6 43 8 43 13C43 18 39 20 39 20H5C5 20 9 18 9 13C9 8 5 6 5 6Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M43 28H9C9 28 5 30 5 35C5 40 9 42 9 42H43C43 42 39 40 39 35C39 30 43 28 43 28Z" fill="$PAPER" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M13 13H34M14 35H35" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "discover": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M19 29L22 19L32 16L29 27L19 29Z" fill="$PAPER" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="25.5" cy="22.5" r="2.5" fill="$LINE"/>
    """,
    "ai": """
      <path d="M7.5 35.5C5.3 32.2 4 28.3 4 24C4 13 13 4 24 4C35 4 44 13 44 24C44 35 35 44 24 44C19.8 44 15.8 42.7 12.6 40.4" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M7.5 35.5L16 27L21 32L12.6 40.4Z" fill="$PAPER" stroke="$ACCENT" stroke-width="4" stroke-linejoin="round"/>
      <path d="M17 14H21M19 12V16M28 17H34M31 14V20M32 29H36M34 27V31" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "profile": """
      <circle cx="24" cy="14" r="9" fill="$PAPER" stroke="$LINE" stroke-width="4"/>
      <path d="M41 43C41 33.6 33.4 26 24 26C14.6 26 7 33.6 7 43" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M15 35C17.5 32.8 20.5 31.5 24 31.5C27.5 31.5 30.5 32.8 33 35" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "back": """
      <path d="M12 24H38" stroke="$LINE" stroke-width="5" stroke-linecap="round"/>
      <path d="M24 36L12 24L24 12" fill="none" stroke="$ACCENT" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "search": """
      <circle cx="21" cy="21" r="16" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M32.5 32.5L42 42" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
      <path d="M15 15C16.8 13.2 19 12.5 21.5 12.5" stroke="$PAPER" stroke-width="3" stroke-linecap="round"/>
    """,
    "more": """
      <circle cx="12" cy="24" r="4" fill="$LINE"/>
      <circle cx="24" cy="24" r="4" fill="$ACCENT"/>
      <circle cx="36" cy="24" r="4" fill="$LINE"/>
    """,
    "close": """
      <path d="M13 13L35 35" stroke="$LINE" stroke-width="5" stroke-linecap="round"/>
      <path d="M13 35L35 13" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
    """,
    "forward": """
      <path d="M10 24H36" stroke="$LINE" stroke-width="5" stroke-linecap="round"/>
      <path d="M24 12L36 24L24 36" fill="none" stroke="$ACCENT" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "settings": """
      <path d="M36.7 15.2C37.9 17 38.8 19 39.2 21.3H44V26.7H39.2C38.8 29 37.9 31 36.7 32.8L40.1 36.2L36.2 40.1L32.8 36.7C31 37.9 29 38.8 26.7 39.2V44H21.3V39.2C19 38.8 17 37.9 15.2 36.7L11.8 40.1L7.9 36.2L11.3 32.8C10.1 31 9.2 29 8.8 26.7H4V21.3H8.8C9.2 19 10.1 17 11.3 15.2L7.9 11.8L11.8 7.9L15.2 11.3C17 10.1 19 9.2 21.3 8.8V4H26.7V8.8C29 9.2 31 10.1 32.8 11.3L36.2 7.9L40.1 11.8L36.7 15.2Z" fill="$FILL" stroke="$LINE" stroke-width="3.5" stroke-linejoin="round"/>
      <circle cx="24" cy="24" r="6" fill="$PAPER" stroke="$ACCENT" stroke-width="3.5"/>
    """,
    "refresh": """
      <path d="M39 18C36.6 10.9 29.3 6.6 21.9 8C16.3 9 11.9 13.1 10.2 18" fill="none" stroke="$LINE" stroke-width="4.5" stroke-linecap="round"/>
      <path d="M39 9V18H30" fill="none" stroke="$ACCENT" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M9 30C11.4 37.1 18.7 41.4 26.1 40C31.7 39 36.1 34.9 37.8 30" fill="none" stroke="$LINE" stroke-width="4.5" stroke-linecap="round"/>
      <path d="M9 39V30H18" fill="none" stroke="$ACCENT" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "add": """
      <circle cx="24" cy="24" r="18" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M24 14V34M14 24H34" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
    """,
    "share": """
      <circle cx="35" cy="11" r="6" fill="$PAPER" stroke="$LINE" stroke-width="4"/>
      <circle cx="13" cy="24" r="6" fill="$FILL" stroke="$ACCENT" stroke-width="4"/>
      <circle cx="35" cy="37" r="6" fill="$PAPER" stroke="$LINE" stroke-width="4"/>
      <path d="M18 21L29.5 14M18 27L29.5 34" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
    """,
    "delete": """
      <path d="M10 13H38V43H10V13Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M5 13H43M17 13L20 6H28L31 13" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M19 22V34M29 22V34" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
    """,
    "check": """
      <path d="M7 25L19 37L42 12" fill="none" stroke="$LINE" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M8 25L19 36" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
    """,
}

# The first 16 semantic symbols above are optically redrawn from the pinned
# IconPark sources recorded in NOTICE.md. The symbols below are original Origo
# X geometry, authored on the same 48 x 48 grid so every bundled collection can
# cover reader controls, title bars, libraries, forms, and system actions
# without falling back to unrelated platform glyphs.
ORIGINAL_ICON_SLOTS = tuple(ICONS)
ICONS.update({
    "bookmark": """
      <path d="M11 6H37V43L24 34L11 43V6Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M17 13H31" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "catalog": """
      <path d="M8 8H40V40H8V8Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M16 8V40M22 16H34M22 24H34M22 32H31" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "readAloud": """
      <path d="M7 13H17L28 5V43L17 35H7V13Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M34 17C38 21 38 27 34 31M39 11C47 18 47 30 39 37" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
    """,
    "locate": """
      <circle cx="24" cy="24" r="8" fill="$PAPER" stroke="$ACCENT" stroke-width="4"/>
      <path d="M24 4V13M24 35V44M4 24H13M35 24H44" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <circle cx="24" cy="24" r="2.5" fill="$LINE"/>
    """,
    "play": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M20 15L34 24L20 33V15Z" fill="$PAPER" stroke="$ACCENT" stroke-width="3.5" stroke-linejoin="round"/>
    """,
    "pause": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M16 14H22V34H16V14ZM27 14H33V34H27V14Z" fill="$PAPER" stroke="$ACCENT" stroke-width="3" stroke-linejoin="round"/>
    """,
    "stop": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M16 16H32V32H16V16Z" fill="$PAPER" stroke="$ACCENT" stroke-width="3.5" stroke-linejoin="round"/>
    """,
    "previous": """
      <path d="M10 11V37" stroke="$LINE" stroke-width="5" stroke-linecap="round"/>
      <path d="M38 11L17 24L38 37V11Z" fill="$FILL" stroke="$ACCENT" stroke-width="4" stroke-linejoin="round"/>
    """,
    "next": """
      <path d="M38 11V37" stroke="$LINE" stroke-width="5" stroke-linecap="round"/>
      <path d="M10 11L31 24L10 37V11Z" fill="$FILL" stroke="$ACCENT" stroke-width="4" stroke-linejoin="round"/>
    """,
    "rewind": """
      <path d="M25 12L8 24L25 36V12ZM42 12L25 24L42 36V12Z" fill="$FILL" stroke="$LINE" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M25 14V34" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "fastForward": """
      <path d="M6 12L23 24L6 36V12ZM23 12L40 24L23 36V12Z" fill="$FILL" stroke="$LINE" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M23 14V34" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "speed": """
      <path d="M7 36C7 26.6 14.6 19 24 19C33.4 19 41 26.6 41 36" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M24 34L35 13" stroke="$ACCENT" stroke-width="4.5" stroke-linecap="round"/>
      <circle cx="24" cy="34" r="4" fill="$PAPER" stroke="$LINE" stroke-width="3"/>
      <path d="M11 26L7 22M37 26L41 22M24 19V13" stroke="$LINE" stroke-width="3" stroke-linecap="round"/>
    """,
    "timer": """
      <circle cx="24" cy="27" r="16" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M19 5H29M24 5V11M35 13L39 9" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M24 18V28L31 32" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "volume": """
      <path d="M6 18H15L25 10V38L15 30H6V18Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M31 18C35 21 35 27 31 30M37 12C45 19 45 29 37 36" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
    """,
    "volumeOff": """
      <path d="M6 18H15L25 10V38L15 30H6V18Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M32 18L43 30M43 18L32 30" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
    """,
    "expand": """
      <path d="M8 19V8H19M29 8H40V19M40 29V40H29M19 40H8V29" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M9 9L19 19M39 9L29 19M39 39L29 29M9 39L19 29" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "collapse": """
      <path d="M18 6V18H6M30 6V18H42M42 30H30V42M6 30H18V42" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M7 7L18 18M41 7L30 18M41 41L30 30M7 41L18 30" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "remove": """
      <circle cx="24" cy="24" r="18" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M14 24H34" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
    """,
    "filter": """
      <path d="M6 8H42L29 23V39L19 44V23L6 8Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M14 14H34" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "sort": """
      <path d="M13 7V41M7 35L13 41L19 35" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M25 11H42M25 22H37M25 33H32" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
    """,
    "layoutGrid": """
      <path d="M7 7H20V20H7V7ZM28 7H41V20H28V7ZM7 28H20V41H7V28ZM28 28H41V41H28V28Z" fill="$FILL" stroke="$LINE" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M10 10H17M31 10H38M10 31H17M31 31H38" stroke="$ACCENT" stroke-width="2.5" stroke-linecap="round"/>
    """,
    "layoutList": """
      <path d="M7 8H14V15H7V8ZM7 21H14V28H7V21ZM7 34H14V41H7V34Z" fill="$FILL" stroke="$ACCENT" stroke-width="3"/>
      <path d="M21 11.5H41M21 24.5H41M21 37.5H41" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
    """,
    "download": """
      <path d="M24 5V31M14 22L24 32L34 22" fill="none" stroke="$ACCENT" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M8 35V42H40V35" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "upload": """
      <path d="M24 34V8M14 17L24 7L34 17" fill="none" stroke="$ACCENT" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M8 35V42H40V35" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "folder": """
      <path d="M5 13H20L24 18H43V40H5V13Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M9 24H37" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "createFolder": """
      <path d="M4 13H18L22 18H43V40H4V13Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M31 23V35M25 29H37" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
    """,
    "moveFolder": """
      <path d="M4 14H18L22 19H42V39H4V14Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M17 29H35M29 23L35 29L29 35" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "edit": """
      <path d="M9 36L7 43L14 41L39 16L32 9L9 36Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M28 13L35 20M8 42L16 40" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "copy": """
      <path d="M15 14H42V42H15V14Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M8 34H6V6H33V8" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "note": """
      <path d="M8 6H40V34L32 42H8V6Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M32 42V34H40M15 16H33M15 24H30" fill="none" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "highlight": """
      <path d="M14 7H34L31 29H17L14 7Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M17 29L11 39H37L31 29M13 44H35" fill="$PAPER" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "history": """
      <path d="M9 15V6M9 6H18" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M10 11C13.5 6.7 18.6 4 24 4C35 4 44 13 44 24C44 35 35 44 24 44C13 44 4 35 4 24" fill="$FILL" fill-opacity=".65" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M24 13V25L32 30" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "help": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M17 18C17.5 12.5 21 10 25 10C30 10 34 13 34 17.5C34 23 28 24 25 28V31" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
      <circle cx="25" cy="38" r="2.5" fill="$LINE"/>
    """,
    "info": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <circle cx="24" cy="14" r="2.5" fill="$ACCENT"/>
      <path d="M24 21V36" stroke="$ACCENT" stroke-width="5" stroke-linecap="round"/>
    """,
    "cloud": """
      <path d="M14 39C8.5 39 4 34.5 4 29C4 23.8 8 19.5 13 19C15 11.5 21 7 28 8C35 9 39 14 39.5 20C43.2 21.2 45 24.5 44 29C43 35 39 39 33 39H14Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M16 29H32" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "sync": """
      <path d="M38 18C35 10 25 7 17 11C14 12 12 14 10 17" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M38 9V18H29M10 30C13 38 23 41 31 37C34 36 36 34 38 31M10 39V30H19" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "save": """
      <path d="M7 6H36L42 12V42H7V6Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <path d="M15 6V18H33V6M15 42V27H34V42" fill="$PAPER" stroke="$ACCENT" stroke-width="3.5" stroke-linejoin="round"/>
    """,
    "restore": """
      <path d="M10 15V6M10 6H19" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M11 11C14.5 7 19.5 5 25 5C35.5 5 43 13 43 24C43 35 35 43 24 43C14 43 6 36 5 27" fill="$FILL" fill-opacity=".65" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M17 19H32V34H17V19ZM22 19V25H28V19" fill="$PAPER" stroke="$ACCENT" stroke-width="3" stroke-linejoin="round"/>
    """,
    "link": """
      <path d="M19 31L14 36C10.5 39.5 5 39.5 1.5 36C-2 32.5-2 27 1.5 23.5L10 15C13.5 11.5 19 11.5 22.5 15" transform="translate(8 0)" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
      <path d="M29 17L34 12C37.5 8.5 43 8.5 46.5 12C50 15.5 50 21 46.5 24.5L38 33C34.5 36.5 29 36.5 25.5 33" transform="translate(-6 0)" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round"/>
      <path d="M17 31L31 17" stroke="$LINE" stroke-width="4" stroke-linecap="round"/>
    """,
    "palette": """
      <path d="M24 5C13 5 5 13 5 24C5 35 13 43 24 43H28C31 43 33 41 33 38C33 35 31 33 28 33H25C22 33 20 31 20 28C20 25 22 23 25 23H37C41 23 43 20 43 16C43 9 34 5 24 5Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <circle cx="14" cy="20" r="3" fill="$ACCENT"/><circle cx="20" cy="13" r="3" fill="$PAPER"/><circle cx="30" cy="13" r="3" fill="$ACCENT"/>
    """,
    "font": """
      <path d="M8 40L21 8H27L40 40M13 30H35" fill="none" stroke="$LINE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M30 40L36 24H40L46 40M33 34H43" fill="none" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "image": """
      <path d="M5 7H43V41H5V7Z" fill="$FILL" stroke="$LINE" stroke-width="4" stroke-linejoin="round"/>
      <circle cx="16" cy="17" r="5" fill="$PAPER" stroke="$ACCENT" stroke-width="3"/>
      <path d="M7 37L18 26L25 32L32 23L41 35" fill="none" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "device": """
      <rect x="11" y="4" width="26" height="40" rx="5" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M18 10H30M21 38H27" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
    """,
    "key": """
      <circle cx="16" cy="21" r="10" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M23 28L41 46M31 36L36 31M36 41L41 36" stroke="$ACCENT" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="16" cy="21" r="3" fill="$PAPER"/>
    """,
    "extension": """
      <path d="M7 7H20V15C20 18 22 20 25 20C28 20 30 18 30 15V7H41V20H35C32 20 30 22 30 25C30 28 32 30 35 30H41V41H28V35C28 32 26 30 23 30C20 30 18 32 18 35V41H7V28H13C16 28 18 26 18 23C18 20 16 18 13 18H7V7Z" fill="$FILL" stroke="$LINE" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M8 8H19" stroke="$ACCENT" stroke-width="3" stroke-linecap="round"/>
    """,
    "network": """
      <circle cx="24" cy="24" r="19" fill="$FILL" stroke="$LINE" stroke-width="4"/>
      <path d="M5 24H43M24 5C30 10 33 16 33 24C33 32 30 38 24 43M24 5C18 10 15 16 15 24C15 32 18 38 24 43" fill="none" stroke="$ACCENT" stroke-width="3.5" stroke-linecap="round"/>
      <path d="M9 14H39M9 34H39" stroke="$LINE" stroke-width="2.5" stroke-linecap="round"/>
    """,
})

EXPANDED_ICON_SLOTS = tuple(slot for slot in ICONS if slot not in ORIGINAL_ICON_SLOTS)


THEMES = {
    "tidal": {
        "light": {"line": "#163F4E", "fill": "#A9DEE0", "paper": "#FFF4D9", "accent": "#EE765E", "badge_a": "#E8F9F8", "badge_b": "#BFE8E8"},
        "dark": {"line": "#ECFFFF", "fill": "#287B83", "paper": "#FFE5B6", "accent": "#FF9D89", "badge_a": "#153944", "badge_b": "#235D66"},
        "shape": "pebble",
    },
    "botanical": {
        "light": {"line": "#315044", "fill": "#A9C9A6", "paper": "#FFF7E8", "accent": "#C96858", "badge_a": "#F5F0E4", "badge_b": "#DCE8D4"},
        "dark": {"line": "#F1F8EC", "fill": "#658C68", "paper": "#F5D7AB", "accent": "#E39A86", "badge_a": "#20352D", "badge_b": "#355541"},
        "shape": "leaf",
    },
    "celestial": {
        "light": {"line": "#343052", "fill": "#B8AAF1", "paper": "#FFF0C4", "accent": "#DB8D55", "badge_a": "#F1ECFF", "badge_b": "#D6CDF8"},
        "dark": {"line": "#F7F2FF", "fill": "#7061BD", "paper": "#FFE5A3", "accent": "#F0B36E", "badge_a": "#24213F", "badge_b": "#3A3265"},
        "shape": "orbit",
    },
}


def _run(*args: str) -> None:
    subprocess.run(args, check=True)


def _badge(shape: str, selected: bool) -> str:
    ring = "#FFFFFF" if selected else "none"
    ring_width = "3" if selected else "0"
    if shape == "pebble":
        return f"""
          <path d="M24 34C33 17 54 13 72 19C94 25 111 44 107 68C103 94 82 111 57 108C33 106 17 91 18 66C18 53 18 45 24 34Z" fill="$BADGE" stroke="{ring}" stroke-width="{ring_width}"/>
          <circle cx="99" cy="32" r="4" fill="$ACCENT" opacity=".9"/>
        """
    if shape == "leaf":
        return f"""
          <path d="M64 15C81 28 105 26 109 49C113 71 99 99 73 108C48 117 18 99 18 72C18 48 38 27 64 15Z" fill="$BADGE" stroke="{ring}" stroke-width="{ring_width}"/>
          <path d="M25 30C20 25 21 19 28 17C34 20 35 26 31 30C29 32 27 32 25 30Z" fill="$ACCENT" opacity=".82"/>
        """
    return f"""
      <path d="M64 14L77 24L94 25L102 42L114 54L108 72L110 90L92 98L79 111L62 105L44 111L32 96L15 88L20 70L15 53L31 42L39 25L56 24L64 14Z" fill="$BADGE" stroke="{ring}" stroke-width="{ring_width}" stroke-linejoin="round"/>
      <circle cx="100" cy="29" r="2.5" fill="$PAPER"/><path d="M100 23V35M94 29H106" stroke="$PAPER" stroke-width="1.5" stroke-linecap="round" opacity=".78"/>
    """


def _icon_svg(theme_id: str, slot: str, brightness: str, selected: bool) -> str:
    theme = THEMES[theme_id]
    colors = theme[brightness].copy()
    colors["badge"] = colors["badge_b"] if selected else colors["badge_a"]
    body = (
        _badge(theme["shape"], selected)
        + f'<g transform="matrix(1.583333 0 0 1.583333 26 26)">{ICONS[slot]}</g>'
    )
    replacements = {
        "$LINE": colors["line"],
        "$FILL": colors["fill"],
        "$PAPER": colors["paper"],
        "$ACCENT": colors["accent"],
        "$BADGE": colors["badge"],
    }
    for key, value in replacements.items():
        body = body.replace(key, value)
    svg = f"""<svg width="128" height="128" viewBox="0 0 128 128" fill="none" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="64" cy="110" rx="34" ry="7" fill="#071D25" opacity=".10"/>
      {body}
    </svg>"""
    return svg.replace(
        'fill="none" stroke=',
        'fill="#000000" fill-opacity="0" stroke=',
    )


BACKGROUND_SVGS = {
    ("tidal", "light"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="80" y1="0" x2="1100" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#F6F2E9"/><stop offset=".38" stop-color="#DDF3F2"/><stop offset="1" stop-color="#8CCDD0"/></linearGradient><radialGradient id="s"><stop stop-color="#FFAA82"/><stop offset="1" stop-color="#F17B6A"/></radialGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><circle cx="970" cy="245" r="122" fill="url(#s)" opacity=".85"/><path d="M-100 1170C160 1010 330 1060 520 1190C720 1328 940 1260 1300 1045V1800H-100Z" fill="#55B3B8" opacity=".48"/><path d="M-90 1320C190 1160 380 1195 570 1335C755 1470 970 1425 1300 1240V1800H-90Z" fill="#1D7B86" opacity=".48"/><path d="M-80 1500C185 1360 390 1390 610 1512C820 1628 1005 1600 1300 1460V1800H-80Z" fill="#164C5D" opacity=".72"/><g fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round" opacity=".58"><path d="M-20 1210C195 1090 370 1120 548 1243C728 1368 946 1334 1230 1160"/><path d="M-20 1390C230 1250 420 1290 604 1407C784 1522 970 1510 1230 1370"/></g><g fill="#FFFFFF" opacity=".7"><circle cx="150" cy="310" r="10"/><circle cx="210" cy="370" r="6"/><circle cx="1035" cy="585" r="8"/></g></svg>""",
    ("tidal", "dark"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="90" y1="0" x2="1120" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#122B39"/><stop offset=".48" stop-color="#164C59"/><stop offset="1" stop-color="#0C2836"/></linearGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><circle cx="970" cy="245" r="118" fill="#FFB28B" opacity=".78"/><path d="M-100 1190C160 1030 330 1080 520 1210C720 1348 940 1280 1300 1065V1800H-100Z" fill="#54BAC0" opacity=".28"/><path d="M-90 1350C190 1190 380 1225 570 1365C755 1500 970 1455 1300 1270V1800H-90Z" fill="#277D88" opacity=".52"/><path d="M-80 1515C185 1375 390 1405 610 1527C820 1643 1005 1615 1300 1475V1800H-80Z" fill="#081D29" opacity=".85"/><g fill="none" stroke="#CFF8F5" stroke-width="10" stroke-linecap="round" opacity=".36"><path d="M-20 1230C195 1110 370 1140 548 1263C728 1388 946 1354 1230 1180"/><path d="M-20 1410C230 1270 420 1310 604 1427C784 1542 970 1530 1230 1390"/></g><g fill="#CFF8F5"><circle cx="150" cy="310" r="8" opacity=".65"/><circle cx="210" cy="370" r="5" opacity=".5"/></g></svg>""",
    ("botanical", "light"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="80" y1="0" x2="1120" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#FBF7ED"/><stop offset=".55" stop-color="#E8EBDD"/><stop offset="1" stop-color="#BDD2B8"/></linearGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><g fill="none" stroke="#6F8F72" stroke-width="11" stroke-linecap="round" opacity=".55"><path d="M80 1800C170 1460 202 1110 152 760C130 610 165 452 278 328"/><path d="M1120 1800C1022 1510 1010 1230 1062 925C1094 738 1040 558 915 430"/></g><g fill="#8FB48E" opacity=".48"><path d="M168 790C42 725 20 596 55 500C168 526 230 639 168 790Z"/><path d="M179 1010C330 943 407 816 372 704C235 734 142 855 179 1010Z"/><path d="M1043 960C916 906 860 790 894 676C1020 700 1095 822 1043 960Z"/><path d="M1058 1195C1178 1128 1218 1012 1179 914C1075 956 1019 1070 1058 1195Z"/></g><g fill="#C86D5D" opacity=".58"><circle cx="300" cy="265" r="62"/><circle cx="876" cy="370" r="42"/><circle cx="176" cy="1360" r="33"/></g><g fill="#F2D8A8" opacity=".9"><circle cx="300" cy="265" r="20"/><circle cx="876" cy="370" r="14"/><circle cx="176" cy="1360" r="11"/></g><path d="M320 1630C528 1510 720 1510 944 1630" fill="none" stroke="#F8F2E7" stroke-width="18" stroke-linecap="round" opacity=".8"/></svg>""",
    ("botanical", "dark"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="80" y1="0" x2="1120" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#182B25"/><stop offset=".55" stop-color="#264437"/><stop offset="1" stop-color="#172D25"/></linearGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><g fill="none" stroke="#89AC86" stroke-width="11" stroke-linecap="round" opacity=".55"><path d="M80 1800C170 1460 202 1110 152 760C130 610 165 452 278 328"/><path d="M1120 1800C1022 1510 1010 1230 1062 925C1094 738 1040 558 915 430"/></g><g fill="#608764" opacity=".46"><path d="M168 790C42 725 20 596 55 500C168 526 230 639 168 790Z"/><path d="M179 1010C330 943 407 816 372 704C235 734 142 855 179 1010Z"/><path d="M1043 960C916 906 860 790 894 676C1020 700 1095 822 1043 960Z"/><path d="M1058 1195C1178 1128 1218 1012 1179 914C1075 956 1019 1070 1058 1195Z"/></g><g fill="#D88C7D" opacity=".72"><circle cx="300" cy="265" r="62"/><circle cx="876" cy="370" r="42"/><circle cx="176" cy="1360" r="33"/></g><g fill="#F0D5A8"><circle cx="300" cy="265" r="20"/><circle cx="876" cy="370" r="14"/><circle cx="176" cy="1360" r="11"/></g></svg>""",
    ("celestial", "light"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="90" y1="0" x2="1120" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#FBF5EB"/><stop offset=".42" stop-color="#E8E2F8"/><stop offset="1" stop-color="#B8B0E4"/></linearGradient><radialGradient id="p"><stop stop-color="#F7D899"/><stop offset=".7" stop-color="#D48F6A"/><stop offset="1" stop-color="#A95B5C"/></radialGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><ellipse cx="900" cy="460" rx="330" ry="145" fill="none" stroke="#695EA8" stroke-width="14" opacity=".36" transform="rotate(-17 900 460)"/><circle cx="900" cy="460" r="125" fill="url(#p)"/><ellipse cx="190" cy="1440" rx="430" ry="188" fill="none" stroke="#FFFFFF" stroke-width="18" opacity=".52" transform="rotate(18 190 1440)"/><circle cx="190" cy="1440" r="165" fill="#6C62A9" opacity=".74"/><g fill="#564E8E" opacity=".68"><circle cx="160" cy="290" r="8"/><circle cx="340" cy="460" r="5"/><circle cx="1020" cy="980" r="7"/><circle cx="730" cy="1290" r="6"/></g><g stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity=".85"><path d="M280 190V242M254 216H306"/><path d="M1005 1170V1230M975 1200H1035"/><path d="M540 880V918M521 899H559"/></g><path d="M90 660C375 770 630 765 1110 610" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-dasharray="4 30" stroke-linecap="round" opacity=".55"/></svg>""",
    ("celestial", "dark"): """<svg width="1200" height="1800" viewBox="0 0 1200 1800" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" x1="90" y1="0" x2="1120" y2="1800" gradientUnits="userSpaceOnUse"><stop stop-color="#16172C"/><stop offset=".42" stop-color="#29264D"/><stop offset="1" stop-color="#17162E"/></linearGradient><radialGradient id="p"><stop stop-color="#FFE2A6"/><stop offset=".7" stop-color="#D88D71"/><stop offset="1" stop-color="#83465F"/></radialGradient></defs><rect width="1200" height="1800" fill="url(#g)"/><ellipse cx="900" cy="460" rx="330" ry="145" fill="none" stroke="#A99AEF" stroke-width="12" opacity=".45" transform="rotate(-17 900 460)"/><circle cx="900" cy="460" r="125" fill="url(#p)"/><ellipse cx="190" cy="1440" rx="430" ry="188" fill="none" stroke="#C7BCFF" stroke-width="16" opacity=".36" transform="rotate(18 190 1440)"/><circle cx="190" cy="1440" r="165" fill="#6557A9" opacity=".8"/><g fill="#F4EFFF"><circle cx="160" cy="290" r="8"/><circle cx="340" cy="460" r="5"/><circle cx="1020" cy="980" r="7"/><circle cx="730" cy="1290" r="6"/></g><g stroke="#FFE8B8" stroke-width="5" stroke-linecap="round" opacity=".88"><path d="M280 190V242M254 216H306"/><path d="M1005 1170V1230M975 1200H1035"/><path d="M540 880V918M521 899H559"/></g><path d="M90 660C375 770 630 765 1110 610" fill="none" stroke="#A99AEF" stroke-width="8" stroke-dasharray="4 30" stroke-linecap="round" opacity=".65"/></svg>""",
}


def _asset_manifest_lines() -> list[str]:
    deliverables = (
        sorted(COLLECTIONS_ROOT.rglob("*.png"))
        + sorted(BACKGROUNDS_ROOT.glob("*.jpg"))
        + [Path(__file__).resolve(), SKIN_ROOT / "LICENSE-ICONPARK-APACHE-2.0.txt"]
    )
    return [
        f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(SKIN_ROOT)}"
        for path in deliverables
    ]


def build(
    *,
    slots: tuple[str, ...] | None = None,
    include_backgrounds: bool = True,
    write_manifest: bool = False,
) -> None:
    if MAGICK is None or SIPS is None:
        raise SystemExit("macOS `sips` and ImageMagick `magick` are required")
    selected_slots = tuple(ICONS) if slots is None else slots
    unknown_slots = set(selected_slots).difference(ICONS)
    if unknown_slots:
        raise SystemExit(f"Unknown icon slots: {', '.join(sorted(unknown_slots))}")
    with tempfile.TemporaryDirectory(prefix="origo-skins-") as temp_dir:
        temp = Path(temp_dir)
        for theme_id in THEMES:
            output_dir = COLLECTIONS_ROOT / theme_id / "icons"
            output_dir.mkdir(parents=True, exist_ok=True)
            for slot in selected_slots:
                for brightness in ("light", "dark"):
                    for selected in (False, True):
                        suffix = "-selected" if selected else ""
                        if brightness == "dark":
                            suffix += "-dark"
                        source = temp / f"{theme_id}-{slot}{suffix}.svg"
                        source.write_text(
                            _icon_svg(theme_id, slot, brightness, selected),
                            encoding="utf-8",
                        )
                        output = output_dir / f"{slot}{suffix}.png"
                        rendered = temp / f"{theme_id}-{slot}{suffix}.png"
                        _run(SIPS, "-s", "format", "png", str(source), "--out", str(rendered))
                        _run(
                            MAGICK,
                            str(rendered),
                            "-strip",
                            "-depth",
                            "8",
                            "-colors",
                            "96",
                            f"PNG8:{output}",
                        )

        if include_backgrounds:
            BACKGROUNDS_ROOT.mkdir(parents=True, exist_ok=True)
            for (theme_id, brightness), svg in BACKGROUND_SVGS.items():
                source = temp / f"{theme_id}-{brightness}.svg"
                source.write_text(svg, encoding="utf-8")
                suffix = "-dark" if brightness == "dark" else ""
                output = BACKGROUNDS_ROOT / f"{theme_id}{suffix}.jpg"
                rendered = temp / f"{theme_id}-{brightness}.png"
                _run(SIPS, "-s", "format", "png", str(source), "--out", str(rendered))
                _run(
                    MAGICK,
                    str(rendered),
                    "-strip",
                    "-depth",
                    "8",
                    "-sampling-factor",
                    "4:2:0",
                    "-quality",
                    "84",
                    str(output),
                )

    lines = _asset_manifest_lines()
    if write_manifest:
        (SKIN_ROOT / "MANIFEST.sha256").write_text(
            "\n".join(lines) + "\n",
            encoding="utf-8",
        )
    else:
        print("\n".join(lines))


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--slots",
        nargs="+",
        choices=tuple(ICONS),
        help="Generate only these semantic slots. Defaults to every slot.",
    )
    parser.add_argument(
        "--expanded-only",
        action="store_true",
        help="Generate the Origo X original expansion without touching the original 16 slots.",
    )
    parser.add_argument(
        "--skip-backgrounds",
        action="store_true",
        help="Do not regenerate the six existing background JPEGs.",
    )
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help="Refresh MANIFEST.sha256 after generation instead of printing it.",
    )
    args = parser.parse_args()
    if args.expanded_only and args.slots:
        parser.error("--expanded-only cannot be combined with --slots")
    return args


if __name__ == "__main__":
    arguments = _parse_args()
    build(
        slots=EXPANDED_ICON_SLOTS if arguments.expanded_only else (
            tuple(arguments.slots) if arguments.slots else None
        ),
        include_backgrounds=not arguments.skip_backgrounds,
        write_manifest=arguments.write_manifest,
    )
