# VCRSS

Create your own VCR/TiVo that downloads videos from RSS or Atom feeds using command line tools such as [youtube-dl](https://github.com/rg3/youtube-dl) and [svtplay-dl](https://github.com/spaam/svtplay-dl).

Why not setup a Raspberry PI or a [Digital Ocean VPS](https://m.do.co/c/5027f75bc292) and have this thing run continuously using a cron job?

## Installation

1. Make sure you have [Ruby](https://www.ruby-lang.org/) installed.
2. Install a download tool – [youtube-dl](https://github.com/rg3/youtube-dl), [svtplay-dl](https://github.com/spaam/svtplay-dl) and/or anything similar.
3. Create your `config.yml` and setup your feed(s).
4. Run `ruby vcrss.rb`

## Configuration

Create a file called `config.yml`. You can add as many feeds as you need.

### Example config.yml

```
feeds:
  - url: "https://www.foobar.com/baz.xml"
    filters:
      - "Foo"
      - "Bar"
      - "Baz"
    binary: "youtube-dl"
    options: " -f -o 'downloads/foo-bar-baz'"
```

**url** *(required)*  
The URL to the RSS feed.

**filters**  
You can specify as many filters as you want. Only videos with titles containing any of these words or phrases will be downloaded.

**binary**  
*default: youtube-dl*  
Specify which binary you want to use to download videos from that feed.

**options**  
*default:  --all-subs -o 'downloads/%(title)s-%(id)s.%(ext)s'*  
Provide a custom configuration for the binary.

**pipes**
*default: ""*  
Add your pipes of necessary. For example you can achieve streaming to [VLC](http://www.videolan.org) by using:  
`pipes: " | vlc -"` 

### Example config.yml for SVT Play

If you want to download episodes of [Vetenskapens värld](http://www.svtplay.se/vetenskapens-varld) then use the following:

```
feeds:
  - url: "http://www.svtplay.se/vetenskapens-varld/rss.xml"
    binary: "svtplay-dl"
    options: " -f -S -o 'downloads/'"
```

Some notes on the options that's svtplay-dl specific:

`-f` overwrites file if it already exists  
`-S` downloads available subtitles

### Example using filters

The following will download videos with "Stellaris" in it from the [Paradox Interactive YouTube channel](https://www.youtube.com/user/Paradoxplaza).

```
feeds:
  - url: "https://www.youtube.com/feeds/videos.xml?channel_id=UC1JOnWZrVWKzX3UMdpnvuMg"
    filters:
      - "Stellaris"
```

### Example using multiple feeds

```
feeds:
  - url: "http://www.svtplay.se/vetenskapens-varld/rss.xml"
    binary: "svtplay-dl"
    options: " -f -S -o 'downloads/'"
  - url: "https://www.youtube.com/feeds/videos.xml?channel_id=UC1JOnWZrVWKzX3UMdpnvuMg"
    filters:
      - "Stellaris"
```
