from pathlib import Path, PurePosixPath
from tempfile import TemporaryDirectory
from zipfile import ZIP_DEFLATED, ZipFile


def main():
    repo = Path(__file__).resolve().parents[2]
    lua_root = repo / "src/mwse"
    fixture = repo / "tests/fixtures/GHSO Gold Check.esp"
    data_files = PurePosixPath("Data Files")
    for required in (lua_root / "mods/GHSO/main.lua", fixture):
        if not required.is_file():
            raise FileNotFoundError(required)

    entries = [(fixture, data_files / fixture.name)]
    for root, destination in (
        (lua_root, data_files / "MWSE"),
        (repo / "content/plugins", data_files),
        (repo / "content/assets", data_files),
    ):
        for file in sorted(root.rglob("*")):
            if file.is_file():
                entries.append((file, destination / file.relative_to(root).as_posix()))

    output = repo / "release/GHSO-test.zip"
    output.parent.mkdir(exist_ok=True)
    with TemporaryDirectory(dir=output.parent) as temporary:
        staged_zip = Path(temporary) / output.name
        written = set()
        with ZipFile(staged_zip, "w", ZIP_DEFLATED) as archive:
            for source, entry in entries:
                name = entry.as_posix()
                key = name.casefold()
                if key in written:
                    raise ValueError(f"Multiple source files map to ZIP entry {name!r}")
                archive.write(source, name)
                written.add(key)
        staged_zip.replace(output)

    print(output)


if __name__ == "__main__":
    main()
