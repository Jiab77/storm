<div align="center">
  <h1>Storm<br>Fast Download Manager</h1>
  <p>Simple script for downloading files as fast as posssible.</p>
</div>

## Status

This project is still experimental and might contains some bugs. Please fill an issue if you find one.

## Usage

### Download single URL to the current folder

```console
./storm.sh <url>
```

### Downlaod multiple URLs to the current folder

```console
./storm.sh links.txt
```

> The file `links.txt` must contains one URL per line and must end with a blank line.

## Why this name?

When discussing with __`0xD1G`__ about this project, he gave me few ideas where "storm" was mentioned. It directly came to my mind that was "the" name to use for this project due to the high download speed it can acheive and the impact on the underlaying storage which is like a storm! 😅

## How it works?

The script will look for several binaries and use any of them from the faster to the slower one based on my tests.

For example, if you have any or all the supported binaries installed, it will try them in the following order:

1. `aria2`
2. `pget`
3. `lftp`
4. `curl`
5. `wget`

However, the script needs to have at least `curl` or `wget` to be installed for running.

## Known issues

Please read this section before creating any new issues.

### Slow download speed

High download speed can be only achieved by installing one of the following binaries: `aria2`, `lftp`, `pget`. However, during the tests, only `aria2` remained constant and reached the fastest download speed on local and network attached storage.

It's not the case with `lftp` and particularly for `pget` that claims to be the fastest download binary but it's completely wrong.

`pget` is certainly fast __*but only on local storage*__ and even that, `lftp` appeared to be sometimes faster than it during my tests...

When used on a network attached storage, the download speed of `pget` is dramatically slow... Using `curl` or `wget` instead would make no difference when the output file is not written locally.

__Conclusion:__

If you want high download speed on both local and network attached storage, please install `aria2`. If you can't, install `lftp` instead. But if you plan to download files only locally, then `pget` is a good choice.

### Unsupported chars when using the `links.txt` file

I still have to figure out why for example, the `&` char is not supported when reading the URLs from a text file. It should be fixed in the future versions.

## Thanks

To __`0xD1G`__ for the great project name! 🤘

## Author

* __Jiab77__